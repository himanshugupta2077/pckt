import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/ingestion/ingestion_service.dart';
import 'package:pckt/ingestion/parser/parsed_txn.dart';

void main() {
  late AppDatabase db;
  late IngestionService svc;
  var seq = 0;

  RawInput msg(String sender, String body, DateTime at, {SourceKind source = SourceKind.sms}) =>
      RawInput(source: source, externalId: '${seq++}', sender: sender, body: body, receivedAt: at);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    svc = IngestionService(db);
  });
  tearDown(() => db.close());

  final t0 = DateTime(2026, 10, 12, 20, 0);

  test('same UPI ref from SMS and email merges into one transaction', () async {
    await svc.ingest([
      msg('VM-HDFCBK', 'Sent Rs.250.00 From HDFC Bank A/C *4521 To SWIGGY On 12/10/26 Ref 528512345678', t0),
      msg(
        'alerts@hdfcbank.net',
        'Dear Customer, Rs.250.00 has been debited from account **4521 to VPA swiggy@icici SWIGGY on 12-10-26. '
            'Your UPI transaction reference number is 528512345678.',
        t0.add(const Duration(hours: 2)),
        source: SourceKind.email,
      ),
    ]);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(1));
    expect(txns.single.status, TxnStatus.confirmed);
    expect(await db.sourcesOf(txns.single.id), hasLength(2));
  });

  test('two identical chai payments from the same bank stay separate', () async {
    await svc.ingest([
      msg('VM-KOTAKB', 'Sent Rs.20.00 from Kotak Bank AC X5555 to chaiwala@ybl on 12-10-26.', t0),
      msg(
        'VM-KOTAKB',
        'Sent Rs.20.00 from Kotak Bank AC X5555 to chaiwala@ybl on 12-10-26.',
        t0.add(const Duration(minutes: 3)),
      ),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(2));
  });

  test('card alert and bill-pay confirmation from the same bank merge', () async {
    await svc.ingest([
      msg('AD-HDFCBK-S', 'Spent Rs.880 On HDFC Bank Card 1234 At HDFCBPELEC On 2026-10-12:20:00:27.', t0),
      msg(
        'JM-HDFCBK-S',
        'Bill Paid! City Elec Bill 1111 of Rs. 880.00 paid on 12-Oct-2026 from HDFC Bank Credit Card 1234. '
            'BillPay Ref: HGAMP0000TEST00002',
        t0,
      ),
    ]);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(1));
    expect(txns.single.merchant, 'Hdfcbpelec');
    expect(txns.single.reference, 'HGAMP0000TEST00002');
  });

  test("a merchant's own receipt SMS merges with the bank alert", () async {
    await svc.ingest([
      msg('AD-HDFCBK-S', 'Spent Rs.299 On HDFC Bank Card 1234 At HOTSTAR On 2026-10-12:20:00:04.', t0),
      msg('VA-JIOHTT-S', 'Yay! Premium 1 Month is successfully activated. Amount paid: Rs.299.00.', t0),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('two formats from one bank half an hour apart go to review, not merged', () async {
    await svc.ingest([
      msg('AD-HDFCBK-S', 'Sent Rs.500.00 From HDFC Bank A/C *1111 To SHOP On 12/10/26', t0),
      msg('JM-HDFCBK-S', 'Update! INR 500.00 debited from HDFC Bank A/c XX1111', t0.add(const Duration(minutes: 20))),
    ]);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(2));
    expect(txns.last.duplicateOfId, txns.first.id);
  });

  test('two bill payments of the same amount from one bank stay separate', () async {
    await svc.ingest([
      msg(
        'JM-HDFCBK-S',
        'Bill Paid! Airtel Bill 1111 of Rs. 349.00 paid on 12-Oct-2026 from HDFC Bank Credit Card 1234.',
        t0,
      ),
      msg(
        'JM-HDFCBK-S',
        'Bill Paid! Jio Bill 2222 of Rs. 349.00 paid on 12-Oct-2026 from HDFC Bank Credit Card 1234.',
        t0,
      ),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(2));
  });

  test('resolveDuplicates merges sure matches flagged earlier, keeping the richer one', () async {
    final card = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountMinor: 58700,
            direction: TxnDirection.debit,
            occurredAt: t0,
            merchant: const Value('Hdfcbpelec'),
            accountHint: const Value('1234'),
            mode: PaymentMode.card,
            status: TxnStatus.confirmed,
          ),
        );
    final bill = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountMinor: 58700,
            direction: TxnDirection.debit,
            occurredAt: t0,
            accountHint: const Value('1234'),
            reference: const Value('HGAMP0001'),
            mode: PaymentMode.card,
            status: TxnStatus.needsReview,
            duplicateOfId: Value(card),
            bucket: const Value(Bucket.fixed),
          ),
        );
    Future<void> raw(int txn, String sender, String body) => db
        .into(db.rawMessages)
        .insert(
          RawMessagesCompanion.insert(
            source: SourceKind.sms,
            externalId: '${seq++}',
            sender: sender,
            body: body,
            receivedAt: t0,
            parseStatus: ParseStatus.parsed,
            transactionId: Value(txn),
          ),
        );
    await raw(card, 'AD-HDFCBK-S', 'Spent Rs.587 On HDFC Bank Card 1234 At HDFCBPELEC');
    await raw(bill, 'JM-HDFCBK-S', 'Bill Paid! Elec Bill of Rs. 587.00 paid from HDFC Bank Credit Card 1234');

    expect(await svc.resolveDuplicates(), hasLength(1));
    final kept = await db.select(db.transactions).getSingle();
    expect(kept.id, card); // it names the merchant
    expect(kept.merchant, 'Hdfcbpelec');
    expect(kept.duplicateOfId, isNull);
    expect(kept.status, TxnStatus.confirmed);
    expect(kept.bucket, Bucket.fixed); // carried over: no payee rule says otherwise
    expect(kept.reference, 'HGAMP0001');
    expect(await db.sourcesOf(kept.id), hasLength(2));
  });

  test("one card bill's bank debit and the card's two confirmations are one transfer", () async {
    await svc.ingest([
      msg(
        'AD-HDFCBK-S',
        'DEAR HDFCBANK CARDMEMBER, PAYMENT OF Rs. 6083.00 RECEIVED TOWARDS YOUR CREDIT CARD ENDING WITH 1234 ON 1-11-2026.',
        t0,
      ),
      msg(
        'JX-HDFCBK-S',
        'Alert! Paid Rs. 6,083.00 For: Credit Card payment From HDFC Bank A/c XX1111 Via Online Banking.',
        t0,
      ),
      msg(
        'VM-HDFCBK-S',
        'HDFC Bank Cardmember, Payment of Rs 6083 was credited to your card ending 1234 on 01/NOV/2026.',
        t0.add(const Duration(days: 1)),
      ),
    ]);
    final bill = await db.select(db.transactions).getSingle();
    expect(
      (bill.direction, bill.isTransfer, bill.merchant, bill.accountHint),
      (TxnDirection.debit, true, 'Card bill', '1111'),
    );
    expect(await db.sourcesOf(bill.id), hasLength(3));
  });

  test('a card bill paid through BBPS or CRED pairs with the card side', () async {
    await svc.ingest([
      msg(
        'JM-HDFCBK-S',
        'Bill Paid! ICICI Credit Card Bill 9999999999 of Rs. 577.07 paid on 01-Oct-2026 from HDFC Bank Account XXXXXXXXXX1111.',
        t0,
      ),
      msg(
        'AD-ICICIT-S',
        'Payment of Rs 577.07 has been received on your ICICI Bank Credit Card XX2222 through Bharat Bill Payment System on 01-OCT-26.',
        t0.add(const Duration(minutes: 20)),
      ),
      msg(
        'AX-ICICIT-S',
        'ICICI Bank Acct XX3333 debited for Rs 538.64 on 05-Nov-26; CRED Club credited. UPI:100000000002.',
        t0.add(const Duration(days: 4)),
      ),
    ]);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(2));
    expect(txns.every((t) => t.isTransfer && t.merchant == 'Card bill' && t.direction == TxnDirection.debit), isTrue);
  });

  test('two card bills of the same amount a month apart stay two', () async {
    await svc.ingest([
      msg(
        'JX-HDFCBK-S',
        'Alert! Paid Rs. 500.00 For: Credit Card payment From HDFC Bank A/c XX1111 Via Online Banking.',
        t0,
      ),
      msg(
        'JX-HDFCBK-S',
        'Alert! Paid Rs. 500.00 For: Credit Card payment From HDFC Bank A/c XX1111 Via Online Banking.',
        t0.add(const Duration(days: 30)),
      ),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(2));
  });

  test('different refs never merge', () async {
    await svc.ingest([
      msg('VM-HDFCBK', 'Sent Rs.250.00 From HDFC Bank A/C *4521 To SWIGGY On 12/10/26 Ref 528512345678', t0),
      msg('VM-HDFCBK', 'Sent Rs.250.00 From HDFC Bank A/C *4521 To SWIGGY On 12/10/26 Ref 528512345679', t0),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(2));
  });

  test('ref-less SMS + email close in time with same account merge', () async {
    await svc.ingest([
      msg('AD-HDFCBK', 'Spent Rs.1,299 On HDFC Bank Card 7788 At AMAZON On 2026-10-12:20:00:07.', t0),
      msg(
        'noreply@amazon.in',
        'Payment of Rs.1,299.00 debited from card ending 7788 at Amazon.',
        t0.add(const Duration(minutes: 4)),
        source: SourceKind.email,
      ),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('candidates without a merchant do not crash dedup', () async {
    await svc.ingest([
      msg('VM-SBIINB', 'Rs.2000 withdrawn at SBI ATM from A/cX3456 on 12Oct26.', t0),
      msg('VM-SBIINB', 'Rs.2000 withdrawn at SBI ATM from A/cX3456 on 12Oct26.', t0.add(const Duration(hours: 1))),
      msg('VM-HDFCBK', 'Rs.2000.00 debited from A/c **4521 on 12-10-26.', t0.add(const Duration(hours: 2))),
    ]);
    expect(await db.select(db.transactions).get(), hasLength(3));
  });

  test('re-ingesting the same message is a no-op', () async {
    final m = msg('VM-HDFCBK', 'Sent Rs.250.00 From HDFC Bank A/C *4521 To SWIGGY On 12/10/26 Ref 528512345678', t0);
    await svc.ingest([m]);
    final r = await svc.ingest([m]);
    expect(r.seen, 0);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('debit from one own account + credit to another is a self-transfer', () async {
    await svc.ingest([
      msg(
        'VM-HDFCBK',
        'Rs.10,000.00 debited from A/c **4521 on 12-10-26 via IMPS to ASHA K. IMPS Ref 628512345678',
        t0,
      ),
      msg(
        'VM-ICICIB',
        'Your A/c XX123 has been credited with INR 10,000.00 on 12-Oct-26 by IMPS from ASHA K.',
        t0.add(const Duration(minutes: 1)),
      ),
    ]);
    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(2));
    expect(txns.every((t) => t.isTransfer), isTrue);
    expect(await db.select(db.accounts).get(), hasLength(2));
  });

  test('resetSource drops SMS-only transactions but keeps manual ones', () async {
    await svc.ingest([
      msg('VM-HDFCBK', 'Sent Rs.250.00 From HDFC Bank A/C *4521 To SWIGGY On 12/10/26 Ref 528512345678', t0),
    ]);
    await db.addManual(amountMinor: 5000, direction: TxnDirection.debit, at: t0, merchant: 'Chai');
    await db.resetSource(SourceKind.sms);
    final left = await db.select(db.transactions).get();
    expect(left.map((t) => t.merchant), ['Chai']);
    expect(await db.knownExternalIds(SourceKind.sms), isEmpty);
  });

  test('ignored and categorised', () async {
    final r = await svc.ingest([
      msg('VM-HDFCBK', '123456 is your OTP for txn of Rs.2,000 at AMAZON.', t0),
      msg(
        'JD-ICICIT',
        'ICICI Bank Acct XX123 debited for Rs 180.00 on 12-Oct-26; ZOMATO LTD credited. UPI:528598765432.',
        t0,
      ),
    ]);
    expect(r.ignored, 1);
    final view = (await db.watchTxns().first).single;
    expect(view.category?.name, 'Food & Dining');
    expect(view.account?.name, 'ICICI Bank');
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/alerts/sort_alerts.dart';
import 'package:pckt/features/budgets/in_budget.dart';
import 'package:pckt/ingestion/ingestion_service.dart';
import 'package:pckt/ingestion/parser/parsed_txn.dart';

void main() {
  late AppDatabase db;
  late IngestionService svc;
  final at = DateTime(2026, 11, 6, 12);
  const upi =
      'Dear UPI user A/C X3456 debited by 250.0 on date 06Nov26 trf to RAHUL SHARMA Refno 528511112222. '
      'If not u? call 1800111109. -SBI';

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    svc = IngestionService(db);
  });
  tearDown(() => db.close());

  Future<TxnView> view(int id) async => (await db.watchTxn(id).first)!;

  Future<TxnView> ingested() async {
    await svc.ingest([
      RawInput(source: SourceKind.sms, externalId: '1', sender: 'BZ-SBIUPI', body: upi, receivedAt: at),
    ]);
    // The SMS app may lay out the parts with different whitespace.
    final raw = await findSms(db, upi.replaceAll('. ', '.  '), at);
    return view(raw!.transactionId!);
  }

  test('a UPI payment to a new person becomes a bucket question', () async {
    final v = await ingested();
    final q = questionFor(v)!;
    expect(q.title, '₹250 to Rahul Sharma');
    expect(q.credit, isFalse);
  });

  test('a payee with an answer or a telling category is not asked about', () async {
    final v = await ingested();
    await db.setPayeeBucket(v.txn.merchant!, Bucket.everyday);
    expect(questionFor(await view(v.txn.id)), isNull);

    final food = (await db.allCategories()).firstWhere((c) => c.name == 'Food & Dining');
    final id = await db.addManual(
      amountMinor: 9900,
      direction: TxnDirection.debit,
      at: at,
      merchant: 'Swiggy',
      categoryId: food.id,
    );
    expect(questionFor(await view(id)), isNull);
  });

  test('money in from a person asks income, lending or transfer', () async {
    final id = await db.addManual(amountMinor: 500000, direction: TxnDirection.credit, at: at, merchant: 'Ramesh K');
    final q = questionFor(await view(id))!;
    expect((q.title, q.credit), ('₹5,000 from Ramesh K', true));
  });

  test('Everyday answers for the payee, Lending for one payment, and survives it', () async {
    final first = await ingested();
    final second = await db.addManual(
      amountMinor: 30000,
      direction: TxnDirection.debit,
      at: at.add(const Duration(days: 1)),
      merchant: first.txn.merchant,
    );
    await applyAlertAnswers(db, [AlertAnswer(txnId: first.txn.id, rawId: 0, choice: 'lending')]);
    expect(budgetDecision(await view(first.txn.id)).bucket, Bucket.lending);
    expect(questionFor(await view(second)), isNotNull, reason: 'Lending is not a payee answer');

    await applyAlertAnswers(db, [AlertAnswer(txnId: second, rawId: 0, choice: 'everyday')]);
    expect(budgetDecision(await view(second)).source, BudgetSource.payee);
    expect(budgetDecision(await view(first.txn.id)).bucket, Bucket.lending, reason: 'the loan stays Lending');
  });

  test('an answer finds the payment through its SMS when the id is gone', () async {
    final v = await ingested();
    final raw = await findSms(db, upi, at);
    await applyAlertAnswers(db, [AlertAnswer(txnId: 9999, rawId: raw!.id, choice: 'fixed')]);
    expect(budgetDecision(await view(v.txn.id)).bucket, Bucket.fixed);
  });

  test('income and unknown choices change nothing', () async {
    final v = await ingested();
    await applyAlertAnswers(db, [
      AlertAnswer(txnId: v.txn.id, rawId: 0, choice: 'income'),
      AlertAnswer(txnId: v.txn.id, rawId: 0, choice: 'nonsense'),
    ]);
    expect(questionFor(await view(v.txn.id)), isNotNull);
  });

  test('Transfer on money in marks it a transfer', () async {
    final id = await db.addManual(amountMinor: 150000, direction: TxnDirection.credit, at: DateTime(2026, 11, 1));
    await applyAlertAnswers(db, [AlertAnswer(txnId: id, rawId: 0, choice: 'transfer')]);
    expect((await db.watchTxn(id).first)!.txn.isTransfer, isTrue);
  });
}

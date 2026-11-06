import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/ingestion/categorizer.dart';
import 'package:pckt/ingestion/parser/parsed_txn.dart';
import 'package:pckt/ingestion/parser/sms_parser.dart';
import 'package:pckt/ingestion/parser/text_utils.dart';

/// Regression tests built from real (masked) messages that were mis-parsed.
ParsedTxn ok(String sender, String body) {
  final r = const SmsParser().parse(
    RawInput(source: SourceKind.sms, externalId: '1', sender: sender, body: body, receivedAt: DateTime(2026, 9, 6)),
  );
  expect(r, isA<Parsed>(), reason: 'expected parse for: $body, got $r');
  return (r as Parsed).txn;
}

void main() {
  group('dates are never merchants', () {
    for (final s in [
      'Sep 06',
      'SEP 06, 2026',
      '06-Sep-26',
      '6th Sept 2026',
      '12Oct26',
      '06/09/26',
      '2026-10-12',
      '20:11:07',
      '08:01 PM',
      'September',
      'Sep 06 refund',
      'Mon, 06 Sep',
    ]) {
      test('"$s"', () {
        expect(isDateLike(s), isTrue);
        expect(cleanMerchant(s), isNull);
      });
    }

    test('real names survive, trailing dates are stripped', () {
      expect(cleanMerchant('SWIGGY'), 'Swiggy');
      expect(cleanMerchant('AMAZON 06-Sep-26'), 'Amazon');
      expect(cleanMerchant('MAYUR STORES'), 'Mayur Stores');
      expect(cleanMerchant('Marriott'), 'Marriott');
      expect(cleanMerchant('BOX8'), 'Box8');
      expect(cleanMerchant('June'), isNull);
    });
  });

  group('refund / credit templates', () {
    test('card credit "by <date> refund" has no date merchant', () {
      final t = ok('AD-HDFCBK-S', 'Rs.500 credited to HDFC Bank Card x1234 by Sep 06 refund');
      expect(t.direction, TxnDirection.credit);
      expect(t.merchant, isNull);
    });

    test('reversal "from <date> txn"', () {
      final t = ok('AD-HDFCBK-S', 'Reversal of Rs 250.00 credited to HDFC Bank Card x1234 from Sep 06 txn');
      expect(t.direction, TxnDirection.credit);
      expect(t.amountMinor, 25000);
      expect(t.merchant, isNull);
    });

    test('OneCard refund received "from <date> transaction"', () {
      final t = ok(
        'AD-ONECRD-S',
        'Refund received! Rs 250 from Sep 06, 2026 transaction has been credited to your OneCard',
      );
      expect(t.direction, TxnDirection.credit);
      expect(t.merchant, isNull);
    });

    test('multi-line credit alert with "From <date>"', () {
      final t = ok('VM-HDFCBK-S', 'Credit Alert!\nRs.250.00 credited to HDFC Bank Card x1234\nFrom Sep 06');
      expect(t.merchant, isNull);
    });

    test('date before the real merchant: picks the merchant', () {
      final t = ok('VM-HDFCBK-S', 'Credit Alert!\nRs.250.00 credited to HDFC Bank Card x1234 on Sep 06\nFrom AMAZON');
      expect(t.merchant, 'Amazon');
    });

    test('refund "for transaction dated <date> at MERCHANT"', () {
      final t = ok(
        'AD-HDFCBK-S',
        'Dear Customer, Rs.250.00 has been refunded to your HDFC Bank Credit Card XX1234 for transaction dated Sep 06 at SWIGGY',
      );
      expect(t.direction, TxnDirection.credit);
      expect(t.merchant, 'Swiggy');
    });

    test('reversed by MERCHANT on <date>', () {
      final t = ok(
        'JM-HDFCBK-S',
        'Dear Customer, Rs.1250.00 has been reversed to HDFC Bank Card XX1234 by SWIGGY on Sep 06, 2026',
      );
      expect(t.merchant, 'Swiggy');
    });
  });

  group('people', () {
    test('HDFC IMPS credit with single concatenated name is a person', () {
      final t = ok(
        'VD-HDFCBK-S',
        'Received! INR 2,000.00 in HDFC Bank A/c xx6610 On 06-09-26 For IMPS -UCHITRAM- 624912345678 Avl bal INR 12,456.00',
      );
      expect(t.merchant, 'Uchitram');
      expect(t.isPersonToPerson, isTrue);
    });

    test('IMPS debit to a single-word name is a person', () {
      final t = ok(
        'VM-KOTAKB-S',
        'Sent IMPS Rs.1,500.00 from Kotak Bank AC X5555 to UCHITRAM on 06-09-26. IMPS Ref 624912345678',
      );
      expect(t.merchant, 'Uchitram');
      expect(t.isPersonToPerson, isTrue);
    });

    test('IMPS to a business is not a person', () {
      final t = ok(
        'VM-KOTAKB-S',
        'Sent IMPS Rs.1,500.00 from Kotak Bank AC X5555 to SHREEJI TRADERS on 06-09-26. IMPS Ref 624912345678',
      );
      expect(t.isPersonToPerson, isFalse);
    });

    test('single-word UPI P2M merchant is not a person', () {
      final t = ok(
        'AX-AXISBK-S',
        'INR 99.00 debited\nA/c no. XX7890\n06-09-26\nUPI/P2M/528533334444/BLINKIT\nAxis Bank',
      );
      expect(t.isPersonToPerson, isFalse);
    });

    test('IME India remittance is person-to-person', () {
      final t = ok(
        'AD-IMEIND-S',
        'Successfully sent 15000.00 to DASHI RAM THARU. Please provide ICN: 12345678901 to the beneficiary only. -IME India',
      );
      expect(t.isPersonToPerson, isTrue);
      expect(t.institution, 'IME India');
    });
  });

  group('categories', () {
    late AppDatabase db;
    late Categorizer cat;
    late Map<int, String> names;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
      final cats = await db.allCategories();
      names = {for (final c in cats) c.id: c.name};
      cat = Categorizer(cats, const []);
    });
    tearDown(() => db.close());

    String? categoryOf(String sender, String body) => names[cat.categorize(ok(sender, body), body)];

    test('Indian Railways → Transport', () {
      expect(
        categoryOf(
          'AD-HDFCBK-S',
          'Spent Rs.30 From HDFC Bank Card x1234 At INDIAN RAILWAYS On 2026-09-06:10:11:12 Bal Rs.5000.00',
        ),
        'Transport',
      );
    });

    test('UTS ticket → Transport', () {
      expect(
        categoryOf(
          'VM-HDFCBK-S',
          'Sent Rs.15.00\nFrom HDFC Bank A/C *4521\nTo UTS MOBILE TICKET\nOn 06/09/26\nRef 624912345678',
        ),
        'Transport',
      );
    });

    test('IRCTC UPI → Transport', () {
      expect(
        categoryOf('VM-HDFCBK-S', 'Sent Rs.845.00\nFrom HDFC Bank A/C *4521\nTo IRCTC\nOn 06/09/26\nRef 624912345678'),
        'Transport',
      );
    });

    test('IME India remittance → People', () {
      expect(
        categoryOf(
          'AD-IMEIND-S',
          'Successfully sent 15000.00 to DASHI RAM THARU. Please provide ICN: 12345678901 to the beneficiary only. -IME India',
        ),
        'People',
      );
    });

    test('IMPS to single-word person → People', () {
      expect(
        categoryOf(
          'VM-KOTAKB-S',
          'Sent IMPS Rs.1,500.00 from Kotak Bank AC X5555 to UCHITRAM on 06-09-26. IMPS Ref 624912345678',
        ),
        'People',
      );
    });

    test('date-merchant refund still lands in Refunds', () {
      expect(
        categoryOf('AD-HDFCBK-S', 'Reversal of Rs 250.00 credited to HDFC Bank Card x1234 from Sep 06 txn'),
        'Refunds & Cashback',
      );
    });
  });

  group('notices and bank footers', () {
    ParseResult parse(String sender, String body) => const SmsParser().parse(
      RawInput(source: SourceKind.sms, externalId: '1', sender: sender, body: body, receivedAt: DateTime(2026, 10, 6)),
    );

    test('"not debited" is not a payment', () {
      expect(
        parse(
          'AX-ICICIT-S',
          'Your account is not debited with Rs 59.00 towards Google Play for GOOGLE due to cbs rejection 0116, RRN 123456789012-ICICI Bank.',
        ),
        isA<Ignored>(),
      );
    });

    test('a real debit that mentions a notice phrase still counts', () {
      final t = ok('AD-HDFCBK-S', 'Rs.500.00 debited from A/c XX1111 to SHOP. Charges will be deducted separately.');
      expect(t.amountMinor, 50000);
    });

    test('FD sweep and pre-debit notices are not payments', () {
      expect(
        parse(
          'AD-HDFCBK-S',
          'FD XX1111 of INR 5,000.00 will be liquidated for INR 128.00 for sweep in debit from A/c XX2222. Add money to your HDFC Bank A/c to avoid liquidation.',
        ),
        isA<Ignored>(),
      );
      expect(
        parse(
          'JX-HDFCBK-S',
          'E-Mandate!\nRs.75.00 will be deducted on 02/11/26, 00:00:00\nFor APPLE MEDIA SERVICES mandate\nUMN 0000test0000@okhdfcbank\nMaintain Balance\n-HDFC Bank',
        ),
        isA<Ignored>(),
      );
    });

    test('"To Block and Reissue" footer is not the merchant', () {
      final t = ok(
        'AD-HDFCBK-S',
        'Amount Spent: Rs.649 with HDFC Bank Credit Card 1234 at NETFLIX on 2026-10-14:22:06:24 This transaction was completed without any additional authentication factor mandated by RBI. Not You? To Block and Reissue, please call 18002586161 or SMS BLOCK CC 1234 to 7308080808',
      );
      expect(t.merchant, 'Netflix');
      expect(t.amountMinor, 64900);
    });

    test('"To dispute" footer is not the merchant', () {
      final t = ok(
        'BP-ICICIT-S',
        'Rs 1,250.00 spent on ICICI Bank Card XX1234 on 01-Nov-26 at 1449 DSI DEHRAD. Avl Lmt: Rs 50,000.00. To dispute, call 18002662/SMS BLOCK 1234 to 9215676766. To convert this txn to EMI give a missed call on 9999999999.',
      );
      expect(t.merchant, '1449 Dsi Dehrad');
      expect(t.amountMinor, 125000);
    });

    test('"to report" footer is not the merchant', () {
      final t = ok(
        'AD-HDFCBK-S',
        'HDFC Bank:Rs. 500.00 debited from a/c *1111 on 01/09/26 to a/c **2222 (UPI Ref No. 100000000001). Not you? Call on 18002586161 to report',
      );
      expect(t.merchant, isNull);
    });

    test('card bill payments are transfers', () {
      expect(
        ok(
          'VM-HDFCBK-S',
          'HDFC Bank Cardmember, Payment of Rs 6083 was credited to your card ending 1234 on 01/NOV/2026.',
        ).transferHint,
        isTrue,
      );
      expect(
        ok(
          'AD-HDFCBK-S',
          'Bill Paid! ICICI Credit Card Bill 9999999999 of Rs. 577.07 paid on 01-Oct-2026 from HDFC Bank Account XXXXXXXXXX1111. BillPay Ref: HGAMP0000TEST00001',
        ).transferHint,
        isTrue,
      );
    });
  });

  test('refunds and cashback to a card are not card bills', () {
    for (final body in [
      'Refund of Rs 500.00 credited to your HDFC Bank Credit Card XX1234 from AMAZON on 01-11-26.',
      'Cashback of Rs 50 has been credited to your card ending 1234.',
    ]) {
      final t = ok('AD-HDFCBK-S', body);
      expect((t.cardBill, t.merchant == 'Card bill'), (false, false), reason: body);
    }
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/dashboard/buckets_card.dart';
import 'package:pckt/features/plan/balances.dart';
import 'package:pckt/features/plan/balances_card.dart';
import 'package:pckt/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_test.dart' show memoryDb;

/// AppTheme without its Google Fonts (they download at runtime): the app's
/// filled buttons are full width, which breaks a Row that doesn't size them.
final appLikeTheme = ThemeData.dark().copyWith(
  filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54))),
);

BalanceSnapshot snap(DateTime month, String label, int minor, {bool liability = false}) =>
    BalanceSnapshot(id: 0, month: month, label: label, amountMinor: minor, isLiability: liability);

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final oct = DateTime(2026, 10);
  final nov = DateTime(2026, 11);
  final dec = DateTime(2026, 12);

  test('labels carry over from the last filled month, else the defaults', () {
    expect(balanceLabels(const [], nov), defaultBalanceLabels);
    final snaps = [snap(oct, 'Bank', 1), snap(nov, 'SBI', 1), snap(nov, 'HDFC card', 1, liability: true)];
    expect(balanceLabels(snaps, dec), [('SBI', false), ('HDFC card', true)]);
    expect(balanceLabels(snaps, nov), [('Bank', false)]);
  });

  test('net worth is assets minus liabilities, newest first, 6 months', () {
    final snaps = [
      for (var m = 1; m <= 8; m++) snap(DateTime(2026, m), 'Bank', m * 100),
      snap(DateTime(2026, 8), 'Card due', 50, liability: true),
    ];
    final worth = netWorthByMonth(snaps);
    expect(worth, hasLength(6));
    expect(worth.first, (DateTime(2026, 8), 750));
    expect(worth.last.$1, DateTime(2026, 3));
  });

  test('due from the 1st to the 7th until filled', () {
    expect(balancesDue(DateTime(2026, 11, 7, 23), const []), isTrue);
    expect(balancesDue(DateTime(2026, 11, 8), const []), isFalse);
    expect(balancesDue(DateTime(2026, 11, 2), [snap(nov, 'Bank', 0)]), isFalse);
    expect(balancesDue(DateTime(2026, 11, 2), [snap(oct, 'Bank', 0)]), isTrue);
  });

  testWidgets('the balances sheet saves every label; the Buckets card renders', (tester) async {
    SharedPreferences.setMockInitialValues({PrefKeys.homeCurrency: 'INR'});
    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    final db = memoryDb();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    await tester.runAsync(() async {
      final fixed = (await db.allCategories()).firstWhere((c) => c.name == 'Subscriptions');
      await db.addManual(
        amountMinor: 64900,
        direction: TxnDirection.debit,
        at: month.add(const Duration(hours: 10)),
        categoryId: fixed.id,
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: appLikeTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  BalancesCard(now: DateTime(month.year, month.month, 3)),
                  const BucketsCard(),
                  TextButton(
                    onPressed: () => showBalancesSheet(context, month, defaultBalanceLabels),
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
    }

    await settle();
    expect(tester.takeException(), isNull);
    expect(find.text('Fill in'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Buckets'), findsOneWidget);
    expect(find.text('₹649 of ₹10,000', findRichText: true), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Bank'), '50000');
    await tester.enterText(find.widgetWithText(TextField, 'Card due'), '20000');
    await tester.pump();
    expect(find.text('Net worth ₹30,000'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await settle();
    final saved = (await tester.runAsync(() => db.watchSnapshots(from: month).first))!;
    expect(saved, hasLength(5));
    expect(netWorthByMonth(saved).single, (month, 3000000));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

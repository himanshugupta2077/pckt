import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/plan/plan_screen.dart';
import 'package:pckt/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'balances_test.dart' show appLikeTheme;
import 'budget_test.dart' show memoryDb;

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('the plan screen shows its inputs and the EMI list, and saves what is typed', (tester) async {
    SharedPreferences.setMockInitialValues({PrefKeys.homeCurrency: 'INR'});
    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    final db = memoryDb();
    await tester.runAsync(() async {
      await db.savePlan(const PlanCompanion(salaryMinor: Value(10000000)));
      await db.saveEmi(name: 'Laptop', amountMinor: 4000000, lastMonth: DateTime(2030, 3));
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(theme: appLikeTheme, home: const PlanScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Planned left over'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3)); // salary, investing, fund
    expect(find.text('Until Mar 2030'), findsOneWidget);
    expect(find.text('Add EMI'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Investing'), '5000');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    final plan = await tester.runAsync(() => db.watchPlan().first);
    expect((plan!.salaryMinor, plan.investingMinor, plan.fundMinor), (10000000, 500000, 1000000));

    // Unmount so drift's stream queries are cancelled; closing the
    // database inside the fake-async zone would hang.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

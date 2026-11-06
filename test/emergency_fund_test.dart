import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/backup/data_export.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/budgets/bucket_stats.dart';
import 'package:pckt/features/dashboard/emergency_fund_card.dart';
import 'package:pckt/features/dashboard/hero_card.dart';
import 'package:pckt/features/plan/plan_math.dart';

import 'budget_test.dart' show memoryDb;
import 'plan_test.dart' show emi, plan;

void main() {
  test('holdings and the goal are saved, edited, removed and backed up', () async {
    final db = memoryDb();
    addTearDown(db.close);
    await db.saveEmergencyHolding(name: 'FD', amountMinor: 2000000);
    await db.saveEmergencyHolding(name: 'Sweep FD', amountMinor: 5000000);
    await db.setEmergencyGoal(20000000);
    var rows = await db.watchEmergencyHoldings().first;
    expect([for (final h in rows) (h.name, h.amountMinor)], [('FD', 2000000), ('Sweep FD', 5000000)]);
    await db.saveEmergencyHolding(id: rows.last.id, name: 'Sweep FD', amountMinor: 3000000);
    await db.deleteEmergencyHolding(rows.first.id);
    rows = await db.watchEmergencyHoldings().first;
    expect([for (final h in rows) (h.name, h.amountMinor)], [('Sweep FD', 3000000)]);

    final fresh = memoryDb();
    addTearDown(fresh.close);
    await DataExport(fresh).restore(await DataExport(db).backupJson());
    expect((await fresh.watchEmergencyHoldings().first).single.amountMinor, 3000000);
    expect((await fresh.watchPlan().first)!.emergencyGoalMinor, 20000000);
  });

  test('a v11 backup restores with no holdings and no goal', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final m = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
    m['schemaVersion'] = 11;
    final tables = m['tables']! as Map;
    tables.remove('emergency_holdings');
    for (final p in (tables['plan'] as List).cast<Map>()) {
      p.remove('emergency_goal_minor');
    }
    final fresh = memoryDb();
    addTearDown(fresh.close);
    await DataExport(fresh).restore(jsonEncode(m));
    expect(await fresh.watchEmergencyHoldings().first, isEmpty);
    expect((await fresh.watchPlan().first)!.emergencyGoalMinor, isNull);
  });

  test('v11 → v12 migration adds the goal column and the holdings table', () async {
    final dir = await Directory.systemTemp.createTemp('pckt_mig12');
    final file = File('${dir.path}/db.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      await db.watchPlan().first;
      await db.customStatement('DROP TABLE emergency_holdings');
      await db.customStatement('ALTER TABLE plan DROP COLUMN emergency_goal_minor');
      await db.customStatement('PRAGMA user_version = 11');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      expect((await db.watchPlan().first)!.emergencyGoalMinor, isNull);
      await db.saveEmergencyHolding(name: 'FD', amountMinor: 2000000);
      expect(await db.watchEmergencyHoldings().first, hasLength(1));
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('with an emergency goal, goal 1 is that goal less the holdings', () {
    final nov = DateTime(2026, 11);
    PlanOutcome outcome(int? emergencyGoal, int saved) => PlanOutcome(
      plan: plan(goal1: 9900000, goal1Due: DateTime(2027, 11), emergencyGoal: emergencyGoal),
      month: nov,
      emis: [emi(100, null)],
      everyday: null,
      fixed: 0,
      familyAvg: const MonthAverage(0, 0),
      emergencySaved: saved,
    );
    expect(outcome(null, 2000000).goals.single.stillToSave, 9900000);
    expect(outcome(20000000, 2000000).goals.single.stillToSave, 18000000);
    expect(outcome(20000000, 2000000).goals.single.perMonth, 1500000); // ₹1.8L over 12 months
    expect(outcome(20000000, 7000000).goals.single.stillToSave, 13000000);
    expect(outcome(20000000, 25000000).goals, isEmpty);
  });

  testWidgets('the card shows what is held, the goal, the share and each holding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyFundView(
            goalMinor: 20000000,
            holdings: const [EmergencyHolding(id: 1, name: 'FD', amountMinor: 2000000)],
          ),
        ),
      ),
    );
    expect(find.text('Emergency fund'), findsOneWidget);
    expect(find.text('₹20,000'), findsOneWidget);
    expect(find.textContaining('of ₹2'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.textContaining('FD ₹20'), findsOneWidget);
  });

  testWidgets('with nothing set the card asks for a goal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmergencyFundView(goalMinor: null, holdings: [])),
      ),
    );
    expect(find.text('₹0'), findsOneWidget);
    expect(find.textContaining('set a goal'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('the month card holds EMI, Invested and Others in their own tiles', (tester) async {
    Widget card({List<Emi> emis = const [], int invested = 0, bool others = false}) => MaterialApp(
      home: Scaffold(
        body: MonthCard(
          month: DateTime(2026, 11),
          everydaySpent: 0,
          everydayLimit: 1000000,
          fixedSpent: 0,
          fixedLimit: 1000000,
          fundSpent: 0,
          fundLimit: 1000000,
          inMinor: 0,
          outMinor: 0,
          emis: emis,
          invested: invested,
          showOthers: others,
        ),
      ),
    );
    await tester.pumpWidget(card());
    expect(find.text('Not budgeted'), findsNothing);

    await tester.pumpWidget(card(emis: [emi(3820000, null)], invested: 4400000, others: true));
    expect(find.text('Not budgeted'), findsOneWidget);
    for (final t in ['EMI', '₹38,200', 'Invested', '₹44,000', 'Others']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    final emiY = tester.getTopLeft(find.text('EMI')).dy;
    expect(tester.getTopLeft(find.text('Invested')).dy, emiY);
    expect(tester.getTopLeft(find.text('Others')).dy, emiY);
    expect(tester.getTopLeft(find.text('Fund')).dy, lessThan(emiY));
  });
}

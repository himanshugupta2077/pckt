import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/backup/data_export.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/dashboard/salary_card.dart';
import 'package:pckt/features/dashboard/salary_split.dart';

import 'budget_test.dart' show cat, memoryDb, txn;

void main() {
  final groceries = cat(1, 'Groceries', seed: 'Groceries', spendKind: SpendKind.need);
  final dining = cat(2, 'Food & Dining', seed: 'Food & Dining');
  final invest = cat(3, 'Investments', bucket: Bucket.outside, seed: 'Investments');
  final family = cat(4, 'Family', bucket: Bucket.lending, seed: 'Family');
  final other = cat(5, 'Other', seed: 'Other');
  final fitness = cat(6, 'Fitness', bucket: Bucket.fixed, seed: 'Fitness');

  test('the category decides, and a payment with no category is a want', () {
    expect(spendDecision(txn(100, category: groceries)).kind, SpendKind.need);
    expect(spendDecision(txn(100, category: dining)).kind, SpendKind.want);
    expect(spendDecision(txn(100, category: fitness)).kind, SpendKind.want);
    expect(spendDecision(txn(100, category: other)).kind, SpendKind.want);
    final none = spendDecision(txn(100));
    expect((none.kind, none.source), (SpendKind.want, SpendSource.fallback));
  });

  test('a payment or a payee overrides the category', () {
    final overridden = txn(100, category: groceries, spendKind: SpendKind.want);
    expect((spendDecision(overridden).kind, spendDecision(overridden).source), (SpendKind.want, SpendSource.manual));
    final payee = txn(100, category: other, merchant: 'Cafe', payeeKind: SpendKind.need);
    expect((spendDecision(payee).kind, spendDecision(payee).source), (SpendKind.need, SpendSource.payee));
  });

  test('investments count even from Outside, and family lending is not a need', () {
    expect(spendDecision(txn(100, category: invest)).source, SpendSource.invest);
    expect(spendDecision(txn(100, category: family)).source, SpendSource.lending);
    expect(spendDecision(txn(100, transfer: true, category: dining)).source, SpendSource.transfer);
    expect(spendDecision(txn(100, dir: TxnDirection.credit, category: dining)).source, SpendSource.income);
    expect(canSetSpendKind(txn(100, category: other)), isTrue);
    expect(canSetSpendKind(txn(100, category: invest)), isFalse);
    expect(categoryHasSpendKind(other), isTrue);
    expect(categoryHasSpendKind(invest), isFalse);
    expect(categoryHasSpendKind(family), isFalse);
  });

  test('savings is the rest of the salary, lending stays out, percents add up to 100', () {
    final split = SalarySplit(
      salaryMinor: 14166700,
      emiMinor: 4258066,
      txns: [
        txn(4400000, category: invest),
        txn(1596500, category: invest, dir: TxnDirection.credit),
        txn(341200, category: groceries),
        txn(1508200, category: dining),
        txn(33000, category: other),
        txn(6400000, category: family),
        txn(999900, transfer: true, category: dining),
      ],
    );
    expect(split.invested, 4400000 - 1596500);
    expect(split.needs, 341200 + 4258066);
    expect(split.wants, 1508200 + 33000);
    expect(split.savings, 14166700 - 2803500 - 4599266 - 1541200);
    final (i, n, w, s) = split.percents;
    expect((i, n, w, s), (20, 32, 11, 37));
    expect(i + n + w + s, 100);
    expect(percentOf(1, 0), 0);
  });

  test('an EMI paid from the bank is not counted again from the plan list', () {
    final loans = cat(7, 'Loans & EMI', bucket: Bucket.outside, seed: 'Loans & EMI', spendKind: SpendKind.need);
    final split = SalarySplit(salaryMinor: 14166700, emiMinor: 4258066, txns: [txn(3820000, category: loans)]);
    expect(split.needs, 4258066);
    expect(split.emiPaid, 3820000);
  });

  test('spending more than the salary shows negative savings', () {
    final split = SalarySplit(salaryMinor: 100000, txns: [txn(150000, category: dining)]);
    expect(split.savings, -50000);
    expect(split.percents.$4, -50);
    expect(percentLabel(-50), '−50%');
  });

  testWidgets('the card shows four percents with small amounts, and nothing else', (tester) async {
    final split = SalarySplit(
      salaryMinor: 14166700,
      emiMinor: 4258066,
      txns: [
        txn(2803500, category: invest),
        txn(341200, category: groceries),
        txn(1541200, category: dining),
        txn(6400000, category: family),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SalarySplitView(split: split)),
      ),
    );

    for (final label in ['Invested', 'Needs', 'Wants', 'Savings', '20%', '32%', '11%', '37%', '₹28,035']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final gone in ['Salary', 'Not sorted', 'Lent', '₹1,41,667']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    expect(tester.getTopLeft(find.text('Needs')).dx, lessThan(tester.getTopLeft(find.text('Wants')).dx));
    expect(tester.getTopLeft(find.text('Wants')).dx, lessThan(tester.getTopLeft(find.text('Savings')).dx));
  });

  testWidgets('with no salary the card asks for one', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalarySplitView(split: SalarySplit(salaryMinor: 0, txns: const [])),
        ),
      ),
    );
    expect(find.text('Set salary in Plan'), findsOneWidget);
    expect(find.text('Savings'), findsNothing);
  });

  group('category need or want in the database', () {
    Future<SpendKind> kindOf(AppDatabase db, String name) async =>
        (await db.allCategories()).firstWhere((c) => c.name == name).spendKind;

    test('seeds start as needs or wants, Other as a want', () async {
      final db = memoryDb();
      addTearDown(db.close);
      expect(await kindOf(db, 'Groceries'), SpendKind.need);
      expect(await kindOf(db, 'Bills & Utilities'), SpendKind.need);
      expect(await kindOf(db, 'Food & Dining'), SpendKind.want);
      expect(await kindOf(db, 'Other'), SpendKind.want);
      final id = (await db.allCategories()).firstWhere((c) => c.name == 'Other').id;
      await db.updateCategory(id, spendKind: SpendKind.need);
      expect(await kindOf(db, 'Other'), SpendKind.need);
    });

    test('a v8 backup restores with seed needs and wants', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final m = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
      m['schemaVersion'] = 8;
      for (final c in ((m['tables']! as Map)['categories'] as List).cast<Map>()) {
        c.remove('spend_kind');
      }
      final fresh = memoryDb();
      addTearDown(fresh.close);
      await DataExport(fresh).restore(jsonEncode(m));
      expect(await kindOf(fresh, 'Groceries'), SpendKind.need);
      expect(await kindOf(fresh, 'Shopping'), SpendKind.want);
    });

    test('v8 → v9 migration adds the column and seeds it', () async {
      final dir = await Directory.systemTemp.createTemp('pckt_mig9');
      final file = File('${dir.path}/db.sqlite');
      try {
        var db = AppDatabase(NativeDatabase(file));
        await db.allCategories();
        await db.customStatement('ALTER TABLE categories DROP COLUMN spend_kind');
        await db.customStatement('PRAGMA user_version = 8');
        await db.close();

        db = AppDatabase(NativeDatabase(file));
        expect(await kindOf(db, 'Health'), SpendKind.need);
        expect(await kindOf(db, 'Subscriptions'), SpendKind.want);
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}

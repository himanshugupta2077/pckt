import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/backup/data_export.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/budgets/budget_math.dart';
import 'package:pckt/features/budgets/in_budget.dart';
import 'package:pckt/features/stats.dart';

var _id = 0;

Category cat(int id, String name, {bool counts = true, String? seed}) => Category(
  id: id,
  name: name,
  icon: 'other',
  color: 0,
  isIncome: false,
  sortOrder: id,
  seedName: seed,
  countsInBudget: counts,
);

TxnView txn(
  int minor, {
  DateTime? at,
  Category? category,
  bool transfer = false,
  TxnDirection dir = TxnDirection.debit,
  String? merchant,
  bool? inBudget,
  bool? payee,
}) => TxnView(
  Transaction(
    id: ++_id,
    amountMinor: minor,
    currency: 'INR',
    direction: dir,
    occurredAt: at ?? DateTime(2026, 10, 10),
    merchant: merchant,
    categoryId: category?.id,
    mode: PaymentMode.upi,
    status: TxnStatus.confirmed,
    isTransfer: transfer,
    categoryLocked: false,
    createdAt: DateTime(2026),
    inBudget: inBudget,
  ),
  category,
  null,
  payee == null ? null : MerchantRule(id: 1, pattern: merchant!.toLowerCase(), countsInBudget: payee),
);

AppDatabase memoryDb() => AppDatabase(DatabaseConnection(NativeDatabase.memory()));

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final food = cat(1, 'Food');
  final invest = cat(2, 'Investments', counts: false, seed: 'Investments');
  final other = cat(3, 'Other', seed: 'Other');
  final people = cat(4, 'People', seed: 'People');

  group('resolver', () {
    test('first match wins: transfer, money in, payment, payee, category, default', () {
      expect(budgetDecision(txn(100, transfer: true, inBudget: true)).source, BudgetSource.transfer);
      expect(budgetDecision(txn(100, dir: TxnDirection.credit)).counts, isFalse);
      final manual = budgetDecision(txn(100, category: invest, merchant: 'Zerodha', payee: false, inBudget: true));
      expect((manual.counts, manual.source), (true, BudgetSource.manual));
      final payee = budgetDecision(txn(100, category: food, merchant: 'Zerodha', payee: false));
      expect((payee.counts, payee.source), (false, BudgetSource.payee));
      final byCat = budgetDecision(txn(100, category: invest));
      expect((byCat.counts, byCat.source), (false, BudgetSource.category));
      final plain = budgetDecision(txn(100));
      expect((plain.counts, plain.source), (true, BudgetSource.fallback));
    });
  });

  group('budget math', () {
    test('only counted spends reach totals, categories and budgets', () {
      final txns = [
        txn(50000, category: food),
        txn(10000000, category: invest),
        txn(30000, category: food, merchant: 'Rent', payee: false),
        txn(20000, merchant: 'Dairy', payee: true, category: invest),
        txn(70000, transfer: true),
        txn(90000, dir: TxnDirection.credit),
      ];
      final stats = MonthStats(txns, DateTime(2026, 10));
      expect(stats.spent, 70000);
      expect(stats.outside, 10030000);
      expect(stats.income, 90000);
      expect(stats.count, 2);
      expect({for (final c in stats.categories) c.category?.id: c.amount}, {1: 50000, 2: 20000});

      Budget b(int id, int minor, {int? categoryId}) => Budget(
        id: id,
        categoryId: categoryId,
        amountMinor: minor,
        currency: 'INR',
        active: true,
        createdAt: DateTime(2026),
      );
      final p = budgetProgress(
        budgets: [b(1, 1500000), b(2, 100000, categoryId: 2)],
        txns: txns,
        categories: [food, invest],
        month: DateTime(2026, 10),
        now: DateTime(2026, 10, 20),
      );
      expect(p.first.spentMinor, 70000);
      expect(p.last.spentMinor, 20000);
    });
  });

  group('to sort', () {
    test('asks about large or repeat payees with no telling answer', () {
      final big = txn(200000, merchant: 'Shop', category: other);
      final small = txn(19999, merchant: 'Once', category: other);
      final repeat = [txn(5000, merchant: 'Dairy', category: people), txn(6000, merchant: 'dairy')];
      final known = txn(300000, merchant: 'Swiggy', category: food);
      final ruled = txn(300000, merchant: 'Zerodha', payee: false);
      final answered = txn(300000, inBudget: false);
      final transfer = txn(300000, transfer: true);
      final all = [big, small, ...repeat, known, ruled, answered, transfer];
      final counts = merchantCounts(all);
      expect(all.where((v) => needsSorting(v, counts)), [big, ...repeat]);

      final items = toSort(all);
      expect(items.map((i) => (i.merchant, i.txns.length, i.totalMinor)), [('Shop', 1, 200000), ('Dairy', 2, 11000)]);
    });
  });

  group('database', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    test('seeds keep investments, loans, insurance, transfers and family outside', () async {
      final outside = {
        for (final c in await db.allCategories())
          if (!c.countsInBudget) c.name,
      };
      expect(outside, {'Investments', 'Insurance', 'Loans & EMI', 'Transfers', 'Family'});
    });

    test('a payee answer is a rule every payment to it follows', () async {
      final a = await db.addManual(
        amountMinor: 5000,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, 1),
        merchant: 'Shiv Dugdh',
      );
      final b = await db.addManual(
        amountMinor: 6000,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, 2),
        merchant: 'SHIV DUGDH',
      );
      await db.setInBudget(a, false);
      await db.setPayeeBudget('Shiv Dugdh', true);
      final views = await db.watchTxns().first;
      expect(views.map((v) => budgetDecision(v).source).toSet(), {BudgetSource.payee});
      expect(views.every((v) => budgetDecision(v).counts), isTrue);

      // A budget-only rule leaves categorisation alone; a later category
      // answer fills it in without losing the budget answer.
      final rule = (await db.allMerchantRules()).single;
      expect((rule.categoryId, rule.countsInBudget), (null, true));
      final groceries = (await db.allCategories()).firstWhere((c) => c.name == 'Groceries');
      await db.setCategory(b, groceries.id, learnPattern: 'shiv dugdh');
      final after = (await db.allMerchantRules()).single;
      expect((after.categoryId, after.countsInBudget), (groceries.id, true));

      await db.renameMerchant('Shiv Dugdh', 'Dairy');
      final renamed = (await db.allMerchantRules()).firstWhere((r) => r.pattern == 'dairy');
      expect(renamed.countsInBudget, isTrue);
    });

    test('CSV says whether each payment counts', () async {
      final invest = (await db.allCategories()).firstWhere((c) => c.name == 'Investments');
      await db.addManual(
        amountMinor: 100,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, 1),
        categoryId: invest.id,
      );
      await db.addManual(amountMinor: 200, direction: TxnDirection.debit, at: DateTime(2026, 10, 2));
      final rows = decodeCsv(await DataExport(db).transactionsCsv());
      final i = rows.first.indexOf('counts_in_budget');
      expect([for (final r in rows.skip(1)) r[i]], ['no', 'yes']);
    });

    test('a pre-v5 backup restores with the budget defaults', () async {
      final m = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
      m['schemaVersion'] = 4;
      final tables = (m['tables']! as Map).cast<String, Object?>();
      final cats = (tables['categories']! as List).cast<Map<String, Object?>>();
      cats.removeWhere((c) => c['name'] == 'Family');
      for (final c in cats) {
        c.remove('counts_in_budget');
      }
      final fresh = memoryDb();
      addTearDown(fresh.close);
      await DataExport(fresh).restore(jsonEncode(m));
      final restored = await fresh.allCategories();
      expect(restored.firstWhere((c) => c.name == 'Investments').countsInBudget, isFalse);
      expect(restored.firstWhere((c) => c.name == 'Family').countsInBudget, isFalse);
      expect(restored.firstWhere((c) => c.name == 'Groceries').countsInBudget, isTrue);
    });
  });

  test('v4 → v5 migration adds the budget columns, Family and the defaults', () async {
    final dir = await Directory.systemTemp.createTemp('pckt_mig5');
    final file = File('${dir.path}/db.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      final cats = await db.allCategories();
      final food = cats.firstWhere((c) => c.name == 'Food & Dining');
      final id = await db.addManual(
        amountMinor: 25000,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, 1),
        merchant: 'Swiggy',
      );
      await db.setCategory(id, food.id, learnPattern: 'swiggy');
      // Strip back to the v4 shape.
      await db.customStatement('DELETE FROM categories WHERE name = \'Family\'');
      await db.customStatement('ALTER TABLE transactions DROP COLUMN in_budget');
      await db.customStatement(
        'CREATE TABLE c4 AS SELECT id, name, icon, color, is_income, sort_order, seed_name FROM categories',
      );
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement('DROP TABLE categories');
      await db.customStatement(
        'CREATE TABLE categories (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL, '
        'color INTEGER NOT NULL, is_income INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0, seed_name TEXT)',
      );
      await db.customStatement('INSERT INTO categories SELECT * FROM c4');
      await db.customStatement('DROP TABLE c4');
      await db.customStatement('DROP TABLE merchant_rules');
      await db.customStatement(
        'CREATE TABLE merchant_rules (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, pattern TEXT NOT NULL UNIQUE, '
        'category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE)',
      );
      await db.customStatement('INSERT INTO merchant_rules (pattern, category_id) VALUES (\'swiggy\', ${food.id})');
      await db.customStatement('PRAGMA user_version = 4');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final after = await db.allCategories();
      expect(after.firstWhere((c) => c.name == 'Investments').countsInBudget, isFalse);
      expect(after.firstWhere((c) => c.name == 'Family').countsInBudget, isFalse);
      expect(after.firstWhere((c) => c.name == 'Food & Dining').countsInBudget, isTrue);
      expect(after.map((c) => c.name).toSet().length, after.length, reason: 'no seed duplicated');
      final rule = (await db.allMerchantRules()).single;
      expect((rule.pattern, rule.categoryId, rule.countsInBudget), ('swiggy', food.id, null));
      expect((await db.select(db.transactions).get()).single.inBudget, isNull);
      await db.setPayeeBudget('Zepto', true); // budget-only rule needs the nullable category
      expect(await db.allMerchantRules(), hasLength(2));
      expect(await db.customSelect('PRAGMA user_version').map((r) => r.data.values.first).getSingle(), 5);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

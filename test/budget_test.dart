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

Category cat(int id, String name, {Bucket bucket = Bucket.everyday, String? seed}) => Category(
  id: id,
  name: name,
  icon: 'other',
  color: 0,
  isIncome: false,
  sortOrder: id,
  seedName: seed,
  countsInBudget: true,
  bucket: bucket,
);

TxnView txn(
  int minor, {
  DateTime? at,
  Category? category,
  bool transfer = false,
  TxnDirection dir = TxnDirection.debit,
  String? merchant,
  Bucket? bucket,
  Bucket? payee,
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
    bucket: bucket,
  ),
  category,
  null,
  payee == null ? null : MerchantRule(id: 1, pattern: merchant!.toLowerCase(), bucket: payee),
);

AppDatabase memoryDb() => AppDatabase(DatabaseConnection(NativeDatabase.memory()));

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final food = cat(1, 'Food');
  final invest = cat(2, 'Investments', bucket: Bucket.outside, seed: 'Investments');
  final other = cat(3, 'Other', seed: 'Other');
  final people = cat(4, 'People', seed: 'People');

  group('resolver', () {
    test('first match wins: transfer, money in, payment, payee, category, default', () {
      final transfer = budgetDecision(txn(100, transfer: true, bucket: Bucket.everyday));
      expect((transfer.bucket, transfer.source, transfer.counts), (null, BudgetSource.transfer, false));
      expect(budgetDecision(txn(100, dir: TxnDirection.credit)).counts, isFalse);
      final manual = budgetDecision(
        txn(100, category: invest, merchant: 'Decathlon', payee: Bucket.everyday, bucket: Bucket.fund),
      );
      expect((manual.bucket, manual.source), (Bucket.fund, BudgetSource.manual));
      final payee = budgetDecision(txn(100, category: food, merchant: 'Healthkart', payee: Bucket.fixed));
      expect((payee.bucket, payee.source, payee.counts), (Bucket.fixed, BudgetSource.payee, false));
      final byCat = budgetDecision(txn(100, category: invest));
      expect((byCat.bucket, byCat.source), (Bucket.outside, BudgetSource.category));
      final plain = budgetDecision(txn(100));
      expect((plain.bucket, plain.source, plain.counts), (Bucket.everyday, BudgetSource.fallback, true));
    });
  });

  group('budget math', () {
    test('only counted spends reach totals, categories and budgets', () {
      final txns = [
        txn(50000, category: food),
        txn(10000000, category: invest),
        txn(30000, category: food, merchant: 'Rent', payee: Bucket.outside),
        txn(20000, merchant: 'Dairy', payee: Bucket.everyday, category: invest),
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
      final ruled = txn(300000, merchant: 'Zerodha', payee: Bucket.outside);
      final answered = txn(300000, bucket: Bucket.fund);
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

    test('seeds start in their buckets', () async {
      final cats = await db.allCategories();
      Set<String> inBucket(Bucket b) => {
        for (final c in cats)
          if (c.bucket == b && !c.isIncome) c.name,
      };
      expect(inBucket(Bucket.fixed), {'Bills & Utilities', 'Mobile & Internet', 'Subscriptions', 'Fitness'});
      expect(inBucket(Bucket.fund), {'Big & occasional'});
      expect(inBucket(Bucket.outside), {'Investments', 'Insurance', 'Loans & EMI', 'Family'});
      expect(inBucket(Bucket.ignore), {'Transfers'});
      expect(cats.where((c) => c.name == 'Gym & supplements'), isEmpty);
      expect(await db.watchPlan().first, isNotNull, reason: 'a new install has its plan row');
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
      await db.setTxnBucket(a, Bucket.outside);
      await db.setPayeeBucket('Shiv Dugdh', Bucket.everyday);
      final views = await db.watchTxns().first;
      expect(views.map((v) => budgetDecision(v).source).toSet(), {BudgetSource.payee});
      expect(views.every((v) => budgetDecision(v).counts), isTrue);

      // A budget-only rule leaves categorisation alone; a later category
      // answer fills it in without losing the budget answer.
      final rule = (await db.allMerchantRules()).single;
      expect((rule.categoryId, rule.bucket), (null, Bucket.everyday));
      final groceries = (await db.allCategories()).firstWhere((c) => c.name == 'Groceries');
      await db.setCategory(b, groceries.id, learnPattern: 'shiv dugdh');
      final after = (await db.allMerchantRules()).single;
      expect((after.categoryId, after.bucket), (groceries.id, Bucket.everyday));

      await db.renameMerchant('Shiv Dugdh', 'Dairy');
      final renamed = (await db.allMerchantRules()).firstWhere((r) => r.pattern == 'dairy');
      expect(renamed.bucket, Bucket.everyday);
    });

    test('the fund action changes this payment only', () async {
      final shopping = (await db.allCategories()).firstWhere((c) => c.name == 'Shopping');
      Future<int> amazon(int day) => db.addManual(
        amountMinor: 100000 * day,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, day),
        merchant: 'Amazon',
        categoryId: shopping.id,
      );
      final tv = await amazon(1);
      final others = [await amazon(2), await amazon(3)];
      await db.setTxnBucket(tv, Bucket.fund);
      final views = {for (final v in await db.watchTxns().first) v.txn.id: v};
      expect(budgetDecision(views[tv]!).bucket, Bucket.fund);
      for (final id in others) {
        expect(views[id]!.txn.categoryId, shopping.id);
        expect(budgetDecision(views[id]!).bucket, Bucket.everyday);
      }
      expect(await db.allMerchantRules(), isEmpty, reason: 'no merchant rule');

      // A later pick for the payee leaves the fund purchase where it is.
      await db.setPayeeBucket('Amazon', Bucket.everyday);
      final after = {for (final v in await db.watchTxns().first) v.txn.id: budgetDecision(v).bucket};
      expect([after[tv], for (final id in others) after[id]], [Bucket.fund, Bucket.everyday, Bucket.everyday]);
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

    test('a v5 backup restores with its answers turned into buckets', () async {
      final cats = await db.allCategories();
      final health = cats.firstWhere((c) => c.name == 'Health');
      final bills = cats.firstWhere((c) => c.name == 'Bills & Utilities');
      final yes = await db.addManual(amountMinor: 100, direction: TxnDirection.debit, at: DateTime(2026, 10, 1));
      final no = await db.addManual(
        amountMinor: 200,
        direction: TxnDirection.debit,
        at: DateTime(2026, 10, 2),
        categoryId: bills.id,
      );
      await db
          .into(db.merchantRules)
          .insert(MerchantRulesCompanion.insert(pattern: 'healthkart', categoryId: Value(health.id)));
      final m = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
      m['schemaVersion'] = 5;
      final tables = (m['tables']! as Map).cast<String, Object?>()
        ..remove('plan')
        ..remove('balance_snapshots');
      for (final name in ['categories', 'transactions', 'merchant_rules']) {
        for (final r in (tables[name]! as List).cast<Map<String, Object?>>()) {
          r.remove('bucket');
          if (name == 'transactions') r['in_budget'] = r['id'] == yes ? 1 : 0;
          if (name == 'merchant_rules') r['counts_in_budget'] = 0;
        }
      }
      (tables['categories']! as List).cast<Map<String, Object?>>().removeWhere((c) => c['name'] == 'Big & occasional');

      final fresh = memoryDb();
      addTearDown(fresh.close);
      await DataExport(fresh).restore(jsonEncode(m));
      final restored = await fresh.allCategories();
      Bucket of(String name) => restored.firstWhere((c) => c.name == name).bucket;
      expect(
        [of('Investments'), of('Subscriptions'), of('Groceries'), of('Big & occasional')],
        [Bucket.outside, Bucket.fixed, Bucket.everyday, Bucket.fund],
      );
      final txns = {for (final t in await fresh.select(fresh.transactions).get()) t.id: t.bucket};
      expect((txns[yes], txns[no]), (Bucket.everyday, Bucket.fixed));
      expect((await fresh.allMerchantRules()).single.bucket, Bucket.outside, reason: 'No in Health → Outside');
      expect(await fresh.watchPlan().first, isNotNull);
    });

    test('a v6 backup restores its single EMI into the EMI list', () async {
      await db.savePlan(PlanCompanion(emiMinor: const Value(3820000), emiEnds: Value(DateTime(2027, 3))));
      final m = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
      m['schemaVersion'] = 6;
      (m['tables']! as Map).remove('emis');
      final fresh = memoryDb();
      addTearDown(fresh.close);
      await DataExport(fresh).restore(jsonEncode(m));
      final emi = (await fresh.watchEmis().first).single;
      expect((emi.name, emi.amountMinor, emi.lastMonth), ('EMI', 3820000, DateTime(2027, 3)));
      // A v7 backup carries the list as it is: no second seed.
      final again = memoryDb();
      addTearDown(again.close);
      await DataExport(again).restore(await DataExport(fresh).backupJson());
      expect(await again.watchEmis().first, hasLength(1));
    });

    test('ticking a credit as income overrides an Ignore from its payee or category', () async {
      final family = (await db.allCategories()).firstWhere((c) => c.name == 'Family');
      await db.updateCategory(family.id, bucket: Bucket.ignore);
      final id = await db.addManual(
        amountMinor: 1800000,
        direction: TxnDirection.credit,
        at: DateTime(2026, 11, 2),
        categoryId: family.id,
      );
      Future<TxnView> view() async => (await db.watchTxn(id).first)!;
      expect(isIgnored(await view()), isTrue);
      await db.setTxnBucket(id, Bucket.everyday); // what the income tick writes
      expect(isIgnored(await view()), isFalse);
      expect(MonthStats([await view()], DateTime(2026, 11)).income, 1800000);
    });

    test('the plan and balances are in the backup', () async {
      await db.savePlan(const PlanCompanion(salaryMinor: Value(14200000), goal1Minor: Value(30000000)));
      await db.saveSnapshots(DateTime(2026, 11), [('Bank', 5000000, false), ('Card due', 6000000, true)]);
      final fresh = memoryDb();
      addTearDown(fresh.close);
      await DataExport(fresh).restore(await DataExport(db).backupJson());
      final plan = (await fresh.watchPlan().first)!;
      expect((plan.salaryMinor, plan.goal1Minor, plan.fundMinor), (14200000, 30000000, 1000000));
      final snaps = await fresh.watchSnapshots(from: DateTime(2026)).first;
      expect(
        [for (final s in snaps) (s.month, s.label, s.amountMinor, s.isLiability)],
        [(DateTime(2026, 11), 'Bank', 5000000, false), (DateTime(2026, 11), 'Card due', 6000000, true)],
      );
    });
  });

  test('v4 → v6 migration adds the bucket columns, Family and the defaults', () async {
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
      expect(after.firstWhere((c) => c.name == 'Investments').bucket, Bucket.outside);
      expect(after.firstWhere((c) => c.name == 'Family').bucket, Bucket.outside);
      expect(after.firstWhere((c) => c.name == 'Food & Dining').bucket, Bucket.everyday);
      expect(after.map((c) => c.name).toSet().length, after.length, reason: 'no seed duplicated');
      final rule = (await db.allMerchantRules()).single;
      expect((rule.pattern, rule.categoryId, rule.bucket), ('swiggy', food.id, null));
      expect((await db.select(db.transactions).get()).single.bucket, isNull);
      await db.setPayeeBucket('Zepto', Bucket.everyday); // bucket-only rule needs the nullable category
      expect(await db.allMerchantRules(), hasLength(2));
      expect(await db.customSelect('PRAGMA user_version').map((r) => r.data.values.first).getSingle(), 7);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('v6 → v7 migration moves the plan EMI into the EMI list', () async {
    final dir = await Directory.systemTemp.createTemp('pckt_mig7');
    final file = File('${dir.path}/db.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      await db.savePlan(PlanCompanion(emiMinor: const Value(3820000), emiEnds: Value(DateTime(2027, 3))));
      await db.customStatement('DROP TABLE emis');
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final emi = (await db.watchEmis().first).single;
      expect((emi.name, emi.amountMinor, emi.lastMonth), ('EMI', 3820000, DateTime(2027, 3)));
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('v5 → v6 migration turns yes/no answers into buckets', () async {
    final dir = await Directory.systemTemp.createTemp('pckt_mig6');
    final file = File('${dir.path}/db.sqlite');
    try {
      var db = AppDatabase(NativeDatabase(file));
      final cats = {for (final c in await db.allCategories()) c.name: c};
      Future<int> pay(String merchant, String category, {bool? inBudget}) async {
        final id = await db.addManual(
          amountMinor: 50000,
          direction: TxnDirection.debit,
          at: DateTime(2026, 10, 5),
          merchant: merchant,
          categoryId: cats[category]!.id,
        );
        if (inBudget != null) {
          await db.customStatement('UPDATE transactions SET in_budget = ${inBudget ? 1 : 0} WHERE id = $id');
        }
        return id;
      }

      // The v5 shape: no bucket columns, plan or balances; Big & occasional
      // and Gym & supplements made by hand, set to not count.
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement('DELETE FROM categories WHERE name = \'Big & occasional\'');
      for (final t in ['categories', 'transactions', 'merchant_rules']) {
        await db.customStatement('ALTER TABLE $t DROP COLUMN bucket');
      }
      await db.customStatement('DROP TABLE plan');
      await db.customStatement('DROP TABLE balance_snapshots');
      await db.customStatement(
        'INSERT INTO categories (name, icon, color, counts_in_budget) VALUES '
        '(\'Big & occasional\', \'shopping\', 0, 0), (\'Gym & supplements\', \'fitness\', 0, 0)',
      );
      await db.customStatement('UPDATE categories SET counts_in_budget = 0 WHERE name = \'Subscriptions\'');
      final big = (await db.customSelect('SELECT id FROM categories WHERE name = \'Big & occasional\'').getSingle())
          .read<int>('id');

      final swiggy = await pay('Swiggy', 'Food & Dining', inBudget: true);
      final healthkart = await pay('Healthkart', 'Health');
      final netflix = await pay('Netflix', 'Subscriptions', inBudget: false);
      final emi = await pay('Bajaj', 'Food & Dining', inBudget: false);
      final decathlon = await db.addManual(
        amountMinor: 850000,
        direction: TxnDirection.debit,
        at: DateTime(2026, 11, 2),
        merchant: 'Decathlon',
      );
      await db.customStatement('UPDATE transactions SET category_id = $big, in_budget = 0 WHERE id = $decathlon');
      final plain = await pay('Zepto', 'Groceries');
      await db.customStatement(
        'INSERT INTO merchant_rules (pattern, category_id, counts_in_budget) VALUES '
        '(\'healthkart\', ${cats['Health']!.id}, 0), (\'ag fitness\', NULL, 0), (\'blinkit\', NULL, 1), '
        '(\'swiggy\', ${cats['Food & Dining']!.id}, NULL)',
      );
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      final after = await db.allCategories();
      Bucket of(String name) => after.singleWhere((c) => c.name == name).bucket;
      expect(after.where((c) => c.name == 'Big & occasional'), hasLength(1), reason: 'hand-made one adopted');
      expect(after.singleWhere((c) => c.name == 'Big & occasional').seedName, 'Big & occasional');
      expect(of('Big & occasional'), Bucket.fund);
      expect(of('Gym & supplements'), Bucket.fixed);
      expect(
        [of('Subscriptions'), of('Fitness'), of('Family'), of('Health')],
        [Bucket.fixed, Bucket.fixed, Bucket.outside, Bucket.everyday],
      );

      final txns = {for (final t in await db.select(db.transactions).get()) t.id: t.bucket};
      expect(txns[swiggy], Bucket.everyday, reason: 'yes → Everyday');
      expect(txns[netflix], Bucket.fixed, reason: 'no → the category bucket');
      expect(txns[emi], Bucket.outside, reason: 'no in an Everyday category → Outside');
      expect(txns[decathlon], Bucket.fund);
      expect((txns[healthkart], txns[plain]), (null, null), reason: 'no answer, no bucket');

      final rules = {for (final r in await db.allMerchantRules()) r.pattern: r.bucket};
      expect(rules, {
        'healthkart': Bucket.outside,
        'ag fitness': Bucket.outside,
        'blinkit': Bucket.everyday,
        'swiggy': null,
      });

      final views = {for (final v in await db.watchTxns().first) v.txn.id: budgetDecision(v)};
      expect(views[healthkart]!.source, BudgetSource.payee);
      expect(views[plain]!.bucket, Bucket.everyday);
      expect((await db.watchPlan().first)?.fundMinor, 1000000);
      expect(await db.customSelect('PRAGMA user_version').map((r) => r.data.values.first).getSingle(), 7);
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

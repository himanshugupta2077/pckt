import 'package:drift/drift.dart';

import '../../core/currency.dart';
import '../../core/format.dart' show monthStart;
import '../seed/default_categories.dart';
import 'db_encryption.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

/// A transaction joined with its category, account and the learned rule
/// for its merchant, for display and budget totals.
class TxnView {
  const TxnView(this.txn, this.category, this.account, [this.rule]);
  final Transaction txn;
  final Category? category;
  final Account? account;
  final MerchantRule? rule;
}

extension TxnMoney on Transaction {
  /// Amount in minor units of [home]: the amount itself for a [home]
  /// transaction, the recorded conversion for a foreign one, or null when
  /// there is none (it is then left out of totals rather than guessed).
  int? amountIn(String home) => currency == home
      ? amountMinor
      : convertedCurrency == home
      ? convertedMinor
      : null;

  /// [amountIn] the current home currency.
  int? get homeMinor => amountIn(Currencies.home);

  bool get isForeign => currency != Currencies.home;
}

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, RawMessages, MerchantRules, Budgets, Plan, BalanceSnapshots, Emis],
)
class AppDatabase extends _$AppDatabase {
  /// Without an [executor], opens the SQLCipher-encrypted `pckt.sqlite`
  /// (migrating a plaintext one first) — see [openAppDatabase].
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppDatabase());

  /// Payments before this are kept but not shown, counted or asked about
  /// (the app was set up in Oct 2026 and older months were never sorted).
  /// Null shows everything.
  DateTime? shownFrom;

  DateTime? _from(DateTime? from) =>
      shownFrom == null || (from != null && !from.isBefore(shownFrom!)) ? from : shownFrom;

  /// Seed categories every transaction can fall back to; never deletable.
  static const protectedCategories = {'Transfers', 'Other'};

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX idx_txn_time ON transactions (occurred_at)');
      await customStatement('CREATE INDEX idx_txn_amount ON transactions (amount_minor, direction)');
      await customStatement('CREATE INDEX idx_txn_ref ON transactions (reference)');
      await _seedCategories();
      await ensurePlan();
    },
    onUpgrade: (m, from, to) async {
      // v5 and v6 columns before anything that reads or writes categories,
      // transactions or rules.
      if (from < 6) {
        await _addColumnIfMissing(m, categories, categories.bucket);
        await _addColumnIfMissing(m, transactions, transactions.bucket);
        await _addColumnIfMissing(m, merchantRules, merchantRules.bucket);
      }
      // Before the v5 merchant-rule rebuild, which copies every current column.
      if (from < 8) {
        await _addColumnIfMissing(m, transactions, transactions.spendKind);
        await _addColumnIfMissing(m, merchantRules, merchantRules.spendKind);
      }
      if (from < 5) {
        await _addColumnIfMissing(m, categories, categories.countsInBudget);
        await _addColumnIfMissing(m, transactions, transactions.inBudget);
      }
      // v3 first: later steps read categories with the new column.
      if (from < 3) {
        await m.addColumn(categories, categories.seedName);
        await m.createTable(budgets);
        for (final c in defaultCategories) {
          await (update(categories)..where((r) => r.name.equals(c.name) & r.seedName.isNull())).write(
            CategoriesCompanion(seedName: Value(c.name)),
          );
        }
      }
      if (from < 2) await _addMissingSeedCategories();
      // v4: currencies. Everything recorded so far was in rupees, which is
      // the columns' default. (A pre-v3 database got the budgets table in
      // its current shape above, hence the existence check.)
      if (from < 4) {
        await _addColumnIfMissing(m, transactions, transactions.currency);
        await _addColumnIfMissing(m, transactions, transactions.convertedMinor);
        await _addColumnIfMissing(m, transactions, transactions.convertedCurrency);
        await _addColumnIfMissing(m, accounts, accounts.currency);
        await _addColumnIfMissing(m, budgets, budgets.currency);
      }
      // v5: "counts toward budget". Merchant rules may now carry only a
      // budget answer, so their category becomes optional (a table rebuild).
      if (from < 5) {
        await m.alterTable(TableMigration(merchantRules, newColumns: [merchantRules.countsInBudget]));
      }
      // v6: buckets replace the yes/no, plus the plan and monthly balances.
      if (from < 6) {
        await m.createTable(plan);
        await m.createTable(balanceSnapshots);
        await migrateToBuckets();
        await ensurePlan();
      }
      // v7: a list of EMIs instead of the plan's one EMI.
      if (from < 7) {
        await m.createTable(emis);
        await seedEmisFromPlan();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _addColumnIfMissing(Migrator m, TableInfo table, GeneratedColumn column) async {
    final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
    if (cols.any((c) => c.read<String>('name') == column.name)) return;
    await m.addColumn(table, column);
  }

  Future<void> _seedCategories() async {
    await batch((b) {
      for (final (i, c) in defaultCategories.indexed) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: c.name,
            icon: c.icon,
            color: c.color,
            isIncome: Value(c.isIncome),
            sortOrder: Value(i),
            seedName: Value(c.name),
            bucket: Value(c.bucket),
          ),
        );
      }
    });
  }

  /// Inserts seed categories added in later versions, matched by name.
  Future<void> _addMissingSeedCategories() async {
    final existing = {
      for (final c in await select(categories).get()) ...[c.name, ?c.seedName],
    };
    for (final (i, c) in defaultCategories.indexed) {
      if (existing.contains(c.name)) continue;
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: c.name,
          icon: c.icon,
          color: c.color,
          isIncome: Value(c.isIncome),
          sortOrder: Value(i),
          seedName: Value(c.name),
          bucket: Value(c.bucket),
        ),
      );
    }
  }

  /// Categories made by hand before they were seeds, adopted instead of
  /// duplicated: by name, the bucket they get.
  static const _adoptedCategories = {'Big & occasional': Bucket.fund, 'Gym & supplements': Bucket.fixed};

  /// One-time move from the v5 yes/no answers to buckets, run when
  /// upgrading to v6 and after restoring an older backup. Adds missing seed
  /// categories (Family, Big & occasional), sets each category's bucket by
  /// its seed, then turns every payment and payee answer into a bucket:
  /// yes → Everyday; no → the category's bucket, or Outside if that is
  /// Everyday. The old yes/no columns are left as they are.
  Future<void> migrateToBuckets() => transaction(() async {
    await (update(categories)..where((c) => c.name.equals('Big & occasional') & c.seedName.isNull())).write(
      const CategoriesCompanion(seedName: Value('Big & occasional')),
    );
    await _addMissingSeedCategories();
    final seeds = {for (final c in defaultCategories) c.name: c.bucket};
    for (final c in await select(categories).get()) {
      // A hand-made category the user had switched off stays out of Everyday.
      final b =
          seeds[c.seedName] ??
          _adoptedCategories[c.name] ??
          (c.countsInBudget || c.isIncome ? Bucket.everyday : Bucket.outside);
      await (update(categories)..where((r) => r.id.equals(c.id))).write(CategoriesCompanion(bucket: Value(b)));
    }
    final (everyday, outside) = (Bucket.everyday.index, Bucket.outside.index);
    String no(String categoryId) =>
        'COALESCE((SELECT CASE bucket WHEN $everyday THEN $outside ELSE bucket END '
        'FROM categories WHERE id = $categoryId), $outside)';
    await customUpdate(
      'UPDATE transactions SET bucket = CASE in_budget WHEN 1 THEN $everyday ELSE ${no('transactions.category_id')} END '
      'WHERE in_budget IS NOT NULL',
      updates: {transactions},
    );
    await customUpdate(
      'UPDATE merchant_rules SET bucket = CASE counts_in_budget WHEN 1 THEN $everyday '
      'ELSE ${no('merchant_rules.category_id')} END WHERE counts_in_budget IS NOT NULL',
      updates: {merchantRules},
    );
  });

  /// Turns the plan's single EMI (before v7) into the first row of the EMI
  /// list, once: on upgrade and after restoring an older backup. The plan's
  /// columns stay, unread.
  Future<void> seedEmisFromPlan() async {
    if (await (select(emis)..limit(1)).getSingleOrNull() != null) return;
    final p = await (select(plan)..limit(1)).getSingleOrNull();
    if (p == null || p.emiMinor <= 0) return;
    await into(emis).insert(EmisCompanion.insert(name: 'EMI', amountMinor: p.emiMinor, lastMonth: Value(p.emiEnds)));
  }

  Stream<List<Emi>> watchEmis() => (select(emis)..orderBy([(e) => OrderingTerm(expression: e.id)])).watch();

  Future<void> saveEmi({int? id, required String name, required int amountMinor, required DateTime? lastMonth}) {
    final row = EmisCompanion(name: Value(name), amountMinor: Value(amountMinor), lastMonth: Value(lastMonth));
    return id == null ? into(emis).insert(row) : (update(emis)..where((e) => e.id.equals(id))).write(row);
  }

  Future<void> deleteEmi(int id) => (delete(emis)..where((e) => e.id.equals(id))).go();

  /// Creates the plan row, starting this month, if there is none.
  Future<void> ensurePlan() async {
    if (await (select(plan)..limit(1)).getSingleOrNull() != null) return;
    await into(plan).insert(PlanCompanion.insert(startMonth: monthStart(DateTime.now())));
  }

  // ---------------------------------------------------------------- reads

  Stream<List<Category>> watchCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).watch();

  Future<List<Category>> allCategories() => select(categories).get();

  Stream<List<Account>> watchAccounts() => (select(accounts)..where((a) => a.archived.equals(false))).watch();

  Future<List<Account>> allAccounts() => select(accounts).get();

  /// Every account including archived ones, for the management screen.
  Stream<List<Account>> watchAllAccounts() => (select(
    accounts,
  )..orderBy([(a) => OrderingTerm(expression: a.archived), (a) => OrderingTerm(expression: a.name)])).watch();

  Stream<List<Budget>> watchBudgets() => select(budgets).watch();

  Future<List<Budget>> allBudgets() => select(budgets).get();

  /// Transaction count per category id (null = uncategorised).
  Future<int> countTxnsInCategory(int categoryId) async {
    final c = transactions.id.count();
    final q = selectOnly(transactions)
      ..addColumns([c])
      ..where(transactions.categoryId.equals(categoryId));
    return (await q.getSingle()).read(c) ?? 0;
  }

  Future<int> countTxnsWithMerchant(String merchant) async {
    final c = transactions.id.count();
    final q = selectOnly(transactions)
      ..addColumns([c])
      ..where(transactions.merchant.lower().equals(merchant.toLowerCase()));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Transactions in [from, to), newest first, joined with category/account.
  /// Nothing before [shownFrom] unless [allTime].
  Stream<List<TxnView>> watchTxns({DateTime? from, DateTime? to, int? limit, bool allTime = false}) {
    final q = select(transactions).join(_viewJoins);
    if (!allTime) from = _from(from);
    if (from != null) q.where(transactions.occurredAt.isBiggerOrEqualValue(from));
    if (to != null) q.where(transactions.occurredAt.isSmallerThanValue(to));
    q.orderBy([OrderingTerm.desc(transactions.occurredAt), OrderingTerm.desc(transactions.id)]);
    if (limit != null) q.limit(limit);
    return q.watch().map((rows) => [for (final r in rows) _view(r)]);
  }

  Stream<TxnView?> watchTxn(int id) {
    final q = select(transactions).join(_viewJoins)..where(transactions.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _view(r));
  }

  // Rule patterns are stored lower-cased (see [setCategory]).
  List<Join> get _viewJoins => [
    leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    leftOuterJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    leftOuterJoin(merchantRules, merchantRules.pattern.equalsExp(transactions.merchant.lower())),
  ];

  TxnView _view(TypedResult r) => TxnView(
    r.readTable(transactions),
    r.readTableOrNull(categories),
    r.readTableOrNull(accounts),
    r.readTableOrNull(merchantRules),
  );

  Stream<List<RawMessage>> watchSourcesFor(int txnId) =>
      (select(rawMessages)..where((m) => m.transactionId.equals(txnId))).watch();

  Stream<int> watchReviewCount() {
    final c = transactions.id.count();
    final q = selectOnly(transactions)
      ..addColumns([c])
      ..where(transactions.status.equalsValue(TxnStatus.needsReview));
    if (shownFrom != null) q.where(transactions.occurredAt.isBiggerOrEqualValue(shownFrom!));
    return q.watchSingle().map((r) => r.read(c) ?? 0);
  }

  Stream<Map<ParseStatus, int>> watchParseStats(SourceKind source) {
    final c = rawMessages.id.count();
    final q = selectOnly(rawMessages)
      ..addColumns([rawMessages.parseStatus, c])
      ..where(rawMessages.source.equalsValue(source))
      ..groupBy([rawMessages.parseStatus]);
    return q.watch().map(
      (rows) => {for (final r in rows) ParseStatus.values[r.read(rawMessages.parseStatus)!]: r.read(c) ?? 0},
    );
  }

  Stream<List<RawMessage>> watchRawMessages(SourceKind source, Set<ParseStatus> statuses) =>
      (select(rawMessages)
            ..where((m) => m.source.equalsValue(source) & m.parseStatus.isIn(statuses.map((s) => s.index)))
            ..orderBy([(m) => OrderingTerm.desc(m.receivedAt)])
            ..limit(300))
          .watch();

  Future<Set<String>> knownExternalIds(SourceKind source) async {
    final q = selectOnly(rawMessages)
      ..addColumns([rawMessages.externalId])
      ..where(rawMessages.source.equalsValue(source));
    return {for (final r in await q.get()) r.read(rawMessages.externalId)!};
  }

  /// Candidate duplicates: same amount, currency and direction within
  /// ±[window]. A transaction recorded in two currencies ("USD 12.50
  /// (INR 1,045.30)") also matches on its converted amount, both ways, so
  /// a rupee-only alert for the same card spend still finds it. [also] is
  /// the new payment's own converted amount, if any.
  Future<List<Transaction>> candidatesFor({
    required int amountMinor,
    String currency = 'INR',
    required TxnDirection direction,
    required DateTime at,
    Duration window = const Duration(hours: 48),
    (int, String)? also,
  }) =>
      (select(transactions)..where((t) {
            var amount =
                (t.amountMinor.equals(amountMinor) & t.currency.equals(currency)) |
                (t.convertedMinor.equals(amountMinor) & t.convertedCurrency.equals(currency));
            if (also != null) amount = amount | (t.amountMinor.equals(also.$1) & t.currency.equals(also.$2));
            return amount &
                t.direction.equalsValue(direction) &
                t.occurredAt.isBetweenValues(at.subtract(window), at.add(window));
          }))
          .get();

  Future<List<RawMessage>> sourcesOf(int txnId) =>
      (select(rawMessages)..where((m) => m.transactionId.equals(txnId))).get();

  Future<List<MerchantRule>> allMerchantRules() => select(merchantRules).get();

  /// Null only until [ensurePlan] has run.
  Stream<MonthlyPlan?> watchPlan() => (select(plan)..limit(1)).watchSingleOrNull();

  /// When the data starts: the earliest bank SMS, or the earliest message
  /// of any kind for an install without SMS; never before [shownFrom].
  Stream<DateTime?> watchDataStart() {
    final first = rawMessages.receivedAt.min();
    final sms = rawMessages.receivedAt.min(filter: rawMessages.source.equalsValue(SourceKind.sms));
    return (selectOnly(rawMessages)..addColumns([first, sms])).watchSingle().map((r) {
      final start = r.read(sms) ?? r.read(first);
      return start == null ? null : _from(start);
    });
  }

  /// Snapshots from [from] on, oldest first.
  Stream<List<BalanceSnapshot>> watchSnapshots({required DateTime from}) =>
      (select(balanceSnapshots)
            ..where((s) => s.month.isBiggerOrEqualValue(from))
            ..orderBy([(s) => OrderingTerm(expression: s.month), (s) => OrderingTerm(expression: s.id)]))
          .watch();

  // ---------------------------------------------------------------- writes

  Future<void> setCategory(int txnId, int? categoryId, {String? learnPattern}) => transaction(() async {
    await (update(transactions)..where((t) => t.id.equals(txnId))).write(
      TransactionsCompanion(categoryId: Value(categoryId), categoryLocked: const Value(true)),
    );
    await _reviewed(txnId);
    if (learnPattern != null && learnPattern.isNotEmpty && categoryId != null) {
      await into(merchantRules).insert(
        MerchantRulesCompanion.insert(pattern: learnPattern, categoryId: Value(categoryId)),
        onConflict: DoUpdate(
          (_) => MerchantRulesCompanion(categoryId: Value(categoryId)),
          target: [merchantRules.pattern],
        ),
      );
      // Apply to other uncategorised/unlocked transactions with the same merchant.
      await (update(transactions)
            ..where((t) => t.merchant.lower().equals(learnPattern) & t.categoryLocked.equals(false)))
          .write(TransactionsCompanion(categoryId: Value(categoryId)));
    }
  });

  Future<void> deleteTxn(int id) => transaction(() async {
    await (update(rawMessages)..where((m) => m.transactionId.equals(id))).write(
      const RawMessagesCompanion(
        transactionId: Value(null),
        parseStatus: Value(ParseStatus.ignored),
        ignoreReason: Value('Deleted by user'),
      ),
    );
    await _forget(id);
  });

  /// Deletes payment [id] and clears "possible duplicate of" links to it.
  Future<void> _forget(int id) async {
    await (update(transactions)..where((t) => t.duplicateOfId.equals(id))).write(
      const TransactionsCompanion(duplicateOfId: Value(null), status: Value(TxnStatus.confirmed)),
    );
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Payment [id] turned out not to be one (a notice, a declined charge):
  /// it goes, and its messages are kept as ignored with [reason] so they
  /// aren't imported again.
  Future<void> dropNonPayment(int id, String reason) => transaction(() async {
    await (update(rawMessages)..where((m) => m.transactionId.equals(id))).write(
      RawMessagesCompanion(
        transactionId: const Value(null),
        parseStatus: const Value(ParseStatus.ignored),
        ignoreReason: Value(reason),
      ),
    );
    await _forget(id);
  });

  /// Sets the merchant and counterparty of one payment, nothing else.
  Future<void> setParty(int id, {required String? merchant, required String? counterparty}) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(merchant: Value(merchant), counterparty: Value(counterparty)),
      );

  /// [fromId] is the same payment as [intoId]: its messages move over, and
  /// what [intoId] lacks (reference, merchant, account, the user's
  /// category, bucket or note) is taken from it before it goes.
  Future<void> mergeInto(int fromId, int intoId) => transaction(() async {
    final from = await (select(transactions)..where((t) => t.id.equals(fromId))).getSingle();
    final into = await (select(transactions)..where((t) => t.id.equals(intoId))).getSingle();
    await (update(rawMessages)..where((m) => m.transactionId.equals(fromId))).write(
      RawMessagesCompanion(transactionId: Value(intoId), parseStatus: const Value(ParseStatus.merged)),
    );
    await (delete(transactions)..where((t) => t.id.equals(fromId))).go();
    Value<T> fill<T>(T? mine, T? theirs) => mine == null && theirs != null ? Value(theirs) : const Value.absent();
    final takeCategory = from.categoryLocked && !into.categoryLocked;
    // A bucket rule for the kept payment's payee is the user's word on it.
    final payee = (into.merchant ?? from.merchant)?.toLowerCase();
    final rule = payee == null
        ? null
        : await (select(merchantRules)..where((r) => r.pattern.equals(payee))).getSingleOrNull();
    await (update(transactions)..where((t) => t.id.equals(intoId))).write(
      TransactionsCompanion(
        status: const Value(TxnStatus.confirmed),
        duplicateOfId: const Value(null),
        reference: fill(into.reference, from.reference),
        merchant: fill(into.merchant, from.merchant),
        counterparty: fill(into.counterparty, from.counterparty),
        accountId: fill(into.accountId, from.accountId),
        accountHint: fill(into.accountHint, from.accountHint),
        note: fill(into.note, from.note),
        bucket: rule?.bucket != null ? const Value.absent() : fill(into.bucket, from.bucket),
        categoryId: takeCategory ? Value(from.categoryId) : fill(into.categoryId, from.categoryId),
        categoryLocked: takeCategory ? const Value(true) : const Value.absent(),
      ),
    );
    // Anything that pointed at the removed payment now points at the kept one.
    await (update(
      transactions,
    )..where((t) => t.duplicateOfId.equals(fromId))).write(TransactionsCompanion(duplicateOfId: Value(intoId)));
  });

  Future<void> confirm(int id) => (update(transactions)..where((t) => t.id.equals(id))).write(
    const TransactionsCompanion(status: Value(TxnStatus.confirmed), duplicateOfId: Value(null)),
  );

  /// The bucket for one payment; null goes back to the payee rule /
  /// category. Touches no other payment and no rule.
  Future<void> setTxnBucket(int id, Bucket? bucket) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(bucket: Value(bucket)));

  /// Need or want for one payment. Null goes back to the payee, then the category.
  Future<void> setTxnSpendKind(int id, SpendKind? kind) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(spendKind: Value(kind)));

  /// Need or want for every payment to [merchant]. Null removes the answer.
  /// Payments that had their own answer follow the payee from now on.
  Future<void> setPayeeSpendKind(String merchant, SpendKind? kind) => transaction(() async {
    final pattern = merchant.toLowerCase();
    if (pattern.isEmpty) return;
    await into(merchantRules).insert(
      MerchantRulesCompanion.insert(pattern: pattern, spendKind: Value(kind)),
      onConflict: DoUpdate((_) => MerchantRulesCompanion(spendKind: Value(kind)), target: [merchantRules.pattern]),
    );
    await (update(
      transactions,
    )..where((t) => t.merchant.lower().equals(pattern))).write(const TransactionsCompanion(spendKind: Value(null)));
  });

  /// The bucket for every payment to [merchant] (null removes the answer).
  /// Payments to it that had their own bucket follow the rule from now on,
  /// so one pick decides for the payee, except ones marked Big & occasional
  /// or Ignore (money lent or paid back): those are calls about one payment.
  Future<void> setPayeeBucket(String merchant, Bucket? bucket) => transaction(() async {
    final pattern = merchant.toLowerCase();
    if (pattern.isEmpty) return;
    await into(merchantRules).insert(
      MerchantRulesCompanion.insert(pattern: pattern, bucket: Value(bucket)),
      onConflict: DoUpdate((_) => MerchantRulesCompanion(bucket: Value(bucket)), target: [merchantRules.pattern]),
    );
    await (update(transactions)..where(
          (t) => t.merchant.lower().equals(pattern) & t.bucket.isNotInValues(const [Bucket.fund, Bucket.lending]),
        ))
        .write(const TransactionsCompanion(bucket: Value(null)));
  });

  Future<void> setTransfer(int id, bool value) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(isTransfer: Value(value)));

  Future<void> setNote(int id, String? note) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(TransactionsCompanion(note: Value(note)));

  /// [currency] defaults to the home currency; [convertedMinor] is the
  /// home-currency amount of a foreign one.
  Future<int> addManual({
    required int amountMinor,
    String? currency,
    int? convertedMinor,
    required TxnDirection direction,
    required DateTime at,
    String? merchant,
    int? categoryId,
    int? accountId,
    String? note,
  }) => transaction(() async {
    final id = await into(transactions).insert(
      TransactionsCompanion.insert(
        amountMinor: amountMinor,
        currency: Value(currency ?? Currencies.home),
        convertedMinor: Value(convertedMinor),
        convertedCurrency: Value(convertedMinor == null ? null : Currencies.home),
        direction: direction,
        occurredAt: at,
        merchant: Value(merchant),
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        note: Value(note),
        mode: PaymentMode.cash,
        status: TxnStatus.confirmed,
        categoryLocked: const Value(true),
      ),
    );
    await into(rawMessages).insert(
      RawMessagesCompanion.insert(
        source: SourceKind.manual,
        externalId: 'manual-$id',
        sender: 'You',
        body: 'Added manually',
        receivedAt: DateTime.now(),
        parseStatus: ParseStatus.parsed,
        transactionId: Value(id),
      ),
    );
    return id;
  });

  /// Drops everything that came from [source] so it can be re-parsed.
  /// Transactions also backed by another source (manual, email) survive.
  Future<void> resetSource(SourceKind source) => transaction(() async {
    await (delete(rawMessages)..where((m) => m.source.equalsValue(source))).go();
    await customStatement(
      'DELETE FROM transactions WHERE id NOT IN '
      '(SELECT transaction_id FROM raw_messages WHERE transaction_id IS NOT NULL)',
    );
  });

  // ------------------------------------------------------------- editing

  /// A low-confidence payment the user has just corrected needs no "Looks
  /// right" on top. A possible duplicate still waits for its own answer.
  Future<void> _reviewed(int id) => (update(transactions)..where((t) => t.id.equals(id) & t.duplicateOfId.isNull()))
      .write(const TransactionsCompanion(status: Value(TxnStatus.confirmed)));

  /// Edits the user-facing fields of a transaction and counts as reviewing
  /// it. Source evidence (raw messages, reference, counterparty) is left
  /// untouched.
  Future<void> updateTxn(
    int id, {
    required int amountMinor,
    Value<String> currency = const Value.absent(),
    Value<int?> convertedMinor = const Value.absent(),
    Value<String?> convertedCurrency = const Value.absent(),
    required TxnDirection direction,
    required DateTime occurredAt,
    required String? merchant,
    required int? accountId,
    required String? note,
    Value<int?> categoryId = const Value.absent(),
  }) => transaction(() async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amountMinor: Value(amountMinor),
        currency: currency,
        convertedMinor: convertedMinor,
        convertedCurrency: convertedCurrency,
        direction: Value(direction),
        occurredAt: Value(occurredAt),
        merchant: Value(merchant),
        accountId: Value(accountId),
        note: Value(note),
        categoryId: categoryId,
      ),
    );
    await _reviewed(id);
  });

  /// Records what a foreign transaction came to in [currency] (normally
  /// the home currency), or clears it with a null [minor].
  Future<void> setConversion(int id, {required int? minor, required String currency}) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(convertedMinor: Value(minor), convertedCurrency: Value(minor == null ? null : currency)),
      );

  /// Renames every transaction from merchant [from] (case-insensitive) to
  /// [to] and carries the learned category rule over, so future messages
  /// that still read [from] keep their category and [to] learns it too.
  /// Returns how many transactions were renamed.
  Future<int> renameMerchant(String from, String to) => transaction(() async {
    final oldKey = from.trim().toLowerCase();
    final newKey = to.trim().toLowerCase();
    if (oldKey.isEmpty || newKey.isEmpty) return 0;
    final n = await (update(
      transactions,
    )..where((t) => t.merchant.lower().equals(oldKey))).write(TransactionsCompanion(merchant: Value(to.trim())));
    if (oldKey == newKey) return n;
    final rules = {for (final r in await allMerchantRules()) r.pattern: r};
    final oldRule = rules[oldKey];
    if (oldRule != null && !rules.containsKey(newKey)) {
      await into(merchantRules).insert(
        MerchantRulesCompanion.insert(
          pattern: newKey,
          categoryId: Value(oldRule.categoryId),
          bucket: Value(oldRule.bucket),
        ),
      );
    }
    // Renamed onto a merchant the user already taught: follow that rule.
    final target = rules[newKey]?.categoryId;
    if (target != null) {
      await (update(transactions)..where((t) => t.merchant.lower().equals(newKey) & t.categoryLocked.equals(false)))
          .write(TransactionsCompanion(categoryId: Value(target)));
    }
    return n;
  });

  // ----------------------------------------------------------- budgets

  /// Creates or replaces the monthly budget for [categoryId] (null = overall),
  /// in [currency] (the home currency by default).
  Future<void> setBudget({int? categoryId, required int amountMinor, bool active = true, String? currency}) =>
      transaction(() async {
        final code = currency ?? Currencies.home;
        final existing = await (select(
          budgets,
        )..where((b) => categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId))).get();
        if (existing.isEmpty) {
          await into(budgets).insert(
            BudgetsCompanion.insert(
              categoryId: Value(categoryId),
              amountMinor: amountMinor,
              active: Value(active),
              currency: Value(code),
            ),
          );
          return;
        }
        await (update(budgets)..where((b) => b.id.equals(existing.first.id))).write(
          BudgetsCompanion(amountMinor: Value(amountMinor), active: Value(active), currency: Value(code)),
        );
        for (final dup in existing.skip(1)) {
          await (delete(budgets)..where((b) => b.id.equals(dup.id))).go();
        }
      });

  Future<void> setBudgetActive(int id, bool active) =>
      (update(budgets)..where((b) => b.id.equals(id))).write(BudgetsCompanion(active: Value(active)));

  Future<void> deleteBudget(int id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  // -------------------------------------------------------------- plan

  Future<void> savePlan(PlanCompanion values) => update(plan).write(values);

  /// Replaces [month]'s balances with [rows]: (label, amount, liability).
  Future<void> saveSnapshots(DateTime month, List<(String, int, bool)> rows) => transaction(() async {
    await (delete(balanceSnapshots)..where((s) => s.month.equals(month))).go();
    for (final (label, amount, liability) in rows) {
      await into(balanceSnapshots).insert(
        BalanceSnapshotsCompanion.insert(
          month: month,
          label: label,
          amountMinor: amount,
          isLiability: Value(liability),
        ),
      );
    }
  });

  // ---------------------------------------------------------- accounts

  /// [currency] defaults to the home currency.
  Future<int> addAccount({required String name, required AccountKind kind, required int color, String? currency}) =>
      into(accounts).insert(
        AccountsCompanion.insert(name: name, kind: kind, color: color, currency: Value(currency ?? Currencies.home)),
      );

  Future<void> updateAccount(int id, {String? name, AccountKind? kind, int? color, bool? archived, String? currency}) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          name: name == null ? const Value.absent() : Value(name),
          kind: kind == null ? const Value.absent() : Value(kind),
          color: color == null ? const Value.absent() : Value(color),
          archived: archived == null ? const Value.absent() : Value(archived),
          currency: currency == null ? const Value.absent() : Value(currency),
        ),
      );

  // -------------------------------------------------------- categories

  static bool isProtected(Category c) => protectedCategories.contains(c.seedName ?? c.name);

  Future<int> addCategory({required String name, required String icon, required int color, bool isIncome = false}) =>
      transaction(() async {
        final maxOrder = categories.sortOrder.max();
        final row = await (selectOnly(categories)..addColumns([maxOrder])).getSingle();
        return into(categories).insert(
          CategoriesCompanion.insert(
            name: name,
            icon: icon,
            color: color,
            isIncome: Value(isIncome),
            sortOrder: Value((row.read(maxOrder) ?? -1) + 1),
          ),
        );
      });

  Future<void> updateCategory(int id, {String? name, String? icon, int? color, bool? isIncome, Bucket? bucket}) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          name: name == null ? const Value.absent() : Value(name),
          icon: icon == null ? const Value.absent() : Value(icon),
          color: color == null ? const Value.absent() : Value(color),
          isIncome: isIncome == null ? const Value.absent() : Value(isIncome),
          bucket: bucket == null ? const Value.absent() : Value(bucket),
        ),
      );

  /// Persists a new display order; [ids] is the full ordered list.
  Future<void> reorderCategories(List<int> ids) => batch((b) {
    for (final (i, id) in ids.indexed) {
      b.update(categories, CategoriesCompanion(sortOrder: Value(i)), where: (c) => c.id.equals(id));
    }
  });

  /// Deletes category [id], moving its transactions and learned merchant
  /// rules to [moveTo] first so nothing is orphaned. Its budget goes too.
  /// Transfers and Other can't be deleted.
  Future<void> deleteCategory(int id, {required int moveTo}) => transaction(() async {
    if (id == moveTo) throw ArgumentError('Pick a different category to move transactions to');
    final cat = await (select(categories)..where((c) => c.id.equals(id))).getSingle();
    await (select(categories)..where((c) => c.id.equals(moveTo))).getSingle(); // must exist
    if (isProtected(cat)) throw StateError('${cat.name} can\'t be deleted');
    await (update(
      transactions,
    )..where((t) => t.categoryId.equals(id))).write(TransactionsCompanion(categoryId: Value(moveTo)));
    await (update(
      merchantRules,
    )..where((r) => r.categoryId.equals(id))).write(MerchantRulesCompanion(categoryId: Value(moveTo)));
    await (delete(budgets)..where((b) => b.categoryId.equals(id))).go();
    await (delete(categories)..where((c) => c.id.equals(id))).go();
  });

  /// Wipes all imported data (keeps categories, accounts and learned rules).
  Future<void> resetImported() => transaction(() async {
    await delete(rawMessages).go();
    await delete(transactions).go();
  });
}

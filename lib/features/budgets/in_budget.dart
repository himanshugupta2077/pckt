import '../../data/db/database.dart';

/// Why a payment is in its bucket.
enum BudgetSource { transfer, income, manual, payee, category, fallback }

class BudgetDecision {
  const BudgetDecision(this.bucket, this.source);

  /// Null for transfers and money in, which are in no bucket.
  final Bucket? bucket;
  final BudgetSource source;

  /// Only Everyday counts toward the monthly budget.
  bool get counts => bucket == Bucket.everyday;
}

/// The one place that decides a payment's bucket. First match wins:
/// transfers and money in never count; then the bucket set for this
/// payment, the payee's, the category's; anything else is Everyday.
BudgetDecision budgetDecision(TxnView v) {
  final t = v.txn;
  if (t.isTransfer) return const BudgetDecision(null, BudgetSource.transfer);
  if (t.direction == TxnDirection.credit) return const BudgetDecision(null, BudgetSource.income);
  if (t.bucket case final b?) return BudgetDecision(b, BudgetSource.manual);
  if (v.rule?.bucket case final b?) return BudgetDecision(b, BudgetSource.payee);
  if (v.category case final c?) return BudgetDecision(c.bucket, BudgetSource.category);
  return const BudgetDecision(Bucket.everyday, BudgetSource.fallback);
}

/// Monthly budget for each of Everyday, Fixed and Fund: ₹10,000, fixed in
/// code rather than set in the app.
const bucketBudgetMinor = 1000000;

String bucketLabel(Bucket b) => switch (b) {
  Bucket.everyday => 'Everyday',
  Bucket.fixed => 'Fixed',
  Bucket.fund => 'Fund',
  Bucket.outside => 'Outside',
  Bucket.ignore => 'Ignore',
};

/// Neither spending nor income (money lent or borrowed and paid back, cash
/// moved into the bank), in either direction. Decided like a bucket (the
/// payment's own choice, then the payee's, then the category's).
bool isIgnored(TxnView v) => (v.txn.bucket ?? v.rule?.bucket ?? v.category?.bucket) == Bucket.ignore;

/// Short line for the transaction sheet.
String budgetSourceLabel(TxnView v) {
  final d = budgetDecision(v);
  return switch (d.source) {
    BudgetSource.transfer => 'Transfers never count',
    BudgetSource.income => 'Money in never counts',
    BudgetSource.manual => 'Set for this payment',
    BudgetSource.payee => 'From payee rule',
    BudgetSource.category => 'From category: ${v.category!.name}',
    BudgetSource.fallback => 'No category, so Everyday',
  };
}

/// Payments at or above this (in home-currency minor units, ₹2,000) are
/// worth a question even from a payee seen once.
const toSortMinMinor = 200000;

/// Seed categories that say nothing about whether a payment is budget spend.
const _vagueCategories = {'Other', 'People'};

/// A payment the app can't place on its own: a debit with no answer, no
/// payee rule, and no telling category, that is either large or from a
/// payee seen more than once. [merchantCounts] is payments per lower-cased
/// merchant (see [merchantCounts]).
bool needsSorting(TxnView v, Map<String, int> merchantCounts) {
  final t = v.txn;
  if (t.isTransfer || t.direction != TxnDirection.debit || t.bucket != null) return false;
  if (v.rule?.bucket != null) return false;
  final c = v.category;
  if (c != null && !_vagueCategories.contains(c.seedName ?? c.name)) return false;
  final amount = t.homeMinor ?? 0;
  final seen = t.merchant == null ? 1 : merchantCounts[t.merchant!.toLowerCase()] ?? 1;
  return amount >= toSortMinMinor || seen >= 2;
}

Map<String, int> merchantCounts(Iterable<TxnView> txns) {
  final out = <String, int>{};
  for (final v in txns) {
    final m = v.txn.merchant?.toLowerCase();
    if (m != null && v.txn.direction == TxnDirection.debit) out[m] = (out[m] ?? 0) + 1;
  }
  return out;
}

/// What the "To sort" screen shows: one row per payee (their payments
/// answered together) or one per payment without a merchant.
class SortItem {
  SortItem(this.merchant, this.txns);

  /// Null for a single payment with no merchant.
  final String? merchant;
  final List<TxnView> txns;

  int get totalMinor => txns.fold(0, (s, v) => s + (v.txn.homeMinor ?? 0));
  TxnView get latest => txns.first;
}

/// [txns] newest first. Payees with the most money first.
List<SortItem> toSort(List<TxnView> txns) {
  final counts = merchantCounts(txns);
  final byMerchant = <String, SortItem>{};
  final singles = <SortItem>[];
  for (final v in txns) {
    if (!needsSorting(v, counts)) continue;
    final m = v.txn.merchant;
    if (m == null) {
      singles.add(SortItem(null, [v]));
    } else {
      (byMerchant[m.toLowerCase()] ??= SortItem(m, [])).txns.add(v);
    }
  }
  return [...byMerchant.values, ...singles]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
}

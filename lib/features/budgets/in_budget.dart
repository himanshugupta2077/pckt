import '../../data/db/database.dart';

/// Why a payment does or doesn't count toward the budget.
enum BudgetSource { transfer, income, manual, payee, category, fallback }

class BudgetDecision {
  const BudgetDecision(this.counts, this.source);
  final bool counts;
  final BudgetSource source;
}

/// The one place that decides "counts toward budget?". First match wins:
/// transfers and money in never count; then the user's answer for this
/// payment, the payee rule, the category; anything else counts.
BudgetDecision budgetDecision(TxnView v) {
  final t = v.txn;
  if (t.isTransfer) return const BudgetDecision(false, BudgetSource.transfer);
  if (t.direction == TxnDirection.credit) return const BudgetDecision(false, BudgetSource.income);
  if (t.inBudget case final b?) return BudgetDecision(b, BudgetSource.manual);
  if (v.rule?.countsInBudget case final b?) return BudgetDecision(b, BudgetSource.payee);
  if (v.category case final c?) return BudgetDecision(c.countsInBudget, BudgetSource.category);
  return const BudgetDecision(true, BudgetSource.fallback);
}

/// Short line for the transaction sheet.
String budgetSourceLabel(TxnView v) {
  final d = budgetDecision(v);
  return switch (d.source) {
    BudgetSource.transfer => 'Transfers never count',
    BudgetSource.income => 'Money in never counts',
    BudgetSource.manual => 'Set for this payment',
    BudgetSource.payee => 'From payee rule',
    BudgetSource.category => 'From category: ${v.category!.name}',
    BudgetSource.fallback => 'No category, so it counts',
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
  if (t.isTransfer || t.direction != TxnDirection.debit || t.inBudget != null) return false;
  if (v.rule?.countsInBudget != null) return false;
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

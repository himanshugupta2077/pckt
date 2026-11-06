import '../../data/db/database.dart';
import '../stats.dart' show CategoryTotal;
import 'in_budget.dart';

/// Debits per bucket, in the home currency ([budgetDecision]). Transfers,
/// money in and unconverted foreign payments are in none.
Map<Bucket, int> bucketTotals(Iterable<TxnView> txns) {
  final out = {for (final b in Bucket.values) b: 0};
  for (final v in txns) {
    final (b, amount) = (budgetDecision(v).bucket, v.txn.homeMinor);
    if (b != null && amount != null) out[b] = out[b]! + amount;
  }
  return out;
}

/// The Outside bucket split by category, largest first.
List<CategoryTotal> outsideByCategory(Iterable<TxnView> txns) {
  final byCat = <int?, CategoryTotal>{};
  for (final v in txns) {
    final amount = v.txn.homeMinor;
    if (amount == null || budgetDecision(v).bucket != Bucket.outside) continue;
    final prev = byCat[v.txn.categoryId];
    byCat[v.txn.categoryId] = CategoryTotal(v.category, (prev?.amount ?? 0) + amount);
  }
  return byCat.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
}

/// Months before [month] that the data covers from start to end, newest
/// first, at most [max]. The month the data starts in counts only if it
/// starts in its first three days (bank SMS rarely land on the 1st itself).
List<DateTime> completeMonths(DateTime month, DateTime? dataStart, {int max = 6}) {
  if (dataStart == null) return const [];
  final first = dataStart.day <= 3
      ? DateTime(dataStart.year, dataStart.month)
      : DateTime(dataStart.year, dataStart.month + 1);
  return [
    for (var i = 1; i <= max; i++)
      if (!DateTime(month.year, month.month - i).isBefore(first)) DateTime(month.year, month.month - i),
  ];
}

class MonthAverage {
  const MonthAverage(this.minor, this.months);

  /// Per month; 0 with no complete months.
  final int minor;
  final int months;

  String get label => 'avg of $months month${months == 1 ? '' : 's'}';
}

/// Average per month over [months] of the debits [include] picks.
MonthAverage monthlyAverage(Iterable<TxnView> txns, List<DateTime> months, bool Function(TxnView) include) {
  if (months.isEmpty) return const MonthAverage(0, 0);
  final keys = {for (final m in months) (m.year, m.month)};
  var total = 0;
  for (final v in txns) {
    final t = v.txn;
    final amount = t.homeMinor;
    if (amount == null || !keys.contains((t.occurredAt.year, t.occurredAt.month)) || !include(v)) continue;
    total += amount;
  }
  return MonthAverage((total / months.length).round(), months.length);
}

bool isFixed(TxnView v) => budgetDecision(v).bucket == Bucket.fixed;

/// Family and Insurance payments in Outside (the plan subtracts these on
/// top of Fixed; ones moved to another bucket are counted there).
bool isFamilyOrInsurance(TxnView v) =>
    budgetDecision(v).bucket == Bucket.outside &&
    const {'Family', 'Insurance'}.contains(v.category?.seedName ?? v.category?.name);

/// Months from [start] to [month], both included; 0 if [month] is earlier.
int monthsSince(DateTime start, DateTime month) {
  final n = (month.year - start.year) * 12 + month.month - start.month + 1;
  return n < 0 ? 0 : n;
}

bool inMonth(DateTime at, DateTime month) => at.year == month.year && at.month == month.month;

/// What the Home Buckets card shows for [month]: Fixed and Fund against
/// their monthly budget ([bucketBudgetMinor]), Outside by category.
class BucketSummary {
  BucketSummary({required List<TxnView> txns, required DateTime month}) {
    final thisMonth = txns.where((v) => inMonth(v.txn.occurredAt, month)).toList();
    final totals = bucketTotals(thisMonth);
    everyday = totals[Bucket.everyday]!;
    fixed = totals[Bucket.fixed]!;
    fund = totals[Bucket.fund]!;
    outside = outsideByCategory(thisMonth);
    for (final v in thisMonth) {
      final amount = v.txn.homeMinor;
      if (amount == null || isTransferLike(v)) continue;
      final out = v.txn.direction == TxnDirection.debit;
      switch (bucketOf(v)) {
        case Bucket.invest:
          invested += out ? amount : -amount;
        case Bucket.lending:
          if (out) {
            lentOut += amount;
          } else {
            lentIn += amount;
          }
        default:
      }
    }
  }

  late final int everyday;
  late final int fixed;
  late final int fund;
  late final List<CategoryTotal> outside;

  /// Put into investments less what came back from them.
  int invested = 0;

  /// Lending money in (borrowed, or paid back to you) and out.
  int lentIn = 0, lentOut = 0;

  int get outsideTotal => outside.fold(0, (s, c) => s + c.amount);
}

/// Out on the month card: spending, EMIs, money invested and money lent,
/// less what came back. [emiMinor] is the plan's EMI list, not payments.
int monthOutMinor(BucketSummary s, int emiMinor) =>
    s.everyday + s.fixed + s.fund + s.outsideTotal + emiMinor + s.invested + s.lentOut - s.lentIn;

/// One piece of [monthOutMinor], for the Out sheet. [minor] is its share:
/// negative when money came back (an investment sold, or lending repaid).
class FlowLine {
  const FlowLine(this.bucket, this.minor, this.txns);

  final Bucket bucket;
  final int minor;
  final List<TxnView> txns;

  String get label => bucket == Bucket.invest ? 'Invested' : bucketLabel(bucket);
}

/// What adds up to Out for transactions already in one month. EMI is not
/// here. Transfers and payments with no home-currency amount are skipped.
List<FlowLine> outLines(Iterable<TxnView> txns) {
  final byBucket = {for (final b in Bucket.values) b: <TxnView>[]};
  for (final v in txns) {
    final amount = v.txn.homeMinor;
    if (amount == null || isTransferLike(v)) continue;
    final decided = budgetDecision(v).bucket;
    if (decided != null) {
      byBucket[decided]!.add(v);
    } else if (isInvest(v) || isLending(v)) {
      // A credit has no spend bucket, but money back from investing or
      // lending still changes Out.
      byBucket[bucketOf(v)]!.add(v);
    }
  }
  int share(Bucket b, List<TxnView> list) {
    if (b != Bucket.invest && b != Bucket.lending) {
      return list.fold(0, (s, v) => s + (v.txn.homeMinor ?? 0));
    }
    var n = 0;
    for (final v in list) {
      final amount = v.txn.homeMinor ?? 0;
      n += v.txn.direction == TxnDirection.debit ? amount : -amount;
    }
    return n;
  }

  const order = [Bucket.everyday, Bucket.fixed, Bucket.fund, Bucket.invest, Bucket.lending, Bucket.outside];
  return [
    for (final b in order)
      if (byBucket[b]!.isNotEmpty) FlowLine(b, share(b, byBucket[b]!), byBucket[b]!),
  ];
}

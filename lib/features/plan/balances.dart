import '../../core/format.dart';
import '../../data/db/database.dart';

/// What a first month starts with: (label, is a liability).
const defaultBalanceLabels = [
  ('Bank', false),
  ('MF/stocks', false),
  ('PF', false),
  ('Card due', true),
  ('Loan left', true),
];

/// Labels to fill in for [month]: the latest earlier month's, in order, or
/// the defaults.
List<(String, bool)> balanceLabels(List<BalanceSnapshot> snaps, DateTime month) {
  final earlier = snaps.where((s) => s.month.isBefore(month)).toList();
  if (earlier.isEmpty) return defaultBalanceLabels;
  final last = earlier.map((s) => s.month).reduce((a, b) => a.isAfter(b) ? a : b);
  return [
    for (final s in earlier)
      if (s.month == last) (s.label, s.isLiability),
  ];
}

/// Assets − liabilities per month, newest first, at most [take] months.
List<(DateTime, int)> netWorthByMonth(List<BalanceSnapshot> snaps, {int take = 6}) {
  final byMonth = <DateTime, int>{};
  for (final s in snaps) {
    byMonth[s.month] = (byMonth[s.month] ?? 0) + (s.isLiability ? -s.amountMinor : s.amountMinor);
  }
  final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final m in months.take(take)) (m, byMonth[m]!)];
}

/// Home asks for balances from the 1st to the 7th, until the month is filled.
bool balancesDue(DateTime now, List<BalanceSnapshot> snaps) =>
    now.day <= 7 && !snaps.any((s) => s.month == monthStart(now));

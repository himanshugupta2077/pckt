import 'dart:math' as math;

import '../../data/db/database.dart';
import '../budgets/in_budget.dart';

/// Why a payment is a need, a want, invested or lent.
enum SpendSource { transfer, income, lending, invest, manual, payee, category, fallback }

class SpendDecision {
  const SpendDecision(this.kind, this.source);

  /// Null when the payment is not a need or a want.
  final SpendKind? kind;
  final SpendSource source;
}

/// First match wins. Investment and lending apply in both directions, and
/// they win over a need/want left on the same payment so it is not counted
/// twice. An Investments payment counts as invested even when its bucket is
/// still Outside. Every other spend is a need or a want: the payment's own
/// answer, the payee's, the category's, else want.
SpendDecision spendDecision(TxnView v) {
  final t = v.txn;
  if (isTransferLike(v)) return const SpendDecision(null, SpendSource.transfer);
  if (_invested(v)) return const SpendDecision(null, SpendSource.invest);
  if (_lent(v)) return const SpendDecision(null, SpendSource.lending);
  if (t.direction == TxnDirection.credit) return const SpendDecision(null, SpendSource.income);
  if (t.spendKind case final k?) return SpendDecision(k, SpendSource.manual);
  if (v.rule?.spendKind case final k?) return SpendDecision(k, SpendSource.payee);
  if (v.category case final c?) return SpendDecision(c.spendKind, SpendSource.category);
  return const SpendDecision(SpendKind.want, SpendSource.fallback);
}

/// A category whose spends are never a need or a want, so it has no
/// choice to make in Settings.
bool categoryHasSpendKind(Category c) {
  final seed = c.seedName ?? c.name;
  return !c.isIncome &&
      seed != 'Transfers' &&
      seed != 'Investments' &&
      seed != 'Family' &&
      c.bucket != Bucket.invest &&
      c.bucket != Bucket.lending;
}

bool _invested(TxnView v) => isInvest(v) || (v.category?.seedName ?? v.category?.name) == 'Investments';

bool _lent(TxnView v) => isLending(v) || (v.category?.seedName ?? v.category?.name) == 'Family';

/// The need/want control applies. Invested, lent, transfers and income do not.
bool canSetSpendKind(TxnView v) => spendDecision(v).kind != null;

/// Whole percent of [whole], half up. 0 when [whole] is not positive.
int percentOf(int part, int whole) {
  if (whole <= 0) return 0;
  final neg = part.isNegative;
  final q = (part.abs() * 100 + whole ~/ 2) ~/ whole;
  return neg ? -q : q;
}

String percentLabel(int n) => '${n.isNegative ? '−' : ''}${n.abs()}%';

/// This month's salary split. [txns] are already the month.
///
/// [emiMinor] is the plan's active instalments. A card EMI is not its own
/// transaction, so it is added to needs, less any Loans & EMI payment
/// already counted there, so a bank-debited EMI is not counted twice.
/// Savings is what the salary has
/// left after invested, needs and wants. Lending is not part of it: money
/// lent comes back.
class SalarySplit {
  SalarySplit({required List<TxnView> txns, required this.salaryMinor, this.emiMinor = 0}) {
    for (final v in txns) {
      final amount = v.txn.homeMinor;
      if (amount == null) continue;
      final d = spendDecision(v);
      final credit = v.txn.direction == TxnDirection.credit;
      switch (d.source) {
        case SpendSource.invest:
          invested += credit ? -amount : amount;
          investTxns.add(v);
        case SpendSource.transfer || SpendSource.income || SpendSource.lending:
          break;
        case SpendSource.manual || SpendSource.payee || SpendSource.category || SpendSource.fallback:
          switch (d.kind) {
            case SpendKind.need:
              needs += amount;
              needTxns.add(v);
              if ((v.category?.seedName ?? v.category?.name) == 'Loans & EMI') emiPaid += amount;
            case SpendKind.want:
              wants += amount;
              wantTxns.add(v);
            case null:
              break;
          }
      }
    }
    needs += math.max(0, emiMinor - emiPaid);
  }

  final int salaryMinor;

  /// Plan EMIs, included in [needs] less [emiPaid].
  final int emiMinor;

  /// Loans & EMI payments this month, counted as needs.
  int emiPaid = 0;

  int invested = 0;
  int needs = 0;
  int wants = 0;
  final investTxns = <TxnView>[];
  final needTxns = <TxnView>[];
  final wantTxns = <TxnView>[];

  /// Salary left after the other three. Negative when they are more.
  int get savings => salaryMinor - invested - needs - wants;

  /// Whole percents of salary for invested, needs, wants and savings.
  /// Savings is 100 minus the other three, so the four add up to 100.
  (int, int, int, int) get percents {
    final i = percentOf(invested, salaryMinor);
    final n = percentOf(needs, salaryMinor);
    final w = percentOf(wants, salaryMinor);
    return (i, n, w, salaryMinor > 0 ? 100 - i - n - w : 0);
  }
}

String spendSourceLabel(TxnView v) {
  final d = spendDecision(v);
  final name = d.kind == SpendKind.need ? 'Need' : 'Want';
  return switch (d.source) {
    SpendSource.transfer => 'Transfers are not part of this',
    SpendSource.income => 'Money in is not part of this',
    SpendSource.lending => 'Lending is not a need or a want',
    SpendSource.invest => 'Invested',
    SpendSource.manual => '$name, set for this payment',
    SpendSource.payee => '$name, from the payee',
    SpendSource.category => '$name, from ${v.category!.name}',
    SpendSource.fallback => 'Want, no category',
  };
}

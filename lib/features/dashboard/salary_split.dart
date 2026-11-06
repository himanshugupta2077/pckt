import '../../data/db/database.dart';
import '../budgets/in_budget.dart';

/// Why a payment is a need, a want, invested, lent, or still unsorted.
enum SpendSource { transfer, income, lending, invest, manual, payee, category, unsorted }

class SpendDecision {
  const SpendDecision(this.kind, this.source);

  /// Null when the payment is not a need or a want.
  final SpendKind? kind;
  final SpendSource source;
}

/// Needs. Family is lending, and EMI comes from the plan list, so neither
/// seed is here.
const needSeeds = {
  'Groceries',
  'Transport',
  'Fuel',
  'Bills & Utilities',
  'Mobile & Internet',
  'Rent & Home',
  'Health',
  'Education',
  'Insurance',
};

/// Not a need or a want until someone says. Other is most of an unsorted month.
const _unsortedSeeds = {'Other', 'People', 'Cash Withdrawal', 'Loans & EMI'};

/// First match wins. Investment and lending apply in both directions, and
/// they win over a need/want left on the same payment so it is not counted
/// twice. An Investments payment counts as invested even when its bucket is
/// still Outside.
SpendDecision spendDecision(TxnView v) {
  final t = v.txn;
  if (isTransferLike(v)) return const SpendDecision(null, SpendSource.transfer);
  if (_invested(v)) return const SpendDecision(null, SpendSource.invest);
  if (_lent(v)) return const SpendDecision(null, SpendSource.lending);
  if (t.direction == TxnDirection.credit) return const SpendDecision(null, SpendSource.income);
  if (t.spendKind case final k?) return SpendDecision(k, SpendSource.manual);
  if (v.rule?.spendKind case final k?) return SpendDecision(k, SpendSource.payee);
  final seed = v.category?.seedName ?? v.category?.name;
  if (v.category == null || _unsortedSeeds.contains(seed)) return const SpendDecision(null, SpendSource.unsorted);
  if (needSeeds.contains(seed)) return const SpendDecision(SpendKind.need, SpendSource.category);
  return const SpendDecision(SpendKind.want, SpendSource.category);
}

bool _invested(TxnView v) => isInvest(v) || (v.category?.seedName ?? v.category?.name) == 'Investments';

bool _lent(TxnView v) => isLending(v) || (v.category?.seedName ?? v.category?.name) == 'Family';

/// The need/want control applies. Invested, lent, transfers and income do not.
bool canSetSpendKind(TxnView v) {
  final s = spendDecision(v).source;
  return s == SpendSource.manual || s == SpendSource.payee || s == SpendSource.category || s == SpendSource.unsorted;
}

/// Whole percent of [whole], half up. 0 when [whole] is not positive.
int percentOf(int part, int whole) {
  if (whole <= 0) return 0;
  final neg = part.isNegative;
  final q = (part.abs() * 100 + whole ~/ 2) ~/ whole;
  return neg ? -q : q;
}

String percentLabel(int part, int whole) {
  if (whole <= 0) return '';
  final n = percentOf(part, whole);
  return '${n.isNegative ? '−' : ''}${n.abs()}%';
}

/// This month's salary split. [txns] are already the month.
///
/// [emiMinor] is the plan's active instalments. A card EMI is not its own
/// transaction, so it is added to needs and is not also taken from a
/// Loans & EMI category. Unsorted and lent are reported beside the three
/// shares. They are not called unspent.
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
        case SpendSource.lending:
          if (!credit) {
            lent += amount;
            lentTxns.add(v);
          }
        case SpendSource.unsorted:
          unsorted += amount;
          unsortedTxns.add(v);
        case SpendSource.transfer || SpendSource.income:
          break;
        case SpendSource.manual || SpendSource.payee || SpendSource.category:
          switch (d.kind) {
            case SpendKind.need:
              needs += amount;
              needTxns.add(v);
            case SpendKind.want:
              wants += amount;
              wantTxns.add(v);
            case null:
              break;
          }
      }
    }
    needs += emiMinor;
  }

  final int salaryMinor;

  /// Plan EMIs included in [needs].
  final int emiMinor;

  int invested = 0;
  int needs = 0;
  int wants = 0;
  int unsorted = 0;
  int lent = 0;
  final investTxns = <TxnView>[];
  final needTxns = <TxnView>[];
  final wantTxns = <TxnView>[];
  final unsortedTxns = <TxnView>[];
  final lentTxns = <TxnView>[];
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
    SpendSource.unsorted => 'Not sorted yet',
  };
}

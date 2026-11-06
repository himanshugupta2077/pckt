import '../../data/db/database.dart';
import '../budgets/bucket_stats.dart';

class GoalPlan {
  const GoalPlan(this.index, this.stillToSave, this.due, this.perMonth);

  /// 1-3, in entry order.
  final int index;
  final int stillToSave;
  final DateTime due;

  /// Null when the goal is due this month or earlier ("due now").
  final int? perMonth;
}

/// The plan's outputs for [month] (normally this month).
///
/// Planned left over = salary − EMI − Everyday budget − Fixed budget −
/// Family and Insurance average − fund − investing − goals per month.
/// The EMI stops counting after the month it ends; a goal due this month
/// or earlier has no monthly amount.
class PlanOutcome {
  PlanOutcome({
    required MonthlyPlan plan,
    required DateTime month,
    required this.everyday,
    required this.fixed,
    required this.familyAvg,
  }) : salary = plan.salaryMinor,
       fund = plan.fundMinor,
       investing = plan.investingMinor,
       emiEnds = plan.emiEnds,
       emi = plan.emiEnds != null && monthsSince(plan.emiEnds!, month) > 1 ? 0 : plan.emiMinor,
       goals = [
         for (final (i, (amount, due)) in [
           (plan.goal1Minor, plan.goal1Due),
           (plan.goal2Minor, plan.goal2Due),
           (plan.goal3Minor, plan.goal3Due),
         ].indexed)
           if (amount != null && amount > 0 && due != null) _goal(i + 1, amount, due, month),
       ];

  final int salary;
  final int emi;
  final DateTime? emiEnds;

  /// The overall monthly budget; null when none is set.
  final int? everyday;

  /// The Fixed bucket's monthly budget.
  final int fixed;
  final MonthAverage familyAvg;
  final int fund;
  final int investing;
  final List<GoalPlan> goals;

  int get goalsPerMonth => goals.fold(0, (s, g) => s + (g.perMonth ?? 0));

  int get leftOver => salary - emi - (everyday ?? 0) - fixed - familyAvg.minor - fund - investing - goalsPerMonth;

  /// The month after the EMI ends, while it is still being paid.
  DateTime? get emiFreedFrom => emi > 0 && emiEnds != null ? DateTime(emiEnds!.year, emiEnds!.month + 1) : null;

  static GoalPlan _goal(int index, int amount, DateTime due, DateTime month) {
    final left = (due.year - month.year) * 12 + due.month - month.month;
    return GoalPlan(index, amount, due, left <= 0 ? null : (amount / left).ceil());
  }
}

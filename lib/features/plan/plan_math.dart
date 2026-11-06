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

/// Goal 1 when the emergency fund card has a goal: the goal less what its
/// holdings have now. Null when that card has no goal (goal 1 is typed).
int? emergencyStillToSave(MonthlyPlan plan, int saved) {
  final goal = plan.emergencyGoalMinor;
  return goal == null ? null : (goal - saved).clamp(0, goal);
}

/// The plan's outputs for [month] (normally this month).
///
/// Planned left over = salary − EMI − Everyday budget − Recurring budget −
/// Family and Insurance average − fund − investing. Goals are not taken
/// off: the Goals tab sets what they need against this.
/// An EMI stops counting after its last month; a goal due this month or
/// earlier has no monthly amount.
class PlanOutcome {
  PlanOutcome({
    required MonthlyPlan plan,
    required DateTime month,
    required List<Emi> emis,
    required this.everyday,
    required this.fixed,
    required this.familyAvg,
    int emergencySaved = 0,
  }) : salary = plan.salaryMinor,
       fund = plan.fundMinor,
       investing = plan.investingMinor,
       emis = [
         for (final e in emis)
           if (emiActive(e, month)) e,
       ],
       goals = [
         for (final (i, (amount, due)) in [
           (emergencyStillToSave(plan, emergencySaved) ?? plan.goal1Minor, plan.goal1Due),
           (plan.goal2Minor, plan.goal2Due),
           (plan.goal3Minor, plan.goal3Due),
         ].indexed)
           if (amount != null && amount > 0 && due != null) _goal(i + 1, amount, due, month),
       ];

  final int salary;

  /// EMIs still being paid in the month.
  final List<Emi> emis;

  int get emi => emis.fold(0, (s, e) => s + e.amountMinor);

  /// The overall monthly budget; null when none is set.
  final int? everyday;

  /// The Fixed bucket's monthly budget.
  final int fixed;
  final MonthAverage familyAvg;
  final int fund;
  final int investing;
  final List<GoalPlan> goals;

  int get goalsPerMonth => goals.fold(0, (s, g) => s + (g.perMonth ?? 0));

  int get leftOver => salary - emi - (everyday ?? 0) - fixed - familyAvg.minor - fund - investing;

  /// For each EMI with a known last month: the month after it and what
  /// that frees up.
  List<(DateTime, int)> get emiFreed => [
    for (final e in emis)
      if (e.lastMonth case final last?) (DateTime(last.year, last.month + 1), e.amountMinor),
  ];

  static GoalPlan _goal(int index, int amount, DateTime due, DateTime month) {
    final left = (due.year - month.year) * 12 + due.month - month.month;
    return GoalPlan(index, amount, due, left <= 0 ? null : (amount / left).ceil());
  }
}

/// Paid in [month]: no last month yet, or [month] is not after it.
bool emiActive(Emi e, DateTime month) => e.lastMonth == null || monthsSince(e.lastMonth!, month) <= 1;

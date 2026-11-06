import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/budgets/bucket_stats.dart';
import 'package:pckt/features/plan/plan_math.dart';

import 'budget_test.dart' show cat, txn;

MonthlyPlan plan({
  int salary = 14200000,
  int emi = 4000000,
  DateTime? emiEnds,
  int investing = 1000000,
  int fund = 1000000,
  int? goal1,
  DateTime? goal1Due,
  int? goal2,
  DateTime? goal2Due,
}) => MonthlyPlan(
  id: 1,
  startMonth: DateTime(2026, 11),
  salaryMinor: salary,
  emiMinor: emi,
  emiEnds: emiEnds,
  investingMinor: investing,
  fundMinor: fund,
  goal1Minor: goal1,
  goal1Due: goal1Due,
  goal2Minor: goal2,
  goal2Due: goal2Due,
);

Emi emi(int amount, DateTime? last, [String name = 'Laptop', SpendKind kind = SpendKind.need]) =>
    Emi(id: amount, name: name, amountMinor: amount, lastMonth: last, spendKind: kind);

void main() {
  final nov = DateTime(2026, 11);
  final laptop = emi(4000000, DateTime(2027, 2));

  test('left over subtracts EMI, budgets, family average, fund and investing, not goals', () {
    final o = PlanOutcome(
      plan: plan(goal1: 30000000, goal1Due: DateTime(2027, 11)),
      month: nov,
      emis: [laptop],
      everyday: 1500000,
      fixed: 1300000,
      familyAvg: const MonthAverage(500000, 2),
    );
    expect(o.goals.single.perMonth, 2500000); // ₹3L over 12 months
    expect(o.leftOver, 14200000 - 4000000 - 1500000 - 1300000 - 500000 - 1000000 - 1000000);
    expect(o.emiFreed, [(DateTime(2027, 3), 4000000)]);
  });

  test('a goal due this month or earlier is "due now", not divided', () {
    final o = PlanOutcome(
      plan: plan(goal1: 5000000, goal1Due: nov, goal2: 600000, goal2Due: DateTime(2026, 9)),
      month: nov,
      emis: [laptop],
      everyday: null,
      fixed: 0,
      familyAvg: const MonthAverage(0, 0),
    );
    expect([for (final g in o.goals) (g.index, g.perMonth)], [(1, null), (2, null)]);
    expect(o.goalsPerMonth, 0);
    expect(o.leftOver, 14200000 - 4000000 - 1000000 - 1000000);
  });

  test('each EMI stops counting after its last month; one without a last month keeps counting', () {
    PlanOutcome at(DateTime m) => PlanOutcome(
      plan: plan(),
      month: m,
      emis: [laptop, emi(540000, DateTime(2026, 12), 'Phone'), emi(100000, null, 'Card')],
      everyday: 0,
      fixed: 0,
      familyAvg: const MonthAverage(0, 0),
    );
    expect(at(nov).emi, 4000000 + 540000 + 100000);
    expect(at(DateTime(2027, 2)).emi, 4000000 + 100000);
    expect(at(DateTime(2027, 3)).emi, 100000);
    expect(at(DateTime(2027, 3)).emiFreed, isEmpty);
    expect(at(nov).emiFreed, [(DateTime(2027, 3), 4000000), (DateTime(2027, 1), 540000)]);
  });

  test('averages come from complete months only, Family and Insurance from Outside', () {
    final bills = cat(1, 'Bills', bucket: Bucket.fixed);
    final family = cat(2, 'Family', bucket: Bucket.outside, seed: 'Family');
    final insurance = cat(3, 'Insurance', bucket: Bucket.outside, seed: 'Insurance');
    final txns = [
      txn(600000, at: DateTime(2026, 9, 4), category: bills),
      txn(800000, at: DateTime(2026, 10, 4), category: bills),
      txn(2000000, at: DateTime(2026, 10, 8), category: family),
      txn(400000, at: DateTime(2026, 9, 8), category: insurance),
      txn(999999, at: DateTime(2026, 10, 9), category: family, bucket: Bucket.everyday), // counted in Everyday
      txn(730000, at: DateTime(2026, 8, 30), category: bills), // before the data is complete
    ];
    final two = completeMonths(nov, DateTime(2026, 9, 1));
    expect(monthlyAverage(txns, two, isFixed).minor, 700000);
    expect(monthlyAverage(txns, two, isFamilyOrInsurance).minor, 1200000);
    final one = completeMonths(nov, DateTime(2026, 9, 10));
    expect((monthlyAverage(txns, one, isFixed).minor, monthlyAverage(txns, one, isFixed).months), (800000, 1));
  });
}

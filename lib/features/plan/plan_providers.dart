import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../budgets/bucket_stats.dart';
import '../budgets/budget_providers.dart';
import 'plan_math.dart';

/// The 6 months before this one, for the plan's averages.
final planTxnsProvider = StreamProvider<List<TxnView>>((ref) {
  ref.watch(homeCurrencyProvider);
  final m = monthStart(DateTime.now());
  return ref.watch(databaseProvider).watchTxns(from: DateTime(m.year, m.month - 6), to: m);
});

final planOutcomeProvider = Provider<PlanOutcome?>((ref) {
  final plan = ref.watch(planProvider).value;
  final txns = ref.watch(planTxnsProvider).value;
  final start = ref.watch(dataStartProvider);
  final budgets = ref.watch(budgetsProvider).value;
  if (plan == null || txns == null || budgets == null || !start.hasValue) return null;
  final month = monthStart(DateTime.now());
  final months = completeMonths(month, start.value);
  final overall = budgets.firstWhereOrNull((b) => b.categoryId == null && b.active && b.currency == Currencies.home);
  return PlanOutcome(
    plan: plan,
    month: month,
    everyday: overall?.amountMinor,
    fixedAvg: monthlyAverage(txns, months, isFixed),
    familyAvg: monthlyAverage(txns, months, isFamilyOrInsurance),
  );
});

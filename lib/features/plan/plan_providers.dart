import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../budgets/bucket_stats.dart';
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart' show bucketBudgetMinor;
import 'plan_math.dart';

/// The 6 months before this one, for the plan's averages.
final planTxnsProvider = StreamProvider<List<TxnView>>((ref) {
  ref.watch(homeCurrencyProvider);
  final m = monthStart(DateTime.now());
  return ref.watch(databaseProvider).watchTxns(from: DateTime(m.year, m.month - 6), to: m);
});

final emisProvider = StreamProvider<List<Emi>>((ref) => ref.watch(databaseProvider).watchEmis());

final emergencyHoldingsProvider = StreamProvider<List<EmergencyHolding>>(
  (ref) => ref.watch(databaseProvider).watchEmergencyHoldings(),
);

/// What the emergency fund holds now, across its holdings.
final emergencySavedProvider = Provider<int?>(
  (ref) => ref.watch(emergencyHoldingsProvider).value?.fold<int>(0, (s, h) => s + h.amountMinor),
);

final planOutcomeProvider = Provider<PlanOutcome?>((ref) {
  final plan = ref.watch(planProvider).value;
  final emis = ref.watch(emisProvider).value;
  final txns = ref.watch(planTxnsProvider).value;
  final start = ref.watch(dataStartProvider);
  final budgets = ref.watch(budgetsProvider).value;
  final saved = ref.watch(emergencySavedProvider);
  if (plan == null || emis == null || txns == null || budgets == null || saved == null || !start.hasValue) {
    return null;
  }
  final month = monthStart(DateTime.now());
  final months = completeMonths(month, start.value);
  final overall = budgets.firstWhereOrNull((b) => b.categoryId == null && b.active && b.currency == Currencies.home);
  return PlanOutcome(
    plan: plan,
    month: month,
    emis: emis,
    everyday: overall?.amountMinor,
    fixed: bucketBudgetMinor,
    familyAvg: monthlyAverage(txns, months, isFamilyOrInsurance),
    emergencySaved: saved,
  );
});

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/notifications.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import 'bucket_stats.dart';
import 'budget_math.dart';
import 'in_budget.dart';

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  ref.watch(homeCurrencyProvider); // budgets apply per currency
  return ref.watch(databaseProvider).watchBudgets();
});

/// Budgets measured against the month selected on the dashboard.
final budgetProgressProvider = Provider<AsyncValue<List<BudgetProgress>>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  final txns = ref.watch(monthTxnsProvider);
  final cats = ref.watch(categoriesProvider);
  final month = ref.watch(selectedMonthProvider);
  if (budgets.hasError) return AsyncValue.error(budgets.error!, budgets.stackTrace ?? StackTrace.current);
  if (txns.hasError) return AsyncValue.error(txns.error!, txns.stackTrace ?? StackTrace.current);
  final (b, t, c) = (budgets.value, txns.value, cats.value);
  if (b == null || t == null || c == null) return const AsyncValue.loading();
  return AsyncValue.data(budgetProgress(budgets: b, txns: t, categories: c, month: month, now: DateTime.now()));
});

/// Payments that need a yes/no for the budget, one row per payee.
final toSortProvider = Provider<List<SortItem>>((ref) => toSort(ref.watch(allTxnsProvider).value ?? const []));

final planProvider = StreamProvider<MonthlyPlan?>((ref) => ref.watch(databaseProvider).watchPlan());

/// When the bank SMS start, for averages over complete months.
final dataStartProvider = StreamProvider<DateTime?>((ref) => ref.watch(databaseProvider).watchDataStart());

/// Transactions from 6 months before the selected month (or the plan's
/// start, if earlier) to its end: enough for the Buckets card.
final bucketTxnsProvider = StreamProvider<List<TxnView>>((ref) {
  ref.watch(homeCurrencyProvider);
  final m = ref.watch(selectedMonthProvider);
  final start = ref.watch(planProvider).value?.startMonth;
  var from = DateTime(m.year, m.month - 6);
  if (start != null && start.isBefore(from)) from = start;
  return ref.watch(databaseProvider).watchTxns(from: from, to: nextMonth(m));
});

final bucketSummaryProvider = Provider<BucketSummary?>((ref) {
  final txns = ref.watch(bucketTxnsProvider).value;
  final plan = ref.watch(planProvider).value;
  final start = ref.watch(dataStartProvider);
  if (txns == null || plan == null || !start.hasValue) return null;
  return BucketSummary(
    txns: txns,
    month: ref.watch(selectedMonthProvider),
    dataStart: start.value,
    planStart: plan.startMonth,
    fundPerMonth: plan.fundMinor,
  );
});

final notificationsProvider = Provider((ref) => LocalNotifications());

abstract final class BudgetPrefKeys {
  static const alertsEnabled = 'budget.alertsEnabled';

  /// String list of sent alert ids for one month, e.g. 'budget.alerts.2026-10'.
  static String sentFor(DateTime month) => 'budget.alerts.${month.year}-${month.month.toString().padLeft(2, '0')}';
  static const sentPrefix = 'budget.alerts.';
}

/// Sends a notification when the overall budget or a category budget
/// crosses 80% / 100% in the current month — once per threshold per month.
///
/// It watches the current month's transactions and the budgets, so it
/// runs after every SMS/email sync, manual add, edit and budget change.
/// State is the "alerts enabled" setting.
class BudgetAlertsController extends Notifier<bool> {
  Timer? _debounce;

  @override
  bool build() {
    final month = monthStart(DateTime.now());
    final db = ref.read(databaseProvider);
    final sub = db.watchTxns(from: month, to: nextMonth(month)).listen((_) => _schedule());
    final budgetSub = db.watchBudgets().listen((_) => _schedule());
    ref.onDispose(() {
      _debounce?.cancel();
      sub.cancel();
      budgetSub.cancel();
    });
    return ref.read(prefsProvider).getBool(BudgetPrefKeys.alertsEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(prefsProvider).setBool(BudgetPrefKeys.alertsEnabled, value);
    state = value;
    if (value) {
      await ref.read(notificationsProvider).requestPermission();
      _schedule();
    }
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(check()));
  }

  /// Checks thresholds now. Safe to call any time.
  Future<void> check({DateTime? now}) async {
    if (!state) return;
    try {
      final at = now ?? DateTime.now();
      final month = monthStart(at);
      final db = ref.read(databaseProvider);
      final budgets = await db.allBudgets();
      if (budgets.every((b) => !b.active)) return;
      final progress = budgetProgress(
        budgets: budgets,
        txns: await db.watchTxns(from: month, to: nextMonth(month)).first,
        categories: await db.allCategories(),
        month: month,
        now: at,
      );
      final prefs = ref.read(prefsProvider);
      final key = BudgetPrefKeys.sentFor(month);
      final sent = (prefs.getStringList(key) ?? const []).toSet();
      final pending = pendingBudgetAlerts(progress, sent);
      if (pending.isEmpty) return;
      // Record first so a crash mid-send can't spam on the next check.
      await prefs.setStringList(key, {...sent, ...alertIdsToMark(pending)}.toList());
      for (final k in prefs.getKeys().where((k) => k.startsWith(BudgetPrefKeys.sentPrefix) && k != key).toList()) {
        await prefs.remove(k);
      }
      final notifications = ref.read(notificationsProvider);
      for (final a in pending) {
        await notifications.showBudgetAlert(id: a.id.hashCode & 0x7fffffff, title: a.title, body: alertBody(a));
      }
    } catch (e, st) {
      debugPrint('Budget alert check failed: $e\n$st');
    }
  }
}

String alertBody(BudgetAlert a) {
  final p = a.progress;
  if (p.remainingMinor < 0) {
    return '${money(p.spentMinor)} spent of ${money(p.limitMinor)} — ${money(-p.remainingMinor)} over this month.';
  }
  final pace = p.daysLeft > 0 ? ' · ${money(p.perDayLeftMinor)}/day left for ${p.daysLeft} days' : '';
  return '${money(p.spentMinor)} of ${money(p.limitMinor)} spent$pace.';
}

final budgetAlertsProvider = NotifierProvider<BudgetAlertsController, bool>(BudgetAlertsController.new);

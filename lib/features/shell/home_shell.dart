import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/icons.dart';

import '../../ingestion/email/email_sync.dart';
import '../../ingestion/ingestion_service.dart';
import '../../llm/llm_providers.dart';
import '../../providers.dart';
import '../activity/add_transaction_sheet.dart';
import '../activity/transaction_sheet.dart';
import '../alerts/sort_alerts.dart';
import 'share_outcome.dart';
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart' show bucketBudgetMinor;
import '../../data/db/database.dart' show Bucket;
import '../settings/server_backup.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Pull new SMS (and email) whenever the app comes to the foreground.
    _lifecycle = AppLifecycleListener(
      onResume: () async {
        await _alertsChanged();
        await _sync();
        await _openFromAlert();
      },
    );
    alertChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'changed':
          await _alertsChanged();
        case 'open':
          await _openFromAlert();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _alertsChanged();
      await _sync();
      await _openFromAlert();
      await _repairOnce();
      await _mergeCardBillsOnce();
      await _transfersOutOfLendingOnce();
      await ref.read(smsAlertsProvider.notifier).ensurePermission();
    });
  }

  Future<void> _sync() => Future.wait([
    ref.read(smsSyncProvider.notifier).sync().then((report) {
      _announce(report);
      // After the sync so the backup has today's messages; quiet if offline.
      return ref.read(serverBackupProvider.notifier).backUpIfDue();
    }),
    ref.read(emailSyncProvider.notifier).syncIfDue().then(_announce),
  ]);

  /// Once, after the parser fixes of Nov 2026: a fresh server backup first
  /// (no backup, no repair; it tries again next start), then the clean-up
  /// since the data start, the ₹10,000 Everyday budget, and family
  /// payments as loans paid back rather than spending.
  Future<void> _repairOnce() async {
    final prefs = ref.read(prefsProvider);
    if (prefs.getBool(PrefKeys.repairedOct2026) ?? false) return;
    if (!await ref.read(serverBackupProvider.notifier).backUpNow()) return;
    final db = ref.read(databaseProvider);
    final log = await ref.read(ingestionProvider).repairSince(db.shownFrom ?? DateTime(2026, 10));
    await db.setBudget(amountMinor: bucketBudgetMinor);
    for (final c in await db.allCategories()) {
      if ((c.seedName ?? c.name) == 'Family') await db.updateCategory(c.id, bucket: Bucket.lending);
    }
    await prefs.setBool(PrefKeys.repairedOct2026, true);
    debugPrint('Repair:\n${log.join('\n')}');
  }

  /// Once, after card bills became one transfer: a fresh server backup
  /// first, then each bill's messages since the data start joined into one,
  /// (Transfers counts as a transfer by itself now, so its bucket is left
  /// alone: see [_transfersOutOfLendingOnce].)
  Future<void> _mergeCardBillsOnce() async {
    final prefs = ref.read(prefsProvider);
    if (prefs.getBool(PrefKeys.mergedCardBills) ?? false) return;
    if (!await ref.read(serverBackupProvider.notifier).backUpNow()) return;
    final db = ref.read(databaseProvider);
    final log = await ref.read(ingestionProvider).mergeCardBills(db.shownFrom ?? DateTime(2026, 10));
    await prefs.setBool(PrefKeys.mergedCardBills, true);
    debugPrint('Card bills:\n${log.join('\n')}');
  }

  /// Notification buttons tapped meanwhile, and payments the background
  /// alert check stored through its own connection (which this one's live
  /// lists don't see on their own).
  Future<void> _alertsChanged() async {
    final db = ref.read(databaseProvider);
    try {
      await applyAlertAnswers(db, await takeAlertAnswers());
    } catch (e) {
      debugPrint('Alert answers failed: $e');
    }
    db.markTablesUpdated(db.allTables);
  }

  /// The payment whose question notification was tapped.
  Future<void> _openFromAlert() async {
    final int? id;
    try {
      id = await alertChannel.invokeMethod<int>('takeOpen');
    } on MissingPluginException {
      return;
    }
    if (id != null && mounted) await showTransactionSheet(context, id);
  }

  /// Once: an earlier build put the Transfers category in Lending. A
  /// transfer is its own type now, so the category goes back to its default.
  Future<void> _transfersOutOfLendingOnce() async {
    final prefs = ref.read(prefsProvider);
    if (prefs.getBool(PrefKeys.transfersOutOfLending) ?? false) return;
    final db = ref.read(databaseProvider);
    for (final c in await db.allCategories()) {
      if ((c.seedName ?? c.name) == 'Transfers') await db.updateCategory(c.id, bucket: Bucket.outside);
    }
    await prefs.setBool(PrefKeys.transfersOutOfLending, true);
  }

  void _announce(IngestReport? report) {
    if (!mounted || report == null || report.added + report.merged == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${report.added} new transaction${report.added == 1 ? '' : 's'}'
          '${report.merged > 0 ? ' · ${report.merged} duplicate${report.merged == 1 ? '' : 's'} merged' : ''}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.shell.currentIndex;
    final review = ref.watch(reviewCountProvider).value ?? 0;
    // Keeps the AI jobs alive so they run after each sync.
    ref.listen(aiJobsProvider, (_, _) {});
    ref.listen(shareIntakeProvider, (_, outcome) {
      if (outcome != null) showShareOutcome(context, outcome);
    });
    // Budget alerts watch the DB, so they fire after syncs, adds and edits.
    ref.listen(budgetAlertsProvider, (_, _) {});
    return Scaffold(
      body: widget.shell,
      floatingActionButton: index <= 1
          ? FloatingActionButton(
              onPressed: () => showAddTransactionSheet(context),
              tooltip: 'Add transaction',
              child: const Icon(PhosphorIconsBold.plus),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == index),
        destinations: [
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.house),
            selectedIcon: Icon(PhosphorIconsFill.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: review > 0,
              label: Text('$review'),
              child: const Icon(PhosphorIconsRegular.listBullets),
            ),
            selectedIcon: Badge(
              isLabelVisible: review > 0,
              label: Text('$review'),
              child: const Icon(PhosphorIconsFill.listBullets),
            ),
            label: 'Activity',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chartPie),
            selectedIcon: Icon(PhosphorIconsFill.chartPie),
            label: 'Insights',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.target),
            selectedIcon: Icon(PhosphorIconsFill.target),
            label: 'Goals',
          ),
          const NavigationDestination(
            icon: Icon(PhosphorIconsRegular.gearSix),
            selectedIcon: Icon(PhosphorIconsFill.gearSix),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

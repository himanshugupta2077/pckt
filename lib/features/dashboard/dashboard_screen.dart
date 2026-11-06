import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import '../budgets/bucket_stats.dart';
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart' show bucketBudgetMinor;
import '../plan/balances_card.dart';
import '../stats.dart';
import 'buckets_card.dart';
import 'hero_card.dart';
import 'where_it_went.dart';
import '../../data/db/database.dart' show Emi;
import '../plan/plan_math.dart' show emiActive;
import '../plan/plan_providers.dart' show emisProvider;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txns = ref.watch(monthTxnsProvider);
    final sync = ref.watch(smsSyncProvider);
    final review = ref.watch(reviewCountProvider).value ?? 0;
    final sortCount = ref.watch(toSortProvider).length;
    final buckets = ref.watch(bucketSummaryProvider);
    final everydayBudget = ref.watch(everydayBudgetProvider);
    final fundBudget = ref.watch(planProvider).value?.fundMinor ?? bucketBudgetMinor;
    final emiMinor = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e.amountMinor,
    ].fold(0, (a, b) => a + b);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(smsSyncProvider.notifier).sync(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(month: month, syncing: sync.running),
              ),
              ...txns.when(
                loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
                error: (e, _) => [SliverFillRemaining(child: Center(child: Text('$e')))],
                data: (list) {
                  final stats = MonthStats(list, month);
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList.list(
                        children: [
                          MonthCard(
                            month: month,
                            everydayLeft: everydayBudget - (buckets?.everyday ?? 0),
                            fixedLeft: bucketBudgetMinor - (buckets?.fixed ?? 0),
                            fundLeft: fundBudget - (buckets?.fund ?? 0),
                            inMinor: stats.income,
                            outMinor: buckets == null ? 0 : monthOutMinor(buckets, emiMinor),
                          ),
                          const BucketsCard(),
                          if (sortCount > 0) ...[const SizedBox(height: 12), _SortBanner(count: sortCount)],
                          if (review > 0) ...[const SizedBox(height: 12), _ReviewBanner(count: review)],
                          if (stats.unconverted > 0) ...[
                            const SizedBox(height: 12),
                            _ForeignBanner(count: stats.unconverted),
                          ],
                          if (!sync.enabled && list.isEmpty) ...[const SizedBox(height: 12), const _ConnectSmsCard()],
                          const BalancesCard(),
                          const SizedBox(height: 20),
                          WhereItWent(txns: list),
                          const SizedBox(height: 20),
                          SectionHeader(
                            'Recent',
                            action: list.isEmpty ? null : 'See all',
                            onAction: () => context.go('/activity'),
                          ),
                        ],
                      ),
                    ),
                    if (list.isEmpty)
                      const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: PhosphorIconsFill.receipt,
                          title: 'Nothing here yet',
                          message:
                              'Transactions from your bank SMS show up automatically. You can also add one with +.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: SliverList.builder(
                          itemCount: list.length.clamp(0, 8),
                          itemBuilder: (_, i) => TransactionTile(
                            view: list[i],
                            showDate: true,
                            onTap: () => showTransactionSheet(context, list[i].txn.id),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.month, required this.syncing});

  final DateTime month;
  final bool syncing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(selectedMonthProvider.notifier);
    final isCurrent = month == monthStart(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Row(children: [Text(monthLabel(month), style: context.text.headlineSmall)]),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => ctrl.shift(-1),
            icon: const Icon(PhosphorIconsBold.caretLeft, size: 20),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: isCurrent ? null : () => ctrl.shift(1),
            icon: const Icon(PhosphorIconsBold.caretRight, size: 20),
          ),
          _SyncButton(syncing: syncing),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
  }
}

class _SyncButton extends ConsumerStatefulWidget {
  const _SyncButton({required this.syncing});
  final bool syncing;

  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(_SyncButton old) {
    super.didUpdateWidget(old);
    widget.syncing ? _spin.repeat() : _spin.reset();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Sync SMS',
    onPressed: widget.syncing ? null : () => ref.read(smsSyncProvider.notifier).sync(),
    icon: RotationTransition(turns: _spin, child: const Icon(PhosphorIconsBold.arrowsClockwise, size: 20)),
  );
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    color: Palette.amber.withValues(alpha: context.isDark ? 0.12 : 0.16),
    onTap: () => context.go('/activity?filter=review'),
    child: Row(
      children: [
        const Icon(PhosphorIconsFill.warningCircle, color: Palette.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count transaction${count == 1 ? '' : 's'} need${count == 1 ? 's' : ''} a quick look',
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(PhosphorIconsBold.caretRight, size: 18),
      ],
    ),
  );
}

/// Payees and payments the app can't place in or out of the budget.
class _SortBanner extends StatelessWidget {
  const _SortBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onTap: () => context.push('/to-sort'),
    child: Row(
      children: [
        Icon(PhosphorIconsFill.target, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count to sort for your budget',
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(PhosphorIconsBold.caretRight, size: 18),
      ],
    ),
  );
}

/// Foreign-currency payments this month that aren't in the totals yet.
class _ForeignBanner extends StatelessWidget {
  const _ForeignBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onTap: () => context.go('/activity?filter=foreign'),
    child: Row(
      children: [
        Icon(PhosphorIconsFill.globeHemisphereWest, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count payment${count == 1 ? '' : 's'} in other currencies not in these totals',
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(PhosphorIconsBold.caretRight, size: 18),
      ],
    ),
  );
}

class _ConnectSmsCard extends ConsumerWidget {
  const _ConnectSmsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    onTap: () => context.go('/settings'),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Palette.mint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(PhosphorIconsFill.chatText, color: Palette.mint),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect SMS', style: context.text.titleMedium),
              Text(
                'Track card, bank & UPI spends automatically',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const Icon(PhosphorIconsBold.caretRight, size: 18),
      ],
    ),
  );
}

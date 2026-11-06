import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_math.dart' show budgetWarnRatio;
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart';
import '../activity/transaction_sheet.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../plan/plan_math.dart' show emiActive;
import '../plan/plan_providers.dart' show emisProvider;

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Fixed and Fund against their monthly budget (₹10,000 each; Fund's is
/// the plan's), and Outside, for the month. Everyday is the budget card
/// above it.
class BucketsCard extends ConsumerWidget {
  const BucketsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bucketSummaryProvider);
    if (s == null) return const SizedBox.shrink();
    final fundBudget = ref.watch(planProvider).value?.fundMinor ?? bucketBudgetMinor;
    final month = ref.watch(selectedMonthProvider);
    final emis = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e,
    ];
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buckets', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Row('Fixed', s.fixed, budget: bucketBudgetMinor, bucket: Bucket.fixed),
          _Row('Fund', s.fund, budget: fundBudget, bucket: Bucket.fund),
          if (emis.isNotEmpty) _EmiRow(emis: emis),
          _Row('Outside', s.outsideTotal, bucket: Bucket.outside),
          for (final c in s.outside)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(c.category?.name ?? 'Uncategorised', style: muted, overflow: TextOverflow.ellipsis),
                  ),
                  Text(money(c.amount), style: muted?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
        ],
      ),
    );
    return Padding(padding: const EdgeInsets.only(top: 12), child: card);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.minor, {this.budget, required this.bucket});

  final String label;
  final int minor;

  /// Monthly budget: shown as "of ₹X" with a bar.
  final int? budget;

  /// Tapping the row lists this bucket's payments for the month.
  final Bucket bucket;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _showBucket(context, bucket, label),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.labelLarge)),
              Text.rich(
                TextSpan(
                  text: money(minor),
                  children: [
                    if (budget != null)
                      TextSpan(
                        text: ' of ${money(budget!)}',
                        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                  ],
                ),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (budget != null) ...[const SizedBox(height: 6), _Bar(ratio: minor / budget!)],
        ],
      ),
    ),
  );
}

/// EMIs paid this month, from the plan's list: card EMIs ride on the card
/// bill, so no message reports them. Opens the plan to edit the list.
class _EmiRow extends StatelessWidget {
  const _EmiRow({required this.emis});
  final List<Emi> emis;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return InkWell(
      onTap: () => context.push('/plan'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('EMI', style: context.text.labelLarge)),
                Text(
                  money(emis.fold(0, (s, e) => s + e.amountMinor)),
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            for (final e in emis)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.lastMonth == null
                            ? e.name
                            : '${e.name} · until ${DateFormat('MMM yyyy').format(e.lastMonth!)}',
                        style: muted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      money(e.amountMinor),
                      style: muted?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The month's payments in [bucket], newest first.
Future<void> _showBucket(BuildContext context, Bucket bucket, String label) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.95,
    builder: (context, scroll) => Consumer(
      builder: (context, ref, _) {
        final txns = [
          for (final v in ref.watch(monthTxnsProvider).value ?? const <TxnView>[])
            if (budgetDecision(v).bucket == bucket) v,
        ];
        final total = txns.fold(0, (s, v) => s + (v.txn.homeMinor ?? 0));
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                '$label  ·  ${money(total)}',
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (txns.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Nothing this month.', style: context.text.bodyMedium),
              ),
            for (final v in txns)
              TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
          ],
        );
      },
    ),
  ),
);

/// Spent against budget: green, amber from 80%, coral past it.
class _Bar extends StatelessWidget {
  const _Bar({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final color = ratio > 1
        ? Palette.coral
        : ratio >= budgetWarnRatio
        ? Palette.amber
        : Palette.mint;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: ratio.clamp(0, 1).toDouble(),
        minHeight: 6,
        color: color,
        backgroundColor: color.withValues(alpha: context.isDark ? 0.16 : 0.14),
      ),
    );
  }
}

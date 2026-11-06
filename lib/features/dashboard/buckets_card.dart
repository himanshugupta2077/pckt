import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_math.dart' show budgetWarnRatio;
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart';

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
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buckets', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Row('Fixed', s.fixed, budget: bucketBudgetMinor),
          _Row('Fund', s.fund, budget: fundBudget),
          _Row('Outside', s.outsideTotal),
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
  const _Row(this.label, this.minor, {this.budget});

  final String label;
  final int minor;

  /// Monthly budget: shown as "of ₹X" with a bar.
  final int? budget;

  @override
  Widget build(BuildContext context) => Padding(
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
  );
}

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

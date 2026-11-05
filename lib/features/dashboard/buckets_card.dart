import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_providers.dart';

/// Fixed, Fund and Outside for the month, under the hero (which is
/// Everyday). The fund is shown as spent against the plan, never as money
/// left to spend.
class BucketsCard extends ConsumerWidget {
  const BucketsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bucketSummaryProvider);
    if (s == null || (s.fixed == 0 && s.fund == 0 && s.fundSince == 0 && s.outside.isEmpty)) {
      return const SizedBox.shrink();
    }
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buckets', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Row(
            'Fixed',
            s.fixed,
            detail: s.fixedAvg.months == 0 ? null : '${s.fixedAvg.label}: ${money(s.fixedAvg.minor)}',
          ),
          _Row(
            'Fund',
            s.fund,
            detail: s.fundPlanned == 0
                ? null
                : '${money(s.fundSince)} spent of ${money(s.fundPlanned)} planned since ${monthShort(s.fundStart)}',
          ),
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
  const _Row(this.label, this.minor, {this.detail});

  final String label;
  final int minor;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.labelLarge)),
            Text(
              money(minor),
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (detail != null)
          Text(detail!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    ),
  );
}

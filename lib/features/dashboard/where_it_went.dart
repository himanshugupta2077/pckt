import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../ui/widgets.dart';
import '../budgets/in_budget.dart';
import '../stats.dart' show CategoryTotal;

/// Everyday spending by category, largest first, as plain rows with a thin
/// bar for each one's share. (Recurring and Fund are short lists already
/// on the Budgets card.)
class WhereItWent extends StatelessWidget {
  const WhereItWent({super.key, required this.txns});

  /// The month's payments.
  final List<TxnView> txns;

  static const _shown = 6;

  @override
  Widget build(BuildContext context) {
    final byCat = <int?, CategoryTotal>{};
    for (final v in txns) {
      final amount = v.txn.homeMinor;
      final b = budgetDecision(v).bucket;
      if (amount == null || b != Bucket.everyday) continue;
      final prev = byCat[v.txn.categoryId];
      byCat[v.txn.categoryId] = CategoryTotal(v.category, (prev?.amount ?? 0) + amount);
    }
    final rows = byCat.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    if (rows.isEmpty) return const SizedBox.shrink();
    final top = rows.first.amount;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Everyday by category',
          action: rows.length > _shown ? 'See all' : null,
          onAction: () => context.go('/activity?filter=spent'),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              for (final c in rows.take(_shown))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CategoryBadge(category: c.category, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.category?.name ?? 'Uncategorised',
                                    style: context.text.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  money(c.amount),
                                  style: context.text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: c.amount / top,
                                minHeight: 4,
                                color: c.category == null ? context.colors.outline : Color(c.category!.color),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (rows.length > _shown)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${rows.length - _shown} more', style: muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

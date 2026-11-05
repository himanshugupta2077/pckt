import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import 'budget_providers.dart';
import 'in_budget.dart';

/// Payees (and payments without one) the app can't place in or out of the
/// budget on its own. A yes/no for a payee becomes a rule for all of its
/// payments, so each one is asked once.
class ToSortScreen extends ConsumerWidget {
  const ToSortScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(toSortProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('To sort')),
      body: items.isEmpty
          ? const EmptyState(
              icon: PhosphorIconsFill.checkCircle,
              title: 'All sorted',
              message: 'New payees that are large or repeat will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Do these count toward your budget? Your answer applies to every payment to that payee.',
                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SortTile(item: item),
                  ),
              ],
            ),
    );
  }
}

class _SortTile extends ConsumerWidget {
  const _SortTile({required this.item});
  final SortItem item;

  Future<void> _answer(WidgetRef ref, bool counts) {
    final db = ref.read(databaseProvider);
    final merchant = item.merchant;
    return merchant == null ? db.setInBudget(item.latest.txn.id, counts) : db.setPayeeBudget(merchant, counts);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = item.latest;
    final n = item.txns.length;
    final detail = [
      v.category?.name ?? 'Uncategorised',
      n == 1 ? dayLabel(v.txn.occurredAt) : '$n payments',
    ].join('  ·  ');
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: n == 1 ? () => showTransactionSheet(context, v.txn.id) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(category: v.category, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txnTitle(v.txn),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    Text(detail, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                money(item.totalMinor),
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => _answer(ref, false), child: const Text('Not budget')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(onPressed: () => _answer(ref, true), child: const Text('Budget')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

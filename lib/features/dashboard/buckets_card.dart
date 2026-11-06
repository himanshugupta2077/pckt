import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../ui/widgets.dart';
import '../budgets/in_budget.dart';
import '../activity/transaction_sheet.dart';
import '../../data/db/database.dart';
import '../../providers.dart';


/// Lending and Outside, each closed until tapped. The net of lending is
/// not shown: money lent and paid back mostly cancels, and a statement does
/// not show that net.
Future<void> showOthersSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.95,
    builder: (context, scroll) => Consumer(
      builder: (context, ref, _) {
        final txns = ref.watch(monthTxnsProvider).value ?? const <TxnView>[];
        final lending = [
          for (final v in txns)
            if (!isTransferLike(v) && bucketOf(v) == Bucket.lending) v,
        ];
        final outside = [
          for (final v in txns)
            if (budgetDecision(v).bucket == Bucket.outside) v,
        ];
        List<Widget> tiles(List<TxnView> rows) => [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text('Nothing this month.', style: context.text.bodyMedium),
            ),
          for (final v in rows)
            TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
        ];
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text('Others', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            _FoldSection(label: 'Lending', children: tiles(lending)),
            _FoldSection(label: 'Outside', children: tiles(outside)),
          ],
        );
      },
    ),
  ),
);

/// Lending or Outside, closed until tapped.
class _FoldSection extends StatefulWidget {
  const _FoldSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  State<_FoldSection> createState() => _FoldSectionState();
}

class _FoldSectionState extends State<_FoldSection> {
  var _open = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.label, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Transform.rotate(
                angle: _open ? 1.5708 : 0,
                child: Icon(PhosphorIconsBold.caretRight, size: 16, color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      if (_open) ...widget.children,
    ],
  );
}

/// The month's payments in [bucket], newest first.
Future<void> showBucketSheet(BuildContext context, Bucket bucket, String label) => showModalBottomSheet(
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
            if (bucket == Bucket.invest || bucket == Bucket.lending
                ? !isTransferLike(v) && bucketOf(v) == bucket
                : budgetDecision(v).bucket == bucket)
              v,
        ];
        final total = txns.fold(
          0,
          (s, v) => s + (v.txn.direction == TxnDirection.credit ? -1 : 1) * (v.txn.homeMinor ?? 0),
        );
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

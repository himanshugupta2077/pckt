import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart';
import '../activity/transaction_sheet.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../plan/plan_math.dart' show emiActive;
import '../plan/plan_providers.dart' show emisProvider;

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// What is not in the three budgets: EMIs, money invested, and Others
/// (lending and outside). The budgets themselves are on the month card.
class BucketsCard extends ConsumerWidget {
  const BucketsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bucketSummaryProvider);
    if (s == null) return const SizedBox.shrink();
    final month = ref.watch(selectedMonthProvider);
    final emis = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e,
    ];
    final showOthers = s.lentIn + s.lentOut > 0 || s.outsideTotal > 0;
    if (emis.isEmpty && s.invested == 0 && !showOthers) return const SizedBox.shrink();
    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Not budgeted', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (emis.isNotEmpty) _EmiRow(emis: emis),
          if (s.invested != 0) _Row('Invested', s.invested, bucket: Bucket.invest),
          if (showOthers) const _OthersRow(),
        ],
      ),
    );
    return Padding(padding: const EdgeInsets.only(top: 12), child: card);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.minor, {required this.bucket});

  final String label;
  final int minor;

  /// Tapping the row lists this bucket's payments for the month.
  final Bucket bucket;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showBucketSheet(context, bucket, label),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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

/// Lending and Outside together. The net of lending is not shown: money
/// lent and paid back mostly cancels, and a statement does not show that net.
class _OthersRow extends StatelessWidget {
  const _OthersRow();

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _showOthers(context),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('Others', style: context.text.labelLarge)),
          Icon(PhosphorIconsBold.caretRight, size: 16, color: context.colors.onSurfaceVariant),
        ],
      ),
    ),
  );
}

Future<void> _showOthers(BuildContext context) => showModalBottomSheet(
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



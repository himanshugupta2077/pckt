import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import '../budgets/bucket_picker.dart';
import '../budgets/in_budget.dart';

/// The month's money in, each with a tick for whether it is income.
/// Unticking asks what it was instead: lending (with a note) or a transfer
/// between own accounts. Transfers and card bills aren't listed: they are
/// never income.
Future<void> showIncomeSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (_, scroll) => _IncomeList(scroll: scroll),
  ),
);

bool _counts(TxnView v) => !isLending(v);

class _IncomeList extends ConsumerWidget {
  const _IncomeList({required this.scroll});
  final ScrollController scroll;

  Future<void> _set(BuildContext context, WidgetRef ref, TxnView v, bool counts) async {
    final db = ref.read(databaseProvider);
    final t = v.txn;
    if (counts) {
      // Lending by its payee or category: this one payment says otherwise.
      final byRule = (v.rule?.bucket ?? v.category?.bucket) == Bucket.lending;
      await db.setTxnBucket(t.id, byRule ? Bucket.everyday : null);
      return;
    }
    final kind = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Not income, so it is'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'lending'),
            child: const Text('Lending: lent or borrowed, and paid back'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'transfer'),
            child: const Text('Transfer: my own money, from another account or cash'),
          ),
        ],
      ),
    );
    if (kind == 'transfer') return db.setTransfer(t.id, true);
    if (kind != 'lending') return;
    await db.setTxnBucket(t.id, Bucket.lending);
    if (!context.mounted) return;
    final note = await askLendingNote(context, t.note);
    if (note != null) await db.setNote(t.id, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = [
      for (final v in ref.watch(monthTxnsProvider).value ?? const <TxnView>[])
        if (v.txn.direction == TxnDirection.credit && !isTransferLike(v)) v,
    ];
    final counted = credits.where(_counts).fold(0, (s, v) => s + (v.txn.homeMinor ?? 0));
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Text(
            'Income  ·  ${money(counted)}',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            'Untick money that isn\'t income: money lent to you or paid back, your own money moved in.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        for (final v in credits)
          Row(
            children: [
              Checkbox(value: _counts(v), onChanged: (on) => _set(context, ref, v, on ?? false)),
              Expanded(
                child: TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
              ),
            ],
          ),
      ],
    );
  }
}

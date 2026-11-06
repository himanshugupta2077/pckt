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
/// Unticking marks the payment Ignore (with a note why); a transfer between
/// own accounts shows unticked.
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

bool _counts(TxnView v) => !v.txn.isTransfer && !isIgnored(v);

class _IncomeList extends ConsumerWidget {
  const _IncomeList({required this.scroll});
  final ScrollController scroll;

  Future<void> _set(BuildContext context, WidgetRef ref, TxnView v, bool counts) async {
    final db = ref.read(databaseProvider);
    final t = v.txn;
    if (counts) {
      if (t.isTransfer) await db.setTransfer(t.id, false);
      // Ignored by its payee or category: this one payment says otherwise.
      final byRule = (v.rule?.bucket ?? v.category?.bucket) == Bucket.ignore;
      await db.setTxnBucket(t.id, byRule ? Bucket.everyday : null);
      return;
    }
    await db.setTxnBucket(t.id, Bucket.ignore);
    if (!context.mounted) return;
    final note = await askWhyIgnored(context, t.note);
    if (note != null) await db.setNote(t.id, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = [
      for (final v in ref.watch(monthTxnsProvider).value ?? const <TxnView>[])
        if (v.txn.direction == TxnDirection.credit) v,
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
            'Untick money that isn\'t income: cash you deposited, a loan from family, your own accounts.',
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

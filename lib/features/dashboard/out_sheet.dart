import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import '../budgets/bucket_stats.dart';
import '../budgets/budget_providers.dart';
import '../budgets/in_budget.dart';
import '../plan/plan_math.dart';
import '../plan/plan_providers.dart';

/// What added up to Out this month. Each payment can be opened, or taken
/// out of the total: a transfer between your own accounts, or money that
/// came back and is really income.
Future<void> showOutSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (_, scroll) => _OutList(scroll: scroll),
  ),
);

String _signed(int minor) => minor < 0 ? '−${money(-minor)}' : money(minor);

class _OutList extends ConsumerWidget {
  const _OutList({required this.scroll});
  final ScrollController scroll;

  Future<void> _takeOut(BuildContext context, WidgetRef ref, TxnView v) async {
    final db = ref.read(databaseProvider);
    final credit = v.txn.direction == TxnDirection.credit;
    if (!credit) {
      final transfer = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Not money out, so it is'),
          content: const Text('A transfer: your own money, moved between accounts or paid as a card bill.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('It\'s a transfer')),
          ],
        ),
      );
      if (transfer == true) await db.setTransfer(v.txn.id, true);
      return;
    }
    final kind = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('This money came back'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'income'), child: const Text('Income: count it in In')),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'transfer'),
            child: const Text('Transfer: my own money, from another account'),
          ),
        ],
      ),
    );
    if (kind == 'transfer') {
      await db.setTransfer(v.txn.id, true);
      return;
    }
    if (kind != 'income') return;
    // A payee or category still marked Invest or Lending would keep this
    // credit out of In. Everyday on this one payment overrides that.
    final inherited = v.rule?.bucket ?? v.category?.bucket;
    final sticks = inherited == Bucket.lending || inherited == Bucket.invest;
    await db.setTxnBucket(v.txn.id, sticks ? Bucket.everyday : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txns = ref.watch(monthTxnsProvider).value ?? const <TxnView>[];
    final lines = outLines(txns);
    final byBucket = {for (final line in lines) line.bucket: line};
    final emis = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e,
    ];
    final emiMinor = emis.fold(0, (s, e) => s + e.amountMinor);
    final summary = ref.watch(bucketSummaryProvider);
    final total = summary == null
        ? lines.fold(0, (s, line) => s + line.minor) + emiMinor
        : monthOutMinor(summary, emiMinor);
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);

    void openPlan() {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.push('/plan');
    }

    Widget section(FlowLine line) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(line.label, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                _signed(line.minor),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (line.bucket == Bucket.lending && line.txns.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Text('Money paid back is subtracted.', style: muted),
          ),
        for (final v in line.txns)
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) => _takeOut(context, ref, v)),
              Expanded(
                child: TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
              ),
            ],
          ),
      ],
    );

    final order = [Bucket.everyday, Bucket.fixed, Bucket.fund, Bucket.invest, Bucket.lending, Bucket.outside];
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Text(
            'Out  ·  ${_signed(total)}',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Text(
            'Left this month is In minus this. Everyday, Recurring and Fund are the budgets, ${money(bucketBudgetMinor)} each. EMI, invested and lending count here too.',
            style: muted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Text(
            'Untick a payment that is not money leaving your accounts. Open one to change its bucket.',
            style: muted,
          ),
        ),
        for (final b in order) ...[
          if (b == Bucket.invest && emis.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('EMI', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        money(emiMinor),
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Text('From the EMI list. The card bill is not counted again.', style: muted),
                ),
                for (final e in emis)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    title: Text(
                      e.lastMonth == null ? e.name : '${e.name} · until ${DateFormat('MMM yyyy').format(e.lastMonth!)}',
                    ),
                    trailing: Text(money(e.amountMinor), style: context.text.titleSmall),
                    onTap: openPlan,
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: openPlan, child: const Text('Edit the EMI list')),
                ),
              ],
            ),
          if (byBucket[b] case final line?) section(line),
        ],
      ],
    );
  }
}

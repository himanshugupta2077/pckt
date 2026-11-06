import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import '../budgets/budget_providers.dart' show planProvider;
import '../plan/plan_math.dart' show emiActive;
import '../plan/plan_providers.dart' show emisProvider;
import 'salary_split.dart';

/// Above the budget card: this month's invested, needs and wants as a
/// share of salary. The three shares are not the whole salary. Money not
/// sorted, and money lent, are separate lines.
class SalaryCard extends ConsumerWidget {
  const SalaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(monthTxnsProvider).value;
    if (txns == null) return const SizedBox.shrink();
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final salary = ref.watch(planProvider).value?.salaryMinor ?? 0;
    final emi = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e.amountMinor,
    ].fold(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SalarySplitView(
        split: SalarySplit(txns: txns, salaryMinor: salary, emiMinor: emi),
        soFar: month.year == now.year && month.month == now.month,
      ),
    );
  }
}

class SalarySplitView extends StatelessWidget {
  const SalarySplitView({super.key, required this.split, this.soFar = false});

  final SalarySplit split;

  /// This month is still open: spends are so far, the EMI is the whole instalment.
  final bool soFar;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final salary = split.salaryMinor;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/plan'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('Salary', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (soFar) ...[const SizedBox(width: 8), Text('so far', style: muted)],
                  const Spacer(),
                  Text(salary > 0 ? money(salary) : 'Set salary in Plan', style: muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _Row('Invested', split.invested, salary, onTap: () => showSalarySheet(context, SalaryPile.invested)),
          _Row(
            'Needs',
            split.needs,
            salary,
            caption: split.emiMinor > 0 ? '${money(split.emiMinor)} EMI' : null,
            onTap: () => showSalarySheet(context, SalaryPile.needs),
          ),
          _Row('Wants', split.wants, salary, onTap: () => showSalarySheet(context, SalaryPile.wants)),
          if (split.unsorted != 0)
            _SideLine('Not sorted', split.unsorted, onTap: () => showSalarySheet(context, SalaryPile.unsorted)),
          if (split.lent != 0) _SideLine('Lent', split.lent, onTap: () => showSalarySheet(context, SalaryPile.lent)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.minor, this.salary, {required this.onTap, this.caption});

  final String label;
  final int minor;
  final int salary;
  final VoidCallback onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final pct = percentLabel(minor, salary);
    final amount = context.text.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.labelLarge),
                  if (caption != null)
                    Text(caption!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ),
            ),
            Text(money(minor), style: amount),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              child: Text(pct.isEmpty ? '—' : pct, textAlign: TextAlign.right, style: amount),
            ),
          ],
        ),
      ),
    );
  }
}

/// Money that is not one of the three shares. No percent.
class _SideLine extends StatelessWidget {
  const _SideLine(this.label, this.minor, {required this.onTap});

  final String label;
  final int minor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(money(minor), style: style),
          ],
        ),
      ),
    );
  }
}

enum SalaryPile { invested, needs, wants, unsorted, lent }

Future<void> showSalarySheet(BuildContext context, SalaryPile pile) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.95,
    builder: (context, scroll) => Consumer(
      builder: (context, ref, _) {
        final month = ref.watch(selectedMonthProvider);
        final txns = ref.watch(monthTxnsProvider).value ?? const <TxnView>[];
        final salary = ref.watch(planProvider).value?.salaryMinor ?? 0;
        final emis = [
          for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
            if (emiActive(e, month)) e,
        ];
        final emi = emis.fold(0, (s, e) => s + e.amountMinor);
        final split = SalarySplit(txns: txns, salaryMinor: salary, emiMinor: emi);
        final (label, total, rows) = switch (pile) {
          SalaryPile.invested => ('Invested', split.invested, split.investTxns),
          SalaryPile.needs => ('Needs', split.needs, split.needTxns),
          SalaryPile.wants => ('Wants', split.wants, split.wantTxns),
          SalaryPile.unsorted => ('Not sorted', split.unsorted, split.unsortedTxns),
          SalaryPile.lent => ('Lent', split.lent, split.lentTxns),
        };
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
            if (pile == SalaryPile.needs)
              for (final e in emis)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(e.name),
                  subtitle: const Text('EMI, from the plan'),
                  trailing: Text(money(e.amountMinor), style: context.text.titleSmall),
                  onTap: () => context.push('/plan'),
                ),
            if (rows.isEmpty && (pile != SalaryPile.needs || emis.isEmpty))
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Nothing this month.', style: context.text.bodyMedium),
              ),
            for (final v in rows)
              TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
          ],
        );
      },
    ),
  ),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import '../budgets/budget_providers.dart' show planProvider;
import '../plan/plan_math.dart' show emiActive;
import '../plan/plan_providers.dart' show emisProvider;
import 'salary_split.dart';

/// Above the budget card: this month's invested, needs, wants and savings
/// as a share of the plan salary. The percents lead; amounts are small.
class SalaryCard extends ConsumerWidget {
  const SalaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(monthTxnsProvider).value;
    if (txns == null) return const SizedBox.shrink();
    final month = ref.watch(selectedMonthProvider);
    final salary = ref.watch(planProvider).value?.salaryMinor ?? 0;
    final emis = [
      for (final e in ref.watch(emisProvider).value ?? const <Emi>[])
        if (emiActive(e, month)) e,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SalarySplitView(
        split: SalarySplit(txns: txns, salaryMinor: salary, emis: emis),
      ),
    );
  }
}

class SalarySplitView extends StatelessWidget {
  const SalarySplitView({super.key, required this.split});

  final SalarySplit split;

  @override
  Widget build(BuildContext context) {
    if (split.salaryMinor <= 0) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          title: const Text('Set salary in Plan'),
          subtitle: const Text('To see invested, needs, wants and savings as a share of it'),
          trailing: const Icon(PhosphorIconsBold.caretRight, size: 16),
          onTap: () => context.push('/plan'),
        ),
      );
    }
    final (i, n, w, s) = split.percents;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Share('Invested', i, split.invested, onTap: () => showSalarySheet(context, SalaryPile.invested)),
          _Share('Needs', n, split.needs, onTap: () => showSalarySheet(context, SalaryPile.needs)),
          _Share('Wants', w, split.wants, onTap: () => showSalarySheet(context, SalaryPile.wants)),
          _Share('Savings', s, split.savings),
        ],
      ),
    );
  }
}

/// One share: label, the percent large, the amount small under it.
class _Share extends StatelessWidget {
  const _Share(this.label, this.percent, this.minor, {this.onTap});

  final String label;
  final int percent;
  final int minor;
  final VoidCallback? onTap;

  static String _rupees(int minor) => '${minor < 0 ? '−' : ''}${money((minor.abs() / 100).round() * 100)}';

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: muted, maxLines: 1),
              const SizedBox(height: 2),
              Text(
                percentLabel(percent),
                maxLines: 1,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: percent < 0 ? context.colors.error : null,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_rupees(minor), style: muted, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SalaryPile { invested, needs, wants }

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
        final split = SalarySplit(txns: txns, salaryMinor: salary, emis: emis);
        final kind = pile == SalaryPile.needs ? SpendKind.need : SpendKind.want;
        final pileEmis = [
          if (pile != SalaryPile.invested)
            for (final e in emis)
              if (e.spendKind == kind) e,
        ];
        final (label, total, rows) = switch (pile) {
          SalaryPile.invested => ('Invested', split.invested, split.investTxns),
          SalaryPile.needs => ('Needs', split.needs, split.needTxns),
          SalaryPile.wants => ('Wants', split.wants, split.wantTxns),
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
            for (final e in pileEmis)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(e.name),
                subtitle: const Text('EMI, from the plan'),
                trailing: Text(money(e.amountMinor), style: context.text.titleSmall),
                onTap: () => context.push('/plan'),
              ),
            if (rows.isEmpty && pileEmis.isEmpty)
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

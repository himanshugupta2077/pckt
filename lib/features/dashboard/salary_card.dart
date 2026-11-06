import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
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
    final savingsColor = s < 0 ? context.colors.error : (context.isDark ? Palette.mint : _savingsGreen);
    final shares = [(i, _invested), (n, _needs), (w, _wants), (s, savingsColor)];
    final filled = shares.fold<int>(0, (t, e) => t + (e.$1 > 0 ? e.$1 : 0));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (final (p, color) in shares)
                      if (p > 0)
                        Expanded(
                          flex: p,
                          child: Container(color: color),
                        ),
                    // Shares under 100% leave the rest of the bar empty.
                    if (filled < 100)
                      Expanded(
                        flex: 100 - filled,
                        child: Container(color: context.colors.onSurface.withValues(alpha: 0.08)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Share(
                'Invested',
                i,
                split.invested,
                color: _invested,
                onTap: () => showSalarySheet(context, SalaryPile.invested),
              ),
              _Share('Needs', n, split.needs, color: _needs, onTap: () => showSalarySheet(context, SalaryPile.needs)),
              _Share('Wants', w, split.wants, color: _wants, onTap: () => showSalarySheet(context, SalaryPile.wants)),
              _Share('Savings', s, split.savings, color: savingsColor, strong: true),
            ],
          ),
        ],
      ),
    );
  }

  // Not status colours: the shares are kinds of money, not good or bad.
  // Savings alone is green when positive and red when negative.
  static const _invested = Palette.violet;
  static const _needs = Color(0xFF1AA0C4);
  static const _wants = Color(0xFFD9559B);
  static const _savingsGreen = Color(0xFF14A37F);
}

/// One share: a colour key and the label, the percent large, the amount
/// small under it. [strong] colours the percent too (Savings).
class _Share extends StatelessWidget {
  const _Share(this.label, this.percent, this.minor, {required this.color, this.strong = false, this.onTap});

  final String label;
  final int percent;
  final int minor;
  final Color color;
  final bool strong;
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(label, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                percentLabel(percent),
                maxLines: 1,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: strong || percent < 0 ? color : null,
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
              if (pile == SalaryPile.invested)
                TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TransactionTile(view: v, showDate: true, onTap: () => showTransactionSheet(context, v.txn.id)),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: SegmentedButton<SpendKind>(
                        segments: const [
                          ButtonSegment(value: SpendKind.need, label: Text('Need')),
                          ButtonSegment(value: SpendKind.want, label: Text('Want')),
                        ],
                        selected: {kind},
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        // This payment only. The payment's sheet can answer for the payee.
                        onSelectionChanged: (k) => ref.read(databaseProvider).setTxnSpendKind(v.txn.id, k.first),
                      ),
                    ),
                  ],
                ),
          ],
        );
      },
    ),
  ),
);

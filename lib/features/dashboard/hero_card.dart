import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/db/database.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_math.dart' show budgetWarnRatio;
import 'buckets_card.dart' show showBucketSheet, showOthersSheet;
import 'income_sheet.dart';
import 'out_sheet.dart';

/// In and Out across the top, then Everyday, Recurring and Fund: each shows
/// what was spent, the limit, and what is left. In and Out are whole rupees.
/// The budget lines keep paise so spent and left add up to the limit.
/// Below them, what is not budgeted: EMI, Invested and Others.
class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.month,
    required this.everydaySpent,
    required this.everydayLimit,
    required this.fixedSpent,
    required this.fixedLimit,
    required this.fundSpent,
    required this.fundLimit,
    required this.inMinor,
    required this.outMinor,
    this.everydayNote,
    this.emis = const [],
    this.invested = 0,
    this.showOthers = false,
  });

  final DateTime month;
  final int everydaySpent;
  final int everydayLimit;
  final int fixedSpent;
  final int fixedLimit;
  final int fundSpent;
  final int fundLimit;
  final int inMinor;
  final int outMinor;

  /// Pace for Everyday this month, when there is still money and days left.
  final String? everydayNote;

  /// Not budgeted: EMIs paid this month (from the plan's list, since card
  /// EMIs ride on the card bill), money invested, and whether there is any
  /// lending or outside spending to open.
  final List<Emi> emis;
  final int invested;
  final bool showOthers;

  static String _rupees(int minor) => '${minor < 0 ? '−' : ''}${money((minor.abs() / 100).round() * 100)}';

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.72);
    final small = context.text.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget part(String label, int minor, {required bool moneyIn, VoidCallback? onTap}) {
      final color = moneyIn ? Palette.income : Palette.expense;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(moneyIn ? PhosphorIconsBold.arrowDownLeft : PhosphorIconsBold.arrowUpRight, size: 16, color: color),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label  ',
                      style: context.text.bodySmall?.copyWith(color: color),
                    ),
                    TextSpan(
                      text: _rupees(minor),
                      style: small?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final notBudgeted = emis.isNotEmpty || invested != 0 || showOthers;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(
        text,
        style: context.text.labelLarge?.copyWith(color: soft, fontWeight: FontWeight.w600),
      ),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: Palette.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                part('In', inMinor, moneyIn: true, onTap: () => showIncomeSheet(context)),
                part('Out', outMinor, moneyIn: false, onTap: () => showOutSheet(context)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          heading('Budgets'),
          _BudgetBlock(
            label: 'Everyday',
            icon: PhosphorIconsFill.wallet,
            bucket: Bucket.everyday,
            spent: everydaySpent,
            limit: everydayLimit,
            note: everydayNote,
          ),
          const SizedBox(height: 8),
          _BudgetBlock(
            label: 'Recurring',
            icon: PhosphorIconsFill.repeat,
            bucket: Bucket.fixed,
            spent: fixedSpent,
            limit: fixedLimit,
          ),
          const SizedBox(height: 8),
          _BudgetBlock(
            label: 'Fund',
            icon: PhosphorIconsFill.piggyBank,
            bucket: Bucket.fund,
            spent: fundSpent,
            limit: fundLimit,
          ),
          if (notBudgeted) ...[
            const SizedBox(height: 14),
            heading('Not budgeted'),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, tile) in [
                    if (emis.isNotEmpty)
                      _Tile(
                        onTap: () => context.push('/plan'),
                        child: _TileTotal(
                          icon: PhosphorIconsFill.creditCard,
                          label: 'EMI',
                          minor: emis.fold<int>(0, (s, e) => s + e.amountMinor),
                        ),
                      ),
                    if (invested != 0)
                      _Tile(
                        onTap: () => showBucketSheet(context, Bucket.invest, 'Invested'),
                        child: _TileTotal(icon: PhosphorIconsFill.trendUp, label: 'Invested', minor: invested),
                      ),
                    if (showOthers)
                      _Tile(
                        onTap: () => showOthersSheet(context),
                        child: const _TileTotal(icon: PhosphorIconsFill.handCoins, label: 'Others'),
                      ),
                  ].indexed) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: tile)],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A box inside the month card.
class _Tile extends StatelessWidget {
  const _Tile({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.09),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: child),
    ),
  );
}

/// Icon and label, then the amount large (or what is inside, without one).
class _TileTotal extends StatelessWidget {
  const _TileTotal({required this.icon, required this.label, this.minor});

  final IconData icon;
  final String label;
  final int? minor;

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.72);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: soft),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label, maxLines: 1, style: context.text.labelLarge?.copyWith(color: soft)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: minor == null
              ? Text('Lending, outside', style: context.text.bodySmall?.copyWith(color: Colors.white))
              : Text(
                  money(minor!),
                  style: context.text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ],
    );
  }
}

/// One budget inside the month card: name and what's left, then spent of
/// the limit, then the bar. Tap lists the month's payments.
class _BudgetBlock extends StatelessWidget {
  const _BudgetBlock({
    required this.label,
    required this.icon,
    required this.bucket,
    required this.spent,
    required this.limit,
    this.note,
  });

  final String label;
  final IconData icon;
  final Bucket bucket;
  final int spent;
  final int limit;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final left = limit - spent;
    final over = left < 0;
    final soft = Colors.white.withValues(alpha: 0.72);
    return _Tile(
      onTap: () => showBucketSheet(context, bucket, label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: soft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: context.text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                over ? '${money(-left)} over' : '${money(left)} left',
                style: context.text.titleSmall?.copyWith(
                  color: over ? Palette.coral : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('${money(spent)} spent of ${money(limit)}', style: context.text.bodySmall?.copyWith(color: soft)),
          const SizedBox(height: 8),
          _LimitBar(ratio: limit <= 0 ? 0 : spent / limit),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: context.text.bodySmall?.copyWith(color: soft)),
          ],
        ],
      ),
    );
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final color = ratio > 1
        ? Palette.coral
        : ratio >= budgetWarnRatio
        ? Palette.amber
        : Palette.mint;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: ratio.clamp(0, 1).toDouble(),
        minHeight: 6,
        color: color,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
      ),
    );
  }
}

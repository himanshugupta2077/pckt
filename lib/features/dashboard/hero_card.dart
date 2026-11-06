import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/db/database.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_math.dart' show budgetWarnRatio;
import 'buckets_card.dart' show showBucketSheet;
import 'income_sheet.dart';
import 'out_sheet.dart';

/// In and Out across the top, then Everyday, Recurring and Fund: each shows
/// what was spent, the limit, and what is left. In and Out are whole rupees.
/// The budget lines keep paise so spent and left add up to the limit.
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
              Icon(
                moneyIn ? PhosphorIconsBold.arrowDownLeft : PhosphorIconsBold.arrowUpRight,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$label  ', style: context.text.bodySmall?.copyWith(color: color)),
                    TextSpan(text: _rupees(minor), style: small?.copyWith(color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              part('In', inMinor, moneyIn: true, onTap: () => showIncomeSheet(context)),
              part('Out', outMinor, moneyIn: false, onTap: () => showOutSheet(context)),
            ],
          ),
          const SizedBox(height: 18),
          Text('Budgets', style: context.text.titleSmall?.copyWith(color: soft, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _BudgetBlock(
            label: 'Everyday',
            bucket: Bucket.everyday,
            spent: everydaySpent,
            limit: everydayLimit,
            note: everydayNote,
          ),
          const SizedBox(height: 18),
          _BudgetBlock(label: 'Recurring', bucket: Bucket.fixed, spent: fixedSpent, limit: fixedLimit),
          const SizedBox(height: 18),
          _BudgetBlock(label: 'Fund', bucket: Bucket.fund, spent: fundSpent, limit: fundLimit),
        ],
      ),
    );
  }
}

/// One budget inside the month card: name and what's left, then spent of
/// the limit, then the bar. Tap lists the month's payments.
class _BudgetBlock extends StatelessWidget {
  const _BudgetBlock({required this.label, required this.bucket, required this.spent, required this.limit, this.note});

  final String label;
  final Bucket bucket;
  final int spent;
  final int limit;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final left = limit - spent;
    final over = left < 0;
    final soft = Colors.white.withValues(alpha: 0.72);
    return InkWell(
      onTap: () => showBucketSheet(context, bucket, label),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: context.text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
          Text(
            '${money(spent)} spent of ${money(limit)}',
            style: context.text.bodySmall?.copyWith(color: soft),
          ),
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

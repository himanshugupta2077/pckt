import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../ui/widgets.dart';
import 'income_sheet.dart';
import 'out_sheet.dart';

/// What's left of Everyday, Recurring and Fund, each on its own, with In
/// and Out along the bottom. Whole rupees: paise only add noise here.
class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.month,
    required this.everydayLeft,
    required this.fixedLeft,
    required this.fundLeft,
    required this.inMinor,
    required this.outMinor,
  });

  final DateTime month;

  /// Budget minus spent. Negative means over.
  final int everydayLeft;
  final int fixedLeft;
  final int fundLeft;
  final int inMinor;
  final int outMinor;

  static String _rupees(int minor) => '${minor < 0 ? '−' : ''}${money((minor.abs() / 100).round() * 100)}';

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.72);
    final small = context.text.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget remain(String label, int left) {
      final over = left < 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.text.bodyMedium?.copyWith(color: soft))),
            Text(
              over ? '${_rupees(-left)} over' : '${_rupees(left)} left',
              style: small?.copyWith(color: over ? Palette.coral : Colors.white),
            ),
          ],
        ),
      );
    }

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
          remain('Everyday', everydayLeft),
          remain('Recurring', fixedLeft),
          remain('Fund', fundLeft),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              part('In', inMinor, moneyIn: true, onTap: () => showIncomeSheet(context)),
              part('Out', outMinor, moneyIn: false, onTap: () => showOutSheet(context)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../ui/widgets.dart';
import 'income_sheet.dart';

/// The month at a glance. In is income. Out is every rupee that left your
/// accounts except moves between them: spending, EMIs, money invested and
/// money lent (less what came back). Left is what stayed.
class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.month,
    required this.inMinor,
    required this.outMinor,
    this.investedMinor = 0,
  });

  final DateTime month;
  final int inMinor;
  final int outMinor;

  /// Put into investments this month, net: part of Out, named under it.
  final int investedMinor;

  @override
  Widget build(BuildContext context) {
    final left = inMinor - outMinor;
    final soft = Colors.white.withValues(alpha: 0.72);
    Widget figure(String label, int minor, {VoidCallback? onTap, bool strong = false}) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall?.copyWith(color: soft)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${minor < 0 ? '−' : ''}${money(minor.abs())}',
                  style: (strong ? context.text.headlineSmall : context.text.titleMedium)?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
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
            children: [
              figure('In', inMinor, onTap: () => showIncomeSheet(context)),
              figure('Out', outMinor),
              figure('Left', left, strong: true),
            ],
          ),
          if (investedMinor > 0) ...[
            const SizedBox(height: 6),
            Text('Out includes ${money(investedMinor)} invested', style: context.text.bodySmall?.copyWith(color: soft)),
          ],
        ],
      ),
    );
  }
}

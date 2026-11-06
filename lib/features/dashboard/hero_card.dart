import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../ui/widgets.dart';
import 'income_sheet.dart';

/// The month at a glance: what's left as the one big number, In and Out
/// under it. In is income. Out is every rupee that left your accounts
/// except moves between them: spending, EMIs, money invested and money lent
/// (less what came back). Whole rupees: paise only add noise here.
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

  static String _rupees(int minor) => '${minor < 0 ? '−' : ''}${money((minor.abs() / 100).round() * 100)}';

  @override
  Widget build(BuildContext context) {
    final left = inMinor - outMinor;
    final soft = Colors.white.withValues(alpha: 0.72);
    final small = context.text.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget part(String label, int minor, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label  ',
                style: context.text.bodySmall?.copyWith(color: soft),
              ),
              TextSpan(text: _rupees(minor), style: small),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Left this month', style: context.text.bodyMedium?.copyWith(color: soft)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _rupees(left),
              style: context.text.displaySmall?.copyWith(
                color: left < 0 ? Palette.coral : Colors.white,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              part('In', inMinor, onTap: () => showIncomeSheet(context)),
              part('Out', outMinor),
            ],
          ),
          if (investedMinor > 0)
            Text(
              'Out includes ${_rupees(investedMinor)} invested',
              style: context.text.bodySmall?.copyWith(color: soft),
            ),
        ],
      ),
    );
  }
}

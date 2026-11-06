import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/core/theme/icons.dart';
import 'package:pckt/features/dashboard/hero_card.dart';

void main() {
  testWidgets('In is green with an in arrow, Out is red with an out arrow, invested stays', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthCard(month: DateTime(2026, 11), inMinor: 14166667, outMinor: 10440569, investedMinor: 4400000),
        ),
      ),
    );

    expect(find.text('Left this month'), findsOneWidget);
    expect(find.textContaining('Out includes'), findsOneWidget);
    expect(find.textContaining('invested'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.arrowDownLeft), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.arrowUpRight), findsOneWidget);

    final inIcon = tester.widget<Icon>(find.byIcon(PhosphorIconsBold.arrowDownLeft));
    final outIcon = tester.widget<Icon>(find.byIcon(PhosphorIconsBold.arrowUpRight));
    expect(inIcon.color, isNot(outIcon.color));
  });
}

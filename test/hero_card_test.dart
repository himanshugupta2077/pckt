import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/core/theme/icons.dart';
import 'package:pckt/features/dashboard/hero_card.dart';

void main() {
  testWidgets('the three budgets are separate, In sits left and Out sits right', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthCard(
            month: DateTime(2026, 11),
            everydaySpent: 381506,
            everydayLimit: 1000000,
            fixedSpent: 344297,
            fixedLimit: 1000000,
            fundSpent: 1156600,
            fundLimit: 1000000,
            inMinor: 14166667,
            outMinor: 10440569,
            everydayNote: '₹206 a day for 24 days',
          ),
        ),
      ),
    );

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('Fund'), findsOneWidget);
    expect(find.textContaining('spent of'), findsNWidgets(3));
    expect(find.textContaining('left'), findsNWidgets(2));
    expect(find.textContaining('over'), findsOneWidget);
    expect(find.text('₹206 a day for 24 days'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Budgets')).dy,
      greaterThan(tester.getTopLeft(find.byIcon(PhosphorIconsBold.arrowDownLeft)).dy),
    );
    expect(find.byIcon(PhosphorIconsBold.arrowDownLeft), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.arrowUpRight), findsOneWidget);

    final inIcon = tester.widget<Icon>(find.byIcon(PhosphorIconsBold.arrowDownLeft));
    final outIcon = tester.widget<Icon>(find.byIcon(PhosphorIconsBold.arrowUpRight));
    expect(inIcon.color, isNot(outIcon.color));
    final inAt = tester.getTopLeft(find.byIcon(PhosphorIconsBold.arrowDownLeft));
    final outAt = tester.getTopLeft(find.byIcon(PhosphorIconsBold.arrowUpRight));
    expect(outAt.dx - inAt.dx, greaterThan(200));
  });
}

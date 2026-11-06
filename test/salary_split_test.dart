import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/dashboard/salary_card.dart';
import 'package:pckt/features/dashboard/salary_split.dart';

import 'budget_test.dart' show cat, txn;

void main() {
  final groceries = cat(1, 'Groceries', seed: 'Groceries');
  final dining = cat(2, 'Food & Dining', seed: 'Food & Dining');
  final invest = cat(3, 'Investments', bucket: Bucket.outside, seed: 'Investments');
  final family = cat(4, 'Family', bucket: Bucket.lending, seed: 'Family');
  final other = cat(5, 'Other', seed: 'Other');
  final fitness = cat(6, 'Fitness', bucket: Bucket.fixed, seed: 'Fitness');
  final loans = cat(7, 'Loans & EMI', bucket: Bucket.outside, seed: 'Loans & EMI');

  test('groceries are needs, dining and fitness are wants, other is not a want', () {
    expect(spendDecision(txn(100, category: groceries)).kind, SpendKind.need);
    expect(spendDecision(txn(100, category: dining)).kind, SpendKind.want);
    expect(spendDecision(txn(100, category: fitness)).kind, SpendKind.want);
    expect(spendDecision(txn(100, category: other)).source, SpendSource.unsorted);
    expect(spendDecision(txn(100, category: loans)).source, SpendSource.unsorted);
    expect(spendDecision(txn(100)).source, SpendSource.unsorted);
  });

  test('a payment or a payee overrides the category, including Other', () {
    final overridden = txn(100, category: groceries, spendKind: SpendKind.want);
    expect((spendDecision(overridden).kind, spendDecision(overridden).source), (SpendKind.want, SpendSource.manual));
    final payee = txn(100, category: other, merchant: 'Cafe', payeeKind: SpendKind.need);
    expect((spendDecision(payee).kind, spendDecision(payee).source), (SpendKind.need, SpendSource.payee));
  });

  test('investments count even from Outside, and family lending is not a need', () {
    expect(spendDecision(txn(100, category: invest)).source, SpendSource.invest);
    expect(spendDecision(txn(100, category: family)).source, SpendSource.lending);
    expect(spendDecision(txn(100, transfer: true, category: dining)).source, SpendSource.transfer);
    expect(spendDecision(txn(100, dir: TxnDirection.credit, category: dining)).source, SpendSource.income);
    expect(canSetSpendKind(txn(100, category: other)), isTrue);
    expect(canSetSpendKind(txn(100, category: invest)), isFalse);
  });

  test('EMI is added to needs, a broker credit reduces invested, Other stays out', () {
    final split = SalarySplit(
      salaryMinor: 14166700,
      emiMinor: 4358000,
      txns: [
        txn(10000, category: invest),
        txn(200000, category: invest, dir: TxnDirection.credit),
        txn(458300, category: groceries),
        txn(232900, category: dining),
        txn(4081100, category: other),
        txn(6400000, category: family),
        txn(999900, transfer: true, category: dining),
      ],
    );
    expect(split.invested, 10000 - 200000);
    expect(split.needs, 458300 + 4358000);
    expect(split.wants, 232900);
    expect(split.unsorted, 4081100);
    expect(split.lent, 6400000);
    expect(split.needTxns, hasLength(1));
    expect(split.wantTxns, hasLength(1));
    expect(
      (
        percentOf(split.invested, split.salaryMinor),
        percentOf(split.needs, split.salaryMinor),
        percentOf(split.wants, split.salaryMinor),
      ),
      (-1, 34, 2),
    );
    expect(percentOf(1, 0), 0);
  });

  testWidgets('the card shows the three shares, the EMI, and what is not a share', (tester) async {
    final split = SalarySplit(
      salaryMinor: 14166700,
      emiMinor: 4358000,
      txns: [
        txn(10000, category: invest),
        txn(458300, category: groceries),
        txn(232900, category: dining),
        txn(4081100, category: other),
        txn(6400000, category: family),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SalarySplitView(split: split, soFar: true)),
      ),
    );

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('so far'), findsOneWidget);
    expect(find.text('Invested'), findsOneWidget);
    expect(find.text('Needs'), findsOneWidget);
    expect(find.text('Wants'), findsOneWidget);
    expect(find.text('₹43,580 EMI'), findsOneWidget);
    expect(find.text('Not sorted'), findsOneWidget);
    expect(find.text('Lent'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('34%'), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Invested')).dy, lessThan(tester.getTopLeft(find.text('Needs')).dy));
    expect(tester.getTopLeft(find.text('Needs')).dy, lessThan(tester.getTopLeft(find.text('Wants')).dy));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/db/database.dart';
import 'package:pckt/features/budgets/bucket_stats.dart';
import 'package:pckt/features/budgets/in_budget.dart';
import 'package:pckt/features/stats.dart';

import 'budget_test.dart' show cat, txn;

void main() {
  final food = cat(1, 'Food');
  final bills = cat(2, 'Bills', bucket: Bucket.fixed);
  final emi = cat(3, 'Loans & EMI', bucket: Bucket.outside, seed: 'Loans & EMI');
  final family = cat(4, 'Family', bucket: Bucket.outside, seed: 'Family');

  group('complete months', () {
    test('the first month counts only if the data starts in its first days', () {
      expect(completeMonths(DateTime(2026, 11), DateTime(2026, 9, 1, 9)), [DateTime(2026, 10), DateTime(2026, 9)]);
      expect(completeMonths(DateTime(2026, 11), DateTime(2026, 9, 14)), [DateTime(2026, 10)]);
      expect(completeMonths(DateTime(2026, 11), DateTime(2026, 10, 20)), isEmpty);
      expect(completeMonths(DateTime(2026, 11), null), isEmpty);
      expect(completeMonths(DateTime(2027, 6), DateTime(2025, 1, 1)), hasLength(6));
    });

    test('averages over one or two complete months', () {
      final txns = [
        txn(500000, at: DateTime(2026, 9, 5), category: bills),
        txn(700000, at: DateTime(2026, 10, 5), category: bills),
        txn(999900, at: DateTime(2026, 11, 2), category: bills), // this month: not in the average
        txn(300000, at: DateTime(2026, 10, 6), category: food),
      ];
      final two = monthlyAverage(txns, completeMonths(DateTime(2026, 11), DateTime(2026, 9, 1)), isFixed);
      expect((two.minor, two.label), (600000, 'avg of 2 months'));
      final one = monthlyAverage(txns, completeMonths(DateTime(2026, 11), DateTime(2026, 9, 20)), isFixed);
      expect((one.minor, one.label), (700000, 'avg of 1 month'));
      expect(monthlyAverage(txns, const [], isFixed).minor, 0);
    });
  });

  test('the Buckets card: fixed and fund this month, outside by category, loans in none', () {
    final txns = [
      txn(120000, at: DateTime(2026, 10, 3), category: bills),
      txn(850000, at: DateTime(2026, 10, 9), category: food, bucket: Bucket.fund), // before the plan
      txn(240000, at: DateTime(2026, 11, 2), category: food, bucket: Bucket.fund),
      txn(300000, at: DateTime(2026, 12, 4), category: food, bucket: Bucket.fund),
      txn(80000, at: DateTime(2026, 12, 5), category: bills),
      txn(4000000, at: DateTime(2026, 12, 5), category: emi),
      txn(1000000, at: DateTime(2026, 12, 6), category: family),
      txn(1500000, at: DateTime(2026, 12, 7), category: family),
      txn(50000, at: DateTime(2026, 12, 7), category: food),
      txn(9999900, at: DateTime(2026, 12, 7), transfer: true),
      txn(6400000, at: DateTime(2026, 12, 4), category: family, bucket: Bucket.ignore), // paying back
      txn(2000000, at: DateTime(2026, 12, 1), dir: TxnDirection.credit, category: family, bucket: Bucket.ignore),
    ];
    final s = BucketSummary(txns: txns, month: DateTime(2026, 12));
    expect(s.fixed, 80000);
    expect(s.fund, 300000);
    expect([for (final c in s.outside) (c.category?.name, c.amount)], [('Loans & EMI', 4000000), ('Family', 2500000)]);
    expect(s.outsideTotal, 6500000);
    expect(monthsSince(DateTime(2026, 11), DateTime(2026, 10)), 0);
    expect(isFamilyOrInsurance(txns[6]), isTrue);
    final stats = MonthStats([
      for (final v in txns)
        if (inMonth(v.txn.occurredAt, DateTime(2026, 12))) v,
    ], DateTime(2026, 12));
    expect((stats.income, stats.outside), (0, 6880000)); // the ignored ones are neither
  });

  test('a payee or category marked Ignore takes its payments out of spending and income', () {
    final family = cat(9, 'Family', bucket: Bucket.ignore, seed: 'Family');
    expect(isIgnored(txn(500000, category: family)), isTrue);
    expect(isIgnored(txn(500000, category: family, bucket: Bucket.outside)), isFalse); // a real gift, this once
    expect(isIgnored(txn(500000, merchant: 'Ravi', payee: Bucket.ignore)), isTrue);
  });
}

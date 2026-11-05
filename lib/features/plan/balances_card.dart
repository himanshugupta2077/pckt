import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/amount_field.dart';
import '../../ui/widgets.dart';
import '../settings/data_section.dart' show backUpNow;
import 'balances.dart';

/// The last year of balance snapshots.
final snapshotsProvider = StreamProvider<List<BalanceSnapshot>>((ref) {
  final m = monthStart(DateTime.now());
  return ref.watch(databaseProvider).watchSnapshots(from: DateTime(m.year - 1, m.month));
});

/// On Home from the 1st to the 7th until this month's balances are in:
/// net worth for recent months, a way to fill this one, and a backup.
class BalancesCard extends ConsumerWidget {
  const BalancesCard({super.key, this.now});

  /// Today, unless a test sets it.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snaps = ref.watch(snapshotsProvider).value;
    final now = this.now ?? DateTime.now();
    if (snaps == null || !balancesDue(now, snaps)) return const SizedBox.shrink();
    final month = monthStart(now);
    final history = netWorthByMonth(snaps);
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balances for ${DateFormat('MMMM').format(month)}',
              style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Net worth', style: muted),
              for (final (m, worth) in history)
                Row(
                  children: [
                    Expanded(child: Text(DateFormat('MMM yyyy').format(m), style: context.text.bodyMedium)),
                    Text(
                      money(worth),
                      style: context.text.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                // The theme's filled buttons are full width, so each side gets half.
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => showBalancesSheet(context, month, balanceLabels(snaps, month)),
                    child: const Text('Fill in'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(onPressed: () => backUpNow(context, ref), child: const Text('Back up now')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showBalancesSheet(BuildContext context, DateTime month, List<(String, bool)> labels) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BalancesSheet(month: month, labels: labels),
    );

class _BalancesSheet extends ConsumerStatefulWidget {
  const _BalancesSheet({required this.month, required this.labels});
  final DateTime month;
  final List<(String, bool)> labels;

  @override
  ConsumerState<_BalancesSheet> createState() => _BalancesSheetState();
}

class _BalancesSheetState extends ConsumerState<_BalancesSheet> {
  late final _fields = [for (final _ in widget.labels) TextEditingController()];
  late final _home = Currencies.home;

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  int _amount(int i) => parseAmountInput(_fields[i].text, currency: _home) ?? 0;

  int get _netWorth =>
      [for (final (i, (_, liability)) in widget.labels.indexed) liability ? -_amount(i) : _amount(i)]
          .fold(0, (a, b) => a + b);

  Future<void> _save() async {
    await ref.read(databaseProvider).saveSnapshots(widget.month, [
      for (final (i, (label, liability)) in widget.labels.indexed) (label, _amount(i), liability),
    ]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Balances on 1 ${DateFormat('MMMM').format(widget.month)}',
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Net worth ${money(_netWorth)}',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final (i, (label, liability)) in widget.labels.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _fields[i],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter(currency: _home)],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: label,
                  helperText: liability ? 'Owed: counts against net worth' : null,
                  prefixText: '${currencySymbol(_home)} ',
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

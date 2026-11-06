import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/icons.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../dashboard/salary_split.dart';

final _payeeKindsProvider = StreamProvider<List<MerchantRule>>(
  (ref) => ref.watch(databaseProvider).watchSpendKindRules(),
);

/// Need or want for each expense category, and for payees that have their
/// own answer. Investments, lending and transfers are never either, so
/// they are not listed.
class NeedsWantsScreen extends ConsumerWidget {
  const NeedsWantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final cats = [
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        if (categoryHasSpendKind(c)) c,
    ];
    final payees = ref.watch(_payeeKindsProvider).value ?? const <MerchantRule>[];
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Needs and wants')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              'Each spend counts as a need or a want on the Home card. A payee\'s answer wins over its category, '
              'and an answer on one payment wins over both. Plan EMIs are always needs.',
              style: muted,
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionHeader('Categories')),
          for (final c in cats)
            ListTile(
              leading: CategoryBadge(category: c, size: 36),
              title: Text(c.name),
              trailing: _KindToggle(
                value: c.spendKind,
                onChanged: (k) => db.updateCategory(c.id, spendKind: k),
              ),
            ),
          if (payees.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionHeader('Payees')),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text('Set from a payment. Remove one to follow its category again.', style: muted),
            ),
            for (final r in payees)
              ListTile(
                title: Text(_title(r.pattern)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _KindToggle(value: r.spendKind!, onChanged: (k) => db.setPayeeSpendKind(r.pattern, k)),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                      onPressed: () => db.setPayeeSpendKind(r.pattern, null),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Payee patterns are stored lower case.
  static String _title(String pattern) =>
      pattern.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.value, required this.onChanged});

  final SpendKind value;
  final ValueChanged<SpendKind> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<SpendKind>(
    segments: const [
      ButtonSegment(value: SpendKind.need, label: Text('Need')),
      ButtonSegment(value: SpendKind.want, label: Text('Want')),
    ],
    selected: {value},
    showSelectedIcon: false,
    style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    onSelectionChanged: (s) => onChanged(s.first),
  );
}

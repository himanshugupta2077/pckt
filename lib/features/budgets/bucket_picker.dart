import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../ui/widgets.dart';
import 'in_budget.dart';

/// The bucket choice, used for categories, payees and payments.
/// [value] null shows nothing selected (an unanswered To-sort row).
class BucketPicker extends StatelessWidget {
  const BucketPicker({super.key, required this.value, required this.onChanged});

  final Bucket? value;

  /// Null disables the picker.
  final ValueChanged<Bucket>? onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final b in bucketChoices)
        ChoiceChip(
          label: Text(bucketLabel(b)),
          selected: value == b,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: onChanged == null ? null : (_) => onChanged!(b),
        ),
    ],
  );
}

/// Compact form for list rows: the current bucket, tap to change.
class BucketMenu extends StatelessWidget {
  const BucketMenu({super.key, required this.value, required this.onChanged});

  final Bucket value;
  final ValueChanged<Bucket> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Bucket>(
    initialValue: value,
    tooltip: 'Bucket',
    onSelected: onChanged,
    itemBuilder: (_) => [for (final b in bucketChoices) PopupMenuItem(value: b, child: Text(bucketLabel(b)))],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        bucketLabel(value),
        style: context.text.labelLarge?.copyWith(
          color: value == Bucket.everyday ? context.colors.onSurfaceVariant : context.colors.primary,
        ),
      ),
    ),
  );
}

/// Asks what a Lending payment was ("Mansi lent me, paid back 4 Nov").
/// Returns the note to save, or null if the dialog was dismissed.
Future<String?> askLendingNote(BuildContext context, String? current) {
  final c = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Lent or borrowed'),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Mansi lent me, paid back on 4 Nov'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
      ],
    ),
  ).whenComplete(c.dispose);
}

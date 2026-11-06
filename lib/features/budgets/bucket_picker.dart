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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<Bucket>(
      segments: [
        for (final b in Bucket.values)
          ButtonSegment(
            value: b,
            label: Text(bucketLabel(b), maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
          ),
      ],
      selected: {?value},
      emptySelectionAllowed: true,
      showSelectedIcon: false,
      // Five choices share a phone's width: a smaller label keeps "Everyday" whole.
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 2)),
        textStyle: WidgetStatePropertyAll(context.text.labelMedium),
      ),
      onSelectionChanged: onChanged == null
          ? null
          : (s) {
              if (s.isNotEmpty) onChanged!(s.first);
            },
    ),
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
    itemBuilder: (_) => [for (final b in Bucket.values) PopupMenuItem(value: b, child: Text(bucketLabel(b)))],
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

/// Asks why a payment is ignored ("Mansi's loan, paid back"). Returns the
/// note to save, or null if the dialog was dismissed.
Future<String?> askWhyIgnored(BuildContext context, String? current) {
  final c = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Why ignore it?'),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Loan from family, paid back'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
      ],
    ),
  ).whenComplete(c.dispose);
}

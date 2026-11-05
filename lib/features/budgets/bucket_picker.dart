import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../ui/widgets.dart';
import 'in_budget.dart';

/// The 4-way bucket choice, used for categories, payees and payments.
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
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../settings/manage_widgets.dart' show accountLabel;
import 'transaction_sheet.dart';

/// One payment with what it is known from: amount, time, account, rail,
/// reference, UPI ID and the message text itself. Tapping it opens the
/// full transaction sheet.
class PaymentEvidence extends ConsumerWidget {
  const PaymentEvidence({super.key, required this.view, this.label});

  final TxnView view;

  /// Shown above the payment, e.g. "This payment".
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = view.txn;
    final sources = ref.watch(txnSourcesProvider(t.id)).value ?? const [];
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final facts = [
      dateTimeLabel(t.occurredAt),
      if (view.account != null) accountLabel(view.account!) else if (t.accountHint != null) '••${t.accountHint}',
      modeLabel(t.mode),
      if (t.reference != null) 'Ref ${t.reference}',
      if (t.counterparty != null && t.counterparty != t.merchant) t.counterparty!,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Text(label!, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
            ),
          TransactionTile(view: view, showDate: true, onTap: () => showTransactionSheet(context, t.id)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(facts.join('  ·  '), style: muted),
          ),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    s.source == SourceKind.email ? PhosphorIconsFill.envelopeSimple : PhosphorIconsFill.chatText,
                    size: 15,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText('${s.sender}: ${s.body}', style: muted?.copyWith(height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

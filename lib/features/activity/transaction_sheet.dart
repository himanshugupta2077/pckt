import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import 'category_picker.dart';
import 'conversion_sheet.dart';
import '../budgets/bucket_picker.dart';
import '../budgets/in_budget.dart';
import '../settings/manage_widgets.dart' show accountLabel;
import 'edit_transaction_sheet.dart';
import 'payment_evidence.dart';

Future<void> showTransactionSheet(BuildContext context, int id) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    maxChildSize: 0.95,
    builder: (_, scroll) => TransactionSheet(id: id, scroll: scroll),
  ),
);

class TransactionSheet extends ConsumerWidget {
  const TransactionSheet({super.key, required this.id, required this.scroll});

  final int id;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(txnProvider(id)).value;
    if (view == null) return const SizedBox(height: 200);
    final t = view.txn;
    final db = ref.read(databaseProvider);
    final credit = t.direction == TxnDirection.credit;
    final sources = ref.watch(txnSourcesProvider(id)).value ?? const [];

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Center(
          child: CategoryBadge(category: view.category, isTransfer: t.isTransfer, size: 64),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '${credit ? '+' : '−'}${money(t.amountMinor, currency: t.currency, forceDecimals: true)}',
            style: context.text.displaySmall?.copyWith(
              color: credit && !t.isTransfer ? Palette.income : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (t.convertedMinor != null && t.convertedCurrency != null)
          Center(
            child: Text(
              '≈ ${money(t.convertedMinor!, currency: t.convertedCurrency, forceDecimals: true)}',
              style: context.text.titleSmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: Text(txnTitle(t), style: context.text.titleMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            dateTimeLabel(t.occurredAt),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoPill(icon: modeIcon(t.mode), label: modeLabel(t.mode)),
            if (view.account != null)
              InfoPill(icon: PhosphorIconsBold.bank, label: accountLabel(view.account!))
            else if (t.accountHint != null)
              InfoPill(icon: PhosphorIconsBold.bank, label: '••${t.accountHint}'),
            if (t.reference != null) InfoPill(icon: PhosphorIconsBold.hash, label: t.reference!),
            if (t.counterparty != null && t.counterparty != t.merchant)
              InfoPill(icon: PhosphorIconsBold.at, label: t.counterparty!),
          ],
        ),
        if (t.note != null && t.note!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIconsRegular.notePencil, size: 18, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text(t.note!, style: context.text.bodyMedium)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => showEditTransactionSheet(context, view),
              icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
              label: const Text('Edit details'),
            ),
            // One purchase into the fund: no payee rule, no other payment.
            if (!credit && !t.isTransfer && t.bucket != Bucket.fund)
              TextButton.icon(
                onPressed: () => db.setTxnBucket(id, Bucket.fund),
                icon: const Icon(PhosphorIconsFill.shoppingBag, size: 18),
                label: const Text('Big & occasional'),
              ),
          ],
        ),
        if (t.isForeign && t.homeMinor == null) ...[
          const SizedBox(height: 18),
          AppCard(
            color: Palette.amber.withValues(alpha: 0.12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(PhosphorIconsFill.globeHemisphereWest, color: Palette.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Paid in ${t.currency}, so it isn't in your ${Currencies.home} totals or budgets yet."),
                ),
                TextButton(
                  onPressed: () => showConversionSheet(context, t),
                  child: Text('Add ${currencySymbol(Currencies.home)}'),
                ),
              ],
            ),
          ),
        ] else if (t.isForeign)
          Center(
            child: TextButton.icon(
              onPressed: () => showConversionSheet(context, t),
              icon: const Icon(PhosphorIconsRegular.arrowsLeftRight, size: 18),
              label: Text('Change the ${Currencies.home} amount'),
            ),
          ),
        if (t.duplicateOfId != null) ...[
          const SizedBox(height: 18),
          _DuplicatePanel(view: view, otherId: t.duplicateOfId!),
        ] else if (t.status == TxnStatus.needsReview) ...[
          const SizedBox(height: 18),
          AppCard(
            color: Palette.amber.withValues(alpha: 0.12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(PhosphorIconsFill.warningCircle, color: Palette.amber),
                const SizedBox(width: 12),
                const Expanded(child: Text('Parsed with low confidence. Does this look right?')),
                TextButton(onPressed: () => db.confirm(id), child: const Text('Looks right')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const SectionHeader('Category'),
        CategoryPicker(
          selectedId: t.categoryId,
          income: credit,
          onSelected: (c) => db.setCategory(id, c.id, learnPattern: t.merchant?.toLowerCase()),
        ),
        if (t.merchant != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Future ${t.merchant} transactions will use the category you pick.',
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: t.isTransfer,
          onChanged: (v) => db.setTransfer(id, v),
          title: const Text('Transfer or card bill'),
          subtitle: const Text('Money moved between your own accounts or cards: not spending or income'),
          secondary: const Icon(PhosphorIconsRegular.arrowsLeftRight),
        ),
        _BudgetSection(view: view),
        const SizedBox(height: 12),
        SectionHeader('Sources (${sources.length})'),
        for (final s in sources) _SourceCard(message: s),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Palette.coral,
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: Palette.coral.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Delete transaction?'),
                content: const Text('The source message stays hidden so it won\'t be re-imported.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              Navigator.pop(context);
              await db.deleteTxn(id);
            }
          },
          icon: const Icon(PhosphorIconsRegular.trash),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

/// Bucket picker. With a merchant it answers for the payee (every payment
/// to it) unless "Apply to all" is turned off.
class _BudgetSection extends ConsumerStatefulWidget {
  const _BudgetSection({required this.view});
  final TxnView view;

  @override
  ConsumerState<_BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends ConsumerState<_BudgetSection> {
  var _applyAll = true;

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final t = v.txn;
    final db = ref.read(databaseProvider);
    final d = budgetDecision(v);
    final fixed = d.source == BudgetSource.transfer || d.source == BudgetSource.income;
    final merchant = t.merchant;
    final own = d.source == BudgetSource.manual || d.source == BudgetSource.payee;
    if (fixed) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: const Icon(PhosphorIconsRegular.target),
        title: const Text('Bucket'),
        subtitle: Text(budgetSourceLabel(v)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(PhosphorIconsRegular.target),
          title: const Text('Bucket'),
          subtitle: Text('${budgetSourceLabel(v)}. Only Everyday counts toward the budget.'),
        ),
        BucketPicker(
          value: d.bucket,
          onChanged: (b) async {
            await (merchant != null && _applyAll
                ? db.setTxnBucket(t.id, null).then((_) => db.setPayeeBucket(merchant, b))
                : db.setTxnBucket(t.id, b));
            if (b != Bucket.lending || !context.mounted) return;
            final note = await askLendingNote(context, t.note);
            if (note != null) await db.setNote(t.id, note.isEmpty ? null : note);
          },
        ),
        if (merchant != null)
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: _applyAll,
            onChanged: (on) => setState(() => _applyAll = on ?? true),
            title: Text('Apply to all $merchant'),
          ),
        if (own)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              onPressed: () async {
                await db.setTxnBucket(t.id, null);
                if (d.source == BudgetSource.payee && merchant != null) await db.setPayeeBucket(merchant, null);
              },
              child: Text(v.category == null ? 'Reset' : 'Reset to ${v.category!.name} default'),
            ),
          ),
      ],
    );
  }
}

/// Both payments side by side, each with its own message, so the user
/// can tell whether it is one payment reported twice.
class _DuplicatePanel extends ConsumerWidget {
  const _DuplicatePanel({required this.view, required this.otherId});
  final TxnView view;
  final int otherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = ref.watch(txnProvider(otherId)).value;
    final db = ref.read(databaseProvider);
    final id = view.txn.id;
    return AppCard(
      color: Palette.amber.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.copy, color: Palette.amber, size: 20),
              const SizedBox(width: 10),
              Text('Possible duplicate', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Same amount, close in time. If both messages describe one payment, merge them; '
            'if they are two payments, keep both.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          PaymentEvidence(view: view, label: 'This payment'),
          const SizedBox(height: 8),
          if (other == null)
            const Text('The matching transaction no longer exists.')
          else
            PaymentEvidence(view: other, label: 'Looks like'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => db.confirm(id), child: const Text('Keep both')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: other == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await db.mergeInto(id, otherId);
                        },
                  child: const Text('Merge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.message});
  final RawMessage message;

  @override
  Widget build(BuildContext context) {
    final icon = switch (message.source) {
      SourceKind.sms => PhosphorIconsFill.chatText,
      SourceKind.email => PhosphorIconsFill.envelopeSimple,
      SourceKind.manual => PhosphorIconsFill.pencilSimple,
      SourceKind.shortcut => PhosphorIconsFill.lightning,
      SourceKind.statement => PhosphorIconsFill.receipt,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(message.sender, style: context.text.labelLarge)),
                if (message.parseStatus == ParseStatus.merged)
                  const InfoPill(icon: PhosphorIconsBold.gitMerge, label: 'merged', color: Palette.mint),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(message.body, style: context.text.bodySmall?.copyWith(height: 1.45)),
            const SizedBox(height: 6),
            Text(
              dateTimeLabel(message.receivedAt),
              style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

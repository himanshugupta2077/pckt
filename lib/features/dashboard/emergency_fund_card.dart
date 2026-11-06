import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../data/db/database.dart';
import '../../providers.dart' show databaseProvider;
import '../../ui/amount_field.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_providers.dart' show planProvider;
import '../plan/plan_providers.dart' show emergencyHoldingsProvider;

/// Below the salary card: what the emergency fund holds against its goal,
/// and where it is kept. Not tied to the month; holdings are typed by hand.
/// Tap to change the goal or the holdings.
class EmergencyFundCard extends ConsumerWidget {
  const EmergencyFundCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(emergencyHoldingsProvider).value;
    final plan = ref.watch(planProvider).value;
    if (holdings == null || plan == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EmergencyFundView(
        holdings: holdings,
        goalMinor: plan.emergencyGoalMinor,
        onTap: () => showEmergencyFundSheet(context),
      ),
    );
  }
}

const emergencyAccent = Color(0xFF14A37F);

class EmergencyFundView extends StatelessWidget {
  const EmergencyFundView({super.key, required this.holdings, required this.goalMinor, this.onTap});

  final List<EmergencyHolding> holdings;
  final int? goalMinor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final saved = holdings.fold(0, (s, h) => s + h.amountMinor);
    final goal = goalMinor ?? 0;
    final ratio = goal <= 0 ? 0.0 : saved / goal;
    final muted = context.text.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final surface = context.theme.cardTheme.color ?? context.colors.surface;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Color.alphaBlend(emergencyAccent.withValues(alpha: context.isDark ? 0.10 : 0.07), surface),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(PhosphorIconsFill.shieldCheck, size: 18, color: emergencyAccent),
              const SizedBox(width: 8),
              Text('Emergency fund', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                money(saved),
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (goal > 0) Text('  of ${moneyCompact(goal)}', style: muted),
            ],
          ),
          if (goal > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1).toDouble(),
                      minHeight: 6,
                      color: emergencyAccent,
                      backgroundColor: emergencyAccent.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(ratio * 100).floor()}%',
                  style: context.text.labelLarge?.copyWith(color: emergencyAccent, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            holdings.isEmpty
                ? (goal > 0 ? 'Tap to add where it is kept, like an FD' : 'Tap to set a goal and add where it is kept')
                : [for (final h in holdings) '${h.name} ${moneyCompact(h.amountMinor)}'].join('  ·  '),
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The goal, each holding (tap to edit or remove), and Add.
Future<void> showEmergencyFundSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final holdings = ref.watch(emergencyHoldingsProvider).value ?? const <EmergencyHolding>[];
      final goal = ref.watch(planProvider).value?.emergencyGoalMinor;
      final saved = holdings.fold(0, (s, h) => s + h.amountMinor);
      final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Text(
                  'Emergency fund  ·  ${money(saved)}',
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text('Goal'),
                subtitle: Text(
                  goal == null
                      ? 'What the fund should hold in all'
                      : saved >= goal
                      ? 'Reached'
                      : '${money(goal - saved)} to go. The plan saves toward this as goal 1.',
                ),
                trailing: Text(goal == null ? 'Set' : money(goal), style: context.text.titleSmall),
                onTap: () => showEmergencyGoalDialog(context, ref, goal),
              ),
              const Divider(),
              if (holdings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Nothing added yet. Add each FD or fund it is kept in.', style: muted),
                ),
              for (final h in holdings)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(h.name),
                  trailing: Text(money(h.amountMinor), style: context.text.titleSmall),
                  onTap: () => showHoldingDialog(context, ref, h),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showHoldingDialog(context, ref, null),
                  icon: const Icon(PhosphorIconsBold.plus, size: 18),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

/// Adds, edits or removes one holding: a name and what it holds now.
Future<void> showHoldingDialog(BuildContext context, WidgetRef ref, EmergencyHolding? holding) async {
  final home = Currencies.home;
  final name = TextEditingController(text: holding?.name);
  final amount = TextEditingController(
    text: holding == null ? '' : amountInputText(holding.amountMinor, currency: home),
  );
  final db = ref.read(databaseProvider);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(holding == null ? 'Add to emergency fund' : 'Emergency fund'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: holding == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Where', hintText: 'e.g. FD, Sweep FD, Arbitrage fund'),
          ),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter(currency: home)],
            decoration: InputDecoration(labelText: 'Holds now', prefixText: '${currencySymbol(home)} '),
          ),
        ],
      ),
      actions: [
        if (holding != null)
          TextButton(
            onPressed: () async {
              await db.deleteEmergencyHolding(holding.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            final minor = parseAmountInput(amount.text, currency: home);
            if (name.text.trim().isEmpty || minor == null || minor < 0) return;
            await db.saveEmergencyHolding(id: holding?.id, name: name.text.trim(), amountMinor: minor);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  amount.dispose();
}

/// What the fund should hold in all. Empty clears it.
Future<void> showEmergencyGoalDialog(BuildContext context, WidgetRef ref, int? goalMinor) async {
  final home = Currencies.home;
  final amount = TextEditingController(text: goalMinor == null ? '' : amountInputText(goalMinor, currency: home));
  final db = ref.read(databaseProvider);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Emergency fund goal'),
      content: TextField(
        controller: amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountInputFormatter(currency: home)],
        decoration: InputDecoration(
          labelText: 'Goal in all',
          helperText: 'What the fund should hold, counting what it has now',
          prefixText: '${currencySymbol(home)} ',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            final minor = parseAmountInput(amount.text, currency: home);
            await db.setEmergencyGoal(minor == null || minor <= 0 ? null : minor);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  amount.dispose();
}

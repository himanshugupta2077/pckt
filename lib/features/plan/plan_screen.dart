import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/amount_field.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_providers.dart';
import 'plan_math.dart';
import 'plan_providers.dart';

String _monthYear(DateTime m) => DateFormat('MMM yyyy').format(m);

String _signed(int minor) => minor < 0 ? '−${money(-minor)}' : money(minor);

/// The monthly plan: what's planned to be left over after everything that
/// goes out each month. Saved as you type.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).value;
    final outcome = ref.watch(planOutcomeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: plan == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                if (outcome != null) _Outcome(outcome: outcome),
                const SizedBox(height: 20),
                _PlanInputs(plan: plan),
              ],
            ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.outcome});
  final PlanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planned left over', style: muted),
          const SizedBox(height: 4),
          Text(
            '${_signed(o.leftOver)}/month',
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: o.leftOver < 0 ? Palette.coral : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          for (final (from, amount) in o.emiFreed)
            Text('From ${_monthYear(from)}: +${money(amount)}/month', style: muted),
          const SizedBox(height: 12),
          _Line('Salary', o.salary),
          for (final e in o.emis) _Line(e.name, -e.amountMinor, detail: 'EMI'),
          o.everyday == null ? const _Note('Everyday', 'no budget set') : _Line('Everyday budget', -o.everyday!),
          _Line('Recurring budget', -o.fixed),
          _Average('Family and insurance', o.familyAvg.minor, o.familyAvg.months),
          _Line('Fund', -o.fund),
          if (o.investing > 0) _Line('Investing', -o.investing),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.minor, {this.detail});
  final String label;
  final int minor;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [if (detail != null) TextSpan(text: '  $detail', style: muted)],
              ),
              style: context.text.bodyMedium,
            ),
          ),
          Text(
            _signed(minor),
            style: context.text.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _Average extends StatelessWidget {
  const _Average(this.label, this.minor, this.months);
  final String label;
  final int minor;
  final int months;

  @override
  Widget build(BuildContext context) => months == 0
      ? _Note(label, 'no complete month yet')
      : _Line(label, -minor, detail: 'avg of $months month${months == 1 ? '' : 's'}');
}

class _Note extends StatelessWidget {
  const _Note(this.label, this.note);
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.bodyMedium)),
        Text(note, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    ),
  );
}

/// The monthly inputs (goals have their own tab). Controllers are filled once from the saved plan; every
/// change is written straight back.
class _PlanInputs extends ConsumerStatefulWidget {
  const _PlanInputs({required this.plan});
  final MonthlyPlan plan;

  @override
  ConsumerState<_PlanInputs> createState() => _PlanInputsState();
}

class _PlanInputsState extends ConsumerState<_PlanInputs> {
  late final _home = Currencies.home;
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    String text(int? minor) => minor == null || minor == 0 ? '' : amountInputText(minor, currency: _home);
    _c = {
      'salary': TextEditingController(text: text(p.salaryMinor)),
      'investing': TextEditingController(text: text(p.investingMinor)),
      'fund': TextEditingController(text: text(p.fundMinor)),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(PlanCompanion values) => ref.read(databaseProvider).savePlan(values);

  int? _amount(String key) => parseAmountInput(_c[key]!.text, currency: _home);

  Widget _field(String key, String label, void Function(int?) onChanged, {String? helper}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _c[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AmountInputFormatter(currency: _home)],
      onChanged: (_) => onChanged(_amount(key)),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixText: '${currencySymbol(_home)} ',
        suffixText: '/month',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Each month'),
        _field('salary', 'Take-home salary', (v) => _save(PlanCompanion(salaryMinor: Value(v ?? 0)))),
        const _EmiList(),
        const SizedBox(height: 8),
        _field(
          'investing',
          'Investing',
          (v) => _save(PlanCompanion(investingMinor: Value(v ?? 0))),
          helper: 'Not counting what you save for your goals',
        ),
        _field(
          'fund',
          'Fund',
          (v) => _save(PlanCompanion(fundMinor: Value(v ?? 0))),
          helper: 'Set aside for big and occasional buys',
        ),
      ],
    );
  }
}

/// The EMIs, each tappable to edit, and "Add EMI". Card EMIs never show up
/// as a message, so this list is where they come from.
class _EmiList extends ConsumerWidget {
  const _EmiList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emis = ref.watch(emisProvider).value ?? const <Emi>[];
    final month = monthStart(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in emis)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(e.name),
            subtitle: Text(
              e.lastMonth == null
                  ? 'Last month not set'
                  : emiActive(e, month)
                  ? 'Until ${_monthYear(e.lastMonth!)}'
                  : 'Ended ${_monthYear(e.lastMonth!)}',
            ),
            trailing: Text('${money(e.amountMinor)}/month', style: context.text.titleSmall),
            onTap: () => showEmiDialog(context, ref, e),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showEmiDialog(context, ref, null),
            icon: const Icon(PhosphorIconsBold.plus, size: 18),
            label: const Text('Add EMI'),
          ),
        ),
      ],
    );
  }
}

/// Adds or edits one EMI: name, amount per month, last month paid, and
/// whether it is a need or a want.
Future<void> showEmiDialog(BuildContext context, WidgetRef ref, Emi? emi) async {
  final home = Currencies.home;
  final name = TextEditingController(text: emi?.name);
  final amount = TextEditingController(text: emi == null ? '' : amountInputText(emi.amountMinor, currency: home));
  var last = emi?.lastMonth;
  var kind = emi?.spendKind ?? SpendKind.need;
  final db = ref.read(databaseProvider);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(emi == null ? 'Add EMI' : 'EMI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What for', hintText: 'e.g. MacBook, HDFC card'),
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter(currency: home)],
              decoration: InputDecoration(labelText: 'Per month', prefixText: '${currencySymbol(home)} '),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Last month paid'),
              trailing: Text(last == null ? 'Pick' : _monthYear(last!)),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: last ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 30),
                  initialDatePickerMode: DatePickerMode.year,
                  helpText: 'Pick any day in the month',
                );
                if (picked != null) setState(() => last = monthStart(picked));
              },
            ),
            Row(
              children: [
                const Expanded(child: Text('On the salary card')),
                SegmentedButton<SpendKind>(
                  segments: const [
                    ButtonSegment(value: SpendKind.need, label: Text('Need')),
                    ButtonSegment(value: SpendKind.want, label: Text('Want')),
                  ],
                  selected: {kind},
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  onSelectionChanged: (k) => setState(() => kind = k.first),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (emi != null)
            TextButton(
              onPressed: () async {
                await db.deleteEmi(emi.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final minor = parseAmountInput(amount.text, currency: home);
              if (name.text.trim().isEmpty || minor == null || minor <= 0) return;
              await db.saveEmi(
                id: emi?.id,
                name: name.text.trim(),
                amountMinor: minor,
                lastMonth: last,
                spendKind: kind,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  amount.dispose();
}

/// One line on Home that opens the plan.
class PlanLine extends ConsumerWidget {
  const PlanLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(planOutcomeProvider);
    if (o == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => context.push('/plan'),
        child: Row(
          children: [
            Expanded(
              child: Text('Planned left over', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              o.salary == 0 ? 'Set up' : '${_signed(o.leftOver)}/month',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: o.salary > 0 && o.leftOver < 0 ? Palette.coral : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsBold.caretRight, size: 18),
          ],
        ),
      ),
    );
  }
}

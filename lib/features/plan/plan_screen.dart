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
    final freed = o.emiFreedFrom;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planned left over', style: muted),
          const SizedBox(height: 4),
          Text(
            '${money(o.leftOver)}/month',
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: o.leftOver < 0 ? Palette.coral : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (freed != null) Text('From ${_monthYear(freed)}: +${money(o.emi)}/month', style: muted),
          const SizedBox(height: 12),
          _Line('Salary', o.salary),
          if (o.emi > 0) _Line('EMI', -o.emi),
          o.everyday == null ? const _Note('Everyday', 'no budget set') : _Line('Everyday budget', -o.everyday!),
          _Average('Fixed', o.fixedAvg.minor, o.fixedAvg.months),
          _Average('Family and insurance', o.familyAvg.minor, o.familyAvg.months),
          _Line('Fund', -o.fund),
          if (o.investing > 0) _Line('Investing', -o.investing),
          for (final g in o.goals)
            g.perMonth == null
                ? _Note('Goal ${g.index}', 'due now: ${money(g.stillToSave)}')
                : _Line('Goal ${g.index} by ${_monthYear(g.due)}', -g.perMonth!),
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
            minor < 0 ? '−${money(-minor)}' : money(minor),
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

/// The 11 inputs. Controllers are filled once from the saved plan; every
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
      'emi': TextEditingController(text: text(p.emiMinor)),
      'investing': TextEditingController(text: text(p.investingMinor)),
      'fund': TextEditingController(text: text(p.fundMinor)),
      'goal1': TextEditingController(text: text(p.goal1Minor)),
      'goal2': TextEditingController(text: text(p.goal2Minor)),
      'goal3': TextEditingController(text: text(p.goal3Minor)),
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

  Future<void> _pickMonth(DateTime? current, void Function(DateTime?) onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 40),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pick any day in the month',
    );
    if (picked != null) onPicked(monthStart(picked));
  }

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

  Widget _month(String label, DateTime? value, void Function(DateTime?) onPicked) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    title: Text(label),
    trailing: Text(
      value == null ? 'Pick' : _monthYear(value),
      style: context.text.titleSmall?.copyWith(color: context.colors.primary),
    ),
    onTap: () => _pickMonth(value, onPicked),
  );

  @override
  Widget build(BuildContext context) {
    // Read the live row for the month fields; amounts live in controllers.
    final p = ref.watch(planProvider).value ?? widget.plan;
    final goals = [(p.goal1Due, 'goal1'), (p.goal2Due, 'goal2'), (p.goal3Due, 'goal3')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Each month'),
        _field('salary', 'Take-home salary', (v) => _save(PlanCompanion(salaryMinor: Value(v ?? 0)))),
        _field('emi', 'EMI', (v) => _save(PlanCompanion(emiMinor: Value(v ?? 0)))),
        _month('EMI ends', p.emiEnds, (m) => _save(PlanCompanion(emiEnds: Value(m)))),
        const SizedBox(height: 8),
        _field(
          'investing',
          'Investing',
          (v) => _save(PlanCompanion(investingMinor: Value(v ?? 0))),
          helper: 'Not counting what you save for the goals below',
        ),
        _field(
          'fund',
          'Fund',
          (v) => _save(PlanCompanion(fundMinor: Value(v ?? 0))),
          helper: 'Set aside for big and occasional buys',
        ),
        const SizedBox(height: 8),
        const SectionHeader('Goals'),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Up to three, emergency fund first. Everyday, Fixed, Family and Insurance come from your budget and '
            'past months, so they aren\'t typed here.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        for (final (i, (due, key)) in goals.indexed) ...[
          TextField(
            controller: _c[key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter(currency: _home)],
            onChanged: (_) => _save(_goalAmount(i, _amount(key))),
            decoration: InputDecoration(
              labelText: i == 0 ? 'Goal 1: still to save (emergency fund)' : 'Goal ${i + 1}: still to save',
              prefixText: '${currencySymbol(_home)} ',
            ),
          ),
          _month('Goal ${i + 1} by', due, (m) => _save(_goalDue(i, m))),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static PlanCompanion _goalAmount(int i, int? v) => switch (i) {
    0 => PlanCompanion(goal1Minor: Value(v)),
    1 => PlanCompanion(goal2Minor: Value(v)),
    _ => PlanCompanion(goal3Minor: Value(v)),
  };

  static PlanCompanion _goalDue(int i, DateTime? m) => switch (i) {
    0 => PlanCompanion(goal1Due: Value(m)),
    1 => PlanCompanion(goal2Due: Value(m)),
    _ => PlanCompanion(goal3Due: Value(m)),
  };
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
              o.salary == 0 ? 'Set up' : '${money(o.leftOver)}/month',
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

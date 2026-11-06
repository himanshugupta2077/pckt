import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/amount_field.dart';
import '../../ui/widgets.dart';
import '../budgets/budget_providers.dart';
import '../plan/plan_math.dart' show emergencyStillToSave;
import '../plan/plan_providers.dart';
import '../plan/plan_screen.dart' show PlanLine;

String _monthYear(DateTime m) => DateFormat('MMM yyyy').format(m);

/// Up to three goals: what each needs per month to be on time, and how
/// that compares with the plan's left over. Saved as you type.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).value;
    final outcome = ref.watch(planOutcomeProvider);
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: plan == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Goals', style: context.text.headlineSmall),
                  ),
                  // The plan's monthly left over, which the goals are paid from.
                  const PlanLine(),
                  const SizedBox(height: 12),
                  if (outcome != null && outcome.goals.isNotEmpty)
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Goals need', style: muted),
                          Text(
                            '${money(outcome.goalsPerMonth)}/month',
                            style: context.text.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (outcome.salary > 0)
                            Text(
                              outcome.leftOver >= outcome.goalsPerMonth
                                  ? 'Planned left over (${money(outcome.leftOver)}) covers it'
                                  : 'Planned left over is ${money(outcome.leftOver)}: '
                                        '${money(outcome.goalsPerMonth - outcome.leftOver)}/month short',
                              style: muted?.copyWith(
                                color: outcome.leftOver >= outcome.goalsPerMonth ? null : Palette.coral,
                              ),
                            ),
                          const SizedBox(height: 10),
                          for (final g in outcome.goals)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Goal ${g.index}: ${money(g.stillToSave)} by ${_monthYear(g.due)}',
                                      style: context.text.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    g.perMonth == null ? 'due now' : '${money(g.perMonth!)}/month',
                                    style: context.text.bodyMedium?.copyWith(
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _GoalInputs(plan: plan),
                ],
              ),
      ),
    );
  }
}

class _GoalInputs extends ConsumerStatefulWidget {
  const _GoalInputs({required this.plan});
  final MonthlyPlan plan;

  @override
  ConsumerState<_GoalInputs> createState() => _GoalInputsState();
}

class _GoalInputsState extends ConsumerState<_GoalInputs> {
  late final _home = Currencies.home;
  late final List<TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    String text(int? minor) => minor == null || minor == 0 ? '' : amountInputText(minor, currency: _home);
    _c = [
      for (final m in [p.goal1Minor, p.goal2Minor, p.goal3Minor]) TextEditingController(text: text(m)),
    ];
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(PlanCompanion values) => ref.read(databaseProvider).savePlan(values);

  Future<void> _pickMonth(int i, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 40),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pick any day in the month',
    );
    if (picked != null) _save(_goalDue(i, monthStart(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(planProvider).value ?? widget.plan;
    final dues = [p.goal1Due, p.goal2Due, p.goal3Due];
    final saved = ref.watch(emergencySavedProvider);
    final fromCard = saved == null ? null : emergencyStillToSave(p, saved);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Up to three, emergency fund first: what is still to save and by when.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        for (final (i, due) in dues.indexed) ...[
          if (i == 0 && fromCard != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Goal 1: still to save (emergency fund)'),
              subtitle: const Text('From the Emergency fund card on Home: its goal less what it holds'),
              trailing: Text(money(fromCard), style: context.text.titleSmall),
            )
          else
            TextField(
              controller: _c[i],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter(currency: _home)],
              onChanged: (t) => _save(_goalAmount(i, parseAmountInput(t, currency: _home))),
              decoration: InputDecoration(
                labelText: i == 0 ? 'Goal 1: still to save (emergency fund)' : 'Goal ${i + 1}: still to save',
                prefixText: '${currencySymbol(_home)} ',
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text('Goal ${i + 1} by'),
            trailing: Text(
              due == null ? 'Pick' : _monthYear(due),
              style: context.text.titleSmall?.copyWith(color: context.colors.primary),
            ),
            onTap: () => _pickMonth(i, due),
          ),
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

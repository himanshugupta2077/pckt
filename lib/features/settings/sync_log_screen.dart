import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/backup/server_backup.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../ui/widgets.dart';
import '../activity/transaction_sheet.dart';
import 'server_backup.dart';

/// The Mac's latest check, read from the server. Null when it hasn't run yet.
final _analysisProvider = FutureProvider.autoDispose<Map<String, Object?>?>((ref) async {
  final uri = serverAnalysisUri(ref.watch(serverBackupProvider.select((s) => s.address)));
  if (uri == null) return null;
  final client = serverBackupClient();
  try {
    return await fetchAnalysis(client, uri);
  } finally {
    client.close();
  }
});

String _at(DateTime t) => DateFormat('d MMM, h:mm a').format(t);

/// Settings → Data → Sync log: the Mac's latest check, then every upload, newest first.
class SyncLogScreen extends ConsumerWidget {
  const SyncLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(syncLogProvider).value ?? const <SyncLogData>[];
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Sync log')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_analysisProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'The phone uploads its data daily at 12:00 and tries again until 22:00 if that fails. '
              'The Mac then checks it with Claude and sends back what it found.',
              style: muted,
            ),
            const SizedBox(height: 16),
            const SectionHeader('Mac check'),
            const _AnalysisCard(),
            const SizedBox(height: 20),
            const SectionHeader('Uploads'),
            if (log.isEmpty) Text('Nothing uploaded yet.', style: muted),
            for (final l in log)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  l.ok ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.warningCircle,
                  color: l.ok ? Palette.mint : Palette.amber,
                ),
                title: Text('${_at(l.at)}  ·  ${_triggerLabel(l.trigger)}'),
                subtitle: Text(
                  l.ok ? '${l.transactions ?? 0} payments sent' : l.error ?? 'Failed',
                  style: l.ok ? null : const TextStyle(color: Palette.amber),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _triggerLabel(String t) => switch (t) {
    'daily' => 'Daily',
    'app' => 'On opening',
    _ => 'By hand',
  };
}

class _AnalysisCard extends ConsumerWidget {
  const _AnalysisCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return ref
        .watch(_analysisProvider)
        .when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          error: (_, _) => Text("Couldn't reach the server. Pull down to try again.", style: muted),
          data: (r) {
            if (r == null) return Text('The Mac has not checked anything yet.', style: muted);
            final ran = DateTime.tryParse('${r['ranAt']}')?.toLocal();
            final ok = r['ok'] == true;
            final suggestions = (r['suggestions'] as List? ?? const []).whereType<Map>().toList();
            final gaps = (r['gaps'] as List? ?? const []).whereType<String>().toList();
            return AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [if (ran != null) _at(ran), ok ? 'done' : 'failed'].join('  ·  '),
                    style: muted?.copyWith(color: ok ? null : Palette.amber),
                  ),
                  const SizedBox(height: 6),
                  Text('${r['summary'] ?? ''}', style: context.text.bodyMedium),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('To look at', style: context.text.titleSmall),
                    for (final s in suggestions) _Suggestion(s),
                  ],
                  if (gaps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Missing or doubtful', style: context.text.titleSmall),
                    for (final g in gaps)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(g, style: context.text.bodyMedium),
                      ),
                  ],
                ],
              ),
            );
          },
        );
  }
}

class _Suggestion extends ConsumerWidget {
  const _Suggestion(this.s);

  final Map s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = s['amount'] is num
        ? '₹${NumberFormat.decimalPattern('en_IN').format((s['amount'] as num).round())}'
        : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text([s['merchant'] ?? 'Payment', amount, if (s['date'] != null) s['date']].join('  ·  ')),
      subtitle: Text('${s['suggest'] ?? ''}\n${s['why'] ?? ''}'),
      isThreeLine: true,
      onTap: () async {
        final txn = s['txnId'];
        if (txn is! int) return;
        final id = await ref.read(databaseProvider).findTxn(txn, s['smsId'] is int ? s['smsId'] as int : null);
        if (!context.mounted) return;
        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That payment is no longer here')));
          return;
        }
        await showTransactionSheet(context, id);
      },
    );
  }
}

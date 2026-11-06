import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/backup/data_export.dart';
import 'package:pckt/data/backup/server_backup.dart';

import 'budget_test.dart' show memoryDb;

void main() {
  test('only https addresses, with the backup path appended', () {
    expect(serverBackupUri('https://box.example.ts.net').toString(), 'https://box.example.ts.net/api/pckt/backup');
    expect(serverBackupUri(' https://box.example.ts.net/ ').toString(), 'https://box.example.ts.net/api/pckt/backup');
    expect(serverBackupUri('http://box.example.ts.net'), isNull);
    expect(serverBackupUri('box.example.ts.net'), isNull);
    expect(serverBackupUri(''), isNull);
  });

  test('due when nothing went up since the latest 12:00, and an hour after a failed try', () {
    expect(syncSlot(DateTime(2026, 11, 6, 9)), DateTime(2026, 11, 5, 12));
    expect(syncSlot(DateTime(2026, 11, 6, 12)), DateTime(2026, 11, 6, 12));
    final now = DateTime(2026, 11, 6, 14);
    expect(isServerBackupDue(now: now), isTrue);
    expect(isServerBackupDue(lastOk: DateTime(2026, 11, 6, 12, 5), now: now), isFalse);
    expect(isServerBackupDue(lastOk: DateTime(2026, 11, 6, 11), now: now), isTrue);
    // Before noon, yesterday's upload is enough.
    expect(isServerBackupDue(lastOk: DateTime(2026, 11, 5, 13), now: DateTime(2026, 11, 6, 9)), isFalse);
    final failedJustNow = now.subtract(const Duration(minutes: 10));
    expect(isServerBackupDue(lastOk: null, lastAttempt: failedJustNow, now: now), isFalse);
    expect(isServerBackupDue(lastAttempt: now.subtract(const Duration(hours: 2)), now: now), isTrue);
    expect(
      serverAnalysisUri('https://box.example.ts.net/').toString(),
      'https://box.example.ts.net/api/pckt/analysis/latest',
    );
  });

  test('uploads the backup as JSON and reads the answer', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final seen = <(String, String, String, String)>[];
    var status = 200;
    server.listen((req) async {
      final body = await utf8.decodeStream(req);
      seen.add((req.method, req.uri.toString(), req.headers.contentType?.mimeType ?? '', body));
      req.response.statusCode = status;
      await req.response.close();
    });
    final uri = Uri.parse('http://127.0.0.1:${server.port}$serverBackupPath');
    final client = serverBackupClient();
    try {
      final saved = await uploadServerBackup(client, uri, '{"format":"pckt-backup"}');
      expect(saved.outcome, ServerBackupOutcome.saved);
      expect(seen.single, ('PUT', '/api/pckt/backup', 'application/json', '{"format":"pckt-backup"}'));

      status = 409;
      expect((await uploadServerBackup(client, uri, '{}')).outcome, ServerBackupOutcome.serverHasMore);
      status = 200;
      await uploadServerBackup(client, uri, '{}', force: true);
      expect(seen.last.$2, '/api/pckt/backup?force=1');
      status = 403;
      final refused = await uploadServerBackup(client, uri, '{}');
      expect((refused.outcome, refused.message), (ServerBackupOutcome.failed, 'The server refused this device'));
    } finally {
      client.close();
      await server.close(force: true);
    }
    final offline = await uploadServerBackup(serverBackupClient(), uri, '{}');
    expect((offline.outcome, offline.message), (ServerBackupOutcome.failed, "Couldn't reach the server"));
  });

  test('each upload is logged, the log keeps 100 rows and stays out of backups', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var status = 200;
    server.listen((req) async {
      await utf8.decodeStream(req);
      req.response.statusCode = status;
      await req.response.close();
    });
    final uri = Uri.parse('http://127.0.0.1:${server.port}$serverBackupPath');
    await backUpAndLog(db, uri, trigger: 'daily');
    status = 409;
    await backUpAndLog(db, uri, trigger: 'app');
    final log = await db.watchSyncLog().first;
    expect(
      [for (final l in log) (l.trigger, l.ok, l.error)],
      [('app', false, serverHasMoreMessage), ('daily', true, null)],
    );
    expect((await db.lastSync(okOnly: true))!.trigger, 'daily');
    expect(log.last.transactions, 0);

    for (var i = 0; i < 120; i++) {
      await db.addSyncLog(
        trigger: 'app',
        ok: true,
        at: DateTime(2026, 1, 1).add(Duration(minutes: i)),
      );
    }
    expect(await db.watchSyncLog().first, hasLength(100));
    final backup = jsonDecode(await DataExport(db).backupJson()) as Map<String, Object?>;
    expect((backup['tables']! as Map).containsKey('sync_log'), isFalse);
    await DataExport(db).restore(jsonEncode(backup));
    expect(await db.watchSyncLog().first, hasLength(100));
  });

  test('a suggestion finds its payment again through the message', () async {
    final db = memoryDb();
    addTearDown(db.close);
    expect(await db.findTxn(999, null), isNull);
    expect(await db.findTxn(999, 12345), isNull);
  });
}

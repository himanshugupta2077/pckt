import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pckt/data/backup/server_backup.dart';

void main() {
  test('only https addresses, with the backup path appended', () {
    expect(serverBackupUri('https://box.example.ts.net').toString(), 'https://box.example.ts.net/api/pckt/backup');
    expect(serverBackupUri(' https://box.example.ts.net/ ').toString(), 'https://box.example.ts.net/api/pckt/backup');
    expect(serverBackupUri('http://box.example.ts.net'), isNull);
    expect(serverBackupUri('box.example.ts.net'), isNull);
    expect(serverBackupUri(''), isNull);
  });

  test('due once every 20 hours, and an hour after a failed try', () {
    final now = DateTime(2026, 11, 6, 9);
    expect(isServerBackupDue(now: now), isTrue);
    expect(isServerBackupDue(lastOk: now.subtract(const Duration(hours: 19)), now: now), isFalse);
    expect(isServerBackupDue(lastOk: now.subtract(const Duration(hours: 21)), now: now), isTrue);
    final failedJustNow = now.subtract(const Duration(minutes: 10));
    expect(isServerBackupDue(lastOk: null, lastAttempt: failedJustNow, now: now), isFalse);
    expect(isServerBackupDue(lastAttempt: now.subtract(const Duration(hours: 2)), now: now), isTrue);
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
}

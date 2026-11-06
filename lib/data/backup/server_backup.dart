import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../db/database.dart';
import 'data_export.dart';

/// Uploading the full JSON backup ([DataExport.backupJson]) to the user's own server: a
/// Toolkit box reached over Tailscale. The server keeps dated copies and refuses (409) an
/// upload with far fewer transactions or rules than its newest one, so a wiped phone can't
/// replace a good backup without being asked; [force] sends it anyway.
const serverBackupPath = '/api/pckt/backup';

/// The upload URL for [address] (e.g. `https://toolkit.example.ts.net`), or null if it isn't
/// an https address. Plain http is refused: the backup holds every bank message.
Uri? serverBackupUri(String address) {
  final uri = Uri.tryParse(address.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  final base = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
  return uri.replace(path: '$base$serverBackupPath', query: null, fragment: null);
}

/// Where the Mac's daily analysis of the backups is read from.
const serverAnalysisPath = '/api/pckt/analysis/latest';

Uri? serverAnalysisUri(String address) {
  final backup = serverBackupUri(address);
  return backup?.replace(
    path: '${backup.path.substring(0, backup.path.length - serverBackupPath.length)}$serverAnalysisPath',
  );
}

/// The daily upload is due at 12:00. [now]'s slot is the latest 12:00 at or before it.
DateTime syncSlot(DateTime now) {
  final noon = DateTime(now.year, now.month, now.day, 12);
  return now.isBefore(noon) ? noon.subtract(const Duration(days: 1)) : noon;
}

/// Due when nothing has been saved since the latest 12:00, and an hour has passed since
/// the last try (offline, Tailscale off).
bool isServerBackupDue({DateTime? lastOk, DateTime? lastAttempt, required DateTime now}) =>
    (lastOk == null || lastOk.isBefore(syncSlot(now))) &&
    (lastAttempt == null || now.difference(lastAttempt) >= const Duration(hours: 1));

enum ServerBackupOutcome { saved, serverHasMore, failed }

class ServerBackupResult {
  const ServerBackupResult(this.outcome, [this.message]);
  final ServerBackupOutcome outcome;

  /// Why it failed, short and user-facing.
  final String? message;
}

/// Logged when the server refused a much smaller backup; the Settings tile then offers to replace it.
const serverHasMoreMessage = 'The server has a bigger backup. Tap to replace it.';

http.Client serverBackupClient() => IOClient(HttpClient()..connectionTimeout = const Duration(seconds: 5));

Future<ServerBackupResult> uploadServerBackup(http.Client client, Uri uri, String json, {bool force = false}) async {
  try {
    final res = await client
        .put(
          force ? uri.replace(queryParameters: {'force': '1'}) : uri,
          headers: {'Content-Type': 'application/json'},
          body: utf8.encode(json),
        )
        .timeout(const Duration(seconds: 60));
    return switch (res.statusCode) {
      200 => const ServerBackupResult(ServerBackupOutcome.saved),
      409 => const ServerBackupResult(ServerBackupOutcome.serverHasMore, serverHasMoreMessage),
      403 => const ServerBackupResult(ServerBackupOutcome.failed, 'The server refused this device'),
      413 => const ServerBackupResult(ServerBackupOutcome.failed, 'The backup is too large for the server'),
      final code => ServerBackupResult(ServerBackupOutcome.failed, 'Server error $code'),
    };
  } on Exception {
    return const ServerBackupResult(ServerBackupOutcome.failed, "Couldn't reach the server");
  }
}

/// Builds the backup from [db], uploads it and writes the result to the sync log. [trigger] is
/// daily (the 12:00 background job), app (on opening the app) or manual.
Future<ServerBackupResult> backUpAndLog(AppDatabase db, Uri uri, {required String trigger, bool force = false}) async {
  final client = serverBackupClient();
  String? json;
  int? txns;
  ServerBackupResult result;
  try {
    final data = await DataExport(db).backup();
    txns = ((data['tables']! as Map)['transactions'] as List?)?.length;
    json = DataExport.encodeBackup(data);
    result = await uploadServerBackup(client, uri, json, force: force);
  } catch (e) {
    result = const ServerBackupResult(ServerBackupOutcome.failed, "Couldn't make the backup");
  } finally {
    client.close();
  }
  await db.addSyncLog(
    trigger: trigger,
    ok: result.outcome == ServerBackupOutcome.saved,
    transactions: txns,
    bytes: json == null ? null : utf8.encode(json).length,
    error: result.message,
  );
  return result;
}

/// The Mac's latest analysis report, or null if there is none yet. Throws when the server
/// can't be reached.
Future<Map<String, Object?>?> fetchAnalysis(http.Client client, Uri uri) async {
  final res = await client.get(uri).timeout(const Duration(seconds: 20));
  if (res.statusCode == 404) return null;
  if (res.statusCode != 200) throw HttpException('Server error ${res.statusCode}');
  final v = jsonDecode(utf8.decode(res.bodyBytes));
  return v is Map<String, Object?> ? v : null;
}

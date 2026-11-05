import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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

/// Automatic backups run at most once every 20 hours, and after a failure (offline,
/// Tailscale off) wait an hour before trying again.
bool isServerBackupDue({DateTime? lastOk, DateTime? lastAttempt, required DateTime now}) =>
    (lastOk == null || now.difference(lastOk) >= const Duration(hours: 20)) &&
    (lastAttempt == null || now.difference(lastAttempt) >= const Duration(hours: 1));

enum ServerBackupOutcome { saved, serverHasMore, failed }

class ServerBackupResult {
  const ServerBackupResult(this.outcome, [this.message]);
  final ServerBackupOutcome outcome;

  /// Why it failed, short and user-facing.
  final String? message;
}

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
      409 => const ServerBackupResult(ServerBackupOutcome.serverHasMore),
      403 => const ServerBackupResult(ServerBackupOutcome.failed, 'The server refused this device'),
      413 => const ServerBackupResult(ServerBackupOutcome.failed, 'The backup is too large for the server'),
      final code => ServerBackupResult(ServerBackupOutcome.failed, 'Server error $code'),
    };
  } on Exception {
    return const ServerBackupResult(ServerBackupOutcome.failed, "Couldn't reach the server");
  }
}

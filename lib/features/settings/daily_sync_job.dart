import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/currency.dart';
import '../../data/backup/server_backup.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import 'server_backup.dart' show ServerBackupKeys;

/// The 12:00 upload, run by DailySyncWorker in a headless engine. New SMS are already
/// stored by the alert check as they arrive, so this only uploads. It tells the worker
/// how it went: ok, stop (the server has a bigger backup; retrying won't help), off
/// (backups are switched off) or retry.
const _channel = MethodChannel('pckt/sync');

Future<void> runDailySyncJob() async {
  var outcome = 'retry';
  AppDatabase? db;
  try {
    final prefs = await SharedPreferences.getInstance();
    final uri = serverBackupUri(prefs.getString(ServerBackupKeys.address) ?? '');
    if (!(prefs.getBool(ServerBackupKeys.on) ?? false) || uri == null) {
      outcome = 'off';
      return;
    }
    Currencies.home = prefs.getString(PrefKeys.homeCurrency) ?? 'INR';
    db = openShownDatabase();
    final lastOk = (await db.lastSync(okOnly: true))?.at;
    if (lastOk != null && !lastOk.isBefore(syncSlot(DateTime.now()))) {
      // The app already uploaded since 12:00.
      outcome = 'ok';
      return;
    }
    final result = await backUpAndLog(db, uri, trigger: 'daily');
    outcome = switch (result.outcome) {
      ServerBackupOutcome.saved => 'ok',
      ServerBackupOutcome.serverHasMore => 'stop',
      ServerBackupOutcome.failed => 'retry',
    };
  } catch (e, st) {
    debugPrint('Daily sync failed: $e\n$st');
  } finally {
    await db?.close();
    try {
      await _channel.invokeMethod('result', outcome);
    } catch (_) {}
  }
}

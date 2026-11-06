import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/backup/server_backup.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

abstract final class ServerBackupKeys {
  static const on = 'backup.server.on';
  static const address = 'backup.server.address';
}

/// Talks to the native daily job (DailySyncWorker): [ensureDailySync] keeps one queued for
/// the next 12:00, [cancelDailySync] stops it.
const _syncChannel = MethodChannel('pckt/sync');

Future<void> ensureDailySync() async {
  try {
    await _syncChannel.invokeMethod('ensure');
  } on MissingPluginException {
    // Not on Android.
  }
}

Future<void> cancelDailySync() async {
  try {
    await _syncChannel.invokeMethod('cancel');
  } on MissingPluginException {
    // Not on Android.
  }
}

class ServerBackupState {
  const ServerBackupState({this.on = false, this.address = '', this.running = false});

  final bool on;
  final String address;
  final bool running;
}

/// Daily backup to the user's own server, off by default. A background job uploads at
/// 12:00 and tries again later that day if it fails; opening the app uploads too when
/// nothing went up since the latest 12:00. Every try is in the sync log, which is also
/// what the due check and the Settings tile read: the background job writes it through
/// its own connection, so saved settings would be stale here.
class ServerBackupController extends Notifier<ServerBackupState> {
  @override
  ServerBackupState build() {
    final p = ref.read(prefsProvider);
    return ServerBackupState(
      on: p.getBool(ServerBackupKeys.on) ?? false,
      address: p.getString(ServerBackupKeys.address) ?? '',
    );
  }

  Future<void> setOn(bool on) async {
    await ref.read(prefsProvider).setBool(ServerBackupKeys.on, on);
    state = ServerBackupState(on: on, address: state.address);
    if (on) {
      await ensureDailySync();
      await backUpNow(trigger: 'manual');
    } else {
      await cancelDailySync();
    }
  }

  /// Returns false if [address] isn't an https address.
  Future<bool> setAddress(String address) async {
    if (serverBackupUri(address) == null) return false;
    await ref.read(prefsProvider).setString(ServerBackupKeys.address, address.trim());
    state = ServerBackupState(on: state.on, address: address.trim(), running: state.running);
    return true;
  }

  Future<void> backUpIfDue() async {
    if (!state.on) return;
    await ensureDailySync();
    final db = ref.read(databaseProvider);
    if (!isServerBackupDue(
      lastOk: (await db.lastSync(okOnly: true))?.at,
      lastAttempt: (await db.lastSync())?.at,
      now: DateTime.now(),
    )) {
      return;
    }
    await backUpNow(trigger: 'app');
  }

  /// [force] replaces a server backup that has more data. True once the
  /// server has saved it.
  Future<bool> backUpNow({bool force = false, String trigger = 'manual'}) async {
    final uri = serverBackupUri(state.address);
    if (state.running || uri == null) return false;
    state = ServerBackupState(on: state.on, address: state.address, running: true);
    try {
      final result = await backUpAndLog(ref.read(databaseProvider), uri, trigger: trigger, force: force);
      return result.outcome == ServerBackupOutcome.saved;
    } finally {
      state = ServerBackupState(on: state.on, address: state.address);
    }
  }
}

final serverBackupProvider = NotifierProvider<ServerBackupController, ServerBackupState>(ServerBackupController.new);

final syncLogProvider = StreamProvider<List<SyncLogData>>((ref) => ref.watch(databaseProvider).watchSyncLog());

/// Settings → Data: the switch, the server address and how the last backup went.
class ServerBackupTiles extends ConsumerWidget {
  const ServerBackupTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(serverBackupProvider);
    final ctrl = ref.read(serverBackupProvider.notifier);
    final log = ref.watch(syncLogProvider).value ?? const <SyncLogData>[];
    final last = log.firstOrNull;
    final lastOk = log.where((l) => l.ok).firstOrNull;
    final serverHasMore = last?.error == serverHasMoreMessage;
    final warn = s.on && last != null && !last.ok;
    String at(DateTime t) => DateFormat('d MMM, h:mm a').format(t);
    final status = switch (s) {
      ServerBackupState(running: true) => 'Backing up…',
      ServerBackupState(on: false) => 'Off. Sends the full backup to your own server daily at 12:00.',
      _ when warn => '${last.error ?? 'Failed'}${lastOk == null ? '' : ' · last good ${at(lastOk.at)}'}',
      _ when lastOk != null => 'Last backup ${at(lastOk.at)}',
      _ => 'No backup yet',
    };
    return Column(
      children: [
        ListTile(
          leading: const Icon(PhosphorIconsRegular.hardDrives),
          title: const Text('Back up to server'),
          subtitle: Text(status, style: warn ? const TextStyle(color: Palette.amber) : null),
          onTap: s.on && s.address.isNotEmpty ? () => ctrl.backUpNow(force: serverHasMore) : null,
          trailing: Switch(
            value: s.on,
            onChanged: (on) async {
              if (on && s.address.isEmpty && !await _editAddress(context, ref)) return;
              await ctrl.setOn(on);
            },
          ),
        ),
        if (s.on)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: const Text('Server address'),
            subtitle: Text(s.address),
            onTap: () => _editAddress(context, ref),
          ),
        if (s.on)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: const Text('Sync log'),
            subtitle: const Text('Uploads and the Mac\'s daily check'),
            trailing: const Icon(PhosphorIconsBold.caretRight, size: 16),
            onTap: () => context.push('/settings/sync-log'),
          ),
      ],
    );
  }
}

Future<bool> _editAddress(BuildContext context, WidgetRef ref) async {
  final ctrl = TextEditingController(text: ref.read(serverBackupProvider).address);
  final saved = await showDialog<bool>(
    context: context,
    builder: (c) {
      String? error;
      return StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Server address'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://toolkit.your-tailnet.ts.net',
              helperText: 'Your own server, over Tailscale. https only.',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (await ref.read(serverBackupProvider.notifier).setAddress(ctrl.text)) {
                  if (c.mounted) Navigator.pop(c, true);
                } else {
                  setState(() => error = 'Use an https:// address');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  ctrl.dispose();
  return saved ?? false;
}

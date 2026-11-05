import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/icons.dart';
import '../../core/theme/palette.dart';
import '../../data/backup/server_backup.dart';
import '../../providers.dart';
import 'data_section.dart' show dataExportProvider;

abstract final class ServerBackupKeys {
  static const on = 'backup.server.on';
  static const address = 'backup.server.address';
  static const lastOk = 'backup.server.lastOkMillis';
  static const lastAttempt = 'backup.server.lastAttemptMillis';
  static const lastError = 'backup.server.lastError';
  static const serverHasMore = 'backup.server.serverHasMore';
}

class ServerBackupState {
  const ServerBackupState({
    this.on = false,
    this.address = '',
    this.lastOk,
    this.lastError,
    this.serverHasMore = false,
    this.running = false,
  });

  final bool on;
  final String address;
  final DateTime? lastOk;
  final String? lastError;

  /// The server refused the last upload because its newest backup has far more data.
  final bool serverHasMore;
  final bool running;
}

/// Daily backup to the user's own server, off by default. Runs after the SMS sync on app
/// resume when due; failures only show in the Settings tile.
class ServerBackupController extends Notifier<ServerBackupState> {
  @override
  ServerBackupState build() {
    final p = ref.read(prefsProvider);
    DateTime? at(String k) => switch (p.getInt(k)) {
      null => null,
      final ms => DateTime.fromMillisecondsSinceEpoch(ms),
    };
    return ServerBackupState(
      on: p.getBool(ServerBackupKeys.on) ?? false,
      address: p.getString(ServerBackupKeys.address) ?? '',
      lastOk: at(ServerBackupKeys.lastOk),
      lastError: p.getString(ServerBackupKeys.lastError),
      serverHasMore: p.getBool(ServerBackupKeys.serverHasMore) ?? false,
    );
  }

  ServerBackupState _copy({bool? on, String? address, bool? running}) => ServerBackupState(
    on: on ?? state.on,
    address: address ?? state.address,
    lastOk: state.lastOk,
    lastError: state.lastError,
    serverHasMore: state.serverHasMore,
    running: running ?? state.running,
  );

  Future<void> setOn(bool on) async {
    await ref.read(prefsProvider).setBool(ServerBackupKeys.on, on);
    state = _copy(on: on);
    if (on) await backUpNow();
  }

  /// Returns false if [address] isn't an https address.
  Future<bool> setAddress(String address) async {
    if (serverBackupUri(address) == null) return false;
    await ref.read(prefsProvider).setString(ServerBackupKeys.address, address.trim());
    state = _copy(address: address.trim());
    return true;
  }

  Future<void> backUpIfDue() async {
    final last = ref.read(prefsProvider).getInt(ServerBackupKeys.lastAttempt);
    if (!state.on ||
        !isServerBackupDue(
          lastOk: state.lastOk,
          lastAttempt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
          now: DateTime.now(),
        )) {
      return;
    }
    await backUpNow();
  }

  /// [force] replaces a server backup that has more data.
  Future<void> backUpNow({bool force = false}) async {
    final uri = serverBackupUri(state.address);
    if (state.running || uri == null) return;
    state = _copy(running: true);
    final prefs = ref.read(prefsProvider);
    final now = DateTime.now();
    await prefs.setInt(ServerBackupKeys.lastAttempt, now.millisecondsSinceEpoch);
    final client = serverBackupClient();
    ServerBackupResult result;
    try {
      final json = await ref.read(dataExportProvider).backupJson();
      result = await uploadServerBackup(client, uri, json, force: force);
    } catch (e) {
      debugPrint('Server backup failed: $e');
      result = const ServerBackupResult(ServerBackupOutcome.failed, "Couldn't make the backup");
    } finally {
      client.close();
    }
    final ok = result.outcome == ServerBackupOutcome.saved;
    final more = result.outcome == ServerBackupOutcome.serverHasMore;
    if (ok) await prefs.setInt(ServerBackupKeys.lastOk, now.millisecondsSinceEpoch);
    await prefs.setBool(ServerBackupKeys.serverHasMore, more);
    if (result.message == null) {
      await prefs.remove(ServerBackupKeys.lastError);
    } else {
      await prefs.setString(ServerBackupKeys.lastError, result.message!);
    }
    state = ServerBackupState(
      on: state.on,
      address: state.address,
      lastOk: ok ? now : state.lastOk,
      lastError: result.message,
      serverHasMore: more,
    );
  }
}

final serverBackupProvider = NotifierProvider<ServerBackupController, ServerBackupState>(ServerBackupController.new);

/// Settings → Data: the switch, the server address and how the last backup went.
class ServerBackupTiles extends ConsumerWidget {
  const ServerBackupTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(serverBackupProvider);
    final ctrl = ref.read(serverBackupProvider.notifier);
    final status = switch (s) {
      ServerBackupState(running: true) => 'Backing up…',
      ServerBackupState(on: false) => 'Off. Sends the full backup to your own server once a day.',
      ServerBackupState(serverHasMore: true) => 'The server has a bigger backup. Tap to replace it.',
      ServerBackupState(lastError: final e?) => e,
      ServerBackupState(lastOk: final t?) => 'Last backup ${DateFormat('d MMM, h:mm a').format(t)}',
      _ => 'No backup yet',
    };
    return Column(
      children: [
        ListTile(
          leading: const Icon(PhosphorIconsRegular.hardDrives),
          title: const Text('Back up to server'),
          subtitle: Text(
            status,
            style: s.on && (s.serverHasMore || s.lastError != null) ? const TextStyle(color: Palette.amber) : null,
          ),
          onTap: s.on && s.address.isNotEmpty ? () => ctrl.backUpNow(force: s.serverHasMore) : null,
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

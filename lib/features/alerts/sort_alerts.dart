import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/currency.dart';
import '../../data/db/database.dart';
import '../../ingestion/ingestion_service.dart';
import '../../ingestion/sms/sms_source.dart';
import '../../providers.dart';
import '../budgets/in_budget.dart';

/// "₹250 to Ramesh K: which bucket?" notifications.
///
/// A bank SMS gets the plain native alert at once (SmsAlertReceiver), then a
/// WorkManager job (SortAlertWorker) starts a headless engine that runs
/// [runSortAlertJob]: store the message, and if the payment is unclear
/// ([isUnclear]) turn the alert into a question with buttons. A button tap
/// is queued natively (SortActionReceiver) and applied by [applyAlertAnswers]
/// the next time any engine runs; tapping the body opens the payment.
const alertChannel = MethodChannel('pckt/alerts');

/// The question for an unclear payment, null for one the app can place.
class AlertQuestion {
  const AlertQuestion(this.title, this.text, {required this.credit});

  final String title;
  final String text;

  /// Money in gets Income / Lending / Transfer buttons, money out Everyday /
  /// Fixed / Lending.
  final bool credit;
}

AlertQuestion? questionFor(TxnView v) {
  if (!isUnclear(v)) return null;
  final t = v.txn;
  final amount = formatMoney(t.amountMinor, currency: t.currency);
  final credit = t.direction == TxnDirection.credit;
  final who = t.merchant;
  return credit
      ? AlertQuestion(
          who == null ? '$amount received' : '$amount from $who',
          'Income, lending or your own transfer? Tap for details.',
          credit: true,
        )
      : AlertQuestion(
          who == null ? '$amount paid' : '$amount to $who',
          'Which bucket? Tap to set category or details.',
          credit: false,
        );
}

/// A button tapped on a question: [choice] is a [Bucket] name, "income" or
/// "transfer".
class AlertAnswer {
  const AlertAnswer({required this.txnId, required this.rawId, required this.choice});

  final int txnId;

  /// The SMS row, to find the payment again if a later merge replaced it.
  final int rawId;
  final String choice;

  static AlertAnswer? fromMap(Map<Object?, Object?> m) {
    final txn = m['txnId'], raw = m['rawId'], choice = m['choice'];
    if (txn is! int || raw is! int || choice is! String) return null;
    return AlertAnswer(txnId: txn, rawId: raw, choice: choice);
  }
}

/// Applies answers like the transaction sheet does, with one difference:
/// Lending (money lent or paid back) is for this payment only. Everyday and
/// Fixed answer for the payee when there is one, so it isn't asked again.
/// "transfer" marks money between own accounts. "income" changes nothing:
/// money in already counts as income.
Future<void> applyAlertAnswers(AppDatabase db, Iterable<AlertAnswer> answers) async {
  for (final a in answers) {
    final bucket = Bucket.values.asNameMap()[a.choice];
    final transfer = a.choice == 'transfer';
    if (bucket == null && !transfer) continue;
    var v = await db.watchTxn(a.txnId).first;
    if (v == null) {
      final raw = await (db.select(db.rawMessages)..where((m) => m.id.equals(a.rawId))).getSingleOrNull();
      if (raw?.transactionId case final id?) v = await db.watchTxn(id).first;
    }
    if (v == null) continue;
    if (transfer) {
      await db.setTransfer(v.txn.id, true);
      continue;
    }
    final merchant = v.txn.merchant;
    if (bucket == Bucket.lending || merchant == null) {
      await db.setTxnBucket(v.txn.id, bucket);
    } else {
      await db.setTxnBucket(v.txn.id, null);
      await db.setPayeeBucket(merchant, bucket);
    }
  }
}

/// Answers tapped since the last call, cleared natively as they are read.
Future<List<AlertAnswer>> takeAlertAnswers() async {
  try {
    final rows = await alertChannel.invokeListMethod<Map<Object?, Object?>>('takeAnswers') ?? const [];
    return [for (final r in rows) ?AlertAnswer.fromMap(r)];
  } on MissingPluginException {
    return const [];
  }
}

/// The stored SMS for [body] received around [at], once the pipeline has it.
/// Whitespace is ignored: the SMS app may store the parts differently.
Future<RawMessage?> findSms(AppDatabase db, String body, DateTime at) async {
  String norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
  final want = norm(body);
  final rows =
      await (db.select(db.rawMessages)
            ..where(
              (m) =>
                  m.source.equalsValue(SourceKind.sms) &
                  m.receivedAt.isBiggerOrEqualValue(at.subtract(const Duration(hours: 1))),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.receivedAt)]))
          .get();
  for (final r in rows) {
    if (norm(r.body) == want) return r;
  }
  return null;
}

/// The background run for one bank SMS. Stores only recent messages (the
/// app's own sync keeps its watermark and does parser-version re-imports),
/// then asks native to replace the plain alert with a question if needed.
/// Always ends with `done`, which lets the worker stop the engine.
Future<void> runSortAlertJob() async {
  AppDatabase? db;
  try {
    final job = await alertChannel.invokeMapMethod<String, Object?>('job');
    final prefs = await SharedPreferences.getInstance();
    if (job == null ||
        !(prefs.getBool(PrefKeys.smsEnabled) ?? false) ||
        (prefs.getInt(PrefKeys.smsParserVersion) ?? 0) != smsParserVersion) {
      return;
    }
    final body = job['body']! as String;
    final at = DateTime.fromMillisecondsSinceEpoch((job['at']! as num).toInt());
    final home = prefs.getString(PrefKeys.homeCurrency) ?? 'INR';
    Currencies.home = home;
    db = openShownDatabase();
    final ingestion = IngestionService(db, homeCurrency: home);
    await applyAlertAnswers(db, await takeAlertAnswers());

    // The SMS app may write its inbox row a moment after the broadcast.
    RawMessage? raw;
    for (var attempt = 0; attempt < 5 && raw == null; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 3));
      await ingestion.ingest(await SmsSource().readSince(at.subtract(const Duration(hours: 1))));
      raw = await findSms(db, body, at);
    }
    final view = raw?.transactionId == null ? null : await db.watchTxn(raw!.transactionId!).first;
    final q = view == null ? null : questionFor(view);
    debugPrint('Sort alert: sms ${raw?.id} txn ${view?.txn.id} ask ${q != null}');
    if (q != null) {
      await alertChannel.invokeMethod('ask', {
        'id': job['id'],
        'title': q.title,
        'text': q.text,
        'credit': q.credit,
        'txnId': view!.txn.id,
        'rawId': raw!.id,
      });
    }
    // A button tapped while this ran.
    await applyAlertAnswers(db, await takeAlertAnswers());
  } catch (e, st) {
    debugPrint('Sort alert failed: $e\n$st');
  } finally {
    await db?.close();
    try {
      await alertChannel.invokeMethod('done');
    } catch (_) {}
  }
}

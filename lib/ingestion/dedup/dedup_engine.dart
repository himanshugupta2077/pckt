import '../../data/db/tables.dart';
import '../parser/parsed_txn.dart';
import '../parser/text_utils.dart';

/// An existing transaction plus what we know about where it came from.
class DedupCandidate {
  const DedupCandidate({
    required this.id,
    required this.occurredAt,
    this.reference,
    this.accountHint,
    this.merchant,
    this.counterparty,
    this.sourceKeys = const {},
    this.templates = const {},
  });

  final int id;
  final DateTime occurredAt;
  final String? reference;
  final String? accountHint;
  final String? merchant;
  final String? counterparty;

  /// `"<source>:<sender header>"` for every raw message already linked.
  final Set<String> sourceKeys;

  /// `"<source key>|<template>"` ([DedupEngine.template]) for the same
  /// messages, when their text is known.
  final Set<String> templates;
}

class DedupMatch {
  const DedupMatch(this.candidate, this.score);
  final DedupCandidate candidate;
  final double score;
}

/// Decides whether a freshly parsed transaction is the same real-world
/// payment as one we already have (e.g. bank SMS + email receipt, or the
/// bank and the card network both alerting).
///
/// Candidates are pre-filtered to the same amount and direction. From
/// there, the score combines:
///  * reference ids — equal ⇒ certain match, different ⇒ certain non-match
///  * account last-4 agreement
///  * time proximity (emails can lag SMS by hours)
///  * merchant / counterparty similarity
///  * a bonus when SMS and email disagree on channel (cross-channel evidence)
///  * a bonus when another sender (a merchant's own receipt) reports it
///    within minutes
///  * a penalty when the *same* sender reports twice in the same wording —
///    banks don't repeat their own alerts, so that is more likely two real
///    payments (two ₹20 chais). A different wording from the same bank (a
///    card "Spent" alert and a "Bill Paid!" confirmation) is no such sign.
class DedupEngine {
  const DedupEngine();

  static const autoMerge = 0.75;
  static const review = 0.5;

  /// [template] is the new message's [DedupEngine.template], if known.
  DedupMatch? best(ParsedTxn txn, String sourceKey, Iterable<DedupCandidate> candidates, {String? template}) {
    DedupMatch? top;
    for (final c in candidates) {
      final s = score(txn, sourceKey, c, template: template);
      if (top == null || s > top.score) top = DedupMatch(c, s);
    }
    return top;
  }

  double score(ParsedTxn t, String sourceKey, DedupCandidate c, {String? template}) {
    if (t.reference != null && c.reference != null) {
      return _sameRef(t.reference!, c.reference!) ? 1.0 : 0.0;
    }

    var s = 0.15; // amount + direction already equal

    if (t.accountHint != null && c.accountHint != null) {
      if (_sameAccount(t.accountHint!, c.accountHint!)) {
        s += 0.25;
      } else {
        s -= 0.5;
      }
    }

    final dt = t.occurredAt.difference(c.occurredAt).abs();
    if (dt <= const Duration(minutes: 5)) {
      s += 0.45;
    } else if (dt <= const Duration(minutes: 30)) {
      s += 0.35;
    } else if (dt <= const Duration(hours: 3)) {
      s += 0.2;
    } else if (dt <= const Duration(hours: 24)) {
      s += 0.1;
    }

    var merchantConflict = false;
    final a = merchantTokens(t.merchant)..addAll(merchantTokens(t.counterparty));
    final b = merchantTokens(c.merchant)..addAll(merchantTokens(c.counterparty));
    if (a.isNotEmpty && b.isNotEmpty) {
      final overlap = a.intersection(b).length / (a.length < b.length ? a.length : b.length);
      if (overlap >= 0.5) {
        s += 0.2;
      } else if (overlap == 0) {
        s -= 0.1;
        merchantConflict = true;
      }
    }

    // The same payment reported over SMS *and* email — typically a bank
    // alert plus a merchant receipt that shares no reference id. Different
    // channels rarely report two distinct same-amount payments minutes
    // apart, so that is evidence for a match — unless something (merchant,
    // account) contradicts it.
    final accountConflict =
        t.accountHint != null && c.accountHint != null && !_sameAccount(t.accountHint!, c.accountHint!);
    if (!merchantConflict && !accountConflict && _crossChannel(sourceKey, c.sourceKeys)) {
      if (dt <= const Duration(minutes: 30)) {
        s += 0.3;
      } else if (dt <= const Duration(hours: 3)) {
        s += 0.15;
      }
    } else if (!merchantConflict &&
        !accountConflict &&
        c.sourceKeys.isNotEmpty &&
        !c.sourceKeys.contains(sourceKey) &&
        dt <= const Duration(minutes: 5)) {
      // Another sender on the same channel within minutes: typically the
      // merchant's own receipt ("Premium activated. Amount paid Rs.299")
      // next to the bank's alert.
      s += 0.2;
    }

    final sameWording = template == null || c.templates.isEmpty || c.templates.contains('$sourceKey|$template');
    if (c.sourceKeys.contains(sourceKey)) {
      if (sameWording) {
        s -= 0.35;
      } else if (merchantConflict || dt > const Duration(minutes: 5)) {
        // Two formats from one bank are one payment only when they land
        // together and agree; otherwise the user decides.
        s = s.clamp(0.0, autoMerge - 0.01);
      }
    }

    return s.clamp(0.0, 1.0);
  }

  static bool _sameRef(String a, String b) {
    final x = a.toUpperCase(), y = b.toUpperCase();
    if (x == y) return true;
    // Some emails show a longer id that embeds the 12-digit RRN.
    return (x.length >= 10 && y.contains(x)) || (y.length >= 10 && x.contains(y));
  }

  static const _channels = {'sms', 'email'};
  static String _channel(String key) => key.split(':').first;

  static bool _crossChannel(String sourceKey, Set<String> existing) {
    final mine = _channel(sourceKey);
    if (!_channels.contains(mine) || existing.isEmpty) return false;
    return existing.every((k) {
      final c = _channel(k);
      return _channels.contains(c) && c != mine;
    });
  }

  static bool _sameAccount(String a, String b) => a.endsWith(b) || b.endsWith(a);

  /// The first two words of a message ("spent rs", "bill paid", "dear
  /// upi"): which of a sender's alert formats it is.
  static String template(String body) =>
      RegExp(r'[a-z]+').allMatches(body.toLowerCase()).take(2).map((m) => m.group(0)).join(' ');

  static String sourceKey(SourceKind source, String sender) =>
      '${source.name}:${sender.trim().toUpperCase().replaceAll(RegExp(r'^[A-Z]{2}-|-[SPTG]$'), '')}';
}

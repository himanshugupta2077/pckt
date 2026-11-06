import 'package:drift/drift.dart';

import '../core/theme/palette.dart';
import '../data/db/database.dart';
import 'categorizer.dart';
import 'dedup/dedup_engine.dart';
import 'parser/email_senders.dart';
import 'parser/parsed_txn.dart';
import 'parser/sms_parser.dart';

class IngestReport {
  int seen = 0, added = 0, merged = 0, flagged = 0, ignored = 0, unparsed = 0;

  @override
  String toString() => 'seen $seen · added $added · merged $merged · review $flagged · ignored $ignored';
}

/// Source-agnostic pipeline: raw message → parse → dedup → categorise → store.
/// SMS, email and anything else just produce [RawInput]s.
class IngestionService {
  IngestionService(
    this.db, {
    this.homeCurrency = 'INR',
    Map<SourceKind, MessageParser> parsers = const {},
    this.dedup = const DedupEngine(),
  }) : parsers = {SourceKind.sms: SmsParser(home: homeCurrency), ...parsers};

  final AppDatabase db;

  /// Assumed for amounts whose source names no currency; new accounts are
  /// held in it.
  final String homeCurrency;

  /// Parser per source. Sources without their own parser fall back to SMS
  /// rules, which also read most plain-text bank alert emails.
  final Map<SourceKind, MessageParser> parsers;
  final DedupEngine dedup;

  MessageParser _parserFor(SourceKind s) => parsers[s] ?? parsers[SourceKind.sms]!;

  Future<IngestReport> ingest(List<RawInput> inputs) async {
    final report = IngestReport();
    if (inputs.isEmpty) return report;

    final known = <SourceKind, Set<String>>{};
    for (final s in inputs.map((i) => i.source).toSet()) {
      known[s] = await db.knownExternalIds(s);
    }
    final fresh = inputs.where((i) => !known[i.source]!.contains(i.externalId)).toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    report.seen = fresh.length;
    if (fresh.isEmpty) return report;

    final categorizer = Categorizer(await db.allCategories(), await db.allMerchantRules());
    final accounts = await db.allAccounts();

    // Chunked transactions keep the UI responsive during big first imports.
    for (var i = 0; i < fresh.length; i += 200) {
      final chunk = fresh.sublist(i, (i + 200).clamp(0, fresh.length));
      await db.transaction(() async {
        for (final input in chunk) {
          await _ingestOne(input, categorizer, accounts, report);
        }
      });
    }
    return report;
  }

  Future<void> _ingestOne(RawInput input, Categorizer categorizer, List<Account> accounts, IngestReport report) async {
    RawMessagesCompanion raw(ParseStatus status, {String? reason, int? txnId, double? score}) =>
        RawMessagesCompanion.insert(
          source: input.source,
          externalId: input.externalId,
          sender: input.sender,
          body: input.body,
          receivedAt: input.receivedAt,
          parseStatus: status,
          ignoreReason: Value(reason),
          transactionId: Value(txnId),
          mergeScore: Value(score),
        );

    switch (_parserFor(input.source).parse(input)) {
      case Ignored(:final reason):
        report.ignored++;
        await db.into(db.rawMessages).insert(raw(ParseStatus.ignored, reason: reason), mode: InsertMode.insertOrIgnore);
      case Unparsed(:final reason):
        report.unparsed++;
        await db
            .into(db.rawMessages)
            .insert(raw(ParseStatus.pendingLlm, reason: reason), mode: InsertMode.insertOrIgnore);
      case Parsed(:final txn):
        await _store(
          txn,
          source: input.source,
          sender: input.sender,
          body: input.body,
          categorizer: categorizer,
          accounts: accounts,
          report: report,
          writeRaw: (status, {txnId, score}) => db
              .into(db.rawMessages)
              .insert(
                raw(status, txnId: txnId, score: score),
                mode: InsertMode.insertOrIgnore,
              ),
        );
    }
  }

  /// Re-reads stored messages that an older parser skipped for want of an
  /// amount or a direction ("USD 12.50 spent", "card was used for Rs.640"),
  /// so they appear without a destructive full re-import. Rows that still
  /// don't parse are left exactly as they were. Returns how many became
  /// (or merged into) transactions.
  Future<int> reparseSkipped() async {
    final rows =
        await (db.select(db.rawMessages)..where(
              (m) =>
                  (m.parseStatus.equalsValue(ParseStatus.ignored) &
                      m.ignoreReason.isIn(const ['No amount', 'Not a transaction'])) |
                  (m.parseStatus.equalsValue(ParseStatus.pendingLlm) &
                      m.ignoreReason.isIn(const ['Could not read amount', 'Could not tell debit from credit'])),
            ))
            .get();
    var n = 0;
    for (final m in rows) {
      final input = RawInput(
        source: m.source,
        externalId: m.externalId,
        sender: m.sender,
        body: m.body,
        receivedAt: m.receivedAt,
      );
      if (_parserFor(m.source).parse(input) case Parsed(:final txn)) {
        await applyParsed(m, txn);
        n++;
      }
    }
    return n;
  }

  /// Applies a transaction extracted out-of-band (e.g. by the LLM fallback)
  /// to a raw message that is already stored. Runs the same dedup →
  /// categorise → store path as [ingest], but updates the existing raw row
  /// instead of inserting a new one. Returns the resulting raw status
  /// ([ParseStatus.parsed] or [ParseStatus.merged]).
  Future<ParseStatus> applyParsed(RawMessage message, ParsedTxn txn, {IngestReport? report}) async {
    final categorizer = Categorizer(await db.allCategories(), await db.allMerchantRules());
    final accounts = await db.allAccounts();
    late ParseStatus result;
    await db.transaction(() async {
      await _store(
        txn,
        source: message.source,
        sender: message.sender,
        body: message.body,
        categorizer: categorizer,
        accounts: accounts,
        report: report ?? IngestReport(),
        writeRaw: (status, {txnId, score}) async {
          result = status;
          await (db.update(db.rawMessages)..where((m) => m.id.equals(message.id))).write(
            RawMessagesCompanion(
              parseStatus: Value(status),
              transactionId: Value(txnId),
              mergeScore: Value(score),
              ignoreReason: const Value(null),
            ),
          );
        },
      );
    });
    return result;
  }

  /// Shared tail of the pipeline for a parsed transaction: dedup against
  /// existing transactions, then merge or insert, then record the raw
  /// message's outcome via [writeRaw].
  Future<void> _store(
    ParsedTxn txn, {
    required SourceKind source,
    required String sender,
    required String body,
    required Categorizer categorizer,
    required List<Account> accounts,
    required IngestReport report,
    required Future<void> Function(ParseStatus status, {int? txnId, double? score}) writeRaw,
  }) async {
    final currency = txn.currency ?? homeCurrency;
    final converted = txn.convertedMinor != null && txn.convertedCurrency != null && txn.convertedCurrency != currency
        ? (txn.convertedMinor!, txn.convertedCurrency!)
        : null;
    if (txn.cardBill) {
      final bill = await _cardBillFor(txn, currency);
      if (bill != null) {
        report.merged++;
        await _joinCardBill(bill, txn, await _resolveAccount(txn, body, accounts));
        await writeRaw(ParseStatus.merged, txnId: bill.id, score: 1);
        return;
      }
    }
    final sourceKey = DedupEngine.sourceKey(source, sender);
    final match = dedup.best(
      txn,
      sourceKey,
      await _candidates(txn, currency, converted),
      template: DedupEngine.template(body),
    );

    if (match != null && match.score >= DedupEngine.autoMerge) {
      report.merged++;
      await _enrich(
        match.candidate.id,
        txn,
        currency: currency,
        converted: converted,
        source: source,
        sender: sender,
        body: body,
        categorizer: categorizer,
      );
      await writeRaw(ParseStatus.merged, txnId: match.candidate.id, score: match.score);
      return;
    }

    final possibleDup = match != null && match.score >= DedupEngine.review;
    final needsReview = possibleDup || txn.confidence < 0.7;
    if (needsReview) report.flagged++;
    report.added++;

    final account = await _resolveAccount(txn, body, accounts);
    final id = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            amountMinor: txn.amountMinor,
            currency: Value(currency),
            convertedMinor: Value(converted?.$1),
            convertedCurrency: Value(converted?.$2),
            direction: txn.direction,
            occurredAt: txn.occurredAt,
            merchant: Value(txn.merchant),
            counterparty: Value(txn.counterparty),
            categoryId: Value(categorizer.categorize(txn, body)),
            accountId: Value(account?.id),
            accountHint: Value(txn.accountHint),
            mode: txn.mode,
            reference: Value(txn.reference),
            status: needsReview ? TxnStatus.needsReview : TxnStatus.confirmed,
            isTransfer: Value(txn.transferHint),
            duplicateOfId: Value(possibleDup ? match.candidate.id : null),
          ),
        );
    await writeRaw(ParseStatus.parsed, txnId: id);
    if (account != null && !txn.transferHint) {
      await _detectSelfTransfer(id, txn, currency, account.id, categorizer.transferId);
    }
  }

  /// The card bill [t] belongs to: a card-bill payment of the same amount
  /// within three days, from either side (bank debit or card credit).
  Future<Transaction?> _cardBillFor(ParsedTxn t, String currency) =>
      (db.select(db.transactions)
            ..where(
              (x) =>
                  x.amountMinor.equals(t.amountMinor) &
                  x.currency.equals(currency) &
                  x.merchant.equals('Card bill') &
                  x.occurredAt.isBetweenValues(
                    t.occurredAt.subtract(const Duration(days: 3)),
                    t.occurredAt.add(const Duration(days: 3)),
                  ),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Adds [t]'s side to [bill]. The bank's debit is the one kept: it says
  /// which account paid.
  Future<void> _joinCardBill(Transaction bill, ParsedTxn t, Account? account) async {
    final debit = t.direction == TxnDirection.debit && bill.direction == TxnDirection.credit;
    await (db.update(db.transactions)..where((x) => x.id.equals(bill.id))).write(
      TransactionsCompanion(
        isTransfer: const Value(true),
        direction: debit ? const Value(TxnDirection.debit) : const Value.absent(),
        accountId: debit ? Value(account?.id) : const Value.absent(),
        accountHint: debit ? Value(t.accountHint) : const Value.absent(),
        reference: bill.reference == null ? Value(t.reference) : const Value.absent(),
      ),
    );
  }

  Future<List<DedupCandidate>> _candidates(ParsedTxn t, String currency, (int, String)? converted) async {
    final rows = await db.candidatesFor(
      amountMinor: t.amountMinor,
      currency: currency,
      also: converted,
      direction: t.direction,
      at: t.occurredAt,
    );
    return [for (final r in rows) await _candidate(r)];
  }

  Future<DedupCandidate> _candidate(Transaction r) async {
    final sources = await db.sourcesOf(r.id);
    return DedupCandidate(
      id: r.id,
      occurredAt: r.occurredAt,
      reference: r.reference,
      accountHint: r.accountHint,
      merchant: r.merchant,
      counterparty: r.counterparty,
      sourceKeys: {for (final m in sources) DedupEngine.sourceKey(m.source, m.sender)},
      templates: {
        for (final m in sources) '${DedupEngine.sourceKey(m.source, m.sender)}|${DedupEngine.template(m.body)}',
      },
    );
  }

  /// Bank footers ("Not you? To block / dispute / report, call…") that older
  /// parsers read as the payee.
  static final footerMerchant = RegExp(r'^(block|unblock|dispute|report|call)\b', caseSensitive: false);

  /// One-time clean-up of payments since [from] after the parser fixes for
  /// notices and bank footers. Re-reads every message behind each SMS or
  /// email payment: if all of them are now ignored (a declined charge, a
  /// pre-debit notice) the payment goes; a payee that was really a footer
  /// gets the right name; a card-bill payment becomes a transfer. Payee
  /// rules learned on footer names are dropped, then flagged duplicates are
  /// re-scored. Manual entries are never touched. Returns a line per change.
  Future<List<String>> repairSince(DateTime from) => db.transaction(() async {
    final log = <String>[];
    final txns = await (db.select(db.transactions)..where((t) => t.occurredAt.isBiggerOrEqualValue(from))).get();
    for (final t in txns) {
      final sources = await db.sourcesOf(t.id);
      if (sources.isEmpty || sources.any((m) => m.source == SourceKind.manual || m.source == SourceKind.shortcut)) {
        continue;
      }
      final results = [
        for (final m in sources)
          _parserFor(m.source).parse(
            RawInput(
              source: m.source,
              externalId: m.externalId,
              sender: m.sender,
              body: m.body,
              receivedAt: m.receivedAt,
            ),
          ),
      ];
      final label = '#${t.id} ${t.occurredAt.toIso8601String().substring(0, 10)} ${t.amountMinor / 100}';
      if (results.every((r) => r is Ignored)) {
        final reason = (results.first as Ignored).reason;
        await db.dropNonPayment(t.id, reason);
        log.add('drop $label ${t.merchant}: $reason');
        continue;
      }
      final parsed = results.whereType<Parsed>().firstOrNull?.txn;
      if (parsed == null) continue;
      if (t.merchant != null && footerMerchant.hasMatch(t.merchant!) && parsed.merchant != t.merchant) {
        await db.setParty(t.id, merchant: parsed.merchant, counterparty: parsed.counterparty ?? t.counterparty);
        log.add('rename $label ${t.merchant} → ${parsed.merchant}');
      }
      if (parsed.transferHint && !t.isTransfer) {
        await db.setTransfer(t.id, true);
        log.add('transfer $label');
      }
    }
    for (final r in await db.allMerchantRules()) {
      if (!footerMerchant.hasMatch(r.pattern)) continue;
      await (db.delete(db.merchantRules)..where((x) => x.id.equals(r.id))).go();
      log.add('rule removed: ${r.pattern}');
    }
    log.addAll(await resolveDuplicates());
    return log;
  });

  /// One-time: joins the messages of each card bill since [from] (the
  /// bank's debit and the card's confirmations, saved as separate payments
  /// before card bills were recognised) into one transfer, kept as the
  /// bank's debit. Answers the user gave those rows (a category, a flipped
  /// direction) are replaced: a card bill is never spending. Returns a line
  /// per change.
  Future<List<String>> mergeCardBills(DateTime from) => db.transaction(() async {
    final log = <String>[];
    final bills = <(Transaction, TxnDirection)>[];
    final txns =
        await (db.select(db.transactions)
              ..where((t) => t.occurredAt.isBiggerOrEqualValue(from))
              ..orderBy([(t) => OrderingTerm(expression: t.occurredAt)]))
            .get();
    for (final t in txns) {
      for (final m in await db.sourcesOf(t.id)) {
        final r = _parserFor(m.source).parse(
          RawInput(
            source: m.source,
            externalId: m.externalId,
            sender: m.sender,
            body: m.body,
            receivedAt: m.receivedAt,
          ),
        );
        if (r case Parsed(:final txn) when txn.cardBill) {
          bills.add((t, txn.direction));
          break;
        }
      }
    }
    final transfers = (await db.allCategories()).where((c) => (c.seedName ?? c.name) == 'Transfers').firstOrNull;
    final done = <int>{};
    for (final (i, (t, _)) in bills.indexed) {
      if (done.contains(t.id)) continue;
      final group = [
        for (final (u, dir) in bills.skip(i))
          if (!done.contains(u.id) &&
              u.amountMinor == t.amountMinor &&
              u.occurredAt.difference(t.occurredAt).abs() <= const Duration(days: 3))
            (u, dir),
      ];
      final keep = group.firstWhere((g) => g.$2 == TxnDirection.debit, orElse: () => group.first).$1;
      for (final (u, _) in group) {
        done.add(u.id);
        if (u.id != keep.id) await db.mergeInto(u.id, keep.id);
      }
      final debit = group.where((g) => g.$2 == TxnDirection.debit).firstOrNull?.$1;
      await (db.update(db.transactions)..where((x) => x.id.equals(keep.id))).write(
        TransactionsCompanion(
          merchant: const Value('Card bill'),
          isTransfer: const Value(true),
          direction: debit == null ? const Value.absent() : const Value(TxnDirection.debit),
          categoryId: Value(transfers?.id),
          categoryLocked: const Value(false),
          bucket: const Value(null),
        ),
      );
      log.add(
        'card bill #${keep.id} ${keep.occurredAt.toIso8601String().substring(0, 10)} ${keep.amountMinor / 100}: '
        '${group.length} message(s)',
      );
    }
    return log;
  });

  /// Re-scores every payment flagged as a possible duplicate with the
  /// current [dedup] rules: a sure match is merged (keeping the payment
  /// that says more), a clear non-match loses the flag, the rest stay for
  /// the user. Returns a line per change.
  Future<List<String>> resolveDuplicates() => db.transaction(() async {
    final log = <String>[];
    final flagged = await (db.select(db.transactions)..where((t) => t.duplicateOfId.isNotNull())).get();
    for (final t in flagged) {
      final other = await (db.select(db.transactions)..where((x) => x.id.equals(t.duplicateOfId!))).getSingleOrNull();
      final sources = await db.sourcesOf(t.id);
      if (other == null) {
        await db.confirm(t.id);
        continue;
      }
      if (sources.isEmpty) continue;
      final m = sources.first;
      final score = dedup.score(
        ParsedTxn(
          amountMinor: t.amountMinor,
          direction: t.direction,
          occurredAt: t.occurredAt,
          mode: t.mode,
          confidence: 1,
          merchant: t.merchant,
          counterparty: t.counterparty,
          accountHint: t.accountHint,
          reference: t.reference,
        ),
        DedupEngine.sourceKey(m.source, m.sender),
        await _candidate(other),
        template: DedupEngine.template(m.body),
      );
      if (score >= DedupEngine.autoMerge) {
        final (from, into) = _richness(t) > _richness(other) ? (other.id, t.id) : (t.id, other.id);
        await db.mergeInto(from, into);
        log.add('merge #$from into #$into (${t.amountMinor / 100}, score ${score.toStringAsFixed(2)})');
      } else if (score < DedupEngine.review) {
        await db.confirm(t.id);
        log.add('not a duplicate: #${t.id} (score ${score.toStringAsFixed(2)})');
      }
    }
    return log;
  });

  /// How much a payment says on its own: a named merchant, a known
  /// account, and a category or note the user gave it.
  static int _richness(Transaction t) =>
      (t.merchant != null ? 2 : 0) + (t.accountId != null ? 1 : 0) + (t.categoryLocked || t.note != null ? 3 : 0);

  /// Fill gaps on the existing transaction with whatever the new source knows.
  /// A merchant receipt email names the merchant better than a bank alert
  /// ("BUNDL TECHNOLOGIES", a VPA, or nothing), so it replaces it and the
  /// category is re-derived unless the user picked one.
  Future<void> _enrich(
    int id,
    ParsedTxn t, {
    required String currency,
    required (int, String)? converted,
    required SourceKind source,
    required String sender,
    required String body,
    required Categorizer categorizer,
  }) async {
    final existing = await (db.select(db.transactions)..where((x) => x.id.equals(id))).getSingle();
    final betterMerchant =
        t.merchant != null &&
        t.merchant != existing.merchant &&
        source == SourceKind.email &&
        EmailSenders.isMerchant(sender);
    final merchant = betterMerchant || existing.merchant == null ? t.merchant : existing.merchant;
    final recategorize = betterMerchant && !existing.categoryLocked && !existing.isTransfer;
    // A rupee-only alert matched a foreign spend (or the other way round):
    // the second source tells us what it cost at home.
    final conversion = existing.convertedMinor != null
        ? null
        : currency != existing.currency
        ? (t.amountMinor, currency)
        : converted != null && converted.$2 != existing.currency
        ? converted
        : null;
    await (db.update(db.transactions)..where((x) => x.id.equals(id))).write(
      TransactionsCompanion(
        reference: existing.reference == null ? Value(t.reference) : const Value.absent(),
        convertedMinor: conversion == null ? const Value.absent() : Value(conversion.$1),
        convertedCurrency: conversion == null ? const Value.absent() : Value(conversion.$2),
        merchant: merchant != existing.merchant ? Value(merchant) : const Value.absent(),
        categoryId: recategorize
            ? Value(
                categorizer.categorize(
                      ParsedTxn(
                        amountMinor: existing.amountMinor,
                        direction: existing.direction,
                        occurredAt: existing.occurredAt,
                        mode: existing.mode,
                        confidence: 1,
                        merchant: merchant,
                        counterparty: existing.counterparty,
                      ),
                      body,
                    ) ??
                    existing.categoryId,
              )
            : const Value.absent(),
        counterparty: existing.counterparty == null ? Value(t.counterparty) : const Value.absent(),
        accountHint: existing.accountHint == null ? Value(t.accountHint) : const Value.absent(),
        // A second independent source confirming the payment is good evidence.
        status: existing.duplicateOfId == null ? const Value(TxnStatus.confirmed) : const Value.absent(),
      ),
    );
  }

  /// Finds or auto-creates the account a message refers to (by last 4 digits).
  Future<Account?> _resolveAccount(ParsedTxn t, String body, List<Account> accounts) async {
    final hint = t.accountHint;
    if (hint == null) return null;
    for (final a in accounts) {
      if (a.last4 != null &&
          (a.last4!.endsWith(hint) || hint.endsWith(a.last4!)) &&
          (a.institution == null || t.institution == null || a.institution == t.institution)) {
        return a;
      }
    }
    final isCard = RegExp(r'credit card|\bcc\b', caseSensitive: false).hasMatch(body);
    final account = Account(
      id: -1,
      name: isCard ? '${t.institution ?? ''} Card'.trim() : (t.institution ?? 'Bank account'),
      kind: isCard ? AccountKind.creditCard : AccountKind.bank,
      institution: t.institution,
      last4: hint,
      color: Palette.categories[(accounts.length * 5 + 6) % Palette.categories.length].toARGB32(),
      archived: false,
      currency: homeCurrency,
    );
    final id = await db.into(db.accounts).insert(account.toCompanion(true).copyWith(id: const Value.absent()));
    final created = account.copyWith(id: id);
    accounts.add(created);
    return created;
  }

  /// Debit from one own account + equal credit into another within an hour
  /// ⇒ both legs are a self-transfer and shouldn't count as spend/income.
  Future<void> _detectSelfTransfer(int id, ParsedTxn t, String currency, int accountId, int? transferCategory) async {
    final opposite = t.direction == TxnDirection.debit ? TxnDirection.credit : TxnDirection.debit;
    final legs = await db.candidatesFor(
      amountMinor: t.amountMinor,
      currency: currency,
      direction: opposite,
      at: t.occurredAt,
      window: const Duration(hours: 1),
    );
    final other = legs.where((l) => l.accountId != null && l.accountId != accountId && !l.isTransfer).firstOrNull;
    if (other == null) return;
    await (db.update(db.transactions)..where((x) => x.id.isIn([id, other.id]))).write(
      TransactionsCompanion(
        isTransfer: const Value(true),
        categoryId: transferCategory == null ? const Value.absent() : Value(transferCategory),
      ),
    );
  }
}

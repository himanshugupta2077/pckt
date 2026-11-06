import 'package:drift/drift.dart';

/// Where a piece of evidence came from. [statement] is a line from a bank
/// or card statement that no message reported. New values go at the end:
/// the index is what is stored.
enum SourceKind { sms, email, manual, shortcut, statement }

enum TxnDirection { debit, credit }

/// Payment rail detected from the message.
enum PaymentMode { upi, card, netbanking, neft, imps, rtgs, atm, wallet, cash, other }

/// How confident we are that a transaction is real and correctly read.
enum TxnStatus { confirmed, needsReview }

/// Lifecycle of a raw message as it moves through ingestion.
enum ParseStatus { parsed, merged, ignored, failed, pendingLlm }

enum AccountKind { bank, creditCard, wallet, cash }

/// Where a debit belongs. Only [everyday] counts toward the monthly budget;
/// [fixed] is bills and subscriptions, [fund] the big and occasional buys
/// judged over the year, [outside] money that leaves but isn't spending
/// (insurance, taxes, gifts). [lending] is money lent or borrowed and paid
/// back, either way, and [invest] money put into or taken out of
/// investments: neither is spending or income. [fixed] shows as
/// "Recurring". New values go at the end: the index is what is stored.
enum Bucket { everyday, fixed, fund, outside, lending, invest }

/// Need or want, for the salary card. Investment is [Bucket.invest], not a
/// value here. New values go at the end: the index is what is stored.
enum SpendKind { need, want }

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get kind => intEnum<AccountKind>()();
  TextColumn get institution => text().nullable()();

  /// Last 3–4 digits of account / card number, used to match messages.
  TextColumn get last4 => text().nullable()();
  IntColumn get color => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// ISO 4217 code the account is held in. Rows from before v4 are INR.
  TextColumn get currency => text().withDefault(const Constant('INR'))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Key into [CategoryIcons]; stored as text so icon sets can change.
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Name of the seed category this row was created from (null for
  /// user-made ones). Keeps keyword rules working after a rename.
  TextColumn get seedName => text().nullable()();

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) so older
  /// backups still carry it into the one-time bucket migration.
  BoolColumn get countsInBudget => boolean().withDefault(const Constant(true))();

  /// Bucket for spends in this category, unless a payee rule or the
  /// transaction itself says otherwise.
  IntColumn get bucket => intEnum<Bucket>().withDefault(const Constant(0))();

  /// Need or want for spends in this category, unless a payee rule or the
  /// transaction itself says otherwise. Defaults to want (index 1).
  IntColumn get spendKind => intEnum<SpendKind>().withDefault(const Constant(1))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// In minor units of [currency] (paise, cents; whole yen for JPY, fils
  /// for KWD) to avoid floating point drift.
  IntColumn get amountMinor => integer()();

  /// ISO 4217 code of [amountMinor]. Rows from before v4 are INR.
  TextColumn get currency => text().withDefault(const Constant('INR'))();

  /// The same payment in another currency, normally the home currency:
  /// stated by the message ("USD 12.50 (INR 1,045.30)") or entered by the
  /// user. A foreign transaction counts towards totals and budgets only
  /// with a converted amount in the home currency. Null for most rows.
  IntColumn get convertedMinor => integer().nullable()();
  TextColumn get convertedCurrency => text().nullable()();
  IntColumn get direction => intEnum<TxnDirection>()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get merchant => text().nullable()();

  /// VPA / raw counterparty string as it appeared in the message.
  TextColumn get counterparty => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  TextColumn get accountHint => text().nullable()();
  IntColumn get mode => intEnum<PaymentMode>()();

  /// UPI ref / RRN / bank reference. The strongest dedup signal.
  TextColumn get reference => text().nullable()();
  IntColumn get status => intEnum<TxnStatus>()();

  /// Self-transfers between own accounts are excluded from spend.
  BoolColumn get isTransfer => boolean().withDefault(const Constant(false))();
  BoolColumn get categoryLocked => boolean().withDefault(const Constant(false))();

  /// Set when dedup found a borderline match the user should confirm.
  IntColumn get duplicateOfId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) for the
  /// one-time migration.
  BoolColumn get inBudget => boolean().nullable()();

  /// The user's bucket for this payment. Null = follow the payee rule,
  /// then the category.
  IntColumn get bucket => intEnum<Bucket>().nullable()();

  /// Need or want for this payment. Null follows the payee, then the category.
  IntColumn get spendKind => intEnum<SpendKind>().nullable()();
}

/// Every SMS / email we have looked at, parsed or not. Keeping the raw
/// evidence lets us re-parse after parser upgrades and explain merges.
class RawMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get source => intEnum<SourceKind>()();

  /// Provider-side id (SMS _id, Gmail message id) — unique per source.
  TextColumn get externalId => text()();
  TextColumn get sender => text()();
  TextColumn get body => text()();
  DateTimeColumn get receivedAt => dateTime()();
  IntColumn get parseStatus => intEnum<ParseStatus>()();
  TextColumn get ignoreReason => text().nullable()();
  IntColumn get transactionId => integer().nullable().references(Transactions, #id, onDelete: KeyAction.setNull)();

  /// Dedup score that linked this message to an existing transaction.
  RealColumn get mergeScore => real().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {source, externalId},
  ];
}

/// Monthly spending limits. A row with a null [categoryId] is the overall
/// monthly budget (at most one); others cap a single category. Budgets
/// repeat every month until removed or paused.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// Limit per month, in minor units of [currency].
  IntColumn get amountMinor => integer()();

  /// A budget applies only while this is the home currency. Rows from
  /// before v4 are INR.
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Learned per-merchant rules: a category (set when the user recategorises
/// a transaction) and/or the payee's bucket. Either may be null on its own.
class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pattern => text().unique()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) for the
  /// one-time migration.
  BoolColumn get countsInBudget => boolean().nullable()();
  IntColumn get bucket => intEnum<Bucket>().nullable()();

  /// Need or want for this payee. Null follows the category.
  IntColumn get spendKind => intEnum<SpendKind>().nullable()();
}

/// The monthly plan: one row. Amounts are home-currency minor units per
/// month; months are stored as the 1st of the month. Everyday, Fixed,
/// Family and Insurance aren't typed here: they come from the overall
/// budget and from averages over complete months.
@DataClassName('MonthlyPlan')
class Plan extends Table {
  @override
  String get tableName => 'plan';

  IntColumn get id => integer().autoIncrement()();

  /// Month the plan started; the fund is measured from here.
  DateTimeColumn get startMonth => dateTime()();
  IntColumn get salaryMinor => integer().withDefault(const Constant(0))();
  IntColumn get emiMinor => integer().withDefault(const Constant(0))();

  /// Last month the EMI is paid.
  DateTimeColumn get emiEnds => dateTime().nullable()();

  /// Investing per month, not counting goal savings.
  IntColumn get investingMinor => integer().withDefault(const Constant(0))();
  IntColumn get fundMinor => integer().withDefault(const Constant(1000000))();

  /// Up to three goals, in entry order (emergency fund first): the amount
  /// still to save and the month it's due.
  IntColumn get goal1Minor => integer().nullable()();
  DateTimeColumn get goal1Due => dateTime().nullable()();
  IntColumn get goal2Minor => integer().nullable()();
  DateTimeColumn get goal2Due => dateTime().nullable()();
  IntColumn get goal3Minor => integer().nullable()();
  DateTimeColumn get goal3Due => dateTime().nullable()();
}

/// Loan instalments paid every month that no message reports: a card EMI
/// rides on the card bill, which is a transfer. Shown on Home and taken off
/// in the plan from this list, not from transactions.
@DataClassName('Emi')
class Emis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Home-currency minor units per month.
  IntColumn get amountMinor => integer()();

  /// The 1st of the last month it is paid; null while unknown.
  DateTimeColumn get lastMonth => dateTime().nullable()();

  /// Need or want, for the salary card. Defaults to need (index 0).
  IntColumn get spendKind => intEnum<SpendKind>().withDefault(const Constant(0))();
}

/// What each account held at the start of a month, entered by hand.
/// Net worth = assets − liabilities.
class BalanceSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The 1st of the month.
  DateTimeColumn get month => dateTime()();
  TextColumn get label => text()();
  IntColumn get amountMinor => integer()();
  BoolColumn get isLiability => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {month, label},
  ];
}

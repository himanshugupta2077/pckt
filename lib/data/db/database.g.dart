// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<AccountKind>($AccountsTable.$converterkind);
  static const VerificationMeta _institutionMeta = const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, kind, institution, last4, color, archived, currency];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(_institutionMeta, institution.isAcceptableOrUnknown(data['institution']!, _institutionMeta));
    }
    if (data.containsKey('last4')) {
      context.handle(_last4Meta, last4.isAcceptableOrUnknown(data['last4']!, _last4Meta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $AccountsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      ),
      institution: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}institution']),
      last4: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last4']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountKind, int, int> $converterkind = const EnumIndexConverter<AccountKind>(
    AccountKind.values,
  );
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final AccountKind kind;
  final String? institution;

  /// Last 3–4 digits of account / card number, used to match messages.
  final String? last4;
  final int color;
  final bool archived;

  /// ISO 4217 code the account is held in. Rows from before v4 are INR.
  final String currency;
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    this.institution,
    this.last4,
    required this.color,
    required this.archived,
    required this.currency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<int>($AccountsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['color'] = Variable<int>(color);
    map['archived'] = Variable<bool>(archived);
    map['currency'] = Variable<String>(currency);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      institution: institution == null && nullToAbsent ? const Value.absent() : Value(institution),
      last4: last4 == null && nullToAbsent ? const Value.absent() : Value(last4),
      color: Value(color),
      archived: Value(archived),
      currency: Value(currency),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $AccountsTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      institution: serializer.fromJson<String?>(json['institution']),
      last4: serializer.fromJson<String?>(json['last4']),
      color: serializer.fromJson<int>(json['color']),
      archived: serializer.fromJson<bool>(json['archived']),
      currency: serializer.fromJson<String>(json['currency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>($AccountsTable.$converterkind.toJson(kind)),
      'institution': serializer.toJson<String?>(institution),
      'last4': serializer.toJson<String?>(last4),
      'color': serializer.toJson<int>(color),
      'archived': serializer.toJson<bool>(archived),
      'currency': serializer.toJson<String>(currency),
    };
  }

  Account copyWith({
    int? id,
    String? name,
    AccountKind? kind,
    Value<String?> institution = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    int? color,
    bool? archived,
    String? currency,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    institution: institution.present ? institution.value : this.institution,
    last4: last4.present ? last4.value : this.last4,
    color: color ?? this.color,
    archived: archived ?? this.archived,
    currency: currency ?? this.currency,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      institution: data.institution.present ? data.institution.value : this.institution,
      last4: data.last4.present ? data.last4.value : this.last4,
      color: data.color.present ? data.color.value : this.color,
      archived: data.archived.present ? data.archived.value : this.archived,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('institution: $institution, ')
          ..write('last4: $last4, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, institution, last4, color, archived, currency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.institution == this.institution &&
          other.last4 == this.last4 &&
          other.color == this.color &&
          other.archived == this.archived &&
          other.currency == this.currency);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<AccountKind> kind;
  final Value<String?> institution;
  final Value<String?> last4;
  final Value<int> color;
  final Value<bool> archived;
  final Value<String> currency;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.institution = const Value.absent(),
    this.last4 = const Value.absent(),
    this.color = const Value.absent(),
    this.archived = const Value.absent(),
    this.currency = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountKind kind,
    this.institution = const Value.absent(),
    this.last4 = const Value.absent(),
    required int color,
    this.archived = const Value.absent(),
    this.currency = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       color = Value(color);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<String>? institution,
    Expression<String>? last4,
    Expression<int>? color,
    Expression<bool>? archived,
    Expression<String>? currency,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (institution != null) 'institution': institution,
      if (last4 != null) 'last4': last4,
      if (color != null) 'color': color,
      if (archived != null) 'archived': archived,
      if (currency != null) 'currency': currency,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AccountKind>? kind,
    Value<String?>? institution,
    Value<String?>? last4,
    Value<int>? color,
    Value<bool>? archived,
    Value<String>? currency,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      institution: institution ?? this.institution,
      last4: last4 ?? this.last4,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      currency: currency ?? this.currency,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($AccountsTable.$converterkind.toSql(kind.value));
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('institution: $institution, ')
          ..write('last4: $last4, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isIncomeMeta = const VerificationMeta('isIncome');
  @override
  late final GeneratedColumn<bool> isIncome = GeneratedColumn<bool>(
    'is_income',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_income" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seedNameMeta = const VerificationMeta('seedName');
  @override
  late final GeneratedColumn<String> seedName = GeneratedColumn<String>(
    'seed_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countsInBudgetMeta = const VerificationMeta('countsInBudget');
  @override
  late final GeneratedColumn<bool> countsInBudget = GeneratedColumn<bool>(
    'counts_in_budget',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("counts_in_budget" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Bucket, int> bucket = GeneratedColumn<int>(
    'bucket',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<Bucket>($CategoriesTable.$converterbucket);
  @override
  late final GeneratedColumnWithTypeConverter<SpendKind, int> spendKind = GeneratedColumn<int>(
    'spend_kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  ).withConverter<SpendKind>($CategoriesTable.$converterspendKind);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    color,
    isIncome,
    sortOrder,
    seedName,
    countsInBudget,
    bucket,
    spendKind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('is_income')) {
      context.handle(_isIncomeMeta, isIncome.isAcceptableOrUnknown(data['is_income']!, _isIncomeMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('seed_name')) {
      context.handle(_seedNameMeta, seedName.isAcceptableOrUnknown(data['seed_name']!, _seedNameMeta));
    }
    if (data.containsKey('counts_in_budget')) {
      context.handle(
        _countsInBudgetMeta,
        countsInBudget.isAcceptableOrUnknown(data['counts_in_budget']!, _countsInBudgetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      isIncome: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_income'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      seedName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}seed_name']),
      countsInBudget: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}counts_in_budget'])!,
      bucket: $CategoriesTable.$converterbucket.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bucket'])!,
      ),
      spendKind: $CategoriesTable.$converterspendKind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}spend_kind'])!,
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Bucket, int, int> $converterbucket = const EnumIndexConverter<Bucket>(Bucket.values);
  static JsonTypeConverter2<SpendKind, int, int> $converterspendKind = const EnumIndexConverter<SpendKind>(
    SpendKind.values,
  );
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;

  /// Key into [CategoryIcons]; stored as text so icon sets can change.
  final String icon;
  final int color;
  final bool isIncome;
  final int sortOrder;

  /// Name of the seed category this row was created from (null for
  /// user-made ones). Keeps keyword rules working after a rename.
  final String? seedName;

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) so older
  /// backups still carry it into the one-time bucket migration.
  final bool countsInBudget;

  /// Bucket for spends in this category, unless a payee rule or the
  /// transaction itself says otherwise.
  final Bucket bucket;

  /// Need or want for spends in this category, unless a payee rule or the
  /// transaction itself says otherwise. Defaults to want (index 1).
  final SpendKind spendKind;
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
    required this.sortOrder,
    this.seedName,
    required this.countsInBudget,
    required this.bucket,
    required this.spendKind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    map['is_income'] = Variable<bool>(isIncome);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || seedName != null) {
      map['seed_name'] = Variable<String>(seedName);
    }
    map['counts_in_budget'] = Variable<bool>(countsInBudget);
    {
      map['bucket'] = Variable<int>($CategoriesTable.$converterbucket.toSql(bucket));
    }
    {
      map['spend_kind'] = Variable<int>($CategoriesTable.$converterspendKind.toSql(spendKind));
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      isIncome: Value(isIncome),
      sortOrder: Value(sortOrder),
      seedName: seedName == null && nullToAbsent ? const Value.absent() : Value(seedName),
      countsInBudget: Value(countsInBudget),
      bucket: Value(bucket),
      spendKind: Value(spendKind),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      isIncome: serializer.fromJson<bool>(json['isIncome']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      seedName: serializer.fromJson<String?>(json['seedName']),
      countsInBudget: serializer.fromJson<bool>(json['countsInBudget']),
      bucket: $CategoriesTable.$converterbucket.fromJson(serializer.fromJson<int>(json['bucket'])),
      spendKind: $CategoriesTable.$converterspendKind.fromJson(serializer.fromJson<int>(json['spendKind'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'isIncome': serializer.toJson<bool>(isIncome),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'seedName': serializer.toJson<String?>(seedName),
      'countsInBudget': serializer.toJson<bool>(countsInBudget),
      'bucket': serializer.toJson<int>($CategoriesTable.$converterbucket.toJson(bucket)),
      'spendKind': serializer.toJson<int>($CategoriesTable.$converterspendKind.toJson(spendKind)),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    int? color,
    bool? isIncome,
    int? sortOrder,
    Value<String?> seedName = const Value.absent(),
    bool? countsInBudget,
    Bucket? bucket,
    SpendKind? spendKind,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isIncome: isIncome ?? this.isIncome,
    sortOrder: sortOrder ?? this.sortOrder,
    seedName: seedName.present ? seedName.value : this.seedName,
    countsInBudget: countsInBudget ?? this.countsInBudget,
    bucket: bucket ?? this.bucket,
    spendKind: spendKind ?? this.spendKind,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isIncome: data.isIncome.present ? data.isIncome.value : this.isIncome,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      seedName: data.seedName.present ? data.seedName.value : this.seedName,
      countsInBudget: data.countsInBudget.present ? data.countsInBudget.value : this.countsInBudget,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      spendKind: data.spendKind.present ? data.spendKind.value : this.spendKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isIncome: $isIncome, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('seedName: $seedName, ')
          ..write('countsInBudget: $countsInBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, isIncome, sortOrder, seedName, countsInBudget, bucket, spendKind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isIncome == this.isIncome &&
          other.sortOrder == this.sortOrder &&
          other.seedName == this.seedName &&
          other.countsInBudget == this.countsInBudget &&
          other.bucket == this.bucket &&
          other.spendKind == this.spendKind);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<bool> isIncome;
  final Value<int> sortOrder;
  final Value<String?> seedName;
  final Value<bool> countsInBudget;
  final Value<Bucket> bucket;
  final Value<SpendKind> spendKind;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isIncome = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.seedName = const Value.absent(),
    this.countsInBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String icon,
    required int color,
    this.isIncome = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.seedName = const Value.absent(),
    this.countsInBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  }) : name = Value(name),
       icon = Value(icon),
       color = Value(color);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<bool>? isIncome,
    Expression<int>? sortOrder,
    Expression<String>? seedName,
    Expression<bool>? countsInBudget,
    Expression<int>? bucket,
    Expression<int>? spendKind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isIncome != null) 'is_income': isIncome,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (seedName != null) 'seed_name': seedName,
      if (countsInBudget != null) 'counts_in_budget': countsInBudget,
      if (bucket != null) 'bucket': bucket,
      if (spendKind != null) 'spend_kind': spendKind,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? color,
    Value<bool>? isIncome,
    Value<int>? sortOrder,
    Value<String?>? seedName,
    Value<bool>? countsInBudget,
    Value<Bucket>? bucket,
    Value<SpendKind>? spendKind,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
      sortOrder: sortOrder ?? this.sortOrder,
      seedName: seedName ?? this.seedName,
      countsInBudget: countsInBudget ?? this.countsInBudget,
      bucket: bucket ?? this.bucket,
      spendKind: spendKind ?? this.spendKind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isIncome.present) {
      map['is_income'] = Variable<bool>(isIncome.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (seedName.present) {
      map['seed_name'] = Variable<String>(seedName.value);
    }
    if (countsInBudget.present) {
      map['counts_in_budget'] = Variable<bool>(countsInBudget.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<int>($CategoriesTable.$converterbucket.toSql(bucket.value));
    }
    if (spendKind.present) {
      map['spend_kind'] = Variable<int>($CategoriesTable.$converterspendKind.toSql(spendKind.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isIncome: $isIncome, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('seedName: $seedName, ')
          ..write('countsInBudget: $countsInBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _convertedMinorMeta = const VerificationMeta('convertedMinor');
  @override
  late final GeneratedColumn<int> convertedMinor = GeneratedColumn<int>(
    'converted_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _convertedCurrencyMeta = const VerificationMeta('convertedCurrency');
  @override
  late final GeneratedColumn<String> convertedCurrency = GeneratedColumn<String>(
    'converted_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnDirection, int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TxnDirection>($TransactionsTable.$converterdirection);
  static const VerificationMeta _occurredAtMeta = const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta('counterparty');
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _accountHintMeta = const VerificationMeta('accountHint');
  @override
  late final GeneratedColumn<String> accountHint = GeneratedColumn<String>(
    'account_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMode, int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<PaymentMode>($TransactionsTable.$convertermode);
  static const VerificationMeta _referenceMeta = const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnStatus, int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TxnStatus>($TransactionsTable.$converterstatus);
  static const VerificationMeta _isTransferMeta = const VerificationMeta('isTransfer');
  @override
  late final GeneratedColumn<bool> isTransfer = GeneratedColumn<bool>(
    'is_transfer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_transfer" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryLockedMeta = const VerificationMeta('categoryLocked');
  @override
  late final GeneratedColumn<bool> categoryLocked = GeneratedColumn<bool>(
    'category_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("category_locked" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _duplicateOfIdMeta = const VerificationMeta('duplicateOfId');
  @override
  late final GeneratedColumn<int> duplicateOfId = GeneratedColumn<int>(
    'duplicate_of_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _inBudgetMeta = const VerificationMeta('inBudget');
  @override
  late final GeneratedColumn<bool> inBudget = GeneratedColumn<bool>(
    'in_budget',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("in_budget" IN (0, 1))'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Bucket?, int> bucket = GeneratedColumn<int>(
    'bucket',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Bucket?>($TransactionsTable.$converterbucketn);
  @override
  late final GeneratedColumnWithTypeConverter<SpendKind?, int> spendKind = GeneratedColumn<int>(
    'spend_kind',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<SpendKind?>($TransactionsTable.$converterspendKindn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountMinor,
    currency,
    convertedMinor,
    convertedCurrency,
    direction,
    occurredAt,
    merchant,
    counterparty,
    note,
    categoryId,
    accountId,
    accountHint,
    mode,
    reference,
    status,
    isTransfer,
    categoryLocked,
    duplicateOfId,
    createdAt,
    inBudget,
    bucket,
    spendKind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(_amountMinorMeta, amountMinor.isAcceptableOrUnknown(data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('converted_minor')) {
      context.handle(
        _convertedMinorMeta,
        convertedMinor.isAcceptableOrUnknown(data['converted_minor']!, _convertedMinorMeta),
      );
    }
    if (data.containsKey('converted_currency')) {
      context.handle(
        _convertedCurrencyMeta,
        convertedCurrency.isAcceptableOrUnknown(data['converted_currency']!, _convertedCurrencyMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(_occurredAtMeta, occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta, merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('counterparty')) {
      context.handle(_counterpartyMeta, counterparty.isAcceptableOrUnknown(data['counterparty']!, _counterpartyMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('account_hint')) {
      context.handle(_accountHintMeta, accountHint.isAcceptableOrUnknown(data['account_hint']!, _accountHintMeta));
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta, reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('is_transfer')) {
      context.handle(_isTransferMeta, isTransfer.isAcceptableOrUnknown(data['is_transfer']!, _isTransferMeta));
    }
    if (data.containsKey('category_locked')) {
      context.handle(
        _categoryLockedMeta,
        categoryLocked.isAcceptableOrUnknown(data['category_locked']!, _categoryLockedMeta),
      );
    }
    if (data.containsKey('duplicate_of_id')) {
      context.handle(
        _duplicateOfIdMeta,
        duplicateOfId.isAcceptableOrUnknown(data['duplicate_of_id']!, _duplicateOfIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('in_budget')) {
      context.handle(_inBudgetMeta, inBudget.isAcceptableOrUnknown(data['in_budget']!, _inBudgetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      amountMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      convertedMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}converted_minor']),
      convertedCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}converted_currency'],
      ),
      direction: $TransactionsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}direction'])!,
      ),
      occurredAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      merchant: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      counterparty: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}counterparty']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}account_id']),
      accountHint: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_hint']),
      mode: $TransactionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}mode'])!,
      ),
      reference: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reference']),
      status: $TransactionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      ),
      isTransfer: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_transfer'])!,
      categoryLocked: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}category_locked'])!,
      duplicateOfId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duplicate_of_id']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      inBudget: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}in_budget']),
      bucket: $TransactionsTable.$converterbucketn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bucket']),
      ),
      spendKind: $TransactionsTable.$converterspendKindn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}spend_kind']),
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxnDirection, int, int> $converterdirection = const EnumIndexConverter<TxnDirection>(
    TxnDirection.values,
  );
  static JsonTypeConverter2<PaymentMode, int, int> $convertermode = const EnumIndexConverter<PaymentMode>(
    PaymentMode.values,
  );
  static JsonTypeConverter2<TxnStatus, int, int> $converterstatus = const EnumIndexConverter<TxnStatus>(
    TxnStatus.values,
  );
  static JsonTypeConverter2<Bucket, int, int> $converterbucket = const EnumIndexConverter<Bucket>(Bucket.values);
  static JsonTypeConverter2<Bucket?, int?, int?> $converterbucketn = JsonTypeConverter2.asNullable($converterbucket);
  static JsonTypeConverter2<SpendKind, int, int> $converterspendKind = const EnumIndexConverter<SpendKind>(
    SpendKind.values,
  );
  static JsonTypeConverter2<SpendKind?, int?, int?> $converterspendKindn = JsonTypeConverter2.asNullable(
    $converterspendKind,
  );
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;

  /// In minor units of [currency] (paise, cents; whole yen for JPY, fils
  /// for KWD) to avoid floating point drift.
  final int amountMinor;

  /// ISO 4217 code of [amountMinor]. Rows from before v4 are INR.
  final String currency;

  /// The same payment in another currency, normally the home currency:
  /// stated by the message ("USD 12.50 (INR 1,045.30)") or entered by the
  /// user. A foreign transaction counts towards totals and budgets only
  /// with a converted amount in the home currency. Null for most rows.
  final int? convertedMinor;
  final String? convertedCurrency;
  final TxnDirection direction;
  final DateTime occurredAt;
  final String? merchant;

  /// VPA / raw counterparty string as it appeared in the message.
  final String? counterparty;
  final String? note;
  final int? categoryId;
  final int? accountId;
  final String? accountHint;
  final PaymentMode mode;

  /// UPI ref / RRN / bank reference. The strongest dedup signal.
  final String? reference;
  final TxnStatus status;

  /// Self-transfers between own accounts are excluded from spend.
  final bool isTransfer;
  final bool categoryLocked;

  /// Set when dedup found a borderline match the user should confirm.
  final int? duplicateOfId;
  final DateTime createdAt;

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) for the
  /// one-time migration.
  final bool? inBudget;

  /// The user's bucket for this payment. Null = follow the payee rule,
  /// then the category.
  final Bucket? bucket;

  /// Need or want for this payment. Null follows the payee, then the category.
  final SpendKind? spendKind;
  const Transaction({
    required this.id,
    required this.amountMinor,
    required this.currency,
    this.convertedMinor,
    this.convertedCurrency,
    required this.direction,
    required this.occurredAt,
    this.merchant,
    this.counterparty,
    this.note,
    this.categoryId,
    this.accountId,
    this.accountHint,
    required this.mode,
    this.reference,
    required this.status,
    required this.isTransfer,
    required this.categoryLocked,
    this.duplicateOfId,
    required this.createdAt,
    this.inBudget,
    this.bucket,
    this.spendKind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || convertedMinor != null) {
      map['converted_minor'] = Variable<int>(convertedMinor);
    }
    if (!nullToAbsent || convertedCurrency != null) {
      map['converted_currency'] = Variable<String>(convertedCurrency);
    }
    {
      map['direction'] = Variable<int>($TransactionsTable.$converterdirection.toSql(direction));
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || accountHint != null) {
      map['account_hint'] = Variable<String>(accountHint);
    }
    {
      map['mode'] = Variable<int>($TransactionsTable.$convertermode.toSql(mode));
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    {
      map['status'] = Variable<int>($TransactionsTable.$converterstatus.toSql(status));
    }
    map['is_transfer'] = Variable<bool>(isTransfer);
    map['category_locked'] = Variable<bool>(categoryLocked);
    if (!nullToAbsent || duplicateOfId != null) {
      map['duplicate_of_id'] = Variable<int>(duplicateOfId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || inBudget != null) {
      map['in_budget'] = Variable<bool>(inBudget);
    }
    if (!nullToAbsent || bucket != null) {
      map['bucket'] = Variable<int>($TransactionsTable.$converterbucketn.toSql(bucket));
    }
    if (!nullToAbsent || spendKind != null) {
      map['spend_kind'] = Variable<int>($TransactionsTable.$converterspendKindn.toSql(spendKind));
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      convertedMinor: convertedMinor == null && nullToAbsent ? const Value.absent() : Value(convertedMinor),
      convertedCurrency: convertedCurrency == null && nullToAbsent ? const Value.absent() : Value(convertedCurrency),
      direction: Value(direction),
      occurredAt: Value(occurredAt),
      merchant: merchant == null && nullToAbsent ? const Value.absent() : Value(merchant),
      counterparty: counterparty == null && nullToAbsent ? const Value.absent() : Value(counterparty),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      accountId: accountId == null && nullToAbsent ? const Value.absent() : Value(accountId),
      accountHint: accountHint == null && nullToAbsent ? const Value.absent() : Value(accountHint),
      mode: Value(mode),
      reference: reference == null && nullToAbsent ? const Value.absent() : Value(reference),
      status: Value(status),
      isTransfer: Value(isTransfer),
      categoryLocked: Value(categoryLocked),
      duplicateOfId: duplicateOfId == null && nullToAbsent ? const Value.absent() : Value(duplicateOfId),
      createdAt: Value(createdAt),
      inBudget: inBudget == null && nullToAbsent ? const Value.absent() : Value(inBudget),
      bucket: bucket == null && nullToAbsent ? const Value.absent() : Value(bucket),
      spendKind: spendKind == null && nullToAbsent ? const Value.absent() : Value(spendKind),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      convertedMinor: serializer.fromJson<int?>(json['convertedMinor']),
      convertedCurrency: serializer.fromJson<String?>(json['convertedCurrency']),
      direction: $TransactionsTable.$converterdirection.fromJson(serializer.fromJson<int>(json['direction'])),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      note: serializer.fromJson<String?>(json['note']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      accountHint: serializer.fromJson<String?>(json['accountHint']),
      mode: $TransactionsTable.$convertermode.fromJson(serializer.fromJson<int>(json['mode'])),
      reference: serializer.fromJson<String?>(json['reference']),
      status: $TransactionsTable.$converterstatus.fromJson(serializer.fromJson<int>(json['status'])),
      isTransfer: serializer.fromJson<bool>(json['isTransfer']),
      categoryLocked: serializer.fromJson<bool>(json['categoryLocked']),
      duplicateOfId: serializer.fromJson<int?>(json['duplicateOfId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      inBudget: serializer.fromJson<bool?>(json['inBudget']),
      bucket: $TransactionsTable.$converterbucketn.fromJson(serializer.fromJson<int?>(json['bucket'])),
      spendKind: $TransactionsTable.$converterspendKindn.fromJson(serializer.fromJson<int?>(json['spendKind'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'convertedMinor': serializer.toJson<int?>(convertedMinor),
      'convertedCurrency': serializer.toJson<String?>(convertedCurrency),
      'direction': serializer.toJson<int>($TransactionsTable.$converterdirection.toJson(direction)),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'merchant': serializer.toJson<String?>(merchant),
      'counterparty': serializer.toJson<String?>(counterparty),
      'note': serializer.toJson<String?>(note),
      'categoryId': serializer.toJson<int?>(categoryId),
      'accountId': serializer.toJson<int?>(accountId),
      'accountHint': serializer.toJson<String?>(accountHint),
      'mode': serializer.toJson<int>($TransactionsTable.$convertermode.toJson(mode)),
      'reference': serializer.toJson<String?>(reference),
      'status': serializer.toJson<int>($TransactionsTable.$converterstatus.toJson(status)),
      'isTransfer': serializer.toJson<bool>(isTransfer),
      'categoryLocked': serializer.toJson<bool>(categoryLocked),
      'duplicateOfId': serializer.toJson<int?>(duplicateOfId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'inBudget': serializer.toJson<bool?>(inBudget),
      'bucket': serializer.toJson<int?>($TransactionsTable.$converterbucketn.toJson(bucket)),
      'spendKind': serializer.toJson<int?>($TransactionsTable.$converterspendKindn.toJson(spendKind)),
    };
  }

  Transaction copyWith({
    int? id,
    int? amountMinor,
    String? currency,
    Value<int?> convertedMinor = const Value.absent(),
    Value<String?> convertedCurrency = const Value.absent(),
    TxnDirection? direction,
    DateTime? occurredAt,
    Value<String?> merchant = const Value.absent(),
    Value<String?> counterparty = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<String?> accountHint = const Value.absent(),
    PaymentMode? mode,
    Value<String?> reference = const Value.absent(),
    TxnStatus? status,
    bool? isTransfer,
    bool? categoryLocked,
    Value<int?> duplicateOfId = const Value.absent(),
    DateTime? createdAt,
    Value<bool?> inBudget = const Value.absent(),
    Value<Bucket?> bucket = const Value.absent(),
    Value<SpendKind?> spendKind = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    convertedMinor: convertedMinor.present ? convertedMinor.value : this.convertedMinor,
    convertedCurrency: convertedCurrency.present ? convertedCurrency.value : this.convertedCurrency,
    direction: direction ?? this.direction,
    occurredAt: occurredAt ?? this.occurredAt,
    merchant: merchant.present ? merchant.value : this.merchant,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    note: note.present ? note.value : this.note,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    accountHint: accountHint.present ? accountHint.value : this.accountHint,
    mode: mode ?? this.mode,
    reference: reference.present ? reference.value : this.reference,
    status: status ?? this.status,
    isTransfer: isTransfer ?? this.isTransfer,
    categoryLocked: categoryLocked ?? this.categoryLocked,
    duplicateOfId: duplicateOfId.present ? duplicateOfId.value : this.duplicateOfId,
    createdAt: createdAt ?? this.createdAt,
    inBudget: inBudget.present ? inBudget.value : this.inBudget,
    bucket: bucket.present ? bucket.value : this.bucket,
    spendKind: spendKind.present ? spendKind.value : this.spendKind,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      convertedMinor: data.convertedMinor.present ? data.convertedMinor.value : this.convertedMinor,
      convertedCurrency: data.convertedCurrency.present ? data.convertedCurrency.value : this.convertedCurrency,
      direction: data.direction.present ? data.direction.value : this.direction,
      occurredAt: data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      counterparty: data.counterparty.present ? data.counterparty.value : this.counterparty,
      note: data.note.present ? data.note.value : this.note,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountHint: data.accountHint.present ? data.accountHint.value : this.accountHint,
      mode: data.mode.present ? data.mode.value : this.mode,
      reference: data.reference.present ? data.reference.value : this.reference,
      status: data.status.present ? data.status.value : this.status,
      isTransfer: data.isTransfer.present ? data.isTransfer.value : this.isTransfer,
      categoryLocked: data.categoryLocked.present ? data.categoryLocked.value : this.categoryLocked,
      duplicateOfId: data.duplicateOfId.present ? data.duplicateOfId.value : this.duplicateOfId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      inBudget: data.inBudget.present ? data.inBudget.value : this.inBudget,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      spendKind: data.spendKind.present ? data.spendKind.value : this.spendKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('convertedMinor: $convertedMinor, ')
          ..write('convertedCurrency: $convertedCurrency, ')
          ..write('direction: $direction, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('counterparty: $counterparty, ')
          ..write('note: $note, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('accountHint: $accountHint, ')
          ..write('mode: $mode, ')
          ..write('reference: $reference, ')
          ..write('status: $status, ')
          ..write('isTransfer: $isTransfer, ')
          ..write('categoryLocked: $categoryLocked, ')
          ..write('duplicateOfId: $duplicateOfId, ')
          ..write('createdAt: $createdAt, ')
          ..write('inBudget: $inBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    amountMinor,
    currency,
    convertedMinor,
    convertedCurrency,
    direction,
    occurredAt,
    merchant,
    counterparty,
    note,
    categoryId,
    accountId,
    accountHint,
    mode,
    reference,
    status,
    isTransfer,
    categoryLocked,
    duplicateOfId,
    createdAt,
    inBudget,
    bucket,
    spendKind,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.convertedMinor == this.convertedMinor &&
          other.convertedCurrency == this.convertedCurrency &&
          other.direction == this.direction &&
          other.occurredAt == this.occurredAt &&
          other.merchant == this.merchant &&
          other.counterparty == this.counterparty &&
          other.note == this.note &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.accountHint == this.accountHint &&
          other.mode == this.mode &&
          other.reference == this.reference &&
          other.status == this.status &&
          other.isTransfer == this.isTransfer &&
          other.categoryLocked == this.categoryLocked &&
          other.duplicateOfId == this.duplicateOfId &&
          other.createdAt == this.createdAt &&
          other.inBudget == this.inBudget &&
          other.bucket == this.bucket &&
          other.spendKind == this.spendKind);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<int?> convertedMinor;
  final Value<String?> convertedCurrency;
  final Value<TxnDirection> direction;
  final Value<DateTime> occurredAt;
  final Value<String?> merchant;
  final Value<String?> counterparty;
  final Value<String?> note;
  final Value<int?> categoryId;
  final Value<int?> accountId;
  final Value<String?> accountHint;
  final Value<PaymentMode> mode;
  final Value<String?> reference;
  final Value<TxnStatus> status;
  final Value<bool> isTransfer;
  final Value<bool> categoryLocked;
  final Value<int?> duplicateOfId;
  final Value<DateTime> createdAt;
  final Value<bool?> inBudget;
  final Value<Bucket?> bucket;
  final Value<SpendKind?> spendKind;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.convertedMinor = const Value.absent(),
    this.convertedCurrency = const Value.absent(),
    this.direction = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.merchant = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.note = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountHint = const Value.absent(),
    this.mode = const Value.absent(),
    this.reference = const Value.absent(),
    this.status = const Value.absent(),
    this.isTransfer = const Value.absent(),
    this.categoryLocked = const Value.absent(),
    this.duplicateOfId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.inBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int amountMinor,
    this.currency = const Value.absent(),
    this.convertedMinor = const Value.absent(),
    this.convertedCurrency = const Value.absent(),
    required TxnDirection direction,
    required DateTime occurredAt,
    this.merchant = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.note = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountHint = const Value.absent(),
    required PaymentMode mode,
    this.reference = const Value.absent(),
    required TxnStatus status,
    this.isTransfer = const Value.absent(),
    this.categoryLocked = const Value.absent(),
    this.duplicateOfId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.inBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  }) : amountMinor = Value(amountMinor),
       direction = Value(direction),
       occurredAt = Value(occurredAt),
       mode = Value(mode),
       status = Value(status);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<int>? convertedMinor,
    Expression<String>? convertedCurrency,
    Expression<int>? direction,
    Expression<DateTime>? occurredAt,
    Expression<String>? merchant,
    Expression<String>? counterparty,
    Expression<String>? note,
    Expression<int>? categoryId,
    Expression<int>? accountId,
    Expression<String>? accountHint,
    Expression<int>? mode,
    Expression<String>? reference,
    Expression<int>? status,
    Expression<bool>? isTransfer,
    Expression<bool>? categoryLocked,
    Expression<int>? duplicateOfId,
    Expression<DateTime>? createdAt,
    Expression<bool>? inBudget,
    Expression<int>? bucket,
    Expression<int>? spendKind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (convertedMinor != null) 'converted_minor': convertedMinor,
      if (convertedCurrency != null) 'converted_currency': convertedCurrency,
      if (direction != null) 'direction': direction,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (merchant != null) 'merchant': merchant,
      if (counterparty != null) 'counterparty': counterparty,
      if (note != null) 'note': note,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (accountHint != null) 'account_hint': accountHint,
      if (mode != null) 'mode': mode,
      if (reference != null) 'reference': reference,
      if (status != null) 'status': status,
      if (isTransfer != null) 'is_transfer': isTransfer,
      if (categoryLocked != null) 'category_locked': categoryLocked,
      if (duplicateOfId != null) 'duplicate_of_id': duplicateOfId,
      if (createdAt != null) 'created_at': createdAt,
      if (inBudget != null) 'in_budget': inBudget,
      if (bucket != null) 'bucket': bucket,
      if (spendKind != null) 'spend_kind': spendKind,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<int?>? convertedMinor,
    Value<String?>? convertedCurrency,
    Value<TxnDirection>? direction,
    Value<DateTime>? occurredAt,
    Value<String?>? merchant,
    Value<String?>? counterparty,
    Value<String?>? note,
    Value<int?>? categoryId,
    Value<int?>? accountId,
    Value<String?>? accountHint,
    Value<PaymentMode>? mode,
    Value<String?>? reference,
    Value<TxnStatus>? status,
    Value<bool>? isTransfer,
    Value<bool>? categoryLocked,
    Value<int?>? duplicateOfId,
    Value<DateTime>? createdAt,
    Value<bool?>? inBudget,
    Value<Bucket?>? bucket,
    Value<SpendKind?>? spendKind,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      convertedMinor: convertedMinor ?? this.convertedMinor,
      convertedCurrency: convertedCurrency ?? this.convertedCurrency,
      direction: direction ?? this.direction,
      occurredAt: occurredAt ?? this.occurredAt,
      merchant: merchant ?? this.merchant,
      counterparty: counterparty ?? this.counterparty,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      accountHint: accountHint ?? this.accountHint,
      mode: mode ?? this.mode,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      isTransfer: isTransfer ?? this.isTransfer,
      categoryLocked: categoryLocked ?? this.categoryLocked,
      duplicateOfId: duplicateOfId ?? this.duplicateOfId,
      createdAt: createdAt ?? this.createdAt,
      inBudget: inBudget ?? this.inBudget,
      bucket: bucket ?? this.bucket,
      spendKind: spendKind ?? this.spendKind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (convertedMinor.present) {
      map['converted_minor'] = Variable<int>(convertedMinor.value);
    }
    if (convertedCurrency.present) {
      map['converted_currency'] = Variable<String>(convertedCurrency.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>($TransactionsTable.$converterdirection.toSql(direction.value));
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (accountHint.present) {
      map['account_hint'] = Variable<String>(accountHint.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>($TransactionsTable.$convertermode.toSql(mode.value));
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (status.present) {
      map['status'] = Variable<int>($TransactionsTable.$converterstatus.toSql(status.value));
    }
    if (isTransfer.present) {
      map['is_transfer'] = Variable<bool>(isTransfer.value);
    }
    if (categoryLocked.present) {
      map['category_locked'] = Variable<bool>(categoryLocked.value);
    }
    if (duplicateOfId.present) {
      map['duplicate_of_id'] = Variable<int>(duplicateOfId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (inBudget.present) {
      map['in_budget'] = Variable<bool>(inBudget.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<int>($TransactionsTable.$converterbucketn.toSql(bucket.value));
    }
    if (spendKind.present) {
      map['spend_kind'] = Variable<int>($TransactionsTable.$converterspendKindn.toSql(spendKind.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('convertedMinor: $convertedMinor, ')
          ..write('convertedCurrency: $convertedCurrency, ')
          ..write('direction: $direction, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('counterparty: $counterparty, ')
          ..write('note: $note, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('accountHint: $accountHint, ')
          ..write('mode: $mode, ')
          ..write('reference: $reference, ')
          ..write('status: $status, ')
          ..write('isTransfer: $isTransfer, ')
          ..write('categoryLocked: $categoryLocked, ')
          ..write('duplicateOfId: $duplicateOfId, ')
          ..write('createdAt: $createdAt, ')
          ..write('inBudget: $inBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }
}

class $RawMessagesTable extends RawMessages with TableInfo<$RawMessagesTable, RawMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceKind, int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<SourceKind>($RawMessagesTable.$convertersource);
  static const VerificationMeta _externalIdMeta = const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ParseStatus, int> parseStatus = GeneratedColumn<int>(
    'parse_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<ParseStatus>($RawMessagesTable.$converterparseStatus);
  static const VerificationMeta _ignoreReasonMeta = const VerificationMeta('ignoreReason');
  @override
  late final GeneratedColumn<String> ignoreReason = GeneratedColumn<String>(
    'ignore_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES transactions (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _mergeScoreMeta = const VerificationMeta('mergeScore');
  @override
  late final GeneratedColumn<double> mergeScore = GeneratedColumn<double>(
    'merge_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    externalId,
    sender,
    body,
    receivedAt,
    parseStatus,
    ignoreReason,
    transactionId,
    mergeScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_messages';
  @override
  VerificationContext validateIntegrity(Insertable<RawMessage> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(_externalIdMeta, externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta));
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta, sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(_receivedAtMeta, receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('ignore_reason')) {
      context.handle(_ignoreReasonMeta, ignoreReason.isAcceptableOrUnknown(data['ignore_reason']!, _ignoreReasonMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(data['transaction_id']!, _transactionIdMeta),
      );
    }
    if (data.containsKey('merge_score')) {
      context.handle(_mergeScoreMeta, mergeScore.isAcceptableOrUnknown(data['merge_score']!, _mergeScoreMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {source, externalId},
  ];
  @override
  RawMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawMessage(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      source: $RawMessagesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      ),
      externalId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}external_id'])!,
      sender: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      receivedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
      parseStatus: $RawMessagesTable.$converterparseStatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parse_status'])!,
      ),
      ignoreReason: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ignore_reason']),
      transactionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}transaction_id']),
      mergeScore: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}merge_score']),
    );
  }

  @override
  $RawMessagesTable createAlias(String alias) {
    return $RawMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceKind, int, int> $convertersource = const EnumIndexConverter<SourceKind>(
    SourceKind.values,
  );
  static JsonTypeConverter2<ParseStatus, int, int> $converterparseStatus = const EnumIndexConverter<ParseStatus>(
    ParseStatus.values,
  );
}

class RawMessage extends DataClass implements Insertable<RawMessage> {
  final int id;
  final SourceKind source;

  /// Provider-side id (SMS _id, Gmail message id) — unique per source.
  final String externalId;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final ParseStatus parseStatus;
  final String? ignoreReason;
  final int? transactionId;

  /// Dedup score that linked this message to an existing transaction.
  final double? mergeScore;
  const RawMessage({
    required this.id,
    required this.source,
    required this.externalId,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.parseStatus,
    this.ignoreReason,
    this.transactionId,
    this.mergeScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['source'] = Variable<int>($RawMessagesTable.$convertersource.toSql(source));
    }
    map['external_id'] = Variable<String>(externalId);
    map['sender'] = Variable<String>(sender);
    map['body'] = Variable<String>(body);
    map['received_at'] = Variable<DateTime>(receivedAt);
    {
      map['parse_status'] = Variable<int>($RawMessagesTable.$converterparseStatus.toSql(parseStatus));
    }
    if (!nullToAbsent || ignoreReason != null) {
      map['ignore_reason'] = Variable<String>(ignoreReason);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<int>(transactionId);
    }
    if (!nullToAbsent || mergeScore != null) {
      map['merge_score'] = Variable<double>(mergeScore);
    }
    return map;
  }

  RawMessagesCompanion toCompanion(bool nullToAbsent) {
    return RawMessagesCompanion(
      id: Value(id),
      source: Value(source),
      externalId: Value(externalId),
      sender: Value(sender),
      body: Value(body),
      receivedAt: Value(receivedAt),
      parseStatus: Value(parseStatus),
      ignoreReason: ignoreReason == null && nullToAbsent ? const Value.absent() : Value(ignoreReason),
      transactionId: transactionId == null && nullToAbsent ? const Value.absent() : Value(transactionId),
      mergeScore: mergeScore == null && nullToAbsent ? const Value.absent() : Value(mergeScore),
    );
  }

  factory RawMessage.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawMessage(
      id: serializer.fromJson<int>(json['id']),
      source: $RawMessagesTable.$convertersource.fromJson(serializer.fromJson<int>(json['source'])),
      externalId: serializer.fromJson<String>(json['externalId']),
      sender: serializer.fromJson<String>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      parseStatus: $RawMessagesTable.$converterparseStatus.fromJson(serializer.fromJson<int>(json['parseStatus'])),
      ignoreReason: serializer.fromJson<String?>(json['ignoreReason']),
      transactionId: serializer.fromJson<int?>(json['transactionId']),
      mergeScore: serializer.fromJson<double?>(json['mergeScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<int>($RawMessagesTable.$convertersource.toJson(source)),
      'externalId': serializer.toJson<String>(externalId),
      'sender': serializer.toJson<String>(sender),
      'body': serializer.toJson<String>(body),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'parseStatus': serializer.toJson<int>($RawMessagesTable.$converterparseStatus.toJson(parseStatus)),
      'ignoreReason': serializer.toJson<String?>(ignoreReason),
      'transactionId': serializer.toJson<int?>(transactionId),
      'mergeScore': serializer.toJson<double?>(mergeScore),
    };
  }

  RawMessage copyWith({
    int? id,
    SourceKind? source,
    String? externalId,
    String? sender,
    String? body,
    DateTime? receivedAt,
    ParseStatus? parseStatus,
    Value<String?> ignoreReason = const Value.absent(),
    Value<int?> transactionId = const Value.absent(),
    Value<double?> mergeScore = const Value.absent(),
  }) => RawMessage(
    id: id ?? this.id,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    receivedAt: receivedAt ?? this.receivedAt,
    parseStatus: parseStatus ?? this.parseStatus,
    ignoreReason: ignoreReason.present ? ignoreReason.value : this.ignoreReason,
    transactionId: transactionId.present ? transactionId.value : this.transactionId,
    mergeScore: mergeScore.present ? mergeScore.value : this.mergeScore,
  );
  RawMessage copyWithCompanion(RawMessagesCompanion data) {
    return RawMessage(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present ? data.externalId.value : this.externalId,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      receivedAt: data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      parseStatus: data.parseStatus.present ? data.parseStatus.value : this.parseStatus,
      ignoreReason: data.ignoreReason.present ? data.ignoreReason.value : this.ignoreReason,
      transactionId: data.transactionId.present ? data.transactionId.value : this.transactionId,
      mergeScore: data.mergeScore.present ? data.mergeScore.value : this.mergeScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawMessage(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('parseStatus: $parseStatus, ')
          ..write('ignoreReason: $ignoreReason, ')
          ..write('transactionId: $transactionId, ')
          ..write('mergeScore: $mergeScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    externalId,
    sender,
    body,
    receivedAt,
    parseStatus,
    ignoreReason,
    transactionId,
    mergeScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawMessage &&
          other.id == this.id &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.receivedAt == this.receivedAt &&
          other.parseStatus == this.parseStatus &&
          other.ignoreReason == this.ignoreReason &&
          other.transactionId == this.transactionId &&
          other.mergeScore == this.mergeScore);
}

class RawMessagesCompanion extends UpdateCompanion<RawMessage> {
  final Value<int> id;
  final Value<SourceKind> source;
  final Value<String> externalId;
  final Value<String> sender;
  final Value<String> body;
  final Value<DateTime> receivedAt;
  final Value<ParseStatus> parseStatus;
  final Value<String?> ignoreReason;
  final Value<int?> transactionId;
  final Value<double?> mergeScore;
  const RawMessagesCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.parseStatus = const Value.absent(),
    this.ignoreReason = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.mergeScore = const Value.absent(),
  });
  RawMessagesCompanion.insert({
    this.id = const Value.absent(),
    required SourceKind source,
    required String externalId,
    required String sender,
    required String body,
    required DateTime receivedAt,
    required ParseStatus parseStatus,
    this.ignoreReason = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.mergeScore = const Value.absent(),
  }) : source = Value(source),
       externalId = Value(externalId),
       sender = Value(sender),
       body = Value(body),
       receivedAt = Value(receivedAt),
       parseStatus = Value(parseStatus);
  static Insertable<RawMessage> custom({
    Expression<int>? id,
    Expression<int>? source,
    Expression<String>? externalId,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<DateTime>? receivedAt,
    Expression<int>? parseStatus,
    Expression<String>? ignoreReason,
    Expression<int>? transactionId,
    Expression<double>? mergeScore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (sender != null) 'sender': sender,
      if (body != null) 'body': body,
      if (receivedAt != null) 'received_at': receivedAt,
      if (parseStatus != null) 'parse_status': parseStatus,
      if (ignoreReason != null) 'ignore_reason': ignoreReason,
      if (transactionId != null) 'transaction_id': transactionId,
      if (mergeScore != null) 'merge_score': mergeScore,
    });
  }

  RawMessagesCompanion copyWith({
    Value<int>? id,
    Value<SourceKind>? source,
    Value<String>? externalId,
    Value<String>? sender,
    Value<String>? body,
    Value<DateTime>? receivedAt,
    Value<ParseStatus>? parseStatus,
    Value<String?>? ignoreReason,
    Value<int?>? transactionId,
    Value<double?>? mergeScore,
  }) {
    return RawMessagesCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      parseStatus: parseStatus ?? this.parseStatus,
      ignoreReason: ignoreReason ?? this.ignoreReason,
      transactionId: transactionId ?? this.transactionId,
      mergeScore: mergeScore ?? this.mergeScore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<int>($RawMessagesTable.$convertersource.toSql(source.value));
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (parseStatus.present) {
      map['parse_status'] = Variable<int>($RawMessagesTable.$converterparseStatus.toSql(parseStatus.value));
    }
    if (ignoreReason.present) {
      map['ignore_reason'] = Variable<String>(ignoreReason.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (mergeScore.present) {
      map['merge_score'] = Variable<double>(mergeScore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawMessagesCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('parseStatus: $parseStatus, ')
          ..write('ignoreReason: $ignoreReason, ')
          ..write('transactionId: $transactionId, ')
          ..write('mergeScore: $mergeScore')
          ..write(')'))
        .toString();
  }
}

class $MerchantRulesTable extends MerchantRules with TableInfo<$MerchantRulesTable, MerchantRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _patternMeta = const VerificationMeta('pattern');
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _countsInBudgetMeta = const VerificationMeta('countsInBudget');
  @override
  late final GeneratedColumn<bool> countsInBudget = GeneratedColumn<bool>(
    'counts_in_budget',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("counts_in_budget" IN (0, 1))'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Bucket?, int> bucket = GeneratedColumn<int>(
    'bucket',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Bucket?>($MerchantRulesTable.$converterbucketn);
  @override
  late final GeneratedColumnWithTypeConverter<SpendKind?, int> spendKind = GeneratedColumn<int>(
    'spend_kind',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<SpendKind?>($MerchantRulesTable.$converterspendKindn);
  @override
  List<GeneratedColumn> get $columns => [id, pattern, categoryId, countsInBudget, bucket, spendKind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_rules';
  @override
  VerificationContext validateIntegrity(Insertable<MerchantRule> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pattern')) {
      context.handle(_patternMeta, pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta));
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('counts_in_budget')) {
      context.handle(
        _countsInBudgetMeta,
        countsInBudget.isAcceptableOrUnknown(data['counts_in_budget']!, _countsInBudgetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MerchantRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantRule(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pattern: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pattern'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      countsInBudget: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}counts_in_budget']),
      bucket: $MerchantRulesTable.$converterbucketn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bucket']),
      ),
      spendKind: $MerchantRulesTable.$converterspendKindn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}spend_kind']),
      ),
    );
  }

  @override
  $MerchantRulesTable createAlias(String alias) {
    return $MerchantRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Bucket, int, int> $converterbucket = const EnumIndexConverter<Bucket>(Bucket.values);
  static JsonTypeConverter2<Bucket?, int?, int?> $converterbucketn = JsonTypeConverter2.asNullable($converterbucket);
  static JsonTypeConverter2<SpendKind, int, int> $converterspendKind = const EnumIndexConverter<SpendKind>(
    SpendKind.values,
  );
  static JsonTypeConverter2<SpendKind?, int?, int?> $converterspendKindn = JsonTypeConverter2.asNullable(
    $converterspendKind,
  );
}

class MerchantRule extends DataClass implements Insertable<MerchantRule> {
  final int id;
  final String pattern;
  final int? categoryId;

  /// v5 yes/no, replaced by [bucket] in v6. Kept (unread) for the
  /// one-time migration.
  final bool? countsInBudget;
  final Bucket? bucket;

  /// Need or want for this payee. Null follows the category.
  final SpendKind? spendKind;
  const MerchantRule({
    required this.id,
    required this.pattern,
    this.categoryId,
    this.countsInBudget,
    this.bucket,
    this.spendKind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pattern'] = Variable<String>(pattern);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || countsInBudget != null) {
      map['counts_in_budget'] = Variable<bool>(countsInBudget);
    }
    if (!nullToAbsent || bucket != null) {
      map['bucket'] = Variable<int>($MerchantRulesTable.$converterbucketn.toSql(bucket));
    }
    if (!nullToAbsent || spendKind != null) {
      map['spend_kind'] = Variable<int>($MerchantRulesTable.$converterspendKindn.toSql(spendKind));
    }
    return map;
  }

  MerchantRulesCompanion toCompanion(bool nullToAbsent) {
    return MerchantRulesCompanion(
      id: Value(id),
      pattern: Value(pattern),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      countsInBudget: countsInBudget == null && nullToAbsent ? const Value.absent() : Value(countsInBudget),
      bucket: bucket == null && nullToAbsent ? const Value.absent() : Value(bucket),
      spendKind: spendKind == null && nullToAbsent ? const Value.absent() : Value(spendKind),
    );
  }

  factory MerchantRule.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantRule(
      id: serializer.fromJson<int>(json['id']),
      pattern: serializer.fromJson<String>(json['pattern']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      countsInBudget: serializer.fromJson<bool?>(json['countsInBudget']),
      bucket: $MerchantRulesTable.$converterbucketn.fromJson(serializer.fromJson<int?>(json['bucket'])),
      spendKind: $MerchantRulesTable.$converterspendKindn.fromJson(serializer.fromJson<int?>(json['spendKind'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pattern': serializer.toJson<String>(pattern),
      'categoryId': serializer.toJson<int?>(categoryId),
      'countsInBudget': serializer.toJson<bool?>(countsInBudget),
      'bucket': serializer.toJson<int?>($MerchantRulesTable.$converterbucketn.toJson(bucket)),
      'spendKind': serializer.toJson<int?>($MerchantRulesTable.$converterspendKindn.toJson(spendKind)),
    };
  }

  MerchantRule copyWith({
    int? id,
    String? pattern,
    Value<int?> categoryId = const Value.absent(),
    Value<bool?> countsInBudget = const Value.absent(),
    Value<Bucket?> bucket = const Value.absent(),
    Value<SpendKind?> spendKind = const Value.absent(),
  }) => MerchantRule(
    id: id ?? this.id,
    pattern: pattern ?? this.pattern,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    countsInBudget: countsInBudget.present ? countsInBudget.value : this.countsInBudget,
    bucket: bucket.present ? bucket.value : this.bucket,
    spendKind: spendKind.present ? spendKind.value : this.spendKind,
  );
  MerchantRule copyWithCompanion(MerchantRulesCompanion data) {
    return MerchantRule(
      id: data.id.present ? data.id.value : this.id,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      countsInBudget: data.countsInBudget.present ? data.countsInBudget.value : this.countsInBudget,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      spendKind: data.spendKind.present ? data.spendKind.value : this.spendKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRule(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryId: $categoryId, ')
          ..write('countsInBudget: $countsInBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pattern, categoryId, countsInBudget, bucket, spendKind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantRule &&
          other.id == this.id &&
          other.pattern == this.pattern &&
          other.categoryId == this.categoryId &&
          other.countsInBudget == this.countsInBudget &&
          other.bucket == this.bucket &&
          other.spendKind == this.spendKind);
}

class MerchantRulesCompanion extends UpdateCompanion<MerchantRule> {
  final Value<int> id;
  final Value<String> pattern;
  final Value<int?> categoryId;
  final Value<bool?> countsInBudget;
  final Value<Bucket?> bucket;
  final Value<SpendKind?> spendKind;
  const MerchantRulesCompanion({
    this.id = const Value.absent(),
    this.pattern = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.countsInBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  });
  MerchantRulesCompanion.insert({
    this.id = const Value.absent(),
    required String pattern,
    this.categoryId = const Value.absent(),
    this.countsInBudget = const Value.absent(),
    this.bucket = const Value.absent(),
    this.spendKind = const Value.absent(),
  }) : pattern = Value(pattern);
  static Insertable<MerchantRule> custom({
    Expression<int>? id,
    Expression<String>? pattern,
    Expression<int>? categoryId,
    Expression<bool>? countsInBudget,
    Expression<int>? bucket,
    Expression<int>? spendKind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pattern != null) 'pattern': pattern,
      if (categoryId != null) 'category_id': categoryId,
      if (countsInBudget != null) 'counts_in_budget': countsInBudget,
      if (bucket != null) 'bucket': bucket,
      if (spendKind != null) 'spend_kind': spendKind,
    });
  }

  MerchantRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? pattern,
    Value<int?>? categoryId,
    Value<bool?>? countsInBudget,
    Value<Bucket?>? bucket,
    Value<SpendKind?>? spendKind,
  }) {
    return MerchantRulesCompanion(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      categoryId: categoryId ?? this.categoryId,
      countsInBudget: countsInBudget ?? this.countsInBudget,
      bucket: bucket ?? this.bucket,
      spendKind: spendKind ?? this.spendKind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (countsInBudget.present) {
      map['counts_in_budget'] = Variable<bool>(countsInBudget.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<int>($MerchantRulesTable.$converterbucketn.toSql(bucket.value));
    }
    if (spendKind.present) {
      map['spend_kind'] = Variable<int>($MerchantRulesTable.$converterspendKindn.toSql(spendKind.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRulesCompanion(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryId: $categoryId, ')
          ..write('countsInBudget: $countsInBudget, ')
          ..write('bucket: $bucket, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, amountMinor, currency, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(_amountMinorMeta, amountMinor.isAcceptableOrUnknown(data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta, active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      amountMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      active: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int? categoryId;

  /// Limit per month, in minor units of [currency].
  final int amountMinor;

  /// A budget applies only while this is the home currency. Rows from
  /// before v4 are INR.
  final String currency;
  final bool active;
  final DateTime createdAt;
  const Budget({
    required this.id,
    this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int?>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Budget copyWith({
    int? id,
    Value<int?> categoryId = const Value.absent(),
    int? amountMinor,
    String? currency,
    bool? active,
    DateTime? createdAt,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      amountMinor: data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, amountMinor, currency, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int?> categoryId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int amountMinor,
    this.currency = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : amountMinor = Value(amountMinor);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int?>? categoryId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<bool>? active,
    Value<DateTime>? createdAt,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlanTable extends Plan with TableInfo<$PlanTable, MonthlyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta('startMonth');
  @override
  late final GeneratedColumn<DateTime> startMonth = GeneratedColumn<DateTime>(
    'start_month',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryMinorMeta = const VerificationMeta('salaryMinor');
  @override
  late final GeneratedColumn<int> salaryMinor = GeneratedColumn<int>(
    'salary_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _emiMinorMeta = const VerificationMeta('emiMinor');
  @override
  late final GeneratedColumn<int> emiMinor = GeneratedColumn<int>(
    'emi_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _emiEndsMeta = const VerificationMeta('emiEnds');
  @override
  late final GeneratedColumn<DateTime> emiEnds = GeneratedColumn<DateTime>(
    'emi_ends',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _investingMinorMeta = const VerificationMeta('investingMinor');
  @override
  late final GeneratedColumn<int> investingMinor = GeneratedColumn<int>(
    'investing_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fundMinorMeta = const VerificationMeta('fundMinor');
  @override
  late final GeneratedColumn<int> fundMinor = GeneratedColumn<int>(
    'fund_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000000),
  );
  static const VerificationMeta _goal1MinorMeta = const VerificationMeta('goal1Minor');
  @override
  late final GeneratedColumn<int> goal1Minor = GeneratedColumn<int>(
    'goal1_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goal1DueMeta = const VerificationMeta('goal1Due');
  @override
  late final GeneratedColumn<DateTime> goal1Due = GeneratedColumn<DateTime>(
    'goal1_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goal2MinorMeta = const VerificationMeta('goal2Minor');
  @override
  late final GeneratedColumn<int> goal2Minor = GeneratedColumn<int>(
    'goal2_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goal2DueMeta = const VerificationMeta('goal2Due');
  @override
  late final GeneratedColumn<DateTime> goal2Due = GeneratedColumn<DateTime>(
    'goal2_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goal3MinorMeta = const VerificationMeta('goal3Minor');
  @override
  late final GeneratedColumn<int> goal3Minor = GeneratedColumn<int>(
    'goal3_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goal3DueMeta = const VerificationMeta('goal3Due');
  @override
  late final GeneratedColumn<DateTime> goal3Due = GeneratedColumn<DateTime>(
    'goal3_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyGoalMinorMeta = const VerificationMeta('emergencyGoalMinor');
  @override
  late final GeneratedColumn<int> emergencyGoalMinor = GeneratedColumn<int>(
    'emergency_goal_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startMonth,
    salaryMinor,
    emiMinor,
    emiEnds,
    investingMinor,
    fundMinor,
    goal1Minor,
    goal1Due,
    goal2Minor,
    goal2Due,
    goal3Minor,
    goal3Due,
    emergencyGoalMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan';
  @override
  VerificationContext validateIntegrity(Insertable<MonthlyPlan> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_month')) {
      context.handle(_startMonthMeta, startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta));
    } else if (isInserting) {
      context.missing(_startMonthMeta);
    }
    if (data.containsKey('salary_minor')) {
      context.handle(_salaryMinorMeta, salaryMinor.isAcceptableOrUnknown(data['salary_minor']!, _salaryMinorMeta));
    }
    if (data.containsKey('emi_minor')) {
      context.handle(_emiMinorMeta, emiMinor.isAcceptableOrUnknown(data['emi_minor']!, _emiMinorMeta));
    }
    if (data.containsKey('emi_ends')) {
      context.handle(_emiEndsMeta, emiEnds.isAcceptableOrUnknown(data['emi_ends']!, _emiEndsMeta));
    }
    if (data.containsKey('investing_minor')) {
      context.handle(
        _investingMinorMeta,
        investingMinor.isAcceptableOrUnknown(data['investing_minor']!, _investingMinorMeta),
      );
    }
    if (data.containsKey('fund_minor')) {
      context.handle(_fundMinorMeta, fundMinor.isAcceptableOrUnknown(data['fund_minor']!, _fundMinorMeta));
    }
    if (data.containsKey('goal1_minor')) {
      context.handle(_goal1MinorMeta, goal1Minor.isAcceptableOrUnknown(data['goal1_minor']!, _goal1MinorMeta));
    }
    if (data.containsKey('goal1_due')) {
      context.handle(_goal1DueMeta, goal1Due.isAcceptableOrUnknown(data['goal1_due']!, _goal1DueMeta));
    }
    if (data.containsKey('goal2_minor')) {
      context.handle(_goal2MinorMeta, goal2Minor.isAcceptableOrUnknown(data['goal2_minor']!, _goal2MinorMeta));
    }
    if (data.containsKey('goal2_due')) {
      context.handle(_goal2DueMeta, goal2Due.isAcceptableOrUnknown(data['goal2_due']!, _goal2DueMeta));
    }
    if (data.containsKey('goal3_minor')) {
      context.handle(_goal3MinorMeta, goal3Minor.isAcceptableOrUnknown(data['goal3_minor']!, _goal3MinorMeta));
    }
    if (data.containsKey('goal3_due')) {
      context.handle(_goal3DueMeta, goal3Due.isAcceptableOrUnknown(data['goal3_due']!, _goal3DueMeta));
    }
    if (data.containsKey('emergency_goal_minor')) {
      context.handle(
        _emergencyGoalMinorMeta,
        emergencyGoalMinor.isAcceptableOrUnknown(data['emergency_goal_minor']!, _emergencyGoalMinorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthlyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyPlan(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startMonth: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}start_month'])!,
      salaryMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}salary_minor'])!,
      emiMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}emi_minor'])!,
      emiEnds: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}emi_ends']),
      investingMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}investing_minor'])!,
      fundMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fund_minor'])!,
      goal1Minor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}goal1_minor']),
      goal1Due: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}goal1_due']),
      goal2Minor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}goal2_minor']),
      goal2Due: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}goal2_due']),
      goal3Minor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}goal3_minor']),
      goal3Due: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}goal3_due']),
      emergencyGoalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}emergency_goal_minor'],
      ),
    );
  }

  @override
  $PlanTable createAlias(String alias) {
    return $PlanTable(attachedDatabase, alias);
  }
}

class MonthlyPlan extends DataClass implements Insertable<MonthlyPlan> {
  final int id;

  /// Month the plan started; the fund is measured from here.
  final DateTime startMonth;
  final int salaryMinor;
  final int emiMinor;

  /// Last month the EMI is paid.
  final DateTime? emiEnds;

  /// Investing per month, not counting goal savings.
  final int investingMinor;
  final int fundMinor;

  /// Up to three goals, in entry order (emergency fund first): the amount
  /// still to save and the month it's due.
  final int? goal1Minor;
  final DateTime? goal1Due;
  final int? goal2Minor;
  final DateTime? goal2Due;
  final int? goal3Minor;
  final DateTime? goal3Due;

  /// What the emergency fund should hold in all; null until set. The
  /// holdings are in [EmergencyHoldings].
  final int? emergencyGoalMinor;
  const MonthlyPlan({
    required this.id,
    required this.startMonth,
    required this.salaryMinor,
    required this.emiMinor,
    this.emiEnds,
    required this.investingMinor,
    required this.fundMinor,
    this.goal1Minor,
    this.goal1Due,
    this.goal2Minor,
    this.goal2Due,
    this.goal3Minor,
    this.goal3Due,
    this.emergencyGoalMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_month'] = Variable<DateTime>(startMonth);
    map['salary_minor'] = Variable<int>(salaryMinor);
    map['emi_minor'] = Variable<int>(emiMinor);
    if (!nullToAbsent || emiEnds != null) {
      map['emi_ends'] = Variable<DateTime>(emiEnds);
    }
    map['investing_minor'] = Variable<int>(investingMinor);
    map['fund_minor'] = Variable<int>(fundMinor);
    if (!nullToAbsent || goal1Minor != null) {
      map['goal1_minor'] = Variable<int>(goal1Minor);
    }
    if (!nullToAbsent || goal1Due != null) {
      map['goal1_due'] = Variable<DateTime>(goal1Due);
    }
    if (!nullToAbsent || goal2Minor != null) {
      map['goal2_minor'] = Variable<int>(goal2Minor);
    }
    if (!nullToAbsent || goal2Due != null) {
      map['goal2_due'] = Variable<DateTime>(goal2Due);
    }
    if (!nullToAbsent || goal3Minor != null) {
      map['goal3_minor'] = Variable<int>(goal3Minor);
    }
    if (!nullToAbsent || goal3Due != null) {
      map['goal3_due'] = Variable<DateTime>(goal3Due);
    }
    if (!nullToAbsent || emergencyGoalMinor != null) {
      map['emergency_goal_minor'] = Variable<int>(emergencyGoalMinor);
    }
    return map;
  }

  PlanCompanion toCompanion(bool nullToAbsent) {
    return PlanCompanion(
      id: Value(id),
      startMonth: Value(startMonth),
      salaryMinor: Value(salaryMinor),
      emiMinor: Value(emiMinor),
      emiEnds: emiEnds == null && nullToAbsent ? const Value.absent() : Value(emiEnds),
      investingMinor: Value(investingMinor),
      fundMinor: Value(fundMinor),
      goal1Minor: goal1Minor == null && nullToAbsent ? const Value.absent() : Value(goal1Minor),
      goal1Due: goal1Due == null && nullToAbsent ? const Value.absent() : Value(goal1Due),
      goal2Minor: goal2Minor == null && nullToAbsent ? const Value.absent() : Value(goal2Minor),
      goal2Due: goal2Due == null && nullToAbsent ? const Value.absent() : Value(goal2Due),
      goal3Minor: goal3Minor == null && nullToAbsent ? const Value.absent() : Value(goal3Minor),
      goal3Due: goal3Due == null && nullToAbsent ? const Value.absent() : Value(goal3Due),
      emergencyGoalMinor: emergencyGoalMinor == null && nullToAbsent ? const Value.absent() : Value(emergencyGoalMinor),
    );
  }

  factory MonthlyPlan.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyPlan(
      id: serializer.fromJson<int>(json['id']),
      startMonth: serializer.fromJson<DateTime>(json['startMonth']),
      salaryMinor: serializer.fromJson<int>(json['salaryMinor']),
      emiMinor: serializer.fromJson<int>(json['emiMinor']),
      emiEnds: serializer.fromJson<DateTime?>(json['emiEnds']),
      investingMinor: serializer.fromJson<int>(json['investingMinor']),
      fundMinor: serializer.fromJson<int>(json['fundMinor']),
      goal1Minor: serializer.fromJson<int?>(json['goal1Minor']),
      goal1Due: serializer.fromJson<DateTime?>(json['goal1Due']),
      goal2Minor: serializer.fromJson<int?>(json['goal2Minor']),
      goal2Due: serializer.fromJson<DateTime?>(json['goal2Due']),
      goal3Minor: serializer.fromJson<int?>(json['goal3Minor']),
      goal3Due: serializer.fromJson<DateTime?>(json['goal3Due']),
      emergencyGoalMinor: serializer.fromJson<int?>(json['emergencyGoalMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startMonth': serializer.toJson<DateTime>(startMonth),
      'salaryMinor': serializer.toJson<int>(salaryMinor),
      'emiMinor': serializer.toJson<int>(emiMinor),
      'emiEnds': serializer.toJson<DateTime?>(emiEnds),
      'investingMinor': serializer.toJson<int>(investingMinor),
      'fundMinor': serializer.toJson<int>(fundMinor),
      'goal1Minor': serializer.toJson<int?>(goal1Minor),
      'goal1Due': serializer.toJson<DateTime?>(goal1Due),
      'goal2Minor': serializer.toJson<int?>(goal2Minor),
      'goal2Due': serializer.toJson<DateTime?>(goal2Due),
      'goal3Minor': serializer.toJson<int?>(goal3Minor),
      'goal3Due': serializer.toJson<DateTime?>(goal3Due),
      'emergencyGoalMinor': serializer.toJson<int?>(emergencyGoalMinor),
    };
  }

  MonthlyPlan copyWith({
    int? id,
    DateTime? startMonth,
    int? salaryMinor,
    int? emiMinor,
    Value<DateTime?> emiEnds = const Value.absent(),
    int? investingMinor,
    int? fundMinor,
    Value<int?> goal1Minor = const Value.absent(),
    Value<DateTime?> goal1Due = const Value.absent(),
    Value<int?> goal2Minor = const Value.absent(),
    Value<DateTime?> goal2Due = const Value.absent(),
    Value<int?> goal3Minor = const Value.absent(),
    Value<DateTime?> goal3Due = const Value.absent(),
    Value<int?> emergencyGoalMinor = const Value.absent(),
  }) => MonthlyPlan(
    id: id ?? this.id,
    startMonth: startMonth ?? this.startMonth,
    salaryMinor: salaryMinor ?? this.salaryMinor,
    emiMinor: emiMinor ?? this.emiMinor,
    emiEnds: emiEnds.present ? emiEnds.value : this.emiEnds,
    investingMinor: investingMinor ?? this.investingMinor,
    fundMinor: fundMinor ?? this.fundMinor,
    goal1Minor: goal1Minor.present ? goal1Minor.value : this.goal1Minor,
    goal1Due: goal1Due.present ? goal1Due.value : this.goal1Due,
    goal2Minor: goal2Minor.present ? goal2Minor.value : this.goal2Minor,
    goal2Due: goal2Due.present ? goal2Due.value : this.goal2Due,
    goal3Minor: goal3Minor.present ? goal3Minor.value : this.goal3Minor,
    goal3Due: goal3Due.present ? goal3Due.value : this.goal3Due,
    emergencyGoalMinor: emergencyGoalMinor.present ? emergencyGoalMinor.value : this.emergencyGoalMinor,
  );
  MonthlyPlan copyWithCompanion(PlanCompanion data) {
    return MonthlyPlan(
      id: data.id.present ? data.id.value : this.id,
      startMonth: data.startMonth.present ? data.startMonth.value : this.startMonth,
      salaryMinor: data.salaryMinor.present ? data.salaryMinor.value : this.salaryMinor,
      emiMinor: data.emiMinor.present ? data.emiMinor.value : this.emiMinor,
      emiEnds: data.emiEnds.present ? data.emiEnds.value : this.emiEnds,
      investingMinor: data.investingMinor.present ? data.investingMinor.value : this.investingMinor,
      fundMinor: data.fundMinor.present ? data.fundMinor.value : this.fundMinor,
      goal1Minor: data.goal1Minor.present ? data.goal1Minor.value : this.goal1Minor,
      goal1Due: data.goal1Due.present ? data.goal1Due.value : this.goal1Due,
      goal2Minor: data.goal2Minor.present ? data.goal2Minor.value : this.goal2Minor,
      goal2Due: data.goal2Due.present ? data.goal2Due.value : this.goal2Due,
      goal3Minor: data.goal3Minor.present ? data.goal3Minor.value : this.goal3Minor,
      goal3Due: data.goal3Due.present ? data.goal3Due.value : this.goal3Due,
      emergencyGoalMinor: data.emergencyGoalMinor.present ? data.emergencyGoalMinor.value : this.emergencyGoalMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyPlan(')
          ..write('id: $id, ')
          ..write('startMonth: $startMonth, ')
          ..write('salaryMinor: $salaryMinor, ')
          ..write('emiMinor: $emiMinor, ')
          ..write('emiEnds: $emiEnds, ')
          ..write('investingMinor: $investingMinor, ')
          ..write('fundMinor: $fundMinor, ')
          ..write('goal1Minor: $goal1Minor, ')
          ..write('goal1Due: $goal1Due, ')
          ..write('goal2Minor: $goal2Minor, ')
          ..write('goal2Due: $goal2Due, ')
          ..write('goal3Minor: $goal3Minor, ')
          ..write('goal3Due: $goal3Due, ')
          ..write('emergencyGoalMinor: $emergencyGoalMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startMonth,
    salaryMinor,
    emiMinor,
    emiEnds,
    investingMinor,
    fundMinor,
    goal1Minor,
    goal1Due,
    goal2Minor,
    goal2Due,
    goal3Minor,
    goal3Due,
    emergencyGoalMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyPlan &&
          other.id == this.id &&
          other.startMonth == this.startMonth &&
          other.salaryMinor == this.salaryMinor &&
          other.emiMinor == this.emiMinor &&
          other.emiEnds == this.emiEnds &&
          other.investingMinor == this.investingMinor &&
          other.fundMinor == this.fundMinor &&
          other.goal1Minor == this.goal1Minor &&
          other.goal1Due == this.goal1Due &&
          other.goal2Minor == this.goal2Minor &&
          other.goal2Due == this.goal2Due &&
          other.goal3Minor == this.goal3Minor &&
          other.goal3Due == this.goal3Due &&
          other.emergencyGoalMinor == this.emergencyGoalMinor);
}

class PlanCompanion extends UpdateCompanion<MonthlyPlan> {
  final Value<int> id;
  final Value<DateTime> startMonth;
  final Value<int> salaryMinor;
  final Value<int> emiMinor;
  final Value<DateTime?> emiEnds;
  final Value<int> investingMinor;
  final Value<int> fundMinor;
  final Value<int?> goal1Minor;
  final Value<DateTime?> goal1Due;
  final Value<int?> goal2Minor;
  final Value<DateTime?> goal2Due;
  final Value<int?> goal3Minor;
  final Value<DateTime?> goal3Due;
  final Value<int?> emergencyGoalMinor;
  const PlanCompanion({
    this.id = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.salaryMinor = const Value.absent(),
    this.emiMinor = const Value.absent(),
    this.emiEnds = const Value.absent(),
    this.investingMinor = const Value.absent(),
    this.fundMinor = const Value.absent(),
    this.goal1Minor = const Value.absent(),
    this.goal1Due = const Value.absent(),
    this.goal2Minor = const Value.absent(),
    this.goal2Due = const Value.absent(),
    this.goal3Minor = const Value.absent(),
    this.goal3Due = const Value.absent(),
    this.emergencyGoalMinor = const Value.absent(),
  });
  PlanCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startMonth,
    this.salaryMinor = const Value.absent(),
    this.emiMinor = const Value.absent(),
    this.emiEnds = const Value.absent(),
    this.investingMinor = const Value.absent(),
    this.fundMinor = const Value.absent(),
    this.goal1Minor = const Value.absent(),
    this.goal1Due = const Value.absent(),
    this.goal2Minor = const Value.absent(),
    this.goal2Due = const Value.absent(),
    this.goal3Minor = const Value.absent(),
    this.goal3Due = const Value.absent(),
    this.emergencyGoalMinor = const Value.absent(),
  }) : startMonth = Value(startMonth);
  static Insertable<MonthlyPlan> custom({
    Expression<int>? id,
    Expression<DateTime>? startMonth,
    Expression<int>? salaryMinor,
    Expression<int>? emiMinor,
    Expression<DateTime>? emiEnds,
    Expression<int>? investingMinor,
    Expression<int>? fundMinor,
    Expression<int>? goal1Minor,
    Expression<DateTime>? goal1Due,
    Expression<int>? goal2Minor,
    Expression<DateTime>? goal2Due,
    Expression<int>? goal3Minor,
    Expression<DateTime>? goal3Due,
    Expression<int>? emergencyGoalMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startMonth != null) 'start_month': startMonth,
      if (salaryMinor != null) 'salary_minor': salaryMinor,
      if (emiMinor != null) 'emi_minor': emiMinor,
      if (emiEnds != null) 'emi_ends': emiEnds,
      if (investingMinor != null) 'investing_minor': investingMinor,
      if (fundMinor != null) 'fund_minor': fundMinor,
      if (goal1Minor != null) 'goal1_minor': goal1Minor,
      if (goal1Due != null) 'goal1_due': goal1Due,
      if (goal2Minor != null) 'goal2_minor': goal2Minor,
      if (goal2Due != null) 'goal2_due': goal2Due,
      if (goal3Minor != null) 'goal3_minor': goal3Minor,
      if (goal3Due != null) 'goal3_due': goal3Due,
      if (emergencyGoalMinor != null) 'emergency_goal_minor': emergencyGoalMinor,
    });
  }

  PlanCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startMonth,
    Value<int>? salaryMinor,
    Value<int>? emiMinor,
    Value<DateTime?>? emiEnds,
    Value<int>? investingMinor,
    Value<int>? fundMinor,
    Value<int?>? goal1Minor,
    Value<DateTime?>? goal1Due,
    Value<int?>? goal2Minor,
    Value<DateTime?>? goal2Due,
    Value<int?>? goal3Minor,
    Value<DateTime?>? goal3Due,
    Value<int?>? emergencyGoalMinor,
  }) {
    return PlanCompanion(
      id: id ?? this.id,
      startMonth: startMonth ?? this.startMonth,
      salaryMinor: salaryMinor ?? this.salaryMinor,
      emiMinor: emiMinor ?? this.emiMinor,
      emiEnds: emiEnds ?? this.emiEnds,
      investingMinor: investingMinor ?? this.investingMinor,
      fundMinor: fundMinor ?? this.fundMinor,
      goal1Minor: goal1Minor ?? this.goal1Minor,
      goal1Due: goal1Due ?? this.goal1Due,
      goal2Minor: goal2Minor ?? this.goal2Minor,
      goal2Due: goal2Due ?? this.goal2Due,
      goal3Minor: goal3Minor ?? this.goal3Minor,
      goal3Due: goal3Due ?? this.goal3Due,
      emergencyGoalMinor: emergencyGoalMinor ?? this.emergencyGoalMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<DateTime>(startMonth.value);
    }
    if (salaryMinor.present) {
      map['salary_minor'] = Variable<int>(salaryMinor.value);
    }
    if (emiMinor.present) {
      map['emi_minor'] = Variable<int>(emiMinor.value);
    }
    if (emiEnds.present) {
      map['emi_ends'] = Variable<DateTime>(emiEnds.value);
    }
    if (investingMinor.present) {
      map['investing_minor'] = Variable<int>(investingMinor.value);
    }
    if (fundMinor.present) {
      map['fund_minor'] = Variable<int>(fundMinor.value);
    }
    if (goal1Minor.present) {
      map['goal1_minor'] = Variable<int>(goal1Minor.value);
    }
    if (goal1Due.present) {
      map['goal1_due'] = Variable<DateTime>(goal1Due.value);
    }
    if (goal2Minor.present) {
      map['goal2_minor'] = Variable<int>(goal2Minor.value);
    }
    if (goal2Due.present) {
      map['goal2_due'] = Variable<DateTime>(goal2Due.value);
    }
    if (goal3Minor.present) {
      map['goal3_minor'] = Variable<int>(goal3Minor.value);
    }
    if (goal3Due.present) {
      map['goal3_due'] = Variable<DateTime>(goal3Due.value);
    }
    if (emergencyGoalMinor.present) {
      map['emergency_goal_minor'] = Variable<int>(emergencyGoalMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanCompanion(')
          ..write('id: $id, ')
          ..write('startMonth: $startMonth, ')
          ..write('salaryMinor: $salaryMinor, ')
          ..write('emiMinor: $emiMinor, ')
          ..write('emiEnds: $emiEnds, ')
          ..write('investingMinor: $investingMinor, ')
          ..write('fundMinor: $fundMinor, ')
          ..write('goal1Minor: $goal1Minor, ')
          ..write('goal1Due: $goal1Due, ')
          ..write('goal2Minor: $goal2Minor, ')
          ..write('goal2Due: $goal2Due, ')
          ..write('goal3Minor: $goal3Minor, ')
          ..write('goal3Due: $goal3Due, ')
          ..write('emergencyGoalMinor: $emergencyGoalMinor')
          ..write(')'))
        .toString();
  }
}

class $BalanceSnapshotsTable extends BalanceSnapshots with TableInfo<$BalanceSnapshotsTable, BalanceSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<DateTime> month = GeneratedColumn<DateTime>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLiabilityMeta = const VerificationMeta('isLiability');
  @override
  late final GeneratedColumn<bool> isLiability = GeneratedColumn<bool>(
    'is_liability',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_liability" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, month, label, amountMinor, isLiability];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<BalanceSnapshot> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(_monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(_amountMinorMeta, amountMinor.isAcceptableOrUnknown(data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('is_liability')) {
      context.handle(_isLiabilityMeta, isLiability.isAcceptableOrUnknown(data['is_liability']!, _isLiabilityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {month, label},
  ];
  @override
  BalanceSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceSnapshot(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}month'])!,
      label: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      amountMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      isLiability: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_liability'])!,
    );
  }

  @override
  $BalanceSnapshotsTable createAlias(String alias) {
    return $BalanceSnapshotsTable(attachedDatabase, alias);
  }
}

class BalanceSnapshot extends DataClass implements Insertable<BalanceSnapshot> {
  final int id;

  /// The 1st of the month.
  final DateTime month;
  final String label;
  final int amountMinor;
  final bool isLiability;
  const BalanceSnapshot({
    required this.id,
    required this.month,
    required this.label,
    required this.amountMinor,
    required this.isLiability,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<DateTime>(month);
    map['label'] = Variable<String>(label);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['is_liability'] = Variable<bool>(isLiability);
    return map;
  }

  BalanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return BalanceSnapshotsCompanion(
      id: Value(id),
      month: Value(month),
      label: Value(label),
      amountMinor: Value(amountMinor),
      isLiability: Value(isLiability),
    );
  }

  factory BalanceSnapshot.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceSnapshot(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<DateTime>(json['month']),
      label: serializer.fromJson<String>(json['label']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      isLiability: serializer.fromJson<bool>(json['isLiability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<DateTime>(month),
      'label': serializer.toJson<String>(label),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'isLiability': serializer.toJson<bool>(isLiability),
    };
  }

  BalanceSnapshot copyWith({int? id, DateTime? month, String? label, int? amountMinor, bool? isLiability}) =>
      BalanceSnapshot(
        id: id ?? this.id,
        month: month ?? this.month,
        label: label ?? this.label,
        amountMinor: amountMinor ?? this.amountMinor,
        isLiability: isLiability ?? this.isLiability,
      );
  BalanceSnapshot copyWithCompanion(BalanceSnapshotsCompanion data) {
    return BalanceSnapshot(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      label: data.label.present ? data.label.value : this.label,
      amountMinor: data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      isLiability: data.isLiability.present ? data.isLiability.value : this.isLiability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshot(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('label: $label, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('isLiability: $isLiability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, month, label, amountMinor, isLiability);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceSnapshot &&
          other.id == this.id &&
          other.month == this.month &&
          other.label == this.label &&
          other.amountMinor == this.amountMinor &&
          other.isLiability == this.isLiability);
}

class BalanceSnapshotsCompanion extends UpdateCompanion<BalanceSnapshot> {
  final Value<int> id;
  final Value<DateTime> month;
  final Value<String> label;
  final Value<int> amountMinor;
  final Value<bool> isLiability;
  const BalanceSnapshotsCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.label = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.isLiability = const Value.absent(),
  });
  BalanceSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime month,
    required String label,
    required int amountMinor,
    this.isLiability = const Value.absent(),
  }) : month = Value(month),
       label = Value(label),
       amountMinor = Value(amountMinor);
  static Insertable<BalanceSnapshot> custom({
    Expression<int>? id,
    Expression<DateTime>? month,
    Expression<String>? label,
    Expression<int>? amountMinor,
    Expression<bool>? isLiability,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (label != null) 'label': label,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (isLiability != null) 'is_liability': isLiability,
    });
  }

  BalanceSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? month,
    Value<String>? label,
    Value<int>? amountMinor,
    Value<bool>? isLiability,
  }) {
    return BalanceSnapshotsCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      label: label ?? this.label,
      amountMinor: amountMinor ?? this.amountMinor,
      isLiability: isLiability ?? this.isLiability,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<DateTime>(month.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (isLiability.present) {
      map['is_liability'] = Variable<bool>(isLiability.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('label: $label, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('isLiability: $isLiability')
          ..write(')'))
        .toString();
  }
}

class $EmisTable extends Emis with TableInfo<$EmisTable, Emi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMonthMeta = const VerificationMeta('lastMonth');
  @override
  late final GeneratedColumn<DateTime> lastMonth = GeneratedColumn<DateTime>(
    'last_month',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SpendKind, int> spendKind = GeneratedColumn<int>(
    'spend_kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<SpendKind>($EmisTable.$converterspendKind);
  @override
  List<GeneratedColumn> get $columns => [id, name, amountMinor, lastMonth, spendKind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emis';
  @override
  VerificationContext validateIntegrity(Insertable<Emi> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(_amountMinorMeta, amountMinor.isAcceptableOrUnknown(data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('last_month')) {
      context.handle(_lastMonthMeta, lastMonth.isAcceptableOrUnknown(data['last_month']!, _lastMonthMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Emi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Emi(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      lastMonth: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_month']),
      spendKind: $EmisTable.$converterspendKind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}spend_kind'])!,
      ),
    );
  }

  @override
  $EmisTable createAlias(String alias) {
    return $EmisTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SpendKind, int, int> $converterspendKind = const EnumIndexConverter<SpendKind>(
    SpendKind.values,
  );
}

class Emi extends DataClass implements Insertable<Emi> {
  final int id;
  final String name;

  /// Home-currency minor units per month.
  final int amountMinor;

  /// The 1st of the last month it is paid; null while unknown.
  final DateTime? lastMonth;

  /// Need or want, for the salary card. Defaults to need (index 0).
  final SpendKind spendKind;
  const Emi({required this.id, required this.name, required this.amountMinor, this.lastMonth, required this.spendKind});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || lastMonth != null) {
      map['last_month'] = Variable<DateTime>(lastMonth);
    }
    {
      map['spend_kind'] = Variable<int>($EmisTable.$converterspendKind.toSql(spendKind));
    }
    return map;
  }

  EmisCompanion toCompanion(bool nullToAbsent) {
    return EmisCompanion(
      id: Value(id),
      name: Value(name),
      amountMinor: Value(amountMinor),
      lastMonth: lastMonth == null && nullToAbsent ? const Value.absent() : Value(lastMonth),
      spendKind: Value(spendKind),
    );
  }

  factory Emi.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Emi(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      lastMonth: serializer.fromJson<DateTime?>(json['lastMonth']),
      spendKind: $EmisTable.$converterspendKind.fromJson(serializer.fromJson<int>(json['spendKind'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'lastMonth': serializer.toJson<DateTime?>(lastMonth),
      'spendKind': serializer.toJson<int>($EmisTable.$converterspendKind.toJson(spendKind)),
    };
  }

  Emi copyWith({
    int? id,
    String? name,
    int? amountMinor,
    Value<DateTime?> lastMonth = const Value.absent(),
    SpendKind? spendKind,
  }) => Emi(
    id: id ?? this.id,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    lastMonth: lastMonth.present ? lastMonth.value : this.lastMonth,
    spendKind: spendKind ?? this.spendKind,
  );
  Emi copyWithCompanion(EmisCompanion data) {
    return Emi(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountMinor: data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      lastMonth: data.lastMonth.present ? data.lastMonth.value : this.lastMonth,
      spendKind: data.spendKind.present ? data.spendKind.value : this.spendKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Emi(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('lastMonth: $lastMonth, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, amountMinor, lastMonth, spendKind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Emi &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountMinor == this.amountMinor &&
          other.lastMonth == this.lastMonth &&
          other.spendKind == this.spendKind);
}

class EmisCompanion extends UpdateCompanion<Emi> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amountMinor;
  final Value<DateTime?> lastMonth;
  final Value<SpendKind> spendKind;
  const EmisCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.lastMonth = const Value.absent(),
    this.spendKind = const Value.absent(),
  });
  EmisCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amountMinor,
    this.lastMonth = const Value.absent(),
    this.spendKind = const Value.absent(),
  }) : name = Value(name),
       amountMinor = Value(amountMinor);
  static Insertable<Emi> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amountMinor,
    Expression<DateTime>? lastMonth,
    Expression<int>? spendKind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (lastMonth != null) 'last_month': lastMonth,
      if (spendKind != null) 'spend_kind': spendKind,
    });
  }

  EmisCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? amountMinor,
    Value<DateTime?>? lastMonth,
    Value<SpendKind>? spendKind,
  }) {
    return EmisCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      lastMonth: lastMonth ?? this.lastMonth,
      spendKind: spendKind ?? this.spendKind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (lastMonth.present) {
      map['last_month'] = Variable<DateTime>(lastMonth.value);
    }
    if (spendKind.present) {
      map['spend_kind'] = Variable<int>($EmisTable.$converterspendKind.toSql(spendKind.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmisCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('lastMonth: $lastMonth, ')
          ..write('spendKind: $spendKind')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog with TableInfo<$SyncLogTable, SyncLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta('trigger');
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _okMeta = const VerificationMeta('ok');
  @override
  late final GeneratedColumn<bool> ok = GeneratedColumn<bool>(
    'ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("ok" IN (0, 1))'),
  );
  static const VerificationMeta _transactionsMeta = const VerificationMeta('transactions');
  @override
  late final GeneratedColumn<int> transactions = GeneratedColumn<int>(
    'transactions',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, trigger, ok, transactions, bytes, error];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(Insertable<SyncLogData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(_triggerMeta, trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta));
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('ok')) {
      context.handle(_okMeta, ok.isAcceptableOrUnknown(data['ok']!, _okMeta));
    } else if (isInserting) {
      context.missing(_okMeta);
    }
    if (data.containsKey('transactions')) {
      context.handle(_transactionsMeta, transactions.isAcceptableOrUnknown(data['transactions']!, _transactionsMeta));
    }
    if (data.containsKey('bytes')) {
      context.handle(_bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    if (data.containsKey('error')) {
      context.handle(_errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      trigger: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}trigger'])!,
      ok: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}ok'])!,
      transactions: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}transactions']),
      bytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bytes']),
      error: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error']),
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogData extends DataClass implements Insertable<SyncLogData> {
  final int id;
  final DateTime at;
  final String trigger;
  final bool ok;
  final int? transactions;
  final int? bytes;
  final String? error;
  const SyncLogData({
    required this.id,
    required this.at,
    required this.trigger,
    required this.ok,
    this.transactions,
    this.bytes,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['trigger'] = Variable<String>(trigger);
    map['ok'] = Variable<bool>(ok);
    if (!nullToAbsent || transactions != null) {
      map['transactions'] = Variable<int>(transactions);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      at: Value(at),
      trigger: Value(trigger),
      ok: Value(ok),
      transactions: transactions == null && nullToAbsent ? const Value.absent() : Value(transactions),
      bytes: bytes == null && nullToAbsent ? const Value.absent() : Value(bytes),
      error: error == null && nullToAbsent ? const Value.absent() : Value(error),
    );
  }

  factory SyncLogData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogData(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      trigger: serializer.fromJson<String>(json['trigger']),
      ok: serializer.fromJson<bool>(json['ok']),
      transactions: serializer.fromJson<int?>(json['transactions']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'trigger': serializer.toJson<String>(trigger),
      'ok': serializer.toJson<bool>(ok),
      'transactions': serializer.toJson<int?>(transactions),
      'bytes': serializer.toJson<int?>(bytes),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncLogData copyWith({
    int? id,
    DateTime? at,
    String? trigger,
    bool? ok,
    Value<int?> transactions = const Value.absent(),
    Value<int?> bytes = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => SyncLogData(
    id: id ?? this.id,
    at: at ?? this.at,
    trigger: trigger ?? this.trigger,
    ok: ok ?? this.ok,
    transactions: transactions.present ? transactions.value : this.transactions,
    bytes: bytes.present ? bytes.value : this.bytes,
    error: error.present ? error.value : this.error,
  );
  SyncLogData copyWithCompanion(SyncLogCompanion data) {
    return SyncLogData(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      ok: data.ok.present ? data.ok.value : this.ok,
      transactions: data.transactions.present ? data.transactions.value : this.transactions,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogData(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('trigger: $trigger, ')
          ..write('ok: $ok, ')
          ..write('transactions: $transactions, ')
          ..write('bytes: $bytes, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, trigger, ok, transactions, bytes, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogData &&
          other.id == this.id &&
          other.at == this.at &&
          other.trigger == this.trigger &&
          other.ok == this.ok &&
          other.transactions == this.transactions &&
          other.bytes == this.bytes &&
          other.error == this.error);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogData> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> trigger;
  final Value<bool> ok;
  final Value<int?> transactions;
  final Value<int?> bytes;
  final Value<String?> error;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.trigger = const Value.absent(),
    this.ok = const Value.absent(),
    this.transactions = const Value.absent(),
    this.bytes = const Value.absent(),
    this.error = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String trigger,
    required bool ok,
    this.transactions = const Value.absent(),
    this.bytes = const Value.absent(),
    this.error = const Value.absent(),
  }) : at = Value(at),
       trigger = Value(trigger),
       ok = Value(ok);
  static Insertable<SyncLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? trigger,
    Expression<bool>? ok,
    Expression<int>? transactions,
    Expression<int>? bytes,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (trigger != null) 'trigger': trigger,
      if (ok != null) 'ok': ok,
      if (transactions != null) 'transactions': transactions,
      if (bytes != null) 'bytes': bytes,
      if (error != null) 'error': error,
    });
  }

  SyncLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? trigger,
    Value<bool>? ok,
    Value<int?>? transactions,
    Value<int?>? bytes,
    Value<String?>? error,
  }) {
    return SyncLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      trigger: trigger ?? this.trigger,
      ok: ok ?? this.ok,
      transactions: transactions ?? this.transactions,
      bytes: bytes ?? this.bytes,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (ok.present) {
      map['ok'] = Variable<bool>(ok.value);
    }
    if (transactions.present) {
      map['transactions'] = Variable<int>(transactions.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('trigger: $trigger, ')
          ..write('ok: $ok, ')
          ..write('transactions: $transactions, ')
          ..write('bytes: $bytes, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $EmergencyHoldingsTable extends EmergencyHoldings with TableInfo<$EmergencyHoldingsTable, EmergencyHolding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyHoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, amountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_holdings';
  @override
  VerificationContext validateIntegrity(Insertable<EmergencyHolding> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(_amountMinorMeta, amountMinor.isAcceptableOrUnknown(data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyHolding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyHolding(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountMinor: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
    );
  }

  @override
  $EmergencyHoldingsTable createAlias(String alias) {
    return $EmergencyHoldingsTable(attachedDatabase, alias);
  }
}

class EmergencyHolding extends DataClass implements Insertable<EmergencyHolding> {
  final int id;
  final String name;

  /// Home-currency minor units.
  final int amountMinor;
  const EmergencyHolding({required this.id, required this.name, required this.amountMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  EmergencyHoldingsCompanion toCompanion(bool nullToAbsent) {
    return EmergencyHoldingsCompanion(id: Value(id), name: Value(name), amountMinor: Value(amountMinor));
  }

  factory EmergencyHolding.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyHolding(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  EmergencyHolding copyWith({int? id, String? name, int? amountMinor}) =>
      EmergencyHolding(id: id ?? this.id, name: name ?? this.name, amountMinor: amountMinor ?? this.amountMinor);
  EmergencyHolding copyWithCompanion(EmergencyHoldingsCompanion data) {
    return EmergencyHolding(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountMinor: data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyHolding(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyHolding &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountMinor == this.amountMinor);
}

class EmergencyHoldingsCompanion extends UpdateCompanion<EmergencyHolding> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amountMinor;
  const EmergencyHoldingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
  });
  EmergencyHoldingsCompanion.insert({this.id = const Value.absent(), required String name, required int amountMinor})
    : name = Value(name),
      amountMinor = Value(amountMinor);
  static Insertable<EmergencyHolding> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amountMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountMinor != null) 'amount_minor': amountMinor,
    });
  }

  EmergencyHoldingsCompanion copyWith({Value<int>? id, Value<String>? name, Value<int>? amountMinor}) {
    return EmergencyHoldingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyHoldingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RawMessagesTable rawMessages = $RawMessagesTable(this);
  late final $MerchantRulesTable merchantRules = $MerchantRulesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $PlanTable plan = $PlanTable(this);
  late final $BalanceSnapshotsTable balanceSnapshots = $BalanceSnapshotsTable(this);
  late final $EmisTable emis = $EmisTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  late final $EmergencyHoldingsTable emergencyHoldings = $EmergencyHoldingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    transactions,
    rawMessages,
    merchantRules,
    budgets,
    plan,
    balanceSnapshots,
    emis,
    syncLog,
    emergencyHoldings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('transactions', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('raw_messages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('categories', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('merchant_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('categories', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('budgets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  required AccountKind kind,
  Value<String?> institution,
  Value<String?> last4,
  required int color,
  Value<bool> archived,
  Value<String> currency,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<AccountKind> kind,
  Value<String?> institution,
  Value<String?> last4,
  Value<int> color,
  Value<bool> archived,
  Value<String> currency,
});

final class $$AccountsTableReferences extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>> _transactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'accounts__id__transactions__account_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountKind, AccountKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get institution =>
      $composableBuilder(column: $table.institution, builder: (column) => column);

  GeneratedColumn<String> get last4 => $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountKind> kind = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> currency = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                kind: kind,
                institution: institution,
                last4: last4,
                color: color,
                archived: archived,
                currency: currency,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required AccountKind kind,
                Value<String?> institution = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                required int color,
                Value<bool> archived = const Value.absent(),
                Value<String> currency = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                institution: institution,
                last4: last4,
                color: color,
                archived: archived,
                currency: currency,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$AccountsTable, Account>(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Transaction>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String icon,
  required int color,
  Value<bool> isIncome,
  Value<int> sortOrder,
  Value<String?> seedName,
  Value<bool> countsInBudget,
  Value<Bucket> bucket,
  Value<SpendKind> spendKind,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<int> color,
  Value<bool> isIncome,
  Value<int> sortOrder,
  Value<String?> seedName,
  Value<bool> countsInBudget,
  Value<Bucket> bucket,
  Value<SpendKind> spendKind,
});

final class $$CategoriesTableReferences extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>> _transactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'categories__id__transactions__category_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MerchantRulesTable, List<MerchantRule>> _merchantRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.merchantRules, aliasName: 'categories__id__merchant_rules__category_id');

  $$MerchantRulesTableProcessedTableManager get merchantRulesRefs {
    final manager = $$MerchantRulesTableTableManager(
      $_db,
      $_db.merchantRules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_merchantRulesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets, aliasName: 'categories__id__budgets__category_id');

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isIncome =>
      $composableBuilder(column: $table.isIncome, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seedName =>
      $composableBuilder(column: $table.seedName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Bucket, Bucket, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<SpendKind, SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> merchantRulesRefs(Expression<bool> Function($$MerchantRulesTableFilterComposer f) f) {
    final $$MerchantRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantRulesTableFilterComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isIncome =>
      $composableBuilder(column: $table.isIncome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seedName =>
      $composableBuilder(column: $table.seedName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get seedName => $composableBuilder(column: $table.seedName, builder: (column) => column);

  GeneratedColumn<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Bucket, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> merchantRulesRefs<T extends Object>(
    Expression<T> Function($$MerchantRulesTableAnnotationComposer a) f,
  ) {
    final $$MerchantRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MerchantRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(Expression<T> Function($$BudgetsTableAnnotationComposer a) f) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool transactionsRefs, bool merchantRulesRefs, bool budgetsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isIncome = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> seedName = const Value.absent(),
                Value<bool> countsInBudget = const Value.absent(),
                Value<Bucket> bucket = const Value.absent(),
                Value<SpendKind> spendKind = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                color: color,
                isIncome: isIncome,
                sortOrder: sortOrder,
                seedName: seedName,
                countsInBudget: countsInBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String icon,
                required int color,
                Value<bool> isIncome = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> seedName = const Value.absent(),
                Value<bool> countsInBudget = const Value.absent(),
                Value<Bucket> bucket = const Value.absent(),
                Value<SpendKind> spendKind = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                color: color,
                isIncome: isIncome,
                sortOrder: sortOrder,
                seedName: seedName,
                countsInBudget: countsInBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$CategoriesTable, Category>(table), $$CategoriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false, merchantRulesRefs = false, budgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsRefs) db.transactions,
                if (merchantRulesRefs) db.merchantRules,
                if (budgetsRefs) db.budgets,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Transaction>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                  if (merchantRulesRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, MerchantRule>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._merchantRulesRefsTable(db),
                      managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).merchantRulesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                  if (budgetsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Budget>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._budgetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).budgetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool transactionsRefs, bool merchantRulesRefs, bool budgetsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  required int amountMinor,
  Value<String> currency,
  Value<int?> convertedMinor,
  Value<String?> convertedCurrency,
  required TxnDirection direction,
  required DateTime occurredAt,
  Value<String?> merchant,
  Value<String?> counterparty,
  Value<String?> note,
  Value<int?> categoryId,
  Value<int?> accountId,
  Value<String?> accountHint,
  required PaymentMode mode,
  Value<String?> reference,
  required TxnStatus status,
  Value<bool> isTransfer,
  Value<bool> categoryLocked,
  Value<int?> duplicateOfId,
  Value<DateTime> createdAt,
  Value<bool?> inBudget,
  Value<Bucket?> bucket,
  Value<SpendKind?> spendKind,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  Value<int> amountMinor,
  Value<String> currency,
  Value<int?> convertedMinor,
  Value<String?> convertedCurrency,
  Value<TxnDirection> direction,
  Value<DateTime> occurredAt,
  Value<String?> merchant,
  Value<String?> counterparty,
  Value<String?> note,
  Value<int?> categoryId,
  Value<int?> accountId,
  Value<String?> accountHint,
  Value<PaymentMode> mode,
  Value<String?> reference,
  Value<TxnStatus> status,
  Value<bool> isTransfer,
  Value<bool> categoryLocked,
  Value<int?> duplicateOfId,
  Value<DateTime> createdAt,
  Value<bool?> inBudget,
  Value<Bucket?> bucket,
  Value<SpendKind?> spendKind,
});

final class $$TransactionsTableReferences extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<int>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RawMessagesTable, List<RawMessage>> _rawMessagesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.rawMessages, aliasName: 'transactions__id__raw_messages__transaction_id');

  $$RawMessagesTableProcessedTableManager get rawMessagesRefs {
    final manager = $$RawMessagesTableTableManager(
      $_db,
      $_db.rawMessages,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rawMessagesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get convertedMinor =>
      $composableBuilder(column: $table.convertedMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get convertedCurrency =>
      $composableBuilder(column: $table.convertedCurrency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TxnDirection, TxnDirection, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterparty =>
      $composableBuilder(column: $table.counterparty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountHint =>
      $composableBuilder(column: $table.accountHint, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PaymentMode, PaymentMode, int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TxnStatus, TxnStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isTransfer =>
      $composableBuilder(column: $table.isTransfer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get categoryLocked =>
      $composableBuilder(column: $table.categoryLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duplicateOfId =>
      $composableBuilder(column: $table.duplicateOfId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get inBudget =>
      $composableBuilder(column: $table.inBudget, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Bucket?, Bucket, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<SpendKind?, SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnWithTypeConverterFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rawMessagesRefs(Expression<bool> Function($$RawMessagesTableFilterComposer f) f) {
    final $$RawMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawMessages,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RawMessagesTableFilterComposer(
            $db: $db,
            $table: $db.rawMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get convertedMinor =>
      $composableBuilder(column: $table.convertedMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get convertedCurrency =>
      $composableBuilder(column: $table.convertedCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterparty =>
      $composableBuilder(column: $table.counterparty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountHint =>
      $composableBuilder(column: $table.accountHint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTransfer =>
      $composableBuilder(column: $table.isTransfer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get categoryLocked =>
      $composableBuilder(column: $table.categoryLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duplicateOfId =>
      $composableBuilder(column: $table.duplicateOfId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get inBudget =>
      $composableBuilder(column: $table.inBudget, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get convertedMinor =>
      $composableBuilder(column: $table.convertedMinor, builder: (column) => column);

  GeneratedColumn<String> get convertedCurrency =>
      $composableBuilder(column: $table.convertedCurrency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnDirection, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get merchant => $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get counterparty =>
      $composableBuilder(column: $table.counterparty, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get accountHint =>
      $composableBuilder(column: $table.accountHint, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PaymentMode, int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get reference => $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isTransfer => $composableBuilder(column: $table.isTransfer, builder: (column) => column);

  GeneratedColumn<bool> get categoryLocked =>
      $composableBuilder(column: $table.categoryLocked, builder: (column) => column);

  GeneratedColumn<int> get duplicateOfId =>
      $composableBuilder(column: $table.duplicateOfId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get inBudget => $composableBuilder(column: $table.inBudget, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Bucket?, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SpendKind?, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rawMessagesRefs<T extends Object>(Expression<T> Function($$RawMessagesTableAnnotationComposer a) f) {
    final $$RawMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawMessages,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RawMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.rawMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool categoryId, bool accountId, bool rawMessagesRefs})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int?> convertedMinor = const Value.absent(),
                Value<String?> convertedCurrency = const Value.absent(),
                Value<TxnDirection> direction = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                Value<PaymentMode> mode = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<TxnStatus> status = const Value.absent(),
                Value<bool> isTransfer = const Value.absent(),
                Value<bool> categoryLocked = const Value.absent(),
                Value<int?> duplicateOfId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool?> inBudget = const Value.absent(),
                Value<Bucket?> bucket = const Value.absent(),
                Value<SpendKind?> spendKind = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                convertedMinor: convertedMinor,
                convertedCurrency: convertedCurrency,
                direction: direction,
                occurredAt: occurredAt,
                merchant: merchant,
                counterparty: counterparty,
                note: note,
                categoryId: categoryId,
                accountId: accountId,
                accountHint: accountHint,
                mode: mode,
                reference: reference,
                status: status,
                isTransfer: isTransfer,
                categoryLocked: categoryLocked,
                duplicateOfId: duplicateOfId,
                createdAt: createdAt,
                inBudget: inBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                Value<int?> convertedMinor = const Value.absent(),
                Value<String?> convertedCurrency = const Value.absent(),
                required TxnDirection direction,
                required DateTime occurredAt,
                Value<String?> merchant = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                required PaymentMode mode,
                Value<String?> reference = const Value.absent(),
                required TxnStatus status,
                Value<bool> isTransfer = const Value.absent(),
                Value<bool> categoryLocked = const Value.absent(),
                Value<int?> duplicateOfId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool?> inBudget = const Value.absent(),
                Value<Bucket?> bucket = const Value.absent(),
                Value<SpendKind?> spendKind = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                currency: currency,
                convertedMinor: convertedMinor,
                convertedCurrency: convertedCurrency,
                direction: direction,
                occurredAt: occurredAt,
                merchant: merchant,
                counterparty: counterparty,
                note: note,
                categoryId: categoryId,
                accountId: accountId,
                accountHint: accountHint,
                mode: mode,
                reference: reference,
                status: status,
                isTransfer: isTransfer,
                categoryLocked: categoryLocked,
                duplicateOfId: duplicateOfId,
                createdAt: createdAt,
                inBudget: inBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$TransactionsTable, Transaction>(table), $$TransactionsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false, accountId = false, rawMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (rawMessagesRefs) db.rawMessages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$TransactionsTableReferences._categoryIdTable(db),
                        referencedColumn: $$TransactionsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$TransactionsTableReferences._accountIdTable(db),
                        referencedColumn: $$TransactionsTableReferences._accountIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rawMessagesRefs)
                    await $_getPrefetchedData<Transaction, $TransactionsTable, RawMessage>(
                      currentTable: table,
                      referencedTable: $$TransactionsTableReferences._rawMessagesRefsTable(db),
                      managerFromTypedResult: (p0) => $$TransactionsTableReferences(db, table, p0).rawMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.transactionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool categoryId, bool accountId, bool rawMessagesRefs})
    >;
typedef $$RawMessagesTableCreateCompanionBuilder = RawMessagesCompanion Function({
  Value<int> id,
  required SourceKind source,
  required String externalId,
  required String sender,
  required String body,
  required DateTime receivedAt,
  required ParseStatus parseStatus,
  Value<String?> ignoreReason,
  Value<int?> transactionId,
  Value<double?> mergeScore,
});
typedef $$RawMessagesTableUpdateCompanionBuilder = RawMessagesCompanion Function({
  Value<int> id,
  Value<SourceKind> source,
  Value<String> externalId,
  Value<String> sender,
  Value<String> body,
  Value<DateTime> receivedAt,
  Value<ParseStatus> parseStatus,
  Value<String?> ignoreReason,
  Value<int?> transactionId,
  Value<double?> mergeScore,
});

final class $$RawMessagesTableReferences extends BaseReferences<_$AppDatabase, $RawMessagesTable, RawMessage> {
  $$RawMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias('raw_messages__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager? get transactionId {
    final $_column = $_itemColumn<int>('transaction_id');
    if ($_column == null) return null;
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RawMessagesTableFilterComposer extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SourceKind, SourceKind, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get externalId =>
      $composableBuilder(column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ParseStatus, ParseStatus, int> get parseStatus =>
      $composableBuilder(column: $table.parseStatus, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get ignoreReason =>
      $composableBuilder(column: $table.ignoreReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get mergeScore =>
      $composableBuilder(column: $table.mergeScore, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawMessagesTableOrderingComposer extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId =>
      $composableBuilder(column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parseStatus =>
      $composableBuilder(column: $table.parseStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ignoreReason =>
      $composableBuilder(column: $table.ignoreReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get mergeScore =>
      $composableBuilder(column: $table.mergeScore, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawMessagesTableAnnotationComposer extends Composer<_$AppDatabase, $RawMessagesTable> {
  $$RawMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceKind, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(column: $table.externalId, builder: (column) => column);

  GeneratedColumn<String> get sender => $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ParseStatus, int> get parseStatus =>
      $composableBuilder(column: $table.parseStatus, builder: (column) => column);

  GeneratedColumn<String> get ignoreReason =>
      $composableBuilder(column: $table.ignoreReason, builder: (column) => column);

  GeneratedColumn<double> get mergeScore => $composableBuilder(column: $table.mergeScore, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawMessagesTable,
          RawMessage,
          $$RawMessagesTableFilterComposer,
          $$RawMessagesTableOrderingComposer,
          $$RawMessagesTableAnnotationComposer,
          $$RawMessagesTableCreateCompanionBuilder,
          $$RawMessagesTableUpdateCompanionBuilder,
          (RawMessage, $$RawMessagesTableReferences),
          RawMessage,
          PrefetchHooks Function({bool transactionId})
        > {
  $$RawMessagesTableTableManager(_$AppDatabase db, $RawMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RawMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RawMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RawMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SourceKind> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<ParseStatus> parseStatus = const Value.absent(),
                Value<String?> ignoreReason = const Value.absent(),
                Value<int?> transactionId = const Value.absent(),
                Value<double?> mergeScore = const Value.absent(),
              }) => RawMessagesCompanion(
                id: id,
                source: source,
                externalId: externalId,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                parseStatus: parseStatus,
                ignoreReason: ignoreReason,
                transactionId: transactionId,
                mergeScore: mergeScore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SourceKind source,
                required String externalId,
                required String sender,
                required String body,
                required DateTime receivedAt,
                required ParseStatus parseStatus,
                Value<String?> ignoreReason = const Value.absent(),
                Value<int?> transactionId = const Value.absent(),
                Value<double?> mergeScore = const Value.absent(),
              }) => RawMessagesCompanion.insert(
                id: id,
                source: source,
                externalId: externalId,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                parseStatus: parseStatus,
                ignoreReason: ignoreReason,
                transactionId: transactionId,
                mergeScore: mergeScore,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$RawMessagesTable, RawMessage>(table), $$RawMessagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$RawMessagesTableReferences._transactionIdTable(db),
                        referencedColumn: $$RawMessagesTableReferences._transactionIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RawMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawMessagesTable,
      RawMessage,
      $$RawMessagesTableFilterComposer,
      $$RawMessagesTableOrderingComposer,
      $$RawMessagesTableAnnotationComposer,
      $$RawMessagesTableCreateCompanionBuilder,
      $$RawMessagesTableUpdateCompanionBuilder,
      (RawMessage, $$RawMessagesTableReferences),
      RawMessage,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$MerchantRulesTableCreateCompanionBuilder = MerchantRulesCompanion Function({
  Value<int> id,
  required String pattern,
  Value<int?> categoryId,
  Value<bool?> countsInBudget,
  Value<Bucket?> bucket,
  Value<SpendKind?> spendKind,
});
typedef $$MerchantRulesTableUpdateCompanionBuilder = MerchantRulesCompanion Function({
  Value<int> id,
  Value<String> pattern,
  Value<int?> categoryId,
  Value<bool?> countsInBudget,
  Value<Bucket?> bucket,
  Value<SpendKind?> spendKind,
});

final class $$MerchantRulesTableReferences extends BaseReferences<_$AppDatabase, $MerchantRulesTable, MerchantRule> {
  $$MerchantRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('merchant_rules__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MerchantRulesTableFilterComposer extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Bucket?, Bucket, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<SpendKind?, SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnWithTypeConverterFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableOrderingComposer extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableAnnotationComposer extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern => $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<bool> get countsInBudget =>
      $composableBuilder(column: $table.countsInBudget, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Bucket?, int> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SpendKind?, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantRulesTable,
          MerchantRule,
          $$MerchantRulesTableFilterComposer,
          $$MerchantRulesTableOrderingComposer,
          $$MerchantRulesTableAnnotationComposer,
          $$MerchantRulesTableCreateCompanionBuilder,
          $$MerchantRulesTableUpdateCompanionBuilder,
          (MerchantRule, $$MerchantRulesTableReferences),
          MerchantRule,
          PrefetchHooks Function({bool categoryId})
        > {
  $$MerchantRulesTableTableManager(_$AppDatabase db, $MerchantRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MerchantRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MerchantRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MerchantRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<bool?> countsInBudget = const Value.absent(),
                Value<Bucket?> bucket = const Value.absent(),
                Value<SpendKind?> spendKind = const Value.absent(),
              }) => MerchantRulesCompanion(
                id: id,
                pattern: pattern,
                categoryId: categoryId,
                countsInBudget: countsInBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String pattern,
                Value<int?> categoryId = const Value.absent(),
                Value<bool?> countsInBudget = const Value.absent(),
                Value<Bucket?> bucket = const Value.absent(),
                Value<SpendKind?> spendKind = const Value.absent(),
              }) => MerchantRulesCompanion.insert(
                id: id,
                pattern: pattern,
                categoryId: categoryId,
                countsInBudget: countsInBudget,
                bucket: bucket,
                spendKind: spendKind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantRulesTable, MerchantRule>(table),
                  $$MerchantRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$MerchantRulesTableReferences._categoryIdTable(db),
                        referencedColumn: $$MerchantRulesTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MerchantRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantRulesTable,
      MerchantRule,
      $$MerchantRulesTableFilterComposer,
      $$MerchantRulesTableOrderingComposer,
      $$MerchantRulesTableAnnotationComposer,
      $$MerchantRulesTableCreateCompanionBuilder,
      $$MerchantRulesTableUpdateCompanionBuilder,
      (MerchantRule, $$MerchantRulesTableReferences),
      MerchantRule,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  required int amountMinor,
  Value<String> currency,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  Value<int> amountMinor,
  Value<String> currency,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$BudgetsTableReferences extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableFilterComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get active => $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                amountMinor: amountMinor,
                currency: currency,
                active: active,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                amountMinor: amountMinor,
                currency: currency,
                active: active,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$BudgetsTable, Budget>(table), $$BudgetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$PlanTableCreateCompanionBuilder = PlanCompanion Function({
  Value<int> id,
  required DateTime startMonth,
  Value<int> salaryMinor,
  Value<int> emiMinor,
  Value<DateTime?> emiEnds,
  Value<int> investingMinor,
  Value<int> fundMinor,
  Value<int?> goal1Minor,
  Value<DateTime?> goal1Due,
  Value<int?> goal2Minor,
  Value<DateTime?> goal2Due,
  Value<int?> goal3Minor,
  Value<DateTime?> goal3Due,
  Value<int?> emergencyGoalMinor,
});
typedef $$PlanTableUpdateCompanionBuilder = PlanCompanion Function({
  Value<int> id,
  Value<DateTime> startMonth,
  Value<int> salaryMinor,
  Value<int> emiMinor,
  Value<DateTime?> emiEnds,
  Value<int> investingMinor,
  Value<int> fundMinor,
  Value<int?> goal1Minor,
  Value<DateTime?> goal1Due,
  Value<int?> goal2Minor,
  Value<DateTime?> goal2Due,
  Value<int?> goal3Minor,
  Value<DateTime?> goal3Due,
  Value<int?> emergencyGoalMinor,
});

class $$PlanTableFilterComposer extends Composer<_$AppDatabase, $PlanTable> {
  $$PlanTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startMonth =>
      $composableBuilder(column: $table.startMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get salaryMinor =>
      $composableBuilder(column: $table.salaryMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get emiMinor =>
      $composableBuilder(column: $table.emiMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get emiEnds =>
      $composableBuilder(column: $table.emiEnds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get investingMinor =>
      $composableBuilder(column: $table.investingMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fundMinor =>
      $composableBuilder(column: $table.fundMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goal1Minor =>
      $composableBuilder(column: $table.goal1Minor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get goal1Due =>
      $composableBuilder(column: $table.goal1Due, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goal2Minor =>
      $composableBuilder(column: $table.goal2Minor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get goal2Due =>
      $composableBuilder(column: $table.goal2Due, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goal3Minor =>
      $composableBuilder(column: $table.goal3Minor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get goal3Due =>
      $composableBuilder(column: $table.goal3Due, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get emergencyGoalMinor =>
      $composableBuilder(column: $table.emergencyGoalMinor, builder: (column) => ColumnFilters(column));
}

class $$PlanTableOrderingComposer extends Composer<_$AppDatabase, $PlanTable> {
  $$PlanTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startMonth =>
      $composableBuilder(column: $table.startMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get salaryMinor =>
      $composableBuilder(column: $table.salaryMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get emiMinor =>
      $composableBuilder(column: $table.emiMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get emiEnds =>
      $composableBuilder(column: $table.emiEnds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get investingMinor =>
      $composableBuilder(column: $table.investingMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fundMinor =>
      $composableBuilder(column: $table.fundMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goal1Minor =>
      $composableBuilder(column: $table.goal1Minor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get goal1Due =>
      $composableBuilder(column: $table.goal1Due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goal2Minor =>
      $composableBuilder(column: $table.goal2Minor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get goal2Due =>
      $composableBuilder(column: $table.goal2Due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goal3Minor =>
      $composableBuilder(column: $table.goal3Minor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get goal3Due =>
      $composableBuilder(column: $table.goal3Due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get emergencyGoalMinor =>
      $composableBuilder(column: $table.emergencyGoalMinor, builder: (column) => ColumnOrderings(column));
}

class $$PlanTableAnnotationComposer extends Composer<_$AppDatabase, $PlanTable> {
  $$PlanTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startMonth =>
      $composableBuilder(column: $table.startMonth, builder: (column) => column);

  GeneratedColumn<int> get salaryMinor => $composableBuilder(column: $table.salaryMinor, builder: (column) => column);

  GeneratedColumn<int> get emiMinor => $composableBuilder(column: $table.emiMinor, builder: (column) => column);

  GeneratedColumn<DateTime> get emiEnds => $composableBuilder(column: $table.emiEnds, builder: (column) => column);

  GeneratedColumn<int> get investingMinor =>
      $composableBuilder(column: $table.investingMinor, builder: (column) => column);

  GeneratedColumn<int> get fundMinor => $composableBuilder(column: $table.fundMinor, builder: (column) => column);

  GeneratedColumn<int> get goal1Minor => $composableBuilder(column: $table.goal1Minor, builder: (column) => column);

  GeneratedColumn<DateTime> get goal1Due => $composableBuilder(column: $table.goal1Due, builder: (column) => column);

  GeneratedColumn<int> get goal2Minor => $composableBuilder(column: $table.goal2Minor, builder: (column) => column);

  GeneratedColumn<DateTime> get goal2Due => $composableBuilder(column: $table.goal2Due, builder: (column) => column);

  GeneratedColumn<int> get goal3Minor => $composableBuilder(column: $table.goal3Minor, builder: (column) => column);

  GeneratedColumn<DateTime> get goal3Due => $composableBuilder(column: $table.goal3Due, builder: (column) => column);

  GeneratedColumn<int> get emergencyGoalMinor =>
      $composableBuilder(column: $table.emergencyGoalMinor, builder: (column) => column);
}

class $$PlanTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanTable,
          MonthlyPlan,
          $$PlanTableFilterComposer,
          $$PlanTableOrderingComposer,
          $$PlanTableAnnotationComposer,
          $$PlanTableCreateCompanionBuilder,
          $$PlanTableUpdateCompanionBuilder,
          (MonthlyPlan, BaseReferences<_$AppDatabase, $PlanTable, MonthlyPlan>),
          MonthlyPlan,
          PrefetchHooks Function()
        > {
  $$PlanTableTableManager(_$AppDatabase db, $PlanTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PlanTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PlanTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PlanTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startMonth = const Value.absent(),
                Value<int> salaryMinor = const Value.absent(),
                Value<int> emiMinor = const Value.absent(),
                Value<DateTime?> emiEnds = const Value.absent(),
                Value<int> investingMinor = const Value.absent(),
                Value<int> fundMinor = const Value.absent(),
                Value<int?> goal1Minor = const Value.absent(),
                Value<DateTime?> goal1Due = const Value.absent(),
                Value<int?> goal2Minor = const Value.absent(),
                Value<DateTime?> goal2Due = const Value.absent(),
                Value<int?> goal3Minor = const Value.absent(),
                Value<DateTime?> goal3Due = const Value.absent(),
                Value<int?> emergencyGoalMinor = const Value.absent(),
              }) => PlanCompanion(
                id: id,
                startMonth: startMonth,
                salaryMinor: salaryMinor,
                emiMinor: emiMinor,
                emiEnds: emiEnds,
                investingMinor: investingMinor,
                fundMinor: fundMinor,
                goal1Minor: goal1Minor,
                goal1Due: goal1Due,
                goal2Minor: goal2Minor,
                goal2Due: goal2Due,
                goal3Minor: goal3Minor,
                goal3Due: goal3Due,
                emergencyGoalMinor: emergencyGoalMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startMonth,
                Value<int> salaryMinor = const Value.absent(),
                Value<int> emiMinor = const Value.absent(),
                Value<DateTime?> emiEnds = const Value.absent(),
                Value<int> investingMinor = const Value.absent(),
                Value<int> fundMinor = const Value.absent(),
                Value<int?> goal1Minor = const Value.absent(),
                Value<DateTime?> goal1Due = const Value.absent(),
                Value<int?> goal2Minor = const Value.absent(),
                Value<DateTime?> goal2Due = const Value.absent(),
                Value<int?> goal3Minor = const Value.absent(),
                Value<DateTime?> goal3Due = const Value.absent(),
                Value<int?> emergencyGoalMinor = const Value.absent(),
              }) => PlanCompanion.insert(
                id: id,
                startMonth: startMonth,
                salaryMinor: salaryMinor,
                emiMinor: emiMinor,
                emiEnds: emiEnds,
                investingMinor: investingMinor,
                fundMinor: fundMinor,
                goal1Minor: goal1Minor,
                goal1Due: goal1Due,
                goal2Minor: goal2Minor,
                goal2Due: goal2Due,
                goal3Minor: goal3Minor,
                goal3Due: goal3Due,
                emergencyGoalMinor: emergencyGoalMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanTable, MonthlyPlan>(table),
                  BaseReferences<_$AppDatabase, $PlanTable, MonthlyPlan>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanTable,
      MonthlyPlan,
      $$PlanTableFilterComposer,
      $$PlanTableOrderingComposer,
      $$PlanTableAnnotationComposer,
      $$PlanTableCreateCompanionBuilder,
      $$PlanTableUpdateCompanionBuilder,
      (MonthlyPlan, BaseReferences<_$AppDatabase, $PlanTable, MonthlyPlan>),
      MonthlyPlan,
      PrefetchHooks Function()
    >;
typedef $$BalanceSnapshotsTableCreateCompanionBuilder = BalanceSnapshotsCompanion Function({
  Value<int> id,
  required DateTime month,
  required String label,
  required int amountMinor,
  Value<bool> isLiability,
});
typedef $$BalanceSnapshotsTableUpdateCompanionBuilder = BalanceSnapshotsCompanion Function({
  Value<int> id,
  Value<DateTime> month,
  Value<String> label,
  Value<int> amountMinor,
  Value<bool> isLiability,
});

class $$BalanceSnapshotsTableFilterComposer extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLiability =>
      $composableBuilder(column: $table.isLiability, builder: (column) => ColumnFilters(column));
}

class $$BalanceSnapshotsTableOrderingComposer extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get month =>
      $composableBuilder(column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLiability =>
      $composableBuilder(column: $table.isLiability, builder: (column) => ColumnOrderings(column));
}

class $$BalanceSnapshotsTableAnnotationComposer extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get month => $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get label => $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<bool> get isLiability => $composableBuilder(column: $table.isLiability, builder: (column) => column);
}

class $$BalanceSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceSnapshotsTable,
          BalanceSnapshot,
          $$BalanceSnapshotsTableFilterComposer,
          $$BalanceSnapshotsTableOrderingComposer,
          $$BalanceSnapshotsTableAnnotationComposer,
          $$BalanceSnapshotsTableCreateCompanionBuilder,
          $$BalanceSnapshotsTableUpdateCompanionBuilder,
          (BalanceSnapshot, BaseReferences<_$AppDatabase, $BalanceSnapshotsTable, BalanceSnapshot>),
          BalanceSnapshot,
          PrefetchHooks Function()
        > {
  $$BalanceSnapshotsTableTableManager(_$AppDatabase db, $BalanceSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BalanceSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BalanceSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BalanceSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> month = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<bool> isLiability = const Value.absent(),
              }) => BalanceSnapshotsCompanion(
                id: id,
                month: month,
                label: label,
                amountMinor: amountMinor,
                isLiability: isLiability,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime month,
                required String label,
                required int amountMinor,
                Value<bool> isLiability = const Value.absent(),
              }) => BalanceSnapshotsCompanion.insert(
                id: id,
                month: month,
                label: label,
                amountMinor: amountMinor,
                isLiability: isLiability,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BalanceSnapshotsTable, BalanceSnapshot>(table),
                  BaseReferences<_$AppDatabase, $BalanceSnapshotsTable, BalanceSnapshot>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BalanceSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceSnapshotsTable,
      BalanceSnapshot,
      $$BalanceSnapshotsTableFilterComposer,
      $$BalanceSnapshotsTableOrderingComposer,
      $$BalanceSnapshotsTableAnnotationComposer,
      $$BalanceSnapshotsTableCreateCompanionBuilder,
      $$BalanceSnapshotsTableUpdateCompanionBuilder,
      (BalanceSnapshot, BaseReferences<_$AppDatabase, $BalanceSnapshotsTable, BalanceSnapshot>),
      BalanceSnapshot,
      PrefetchHooks Function()
    >;
typedef $$EmisTableCreateCompanionBuilder = EmisCompanion Function({
  Value<int> id,
  required String name,
  required int amountMinor,
  Value<DateTime?> lastMonth,
  Value<SpendKind> spendKind,
});
typedef $$EmisTableUpdateCompanionBuilder = EmisCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> amountMinor,
  Value<DateTime?> lastMonth,
  Value<SpendKind> spendKind,
});

class $$EmisTableFilterComposer extends Composer<_$AppDatabase, $EmisTable> {
  $$EmisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMonth =>
      $composableBuilder(column: $table.lastMonth, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SpendKind, SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$EmisTableOrderingComposer extends Composer<_$AppDatabase, $EmisTable> {
  $$EmisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMonth =>
      $composableBuilder(column: $table.lastMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => ColumnOrderings(column));
}

class $$EmisTableAnnotationComposer extends Composer<_$AppDatabase, $EmisTable> {
  $$EmisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMonth => $composableBuilder(column: $table.lastMonth, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SpendKind, int> get spendKind =>
      $composableBuilder(column: $table.spendKind, builder: (column) => column);
}

class $$EmisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmisTable,
          Emi,
          $$EmisTableFilterComposer,
          $$EmisTableOrderingComposer,
          $$EmisTableAnnotationComposer,
          $$EmisTableCreateCompanionBuilder,
          $$EmisTableUpdateCompanionBuilder,
          (Emi, BaseReferences<_$AppDatabase, $EmisTable, Emi>),
          Emi,
          PrefetchHooks Function()
        > {
  $$EmisTableTableManager(_$AppDatabase db, $EmisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EmisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EmisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EmisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<DateTime?> lastMonth = const Value.absent(),
            Value<SpendKind> spendKind = const Value.absent(),
          }) => EmisCompanion(id: id, name: name, amountMinor: amountMinor, lastMonth: lastMonth, spendKind: spendKind),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int amountMinor,
                Value<DateTime?> lastMonth = const Value.absent(),
                Value<SpendKind> spendKind = const Value.absent(),
              }) => EmisCompanion.insert(
                id: id,
                name: name,
                amountMinor: amountMinor,
                lastMonth: lastMonth,
                spendKind: spendKind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$EmisTable, Emi>(table), BaseReferences<_$AppDatabase, $EmisTable, Emi>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmisTable,
      Emi,
      $$EmisTableFilterComposer,
      $$EmisTableOrderingComposer,
      $$EmisTableAnnotationComposer,
      $$EmisTableCreateCompanionBuilder,
      $$EmisTableUpdateCompanionBuilder,
      (Emi, BaseReferences<_$AppDatabase, $EmisTable, Emi>),
      Emi,
      PrefetchHooks Function()
    >;
typedef $$SyncLogTableCreateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  required DateTime at,
  required String trigger,
  required bool ok,
  Value<int?> transactions,
  Value<int?> bytes,
  Value<String?> error,
});
typedef $$SyncLogTableUpdateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> trigger,
  Value<bool> ok,
  Value<int?> transactions,
  Value<int?> bytes,
  Value<String?> error,
});

class $$SyncLogTableFilterComposer extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ok => $composableBuilder(column: $table.ok, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transactions =>
      $composableBuilder(column: $table.transactions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnFilters(column));
}

class $$SyncLogTableOrderingComposer extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ok => $composableBuilder(column: $table.ok, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transactions =>
      $composableBuilder(column: $table.transactions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnOrderings(column));
}

class $$SyncLogTableAnnotationComposer extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get trigger => $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<bool> get ok => $composableBuilder(column: $table.ok, builder: (column) => column);

  GeneratedColumn<int> get transactions => $composableBuilder(column: $table.transactions, builder: (column) => column);

  GeneratedColumn<int> get bytes => $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get error => $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogTable,
          SyncLogData,
          $$SyncLogTableFilterComposer,
          $$SyncLogTableOrderingComposer,
          $$SyncLogTableAnnotationComposer,
          $$SyncLogTableCreateCompanionBuilder,
          $$SyncLogTableUpdateCompanionBuilder,
          (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
          SyncLogData,
          PrefetchHooks Function()
        > {
  $$SyncLogTableTableManager(_$AppDatabase db, $SyncLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<bool> ok = const Value.absent(),
                Value<int?> transactions = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncLogCompanion(
                id: id,
                at: at,
                trigger: trigger,
                ok: ok,
                transactions: transactions,
                bytes: bytes,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String trigger,
                required bool ok,
                Value<int?> transactions = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SyncLogCompanion.insert(
                id: id,
                at: at,
                trigger: trigger,
                ok: ok,
                transactions: transactions,
                bytes: bytes,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncLogTable, SyncLogData>(table),
                  BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogTable,
      SyncLogData,
      $$SyncLogTableFilterComposer,
      $$SyncLogTableOrderingComposer,
      $$SyncLogTableAnnotationComposer,
      $$SyncLogTableCreateCompanionBuilder,
      $$SyncLogTableUpdateCompanionBuilder,
      (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
      SyncLogData,
      PrefetchHooks Function()
    >;
typedef $$EmergencyHoldingsTableCreateCompanionBuilder = EmergencyHoldingsCompanion Function({
  Value<int> id,
  required String name,
  required int amountMinor,
});
typedef $$EmergencyHoldingsTableUpdateCompanionBuilder = EmergencyHoldingsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> amountMinor,
});

class $$EmergencyHoldingsTableFilterComposer extends Composer<_$AppDatabase, $EmergencyHoldingsTable> {
  $$EmergencyHoldingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnFilters(column));
}

class $$EmergencyHoldingsTableOrderingComposer extends Composer<_$AppDatabase, $EmergencyHoldingsTable> {
  $$EmergencyHoldingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor =>
      $composableBuilder(column: $table.amountMinor, builder: (column) => ColumnOrderings(column));
}

class $$EmergencyHoldingsTableAnnotationComposer extends Composer<_$AppDatabase, $EmergencyHoldingsTable> {
  $$EmergencyHoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(column: $table.amountMinor, builder: (column) => column);
}

class $$EmergencyHoldingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmergencyHoldingsTable,
          EmergencyHolding,
          $$EmergencyHoldingsTableFilterComposer,
          $$EmergencyHoldingsTableOrderingComposer,
          $$EmergencyHoldingsTableAnnotationComposer,
          $$EmergencyHoldingsTableCreateCompanionBuilder,
          $$EmergencyHoldingsTableUpdateCompanionBuilder,
          (EmergencyHolding, BaseReferences<_$AppDatabase, $EmergencyHoldingsTable, EmergencyHolding>),
          EmergencyHolding,
          PrefetchHooks Function()
        > {
  $$EmergencyHoldingsTableTableManager(_$AppDatabase db, $EmergencyHoldingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EmergencyHoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EmergencyHoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EmergencyHoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
          }) => EmergencyHoldingsCompanion(id: id, name: name, amountMinor: amountMinor),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int amountMinor,
          }) => EmergencyHoldingsCompanion.insert(id: id, name: name, amountMinor: amountMinor),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmergencyHoldingsTable, EmergencyHolding>(table),
                  BaseReferences<_$AppDatabase, $EmergencyHoldingsTable, EmergencyHolding>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmergencyHoldingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmergencyHoldingsTable,
      EmergencyHolding,
      $$EmergencyHoldingsTableFilterComposer,
      $$EmergencyHoldingsTableOrderingComposer,
      $$EmergencyHoldingsTableAnnotationComposer,
      $$EmergencyHoldingsTableCreateCompanionBuilder,
      $$EmergencyHoldingsTableUpdateCompanionBuilder,
      (EmergencyHolding, BaseReferences<_$AppDatabase, $EmergencyHoldingsTable, EmergencyHolding>),
      EmergencyHolding,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories => $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions => $$TransactionsTableTableManager(_db, _db.transactions);
  $$RawMessagesTableTableManager get rawMessages => $$RawMessagesTableTableManager(_db, _db.rawMessages);
  $$MerchantRulesTableTableManager get merchantRules => $$MerchantRulesTableTableManager(_db, _db.merchantRules);
  $$BudgetsTableTableManager get budgets => $$BudgetsTableTableManager(_db, _db.budgets);
  $$PlanTableTableManager get plan => $$PlanTableTableManager(_db, _db.plan);
  $$BalanceSnapshotsTableTableManager get balanceSnapshots =>
      $$BalanceSnapshotsTableTableManager(_db, _db.balanceSnapshots);
  $$EmisTableTableManager get emis => $$EmisTableTableManager(_db, _db.emis);
  $$SyncLogTableTableManager get syncLog => $$SyncLogTableTableManager(_db, _db.syncLog);
  $$EmergencyHoldingsTableTableManager get emergencyHoldings =>
      $$EmergencyHoldingsTableTableManager(_db, _db.emergencyHoldings);
}

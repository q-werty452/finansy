import 'dart:math';

import 'package:flutter/material.dart';

final _rnd = Random.secure();

/// Локальный uuid v4
String newId() {
  final b = List<int>.generate(16, (_) => _rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

enum OpType { expense, income }

OpType opTypeFrom(String s) => s == 'income' ? OpType.income : OpType.expense;
String opTypeStr(OpType t) => t == OpType.income ? 'income' : 'expense';

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.parse(v.toString()));
DateTime _t(dynamic v) => DateTime.parse(v as String).toLocal();
List<String> _sl(dynamic v) => v == null ? <String>[] : List<String>.from(v as List);

Color hexColor(String hex) => Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
String colorHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class Profile {
  final String id;
  final int shortId;
  String name;
  String? email;
  String? avatarUrl;
  String? currency;
  Map<String, dynamic> settings;

  Profile({required this.id, required this.shortId, required this.name, this.email, this.avatarUrl, this.currency, required this.settings});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'],
    shortId: (j['short_id'] as num).toInt(),
    name: j['name'] ?? '',
    email: j['email'],
    avatarUrl: j['avatar_url'],
    currency: j['currency'],
    settings: Map<String, dynamic>.from(j['settings'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'short_id': shortId,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'currency': currency,
    'settings': settings,
  };
}

class Account {
  final String id;
  String name;
  String icon;
  String color;
  String currency;
  double initialBalance;
  double balance;
  bool inTotal;
  int position;

  Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.currency,
    required this.initialBalance,
    required this.balance,
    required this.inTotal,
    required this.position,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: j['id'],
    name: j['name'],
    icon: j['icon'],
    color: j['color'],
    currency: j['currency'],
    initialBalance: _d(j['initial_balance']),
    balance: _d(j['balance']),
    inTotal: j['in_total'] ?? true,
    position: j['position'] ?? 0,
  );

  Color get col => hexColor(color);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'currency': currency,
    'initial_balance': initialBalance,
    'balance': balance,
    'in_total': inTotal,
    'position': position,
  };
}

class Category {
  final String id;
  OpType type;
  String name;
  String icon;
  String color;
  int position;

  Category({required this.id, required this.type, required this.name, required this.icon, required this.color, required this.position});

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'], type: opTypeFrom(j['type']), name: j['name'], icon: j['icon'], color: j['color'], position: j['position'] ?? 0);

  Color get col => hexColor(color);

  Map<String, dynamic> toJson() => {'id': id, 'type': opTypeStr(type), 'name': name, 'icon': icon, 'color': color, 'position': position};
}

class Operation {
  final String id;
  OpType type;
  double amount;
  String accountId;
  String? categoryId;
  DateTime date;
  List<String> tags;
  String comment;
  List<String> photos;
  String? recurringId;

  Operation({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.categoryId,
    required this.date,
    required this.tags,
    required this.comment,
    required this.photos,
    this.recurringId,
  });

  factory Operation.fromJson(Map<String, dynamic> j) => Operation(
    id: j['id'],
    type: opTypeFrom(j['type']),
    amount: _d(j['amount']),
    accountId: j['account_id'],
    categoryId: j['category_id'],
    date: _t(j['date']),
    tags: _sl(j['tags']),
    comment: j['comment'] ?? '',
    photos: _sl(j['photos']),
    recurringId: j['recurring_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': opTypeStr(type),
    'amount': amount,
    'account_id': accountId,
    'category_id': categoryId,
    'date': date.toUtc().toIso8601String(),
    'tags': tags,
    'comment': comment,
    'photos': photos,
    'recurring_id': recurringId,
  };
}

class Transfer {
  final String id;
  String fromAccount;
  String toAccount;
  double amountFrom;
  double amountTo;
  DateTime date;
  String comment;

  Transfer({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amountFrom,
    required this.amountTo,
    required this.date,
    required this.comment,
  });

  factory Transfer.fromJson(Map<String, dynamic> j) => Transfer(
    id: j['id'],
    fromAccount: j['from_account'],
    toAccount: j['to_account'],
    amountFrom: _d(j['amount_from']),
    amountTo: _d(j['amount_to']),
    date: _t(j['date']),
    comment: j['comment'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_account': fromAccount,
    'to_account': toAccount,
    'amount_from': amountFrom,
    'amount_to': amountTo,
    'date': date.toUtc().toIso8601String(),
    'comment': comment,
  };
}

class Recurring {
  final String id;
  OpType type;
  String name;
  String period;
  bool autoAdd;
  DateTime startAt;
  DateTime? endDate;
  DateTime nextRun;
  String? accountId;
  String? categoryId;
  double? amount;
  List<String> tags;
  String comment;
  bool active;

  Recurring({
    required this.id,
    required this.type,
    required this.name,
    required this.period,
    required this.autoAdd,
    required this.startAt,
    this.endDate,
    required this.nextRun,
    this.accountId,
    this.categoryId,
    this.amount,
    required this.tags,
    required this.comment,
    required this.active,
  });

  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
    id: j['id'],
    type: opTypeFrom(j['type']),
    name: j['name'],
    period: j['period'],
    autoAdd: j['auto_add'] ?? false,
    startAt: _t(j['start_at']),
    endDate: j['end_date'] == null ? null : DateTime.parse(j['end_date']),
    nextRun: _t(j['next_run']),
    accountId: j['account_id'],
    categoryId: j['category_id'],
    amount: j['amount'] == null ? null : _d(j['amount']),
    tags: _sl(j['tags']),
    comment: j['comment'] ?? '',
    active: j['active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': opTypeStr(type),
    'name': name,
    'period': period,
    'auto_add': autoAdd,
    'start_at': startAt.toUtc().toIso8601String(),
    'end_date': endDate?.toIso8601String().substring(0, 10),
    'next_run': nextRun.toUtc().toIso8601String(),
    'account_id': accountId,
    'category_id': categoryId,
    'amount': amount,
    'tags': tags,
    'comment': comment,
    'active': active,
  };
}

class Reminder {
  final String id;
  String name;
  String period;
  DateTime remindAt;
  String comment;
  bool enabled;

  Reminder({
    required this.id,
    required this.name,
    required this.period,
    required this.remindAt,
    required this.comment,
    required this.enabled,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'],
    name: j['name'],
    period: j['period'],
    remindAt: _t(j['remind_at']),
    comment: j['comment'] ?? '',
    enabled: j['enabled'] ?? true,
  );

  /// Стабильный id уведомления из uuid
  int get notificationId => int.parse(id.replaceAll('-', '').substring(0, 7), radix: 16);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'period': period,
    'remind_at': remindAt.toUtc().toIso8601String(),
    'comment': comment,
    'enabled': enabled,
  };
}

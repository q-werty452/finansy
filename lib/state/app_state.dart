import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import '../l10n.dart';
import '../services/notifications.dart';
import '../util/format.dart';
import 'prefs.dart';

class CatSum {
  final Category? category; // null = «Малые траты»
  final double sum;
  final int count;
  const CatSum(this.category, this.sum, this.count);
}

/// Все данные хранятся локально в одном JSON-файле в папке приложения.
/// Фото и аватар — отдельными файлами, в данных лежит относительный путь.
class AppState extends ChangeNotifier {
  final LocalPrefs prefs;
  AppState(this.prefs);

  static String docsPath = '';
  static File fileOf(String rel) => File('$docsPath/$rel');

  Profile? profile;
  List<Account> accounts = [];
  List<Category> categories = [];
  List<Operation> operations = [];
  List<Transfer> transfers = [];
  List<Recurring> recurring = [];
  List<Reminder> reminders = [];
  List<String> tags = [];
  Map<String, double> rates = {};

  bool loading = false;
  bool loaded = false;
  String? error;
  DateTime? lastSync;

  /// null = «Итого»
  String? homeAccountId;

  Timer? _saveTimer;

  bool get needsOnboarding => profile != null && profile!.currency == null;
  String get baseCurrency => profile?.currency ?? 'RUB';
  File get _dataFile => File('$docsPath/finansy_data.json');

  // -------------------------------------------------------------------
  //  Загрузка и сохранение
  // -------------------------------------------------------------------
  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      if (docsPath.isEmpty) docsPath = (await getApplicationDocumentsDirectory()).path;
      final f = _dataFile;
      if (await f.exists()) {
        _fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } else {
        _fresh();
        await _writeNow();
      }
      _applySettings();
      _processRecurring();
      _recalc();
      final home = setting<String>('homeAccount', 'total');
      homeAccountId = home == 'total' || accounts.every((a) => a.id != home) ? null : home;
      loaded = true;
      error = null;
      lastSync = DateTime.now();
      unawaited(_loadRates());
      unawaited(Notifications.syncAll(reminders, recurring));
    } catch (e) {
      error = e.toString();
      debugPrint('load: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Вызывается при возврате в приложение: добавить наступившие автоплатежи
  Future<void> refresh() async {
    if (!loaded) return load();
    if (_processRecurring() > 0) {
      _recalc();
      _changed();
    }
    lastSync = DateTime.now();
    notifyListeners();
  }

  void _fresh() {
    profile = Profile(
      id: newId(),
      shortId: 10000000 + math.Random().nextInt(89999999),
      name: L10n.lang == 'en' ? 'User' : 'Пользователь',
      settings: {},
    );
    accounts = [];
    categories = _defaultCategories();
    operations = [];
    transfers = [];
    recurring = [];
    reminders = [];
    tags = [];
  }

  List<Category> _defaultCategories() {
    var i = 0, j = 0;
    Category e(String n, String ic, String c) =>
        Category(id: newId(), type: OpType.expense, name: tr(n), icon: ic, color: c, position: i++);
    Category inc(String n, String ic, String c) =>
        Category(id: newId(), type: OpType.income, name: tr(n), icon: ic, color: c, position: j++);
    return [
      e('Здоровье', 'heartbeat', '#F63535'),
      e('Досуг', 'wallet', '#41BCA8'),
      e('Дом', 'house', '#FB8837'),
      e('Кафе', 'forkKnife', '#A788D6'),
      e('Образование', 'graduationCap', '#4895DD'),
      e('Подарки', 'gift', '#E16095'),
      e('Продукты', 'basket', '#67AF45'),
      e('Семья', 'users', '#F2B108'),
      e('Спорт', 'barbell', '#EA6F18'),
      e('Транспорт', 'bus', '#2E78CF'),
      e('Другое', 'question', '#888888'),
      inc('Зарплата', 'handCoins', '#2E78CF'),
      inc('Подарок', 'gift', '#E16095'),
      inc('Проценты по вкладам', 'bank', '#67AF45'),
      inc('Другое', 'question', '#67AF45'),
    ];
  }

  Map<String, dynamic> _toJson() => {
    'format': 'finansy-backup',
    'version': 2,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'profile': profile!.toJson(),
    'accounts': [for (final a in accounts) a.toJson()],
    'categories': [for (final c in categories) c.toJson()],
    'operations': [for (final o in operations) o.toJson()],
    'transfers': [for (final t in transfers) t.toJson()],
    'recurring': [for (final r in recurring) r.toJson()],
    'reminders': [for (final r in reminders) r.toJson()],
    'tags': tags,
  };

  void _fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
      for (final x in (j[k] as List? ?? const [])) f(Map<String, dynamic>.from(x as Map)),
    ];
    final p = Map<String, dynamic>.from(j['profile'] as Map? ?? {});
    profile = Profile(
      id: p['id'] as String? ?? newId(),
      shortId: (p['short_id'] as num?)?.toInt() ?? 10000000 + math.Random().nextInt(89999999),
      name: p['name'] as String? ?? '',
      email: p['email'] as String?,
      avatarUrl: p['avatar_url'] as String?,
      currency: p['currency'] as String?,
      settings: Map<String, dynamic>.from(p['settings'] as Map? ?? {}),
    );
    accounts = list('accounts', Account.fromJson)..sort((a, b) => a.position.compareTo(b.position));
    categories = list('categories', Category.fromJson);
    operations = list('operations', Operation.fromJson)..sort((a, b) => b.date.compareTo(a.date));
    transfers = list('transfers', Transfer.fromJson)..sort((a, b) => b.date.compareTo(a.date));
    recurring = list('recurring', Recurring.fromJson);
    reminders = list('reminders', Reminder.fromJson)..sort((a, b) => a.remindAt.compareTo(b.remindAt));
    tags = List<String>.from(j['tags'] as List? ?? const []);
    for (final o in operations) {
      for (final t in o.tags) {
        if (!tags.contains(t)) tags.add(t);
      }
    }
  }

  /// Отложенная запись: много быстрых изменений → одна запись на диск
  void _changed() {
    lastSync = DateTime.now();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _writeNow);
  }

  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _writeNow();
    }
  }

  Future<void> _writeNow() async {
    if (profile == null) return;
    try {
      final tmp = File('${_dataFile.path}.tmp');
      await tmp.writeAsString(jsonEncode(_toJson()), flush: true);
      await tmp.rename(_dataFile.path);
    } catch (e) {
      debugPrint('save: $e');
    }
  }

  void _commit() {
    _recalc();
    _changed();
    notifyListeners();
  }

  // -------------------------------------------------------------------
  //  Баланс: начальный + операции + переводы
  // -------------------------------------------------------------------
  void _recalc() {
    for (final a in accounts) {
      var b = a.initialBalance;
      for (final o in operations) {
        if (o.accountId == a.id) b += o.type == OpType.income ? o.amount : -o.amount;
      }
      for (final t in transfers) {
        if (t.toAccount == a.id) b += t.amountTo;
        if (t.fromAccount == a.id) b -= t.amountFrom;
      }
      a.balance = (b * 100).roundToDouble() / 100;
    }
  }

  // -------------------------------------------------------------------
  //  Настройки
  // -------------------------------------------------------------------
  T setting<T>(String key, T def) {
    final v = profile?.settings[key];
    return v is T ? v : def;
  }

  Future<void> setSetting(String key, Object? value) async {
    if (profile == null) return;
    if (value == null) {
      profile!.settings.remove(key);
    } else {
      profile!.settings[key] = value;
    }
    _applySettings();
    _changed();
    notifyListeners();
  }

  void _applySettings() {
    NumFmt.decimalSep = setting('decimalSep', 'default');
    NumFmt.showCents = setting('showCents', false);
    PeriodCfg.firstDayOfWeek = setting('firstDay', 0);
    PeriodCfg.monthStartDay = setting('monthStart', 1);
  }

  bool get hideBalance => setting('hideBalance', false);
  PeriodKind get defaultPeriod => periodFrom(setting('defaultPeriod', 'week'));
  bool get incomeFirst => setting('incomeFirst', false);
  bool get compactList => setting('compact', false);
  int get mergeSmall => setting('mergeSmall', 0);
  bool fieldOn(String f) => setting('field_$f', true);

  // -------------------------------------------------------------------
  //  Курсы валют (для «Итого», если счета в разных валютах; нужен интернет)
  // -------------------------------------------------------------------
  Future<void> _loadRates() async {
    final cached = prefs.raw.getString('rates_$baseCurrency');
    if (cached != null) {
      rates = Map<String, double>.from((jsonDecode(cached) as Map).map((k, v) => MapEntry(k, (v as num).toDouble())));
    }
    if (accounts.every((a) => a.currency == baseCurrency)) return;
    try {
      final r = await http.get(Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency')).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final m = (jsonDecode(r.body)['rates'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
        rates = m;
        await prefs.raw.setString('rates_$baseCurrency', jsonEncode(m));
        notifyListeners();
      }
    } catch (_) {}
  }

  double toBase(double amount, String currency) {
    if (currency == baseCurrency) return amount;
    final r = rates[currency];
    return r == null || r == 0 ? amount : amount / r;
  }

  // -------------------------------------------------------------------
  //  Вычисления
  // -------------------------------------------------------------------
  Account? accountById(String? id) => id == null ? null : accounts.where((a) => a.id == id).firstOrNull;
  Category? categoryById(String? id) => id == null ? null : categories.where((c) => c.id == id).firstOrNull;

  List<Category> categoriesOf(OpType t) => categories.where((c) => c.type == t).toList()..sort((a, b) => a.position.compareTo(b.position));

  Account? get homeAccount => accountById(homeAccountId);

  double get totalBalance => accounts.where((a) => a.inTotal).fold(0.0, (s, a) => s + toBase(a.balance, a.currency));

  double get shownBalance => homeAccount?.balance ?? totalBalance;
  String get shownCurrency => homeAccount?.currency ?? baseCurrency;

  double opValue(Operation o, {String? accountId}) {
    if (accountId != null) return o.amount;
    final a = accountById(o.accountId);
    return a == null ? o.amount : toBase(o.amount, a.currency);
  }

  Iterable<Operation> opsFiltered({OpType? type, DateRange? range, String? accountId, Set<String>? accountIds, String? categoryId}) =>
      operations.where(
        (o) =>
            (type == null || o.type == type) &&
            (range == null || range.contains(o.date)) &&
            (accountId == null || o.accountId == accountId) &&
            (accountIds == null || accountIds.contains(o.accountId)) &&
            (categoryId == null || o.categoryId == categoryId),
      );

  List<CatSum> categorySums(OpType type, DateRange? range, {String? accountId, bool merge = true}) {
    final map = <String?, (double, int)>{};
    for (final o in opsFiltered(type: type, range: range, accountId: accountId)) {
      final cur = map[o.categoryId] ?? (0.0, 0);
      map[o.categoryId] = (cur.$1 + opValue(o, accountId: accountId), cur.$2 + 1);
    }
    var list = map.entries.map((e) => CatSum(categoryById(e.key), e.value.$1, e.value.$2)).toList()..sort((a, b) => b.sum.compareTo(a.sum));
    final pct = mergeSmall;
    if (merge && pct > 0 && list.length > 2) {
      final total = list.fold(0.0, (s, c) => s + c.sum);
      final small = list.where((c) => c.sum / total * 100 < pct).toList();
      if (small.length > 1) {
        list = list.where((c) => !small.contains(c)).toList()
          ..add(CatSum(null, small.fold(0.0, (s, c) => s + c.sum), small.fold(0, (s, c) => s + c.count)));
      }
    }
    return list;
  }

  // -------------------------------------------------------------------
  //  Профиль
  // -------------------------------------------------------------------
  Future<void> finishOnboarding(String currency, double balance) async {
    profile!.currency = currency;
    if (accounts.isEmpty) {
      accounts.add(
        Account(
          id: newId(),
          name: tr('Основной'),
          icon: 'money',
          color: '#9BB68E',
          currency: currency,
          initialBalance: balance,
          balance: balance,
          inTotal: true,
          position: 0,
        ),
      );
    }
    _commit();
  }

  Future<void> updateProfileName(String name) async {
    profile!.name = name;
    _commit();
  }

  Future<void> updateProfileEmail(String email) async {
    profile!.email = email.isEmpty ? null : email;
    _commit();
  }

  Future<void> uploadAvatar(Uint8List bytes, String ext) async {
    final old = profile!.avatarUrl;
    profile!.avatarUrl = await uploadFile('avatars', bytes, ext);
    if (old != null) unawaited(_deleteFile(old));
    _commit();
  }

  /// Сохраняет файл в папку приложения, возвращает относительный путь
  Future<String> uploadFile(String folder, Uint8List bytes, String ext) async {
    final rel = '$folder/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final f = fileOf(rel);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
    return rel;
  }

  Future<void> _deleteFile(String rel) async {
    try {
      final f = fileOf(rel);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // -------------------------------------------------------------------
  //  Счета
  // -------------------------------------------------------------------
  Future<void> saveAccount({
    String? id,
    required String name,
    required String icon,
    required String color,
    required String currency,
    required double balance,
    required bool inTotal,
  }) async {
    if (id == null) {
      accounts.add(
        Account(
          id: newId(),
          name: name,
          icon: icon,
          color: color,
          currency: currency,
          initialBalance: balance,
          balance: balance,
          inTotal: inTotal,
          position: accounts.length,
        ),
      );
    } else {
      final a = accountById(id)!;
      a
        ..initialBalance = a.initialBalance + (balance - a.balance)
        ..name = name
        ..icon = icon
        ..color = color
        ..currency = currency
        ..inTotal = inTotal;
    }
    _commit();
    unawaited(_loadRates());
  }

  Future<void> removeAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
    for (final o in operations.where((o) => o.accountId == id)) {
      for (final p in o.photos) {
        unawaited(_deleteFile(p));
      }
    }
    operations.removeWhere((o) => o.accountId == id);
    transfers.removeWhere((t) => t.fromAccount == id || t.toAccount == id);
    for (final r in recurring) {
      if (r.accountId == id) r.accountId = null;
    }
    if (homeAccountId == id) homeAccountId = null;
    if (setting<String?>('defaultAccount', null) == id) profile!.settings.remove('defaultAccount');
    if (setting<String>('homeAccount', 'total') == id) profile!.settings['homeAccount'] = 'total';
    _commit();
  }

  Future<void> recalcBalances() async {
    _commit();
    await flush();
  }

  void selectHomeAccount(String? id) {
    homeAccountId = id;
    notifyListeners();
  }

  // -------------------------------------------------------------------
  //  Категории
  // -------------------------------------------------------------------
  Future<void> saveCategory({String? id, required OpType type, required String name, required String icon, required String color}) async {
    if (id == null) {
      categories.add(Category(id: newId(), type: type, name: name, icon: icon, color: color, position: categoriesOf(type).length));
    } else {
      categoryById(id)!
        ..name = name
        ..icon = icon
        ..color = color;
    }
    _commit();
  }

  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
    for (final o in operations) {
      if (o.categoryId == id) o.categoryId = null;
    }
    for (final r in recurring) {
      if (r.categoryId == id) r.categoryId = null;
    }
    _commit();
  }

  Future<void> reorderCategories(OpType type, List<Category> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].position = i;
    }
    _commit();
  }

  // -------------------------------------------------------------------
  //  Операции
  // -------------------------------------------------------------------
  Future<void> saveOperation({
    String? id,
    required OpType type,
    required double amount,
    required String accountId,
    required String? categoryId,
    required DateTime date,
    required List<String> tags,
    required String comment,
    required List<String> photos,
    String? recurringId,
  }) async {
    if (id == null) {
      operations.add(
        Operation(
          id: newId(),
          type: type,
          amount: amount,
          accountId: accountId,
          categoryId: categoryId,
          date: date,
          tags: tags,
          comment: comment,
          photos: photos,
          recurringId: recurringId,
        ),
      );
    } else {
      final o = operations.firstWhere((o) => o.id == id);
      for (final p in o.photos.where((p) => !photos.contains(p))) {
        unawaited(_deleteFile(p));
      }
      o
        ..type = type
        ..amount = amount
        ..accountId = accountId
        ..categoryId = categoryId
        ..date = date
        ..tags = tags
        ..comment = comment
        ..photos = photos;
    }
    operations.sort((a, b) => b.date.compareTo(a.date));
    for (final t in tags) {
      if (!this.tags.contains(t)) this.tags.add(t);
    }
    _commit();
  }

  Future<void> deleteOperation(String id) async {
    final o = operations.where((o) => o.id == id).firstOrNull;
    if (o == null) return;
    for (final p in o.photos) {
      unawaited(_deleteFile(p));
    }
    operations.remove(o);
    _commit();
  }

  // -------------------------------------------------------------------
  //  Переводы
  // -------------------------------------------------------------------
  Future<void> saveTransfer({
    String? id,
    required String from,
    required String to,
    required double amountFrom,
    required double amountTo,
    required DateTime date,
    required String comment,
  }) async {
    if (id == null) {
      transfers.add(
        Transfer(id: newId(), fromAccount: from, toAccount: to, amountFrom: amountFrom, amountTo: amountTo, date: date, comment: comment),
      );
    } else {
      transfers.firstWhere((t) => t.id == id)
        ..fromAccount = from
        ..toAccount = to
        ..amountFrom = amountFrom
        ..amountTo = amountTo
        ..date = date
        ..comment = comment;
    }
    transfers.sort((a, b) => b.date.compareTo(a.date));
    _commit();
  }

  Future<void> deleteTransfer(String id) async {
    transfers.removeWhere((t) => t.id == id);
    _commit();
  }

  // -------------------------------------------------------------------
  //  Регулярные платежи
  // -------------------------------------------------------------------
  DateTime _nextPeriod(DateTime d, String p) => switch (p) {
    'day' => DateTime(d.year, d.month, d.day + 1, d.hour, d.minute),
    'week' => DateTime(d.year, d.month, d.day + 7, d.hour, d.minute),
    'month' => DateTime(d.year, d.month + 1, d.day, d.hour, d.minute),
    'quarter' => DateTime(d.year, d.month + 3, d.day, d.hour, d.minute),
    _ => DateTime(d.year + 1, d.month, d.day, d.hour, d.minute),
  };

  bool _beforeEnd(Recurring r, DateTime d) => r.endDate == null || !dayStart(d).isAfter(r.endDate!);

  /// Добавляет операции по наступившим автоплатежам и сдвигает дату следующего.
  /// Ручные платежи не сдвигаются — висят «к оплате», пока не нажмут «Внести платеж».
  int _processRecurring() {
    final now = DateTime.now();
    var added = 0;
    for (final r in recurring.where((r) => r.active && r.autoAdd)) {
      var guard = 0;
      while (!r.nextRun.isAfter(now) && _beforeEnd(r, r.nextRun) && guard++ < 1000) {
        if (accountById(r.accountId) != null && (r.amount ?? 0) > 0) {
          operations.add(
            Operation(
              id: newId(),
              type: r.type,
              amount: r.amount!,
              accountId: r.accountId!,
              categoryId: r.categoryId,
              date: r.nextRun,
              tags: [...r.tags],
              comment: r.comment.isEmpty ? r.name : r.comment,
              photos: [],
              recurringId: r.id,
            ),
          );
          added++;
        }
        r.nextRun = _nextPeriod(r.nextRun, r.period);
      }
      r.active = _beforeEnd(r, r.nextRun);
    }
    if (added > 0) operations.sort((a, b) => b.date.compareTo(a.date));
    return added;
  }

  Future<void> saveRecurring({
    String? id,
    required OpType type,
    required String name,
    required String period,
    required bool autoAdd,
    required DateTime startAt,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
    double? amount,
    required List<String> tags,
    required String comment,
  }) async {
    if (id == null) {
      recurring.add(
        Recurring(
          id: newId(),
          type: type,
          name: name,
          period: period,
          autoAdd: autoAdd,
          startAt: startAt,
          endDate: endDate,
          nextRun: startAt,
          accountId: accountId,
          categoryId: categoryId,
          amount: amount,
          tags: tags,
          comment: comment,
          active: true,
        ),
      );
    } else {
      final r = recurring.firstWhere((r) => r.id == id);
      if (r.startAt != startAt || r.period != period) r.nextRun = startAt;
      r
        ..type = type
        ..name = name
        ..period = period
        ..autoAdd = autoAdd
        ..startAt = startAt
        ..endDate = endDate
        ..accountId = accountId
        ..categoryId = categoryId
        ..amount = amount
        ..tags = tags
        ..comment = comment
        ..active = true;
    }
    for (final t in tags) {
      if (!this.tags.contains(t)) this.tags.add(t);
    }
    _processRecurring();
    recurring.sort((a, b) => a.nextRun.compareTo(b.nextRun));
    _commit();
    unawaited(Notifications.syncAll(reminders, recurring));
  }

  Future<void> deleteRecurring(String id) async {
    recurring.removeWhere((r) => r.id == id);
    _commit();
    unawaited(Notifications.syncAll(reminders, recurring));
  }

  Future<void> payRecurring(Recurring r) async {
    await saveOperation(
      type: r.type,
      amount: r.amount ?? 0,
      accountId: r.accountId!,
      categoryId: r.categoryId,
      date: DateTime.now(),
      tags: r.tags,
      comment: r.comment.isEmpty ? r.name : r.comment,
      photos: [],
      recurringId: r.id,
    );
    r.nextRun = _nextPeriod(r.nextRun, r.period);
    r.active = _beforeEnd(r, r.nextRun);
    _commit();
    unawaited(Notifications.syncAll(reminders, recurring));
  }

  // -------------------------------------------------------------------
  //  Напоминания
  // -------------------------------------------------------------------
  Future<void> saveReminder({
    String? id,
    required String name,
    required String period,
    required DateTime at,
    required String comment,
    bool enabled = true,
  }) async {
    Reminder r;
    if (id == null) {
      r = Reminder(id: newId(), name: name, period: period, remindAt: at, comment: comment, enabled: enabled);
      reminders.add(r);
    } else {
      r = reminders.firstWhere((x) => x.id == id)
        ..name = name
        ..period = period
        ..remindAt = at
        ..comment = comment
        ..enabled = enabled;
    }
    reminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
    _commit();
    await Notifications.schedule(r);
  }

  Future<void> toggleReminder(Reminder r, bool on) async {
    r.enabled = on;
    _commit();
    await Notifications.schedule(r);
  }

  Future<void> deleteReminder(Reminder r) async {
    reminders.remove(r);
    _commit();
    await Notifications.cancel(r);
  }

  // -------------------------------------------------------------------
  //  Резервная копия: JSON + фото внутри (base64), чтобы перенести на другой телефон
  // -------------------------------------------------------------------
  Future<Map<String, dynamic>> exportBackup() async {
    await flush();
    final data = _toJson();
    final files = <String, String>{};
    final paths = {for (final o in operations) ...o.photos, if (profile!.avatarUrl != null) profile!.avatarUrl!};
    for (final rel in paths) {
      final f = fileOf(rel);
      if (await f.exists()) files[rel] = base64Encode(await f.readAsBytes());
    }
    data['files'] = files;
    return data;
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    if (data['format'] != 'finansy-backup') throw AppError(tr('Неверный формат файла'));
    final files = Map<String, dynamic>.from(data['files'] as Map? ?? {});
    for (final e in files.entries) {
      if (e.key.contains('..')) continue;
      final f = fileOf(e.key);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(base64Decode(e.value as String), flush: true);
    }
    _fromJson(data);
    _applySettings();
    _processRecurring();
    homeAccountId = null;
    _recalc();
    await _writeNow();
    lastSync = DateTime.now();
    notifyListeners();
    unawaited(_loadRates());
    unawaited(Notifications.syncAll(reminders, recurring));
  }

  /// Полный сброс: всё удаляется, приложение возвращается к выбору валюты
  Future<void> deleteAllData() async {
    try {
      for (final d in ['photos', 'avatars']) {
        final dir = Directory('$docsPath/$d');
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (_) {}
    final name = profile?.name;
    _fresh();
    if (name != null && name.isNotEmpty) profile!.name = name;
    _applySettings();
    homeAccountId = null;
    await _writeNow();
    await Notifications.syncAll(const [], const []);
    notifyListeners();
  }
}

class AppError implements Exception {
  final String message;
  AppError(this.message);
  @override
  String toString() => message;
}

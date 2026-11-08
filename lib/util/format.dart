import '../l10n.dart';
import 'currencies.dart';

class NumFmt {
  /// 'default' | 'point' | 'comma'
  static String decimalSep = 'default';
  static bool showCents = false;

  static String get sep => switch (decimalSep) {
    'point' => '.',
    'comma' => ',',
    _ => L10n.lang == 'en' ? '.' : ',',
  };
}

String _group(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

/// 12345.5 → "12 345,50"
String fmtNum(double v, {bool forceCents = false}) {
  final neg = v < 0;
  final a = v.abs();
  final cents = (a * 100).round();
  final intPart = cents ~/ 100;
  final frac = cents % 100;
  var s = _group(intPart.toString());
  if (forceCents || NumFmt.showCents || frac != 0) {
    s += NumFmt.sep + frac.toString().padLeft(2, '0');
  }
  return neg ? '-$s' : s;
}

String fmtMoney(double v, String currency) => '${fmtNum(v)} ${currencySymbol(currency)}';

/// Ввод пользователя "1 234,5" → 1234.5
double? parseAmount(String s) {
  final c = s.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
  if (c.isEmpty) return null;
  return double.tryParse(c);
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

// ---------------------------------------------------------------------
//  Периоды
// ---------------------------------------------------------------------
enum PeriodKind { day, week, month, year, custom }

PeriodKind periodFrom(String s) => PeriodKind.values.firstWhere((e) => e.name == s, orElse: () => PeriodKind.week);

class PeriodCfg {
  /// 0 = по умолчанию (пн), 1 = пн, 6 = сб, 7 = вс
  static int firstDayOfWeek = 0;

  /// 1..28 — с какого числа начинается «свой месяц»
  static int monthStartDay = 1;

  static int get weekStart => firstDayOfWeek == 0 ? (L10n.lang == 'en' ? DateTime.sunday : DateTime.monday) : firstDayOfWeek;
}

class DateRange {
  final DateTime start; // включительно
  final DateTime end; // не включительно
  const DateRange(this.start, this.end);
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  DateTime get lastDay => end.subtract(const Duration(days: 1));
}

DateRange rangeFor(PeriodKind k, DateTime anchor) {
  final d = dayStart(anchor);
  switch (k) {
    case PeriodKind.day:
      return DateRange(d, d.add(const Duration(days: 1)));
    case PeriodKind.week:
      final diff = (d.weekday - PeriodCfg.weekStart + 7) % 7;
      final s = d.subtract(Duration(days: diff));
      return DateRange(s, DateTime(s.year, s.month, s.day + 7));
    case PeriodKind.month:
      final m = PeriodCfg.monthStartDay;
      var s = DateTime(d.year, d.month, m);
      if (d.isBefore(s)) s = DateTime(d.year, d.month - 1, m);
      return DateRange(s, DateTime(s.year, s.month + 1, m));
    case PeriodKind.year:
      return DateRange(DateTime(d.year), DateTime(d.year + 1));
    case PeriodKind.custom:
      return DateRange(d, d.add(const Duration(days: 1)));
  }
}

DateRange shiftRange(PeriodKind k, DateRange r, int delta) {
  final s = r.start;
  return switch (k) {
    PeriodKind.day => rangeFor(k, DateTime(s.year, s.month, s.day + delta)),
    PeriodKind.week => rangeFor(k, DateTime(s.year, s.month, s.day + 7 * delta)),
    PeriodKind.month => rangeFor(k, DateTime(s.year, s.month + delta, s.day)),
    PeriodKind.year => rangeFor(k, DateTime(s.year + delta, 1, 1)),
    PeriodKind.custom => r,
  };
}

String rangeLabel(PeriodKind k, DateRange r, {bool allTime = false}) {
  final now = DateTime.now();
  switch (k) {
    case PeriodKind.day:
      final base = '${df('d MMMM').format(r.start)} (${df('E').format(r.start).toLowerCase()})';
      if (sameDay(r.start, now)) return '${tr('Сегодня')}, $base';
      if (sameDay(r.start, now.subtract(const Duration(days: 1)))) return '${tr('Вчера')}, $base';
      return r.start.year == now.year ? base : '$base ${r.start.year}';
    case PeriodKind.week:
      final f = df('d MMM');
      final y = r.start.year == now.year ? '' : ' ${r.lastDay.year}';
      return '${f.format(r.start)} - ${f.format(r.lastDay)}$y';
    case PeriodKind.month:
      if (PeriodCfg.monthStartDay == 1) return capitalize(df('LLLL yyyy').format(r.start));
      final f = df('d MMM');
      return '${f.format(r.start)} - ${f.format(r.lastDay)}';
    case PeriodKind.year:
      return '${r.start.year}';
    case PeriodKind.custom:
      if (allTime) return tr('За все время');
      final f = df('d MMM');
      final same = r.start.year == r.lastDay.year;
      return same
          ? '${f.format(r.start)} - ${f.format(r.lastDay)}, ${r.start.year}'
          : '${df('d MMM yyyy').format(r.start)} - ${df('d MMM yyyy').format(r.lastDay)}';
  }
}

String emptyLabel(PeriodKind k, DateRange r, bool income) {
  final now = DateTime.now();
  final cur = r.contains(now);
  final what = income ? 'доходов' : 'расходов';
  final ru = switch (k) {
    PeriodKind.day => cur ? 'Сегодня $what не было' : 'В этот день $what не было',
    PeriodKind.week => cur ? 'На этой неделе $what не было' : 'В эту неделю $what не было',
    PeriodKind.month => 'В этом месяце $what не было',
    PeriodKind.year => 'В этом году $what не было',
    PeriodKind.custom => 'За этот период $what не было',
  };
  return tr(ru);
}

/// «2 ноября 2026 г. (пн)»
String fullDate(DateTime d) {
  if (L10n.lang == 'en') return '${df('MMMM d, yyyy').format(d)} (${df('E').format(d)})';
  return '${df('d MMMM yyyy').format(d)} г. (${df('E').format(d).toLowerCase()})';
}

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String periodName(String p) => tr(switch (p) {
  'once' => 'Один раз',
  'day' => 'Каждый день',
  'week' => 'Каждую неделю',
  'month' => 'Каждый месяц',
  'quarter' => 'Каждый квартал',
  _ => 'Каждый год',
});

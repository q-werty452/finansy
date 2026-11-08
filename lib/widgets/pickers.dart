import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util/format.dart';
import '../util/icons.dart';
import 'common.dart';

/// Возвращает '' для «Итого», id счёта, или null при отмене
Future<String?> showAccountPicker(
  BuildContext context, {
  String? selected,
  bool withHideSwitch = false,
  bool withTotal = true,
  bool showBalances = true,
  String title = 'Выберите счет',
}) {
  final s = context.read<AppState>();
  var sel = selected ?? (withTotal ? '' : s.accounts.firstOrNull?.id ?? '');
  return showAppDialog<String>(
    context,
    (c) => StatefulBuilder(
      builder: (c, set) {
        final p = c.pal;
        final st = c.watch<AppState>();
        Widget row(String id, String icon, Color color, String name, double? bal, String cur) => InkWell(
          onTap: () => set(() => sel = id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                RadioDot(on: sel == id),
                const SizedBox(width: 18),
                IconCircle(icon: icon, color: color, size: 32, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: p.text, fontSize: 22, letterSpacing: 0.2)),
                      if (bal != null && showBalances)
                        Text(
                          st.hideBalance ? '•••' : fmtMoney(bal, cur),
                          style: TextStyle(color: p.text.withValues(alpha: 0.85), fontSize: 16.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return AppDialog(
          title: tr(title),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.5, minHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (withHideSwitch)
                    Row(
                      children: [
                        Expanded(
                          child: Text(tr('Скрыть баланс на главной'), style: TextStyle(color: p.text, fontSize: 16.5, letterSpacing: 0.2)),
                        ),
                        SmallSwitch(value: st.hideBalance, onChanged: (v) => st.setSetting('hideBalance', v)),
                      ],
                    ),
                  if (withTotal) row('', 'moneyBag', const Color(0xFF639F86), tr('Итого'), st.totalBalance, st.baseCurrency),
                  for (final a in st.accounts) row(a.id, a.icon, a.col, a.name, a.balance, a.currency),
                ],
              ),
            ),
          ),
          actions: [
            DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
            DialogButton(tr('ВЫБРАТЬ'), onTap: () => Navigator.pop(c, sel)),
          ],
        );
      },
    ),
  );
}

class RadioDot extends StatelessWidget {
  final bool on;
  const RadioDot({required this.on});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: on ? p.accent : p.text.withValues(alpha: 0.8), width: 2.2),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: on ? 11 : 0,
        height: on ? 11 : 0,
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent),
      ),
    );
  }
}

class AppCheck extends StatelessWidget {
  final bool on;
  final double size;
  const AppCheck({super.key, required this.on, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: on ? p.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: on ? p.accent : p.text.withValues(alpha: 0.8), width: 2),
      ),
      child: on ? Icon(Icons.check, size: size - 4, color: p.bg) : null,
    );
  }
}

/// Мультивыбор счетов (графики)
Future<Set<String>?> showAccountsMultiPicker(BuildContext context, Set<String> selected) {
  final s = context.read<AppState>();
  final sel = {...selected};
  return showAppDialog<Set<String>>(
    context,
    (c) => StatefulBuilder(
      builder: (c, set) {
        final p = c.pal;
        final all = sel.length == s.accounts.length;
        Widget row(bool on, String icon, Color color, String name, VoidCallback tap) => InkWell(
          onTap: tap,
          highlightColor: p.selectedRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            child: Row(
              children: [
                AppCheck(on: on),
                const SizedBox(width: 30),
                IconCircle(icon: icon, color: color, size: 32, iconSize: 20),
                const SizedBox(width: 20),
                Text(name, style: TextStyle(color: p.text, fontSize: 22, letterSpacing: 0.2)),
              ],
            ),
          ),
        );
        return AppDialog(
          title: tr('Выберите счета'),
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(
                    all,
                    'money',
                    const Color(0xFF46BF8D),
                    tr('Все'),
                    () => set(() => all ? sel.clear() : sel.addAll(s.accounts.map((a) => a.id))),
                  ),
                  for (final a in s.accounts)
                    row(sel.contains(a.id), a.icon, a.col, a.name, () => set(() => sel.contains(a.id) ? sel.remove(a.id) : sel.add(a.id))),
                ],
              ),
            ),
          ),
          actions: [
            DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
            DialogButton(tr('ВЫБРАТЬ'), onTap: sel.isEmpty ? null : () => Navigator.pop(c, sel)),
            const SizedBox(width: 12),
          ],
        );
      },
    ),
  );
}

/// Выбор категории (сетка)
Future<Category?> showCategoryPicker(BuildContext context, OpType type) {
  final s = context.read<AppState>();
  final cats = s.categoriesOf(type);
  return showModalBottomSheet<Category>(
    context: context,
    backgroundColor: context.pal.dialog,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: c.pal.line, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('Выберите категорию'), style: TextStyle(color: c.pal.text, fontSize: 20)),
            ),
            Flexible(
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  for (final cat in cats)
                    CategoryCell(
                      circle: IconCircle(icon: cat.icon, color: cat.col),
                      label: cat.name,
                      onTap: () => Navigator.pop(c, cat),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Простой выбор из списка в диалоге с радио-кнопками
Future<T?> showRadioPicker<T>(BuildContext context, String title, List<(T, String)> items, T current) {
  return showAppDialog<T>(
    context,
    (c) => AppDialog(
      title: title,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final it in items)
              InkWell(
                onTap: () => Navigator.pop(c, it.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      RadioDot(on: it.$1 == current),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(it.$2, style: TextStyle(color: c.pal.text, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c))],
    ),
  );
}

// ---------------------------------------------------------------------
//  Выбор периода (календарь как в оригинале)
// ---------------------------------------------------------------------
Future<(DateRange, bool)?> showRangePickerDialog(BuildContext context, {required DateRange initial, bool allTime = false}) =>
    showAppDialog<(DateRange, bool)>(context, (c) => _RangePicker(initial: initial, allTime: allTime));

class _RangePicker extends StatefulWidget {
  final DateRange initial;
  final bool allTime;
  const _RangePicker({required this.initial, required this.allTime});

  @override
  State<_RangePicker> createState() => _RangePickerState();
}

class _RangePickerState extends State<_RangePicker> {
  late DateTime? _start = widget.initial.start;
  late DateTime? _end = widget.initial.lastDay;
  late bool _all = widget.allTime;
  late final List<DateTime> _months;
  late final ScrollController _sc;
  static const _rowH = 46.0, _headH = 56.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = [for (var i = -48; i <= 1; i++) DateTime(now.year, now.month + i)];
    double off = 0;
    for (final m in _months) {
      if (m.year == now.year && m.month == now.month) break;
      off += _monthH(m);
    }
    _sc = ScrollController(initialScrollOffset: off);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  int _lead(DateTime m) => (DateTime(m.year, m.month).weekday - PeriodCfg.weekStart + 7) % 7;
  int _days(DateTime m) => DateTime(m.year, m.month + 1, 0).day;
  double _monthH(DateTime m) => _headH + ((_lead(m) + _days(m)) / 7).ceil() * _rowH;

  void _tap(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      _all = false;
      if (_start == null || _end != null) {
        _start = d;
        _end = null;
      } else if (d.isBefore(_start!)) {
        _end = _start;
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  String get _subtitle {
    if (_all) return tr('За все время');
    if (_start == null) return '';
    final f = df('d MMM');
    final e = _end ?? _start!;
    final pre = L10n.lang == 'en' ? 'from' : 'с';
    final mid = L10n.lang == 'en' ? 'to' : 'по';
    return '$pre ${f.format(_start!)} $mid ${f.format(e)}, ${e.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wd = [for (var i = 0; i < 7; i++) df('E').format(DateTime(2024, 1, 1 + (PeriodCfg.weekStart - 1 + i) % 7)).toLowerCase()];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 60),
        child: Material(
          color: p.dialog,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: p.card,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Выбор периода'), style: TextStyle(color: p.text, fontSize: 23)),
                    const SizedBox(height: 10),
                    Text(_subtitle, style: TextStyle(color: p.text, fontSize: 16.5)),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setState(() => _all = !_all),
                      child: Row(
                        children: [
                          AppCheck(on: _all),
                          const SizedBox(width: 18),
                          Text(tr('За все время'), style: TextStyle(color: p.text, fontSize: 17)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        for (final w in wd)
                          Expanded(
                            child: Text(
                              w,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.tabInactive.withValues(alpha: 0.7), fontSize: 15),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Flexible(
                child: SizedBox(
                  height: 420,
                  child: ListView.builder(
                    controller: _sc,
                    itemCount: _months.length,
                    itemExtentBuilder: (i, _) => _monthH(_months[i]),
                    itemBuilder: (_, i) => _month(p, _months[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(context)),
                    DialogButton(
                      tr('OK'),
                      onTap: _all || _start != null
                          ? () {
                              if (_all) {
                                Navigator.pop(context, (DateRange(DateTime(2000), DateTime(2100)), true));
                              } else {
                                final e = _end ?? _start!;
                                Navigator.pop(context, (DateRange(_start!, DateTime(e.year, e.month, e.day + 1)), false));
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _month(Pal p, DateTime m) {
    final lead = _lead(m), days = _days(m);
    final cells = lead + days;
    final today = dayStart(DateTime.now());
    return Column(
      children: [
        SizedBox(
          height: _headH,
          child: Center(
            child: Text(
              capitalize('${df('LLLL yyyy').format(m)}${L10n.lang == 'en' ? '' : ' г.'}'),
              style: TextStyle(color: p.text, fontSize: 17),
            ),
          ),
        ),
        for (var r = 0; r < (cells / 7).ceil(); r++)
          SizedBox(
            height: _rowH,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: () {
                      final idx = r * 7 + col - lead + 1;
                      if (idx < 1 || idx > days) return const SizedBox();
                      final d = DateTime(m.year, m.month, idx);
                      final isStart = !_all && _start != null && sameDay(d, _start!);
                      final isEnd = !_all && _end != null && sameDay(d, _end!);
                      final inRange = !_all && _start != null && _end != null && d.isAfter(_start!) && d.isBefore(_end!);
                      final future = d.isAfter(today);
                      final edge = isStart || isEnd;
                      return GestureDetector(
                        onTap: future ? null : () => _tap(d),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (inRange || (edge && _end != null && !sameDay(_start!, _end!)))
                              Positioned.fill(
                                top: 4,
                                bottom: 4,
                                left: isStart ? 20 : 0,
                                right: isEnd ? 20 : 0,
                                child: Container(color: p.accentDim.withValues(alpha: 0.9)),
                              ),
                            if (edge)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                              ),
                            Text(
                              '$idx',
                              style: TextStyle(
                                color: edge || inRange ? Colors.white : (future ? p.tabInactive.withValues(alpha: 0.35) : p.tabInactive),
                                fontSize: 16,
                                fontWeight: edge ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

IconData accountIcon(Account? a) => a == null ? PI.moneyWavy : iconFor(a.icon);

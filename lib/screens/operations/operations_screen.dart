import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../services/export.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import '../../widgets/money_bag.dart';
import '../../widgets/pickers.dart';
import 'add_operation_screen.dart';

enum _Sort { dateDesc, dateAsc, amountDesc, amountAsc }

class OperationsScreen extends StatefulWidget {
  final String? accountId;
  final OpType type;
  final PeriodKind? kind;
  final DateRange? range;
  final bool allTime;
  final Set<String>? categoryIds;
  const OperationsScreen({
    super.key,
    this.accountId,
    this.type = OpType.expense,
    this.kind,
    this.range,
    this.allTime = false,
    this.categoryIds,
  });

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> with TickerProviderStateMixin {
  late final AppState s = context.read<AppState>();
  late final TabController _type = TabController(length: 2, vsync: this, initialIndex: widget.type == OpType.income ? 1 : 0);
  late PeriodKind _kind = widget.kind ?? s.defaultPeriod;
  late final TabController _period = TabController(length: 5, vsync: this, initialIndex: _kind.index);
  late DateRange _range = widget.range ?? rangeFor(_kind, DateTime.now());
  late DateRange _custom = _kind == PeriodKind.custom
      ? _range
      : DateRange(DateTime(DateTime.now().year), dayStart(DateTime.now()).add(const Duration(days: 1)));
  late bool _allTime = widget.allTime;
  late String? _accountId = widget.accountId;
  late Set<String>? _cats = widget.categoryIds;
  _Sort _sort = _Sort.dateDesc;
  bool _search = false;
  final _q = TextEditingController();
  int _dir = 0;

  @override
  void initState() {
    super.initState();
    _type.addListener(() {
      if (!_type.indexIsChanging) setState(() => _cats = null);
    });
  }

  @override
  void dispose() {
    _type.dispose();
    _period.dispose();
    _q.dispose();
    super.dispose();
  }

  OpType get _opType => _type.index == 1 ? OpType.income : OpType.expense;
  DateRange? get _effRange => _kind == PeriodKind.custom && _allTime ? null : _range;
  String get _cur => s.accountById(_accountId)?.currency ?? s.baseCurrency;

  List<Operation> _list(AppState st) {
    final q = _q.text.trim().toLowerCase();
    final list = st.opsFiltered(type: _opType, range: _effRange, accountId: _accountId).where((o) {
      if (_cats != null && !_cats!.contains(o.categoryId)) return false;
      if (q.isEmpty) return true;
      return o.comment.toLowerCase().contains(q) ||
          o.tags.any((t) => t.toLowerCase().contains(q)) ||
          (st.categoryById(o.categoryId)?.name.toLowerCase().contains(q) ?? false) ||
          fmtNum(o.amount).replaceAll(' ', '').contains(q.replaceAll(' ', ''));
    }).toList();
    switch (_sort) {
      case _Sort.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _Sort.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _Sort.amountDesc:
        list.sort((a, b) => st.opValue(b, accountId: _accountId).compareTo(st.opValue(a, accountId: _accountId)));
      case _Sort.amountAsc:
        list.sort((a, b) => st.opValue(a, accountId: _accountId).compareTo(st.opValue(b, accountId: _accountId)));
    }
    return list;
  }

  Future<void> _onPeriodTap(int i) async {
    final k = PeriodKind.values[i];
    if (k == PeriodKind.custom) {
      final r = await showRangePickerDialog(context, initial: _custom, allTime: _allTime);
      if (r == null) {
        _period.animateTo(_kind.index);
        return;
      }
      setState(() {
        _custom = r.$1;
        _allTime = r.$2;
        _kind = k;
        _range = _custom;
      });
      return;
    }
    setState(() {
      _kind = k;
      _range = rangeFor(k, DateTime.now());
      _dir = 0;
    });
  }

  void _shift(int d) {
    if (_kind == PeriodKind.custom) return;
    final next = shiftRange(_kind, _range, d);
    if (d > 0 && next.start.isAfter(DateTime.now())) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = d;
      _range = next;
    });
  }

  bool get _canForward => _kind != PeriodKind.custom && _range.end.isBefore(DateTime.now());

  Future<void> _pickDate() async {
    if (_kind == PeriodKind.custom) return _onPeriodTap(4);
    final d = await showDatePicker(
      context: context,
      initialDate: _range.start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: Locale(L10n.locale),
    );
    if (d != null) setState(() => _range = rangeFor(_kind, d));
  }

  Future<void> _filter() async {
    final cats = s.categoriesOf(_opType);
    final sel = {...(_cats ?? cats.map((c) => c.id))};
    final r = await showAppDialog<Set<String>>(
      context,
      (c) => StatefulBuilder(
        builder: (c, set) {
          final p = c.pal;
          final all = sel.length == cats.length;
          Widget row(bool on, Widget icon, String name, VoidCallback tap) => InkWell(
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AppCheck(on: on),
                  const SizedBox(width: 18),
                  icon,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(name, style: TextStyle(color: p.text, fontSize: 17)),
                  ),
                ],
              ),
            ),
          );
          return AppDialog(
            title: tr('Категории'),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    row(all, const SizedBox(width: 32), tr('Все'), () => set(() => all ? sel.clear() : sel.addAll(cats.map((x) => x.id)))),
                    for (final cat in cats)
                      row(
                        sel.contains(cat.id),
                        IconCircle(icon: cat.icon, color: cat.col, size: 32, iconSize: 20),
                        cat.name,
                        () => set(() => sel.contains(cat.id) ? sel.remove(cat.id) : sel.add(cat.id)),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
              DialogButton(tr('ВЫБРАТЬ'), onTap: sel.isEmpty ? null : () => Navigator.pop(c, sel)),
            ],
          );
        },
      ),
    );
    if (r != null) setState(() => _cats = r.length == cats.length ? null : r);
  }

  Future<void> _sortMenu(Offset pos) async {
    final r = await showAnchoredMenu<_Sort>(context, pos, [
      (_Sort.dateDesc, tr('Сначала новые'), null),
      (_Sort.dateAsc, tr('Сначала старые'), null),
      (_Sort.amountDesc, tr('Сначала крупные'), null),
      (_Sort.amountAsc, tr('Сначала мелкие'), null),
    ]);
    if (r != null) setState(() => _sort = r);
  }

  Future<void> _export() async {
    var fmt = 'xlsx';
    final ok = await showAppDialog<bool>(
      context,
      (c) => StatefulBuilder(
        builder: (c, set) {
          final p = c.pal;
          Widget opt(String v, String label) => InkWell(
            onTap: () => set(() => fmt = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  RadioDot(on: fmt == v),
                  const SizedBox(width: 20),
                  Text(label, style: TextStyle(color: p.text, fontSize: 17)),
                ],
              ),
            ),
          );
          return AppDialog(
            title: tr('Экспортировать данные в формат:'),
            padding: const EdgeInsets.fromLTRB(26, 26, 16, 10),
            content: Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 34),
              child: Column(mainAxisSize: MainAxisSize.min, children: [opt('xlsx', 'Excel'), opt('pdf', 'PDF')]),
            ),
            actions: [
              DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
              DialogButton(tr('ВЫГРУЗИТЬ'), onTap: () => Navigator.pop(c, true)),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final d = ExportData(
        ops: _list(s),
        type: _opType,
        period: rangeLabel(_kind, _range, allTime: _allTime),
        accountName: s.accountById(_accountId)?.name ?? tr('Итого'),
        currency: _cur,
        accountId: _accountId,
      );
      final f = fmt == 'pdf' ? await exportPdf(s, d) : await exportExcel(s, d);
      await shareFile(f, fmt == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final list = _list(st);
    final total = list.fold(0.0, (a, o) => a + st.opValue(o, accountId: _accountId));
    final acc = st.accountById(_accountId);

    final groups = <DateTime, List<Operation>>{};
    if (_sort == _Sort.dateDesc || _sort == _Sort.dateAsc) {
      for (final o in list) {
        groups.putIfAbsent(dayStart(o.date), () => []).add(o);
      }
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: AnnotatedRegion(
              value: kLightStatus,
              child: Container(
                height: top + 130,
                decoration: BoxDecoration(
                  color: p.header,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  height: 66,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 4,
                        child: HeaderIcon(icon: PI.caretLeft, size: 30, onTap: () => Navigator.maybePop(context)),
                      ),
                      Positioned(
                        right: 4,
                        child: Row(
                          children: [
                            HeaderIcon(
                              icon: _search ? Icons.close : PI.magnifyingGlass,
                              size: 27,
                              onTap: () => setState(() {
                                _search = !_search;
                                if (!_search) _q.clear();
                              }),
                            ),
                            HeaderIcon(icon: PI.downloadSimple, size: 27, onTap: _export),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        child: _search
                            ? TextField(
                                controller: _q,
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(color: p.onHeader, fontSize: 17),
                                cursorColor: p.onHeader,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: tr('Поиск'),
                                  hintStyle: TextStyle(color: p.headerInactive),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.headerInactive)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.onHeader)),
                                ),
                              )
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  final r = await showAccountPicker(context, selected: _accountId);
                                  if (r != null) setState(() => _accountId = r.isEmpty ? null : r);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(tr('Операции'), style: TextStyle(color: p.headerInactive, fontSize: 15.5)),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        acc == null
                                            ? MoneyBagIcon(size: 26, color: p.onHeader.withValues(alpha: 0.9))
                                            : Icon(iconFor(acc.icon), size: 24, color: p.onHeader.withValues(alpha: 0.9)),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            acc?.name ?? tr('Итого'),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: p.onHeader, fontSize: 17.5, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down, color: p.onHeader, size: 30),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: HeaderTabs(controller: _type, labels: [tr('РАСХОДЫ'), tr('ДОХОДЫ')]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 95,
            left: 16,
            right: 16,
            bottom: bottom + 6,
            child: Container(
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      CardTabs(
                        controller: _period,
                        labels: [tr('День'), tr('Неделя'), tr('Месяц'), tr('Год'), tr('Период')],
                        onTap: _onPeriodTap,
                      ),
                      _nav(p),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 6, 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${tr('Всего')}: ${fmtMoney(total, _cur)}',
                                style: TextStyle(color: p.text, fontSize: 16.5, letterSpacing: 0.2),
                              ),
                            ),
                            IconButton(
                              onPressed: _filter,
                              icon: Icon(PI.funnel, color: _cats == null ? p.tabInactive : p.accent, size: 28),
                            ),
                            Builder(
                              builder: (bc) => IconButton(
                                onPressed: () {
                                  final box = bc.findRenderObject() as RenderBox;
                                  _sortMenu(box.localToGlobal(Offset(-150, box.size.height)));
                                },
                                icon: Icon(PI.calendarDots, color: _sort == _Sort.dateDesc ? p.tabInactive : p.accent, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  child: Text(tr('Нет операций'), style: TextStyle(color: p.tabInactive, fontSize: 16.5)),
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: ListView(
                                  key: ValueKey('${_opType.name}${_range.start}$_sort$_accountId${_cats?.length}'),
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 100),
                                  physics: const BouncingScrollPhysics(),
                                  children: groups.isEmpty
                                      ? [const SizedBox(height: 10), _Group(ops: list, accountId: _accountId)]
                                      : [
                                          for (final (i, d) in groups.keys.indexed)
                                            FadeSlideIn(
                                              index: i < 6 ? i : 0,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                                                    child: Text(
                                                      fullDate(d),
                                                      style: TextStyle(color: p.tabInactive, fontSize: 16.5, letterSpacing: 0.2),
                                                    ),
                                                  ),
                                                  _Group(ops: groups[d]!, accountId: _accountId),
                                                ],
                                              ),
                                            ),
                                        ],
                                ),
                              ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22,
                    child: Center(
                      child: YellowFab(
                        onTap: () => Navigator.push(context, pageRoute(AddOperationScreen(type: _opType, accountId: _accountId))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(Pal p) {
    final label = rangeLabel(_kind, _range, allTime: _allTime);
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 300) _shift(-1);
        if (v < -300 && _canForward) _shift(1);
      },
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: _kind == PeriodKind.custom
                  ? null
                  : IconButton(
                      onPressed: () => _shift(-1),
                      icon: Icon(PI.caretLeft, color: p.tabInactive, size: 26),
                    ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: Offset(_dir * 0.25, 0), end: Offset.zero).animate(a),
                    child: c,
                  ),
                ),
                child: GestureDetector(
                  key: ValueKey(label),
                  onTap: _pickDate,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17.5,
                      decoration: _kind == PeriodKind.year ? null : TextDecoration.underline,
                      decorationColor: p.text,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: _canForward
                  ? IconButton(
                      onPressed: () => _shift(1),
                      icon: Icon(PI.caretRight, color: p.tabInactive, size: 26),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Группа операций одного дня: светлая подложка с разделителями
class _Group extends StatelessWidget {
  final List<Operation> ops;
  final String? accountId;
  const _Group({required this.ops, required this.accountId});

  @override
  Widget build(BuildContext context) {
    const groupColor = Color(0xFF383E3A);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? groupColor : context.pal.card,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < ops.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(height: 1, color: const Color(0xFF4A524C)),
              ),
            _OpRow(op: ops[i], accountId: accountId),
          ],
        ],
      ),
    );
  }
}

class _OpRow extends StatelessWidget {
  final Operation op;
  final String? accountId;
  const _OpRow({required this.op, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.read<AppState>();
    final c = s.categoryById(op.categoryId);
    final a = s.accountById(op.accountId);
    final compact = s.compactList;
    final sub = [
      a?.name ?? '',
      if (op.comment.isNotEmpty && op.comment != c?.name) op.comment,
      if (op.tags.isNotEmpty) op.tags.map((t) => '#$t').join(' '),
    ].where((x) => x.isNotEmpty).join(' · ');
    return Dismissible(
      key: ValueKey(op.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: p.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Icon(PI.trash, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => confirm(context, tr('Удалить операцию?'), danger: true, yes: 'УДАЛИТЬ'),
      onDismissed: (_) => s.deleteOperation(op.id),
      child: InkWell(
        onTap: () => Navigator.push(context, pageRoute(AddOperationScreen(edit: op))),
        child: SizedBox(
          height: compact ? 48 : 64,
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconCircle(
                icon: c?.icon ?? 'question',
                color: c?.col ?? const Color(0xFF888888),
                size: compact ? 28 : 32,
                iconSize: compact ? 17 : 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c?.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, fontSize: 17, letterSpacing: 0.15),
                    ),
                    if (!compact && sub.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.tabInactive, fontSize: 15.5, letterSpacing: 0.15),
                        ),
                      ),
                  ],
                ),
              ),
              if (op.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(PI.image, size: 18, color: p.tabInactive),
                ),
              Text(fmtMoney(op.amount, a?.currency ?? s.baseCurrency), style: TextStyle(color: p.text, fontSize: 17, letterSpacing: 0.15)),
              const SizedBox(width: 9),
            ],
          ),
        ),
      ),
    );
  }
}

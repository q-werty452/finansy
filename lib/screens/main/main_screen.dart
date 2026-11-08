import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/money_bag.dart';
import '../../widgets/pickers.dart';
import '../operations/add_operation_screen.dart';
import '../operations/operations_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late final AppState s = context.read<AppState>();
  late final TabController _type = TabController(length: 2, vsync: this, initialIndex: s.incomeFirst ? 1 : 0);
  late final TabController _period = TabController(length: 5, vsync: this, initialIndex: s.defaultPeriod.index);
  late PeriodKind _kind = s.defaultPeriod;
  late DateRange _range = rangeFor(_kind, DateTime.now());
  DateRange _custom = DateRange(DateTime(DateTime.now().year), dayStart(DateTime.now()).add(const Duration(days: 1)));
  bool _allTime = false;
  int? _selected;
  int _dir = 0;

  @override
  void initState() {
    super.initState();
    _type.addListener(() {
      if (!_type.indexIsChanging) setState(() => _selected = null);
    });
  }

  @override
  void dispose() {
    _type.dispose();
    _period.dispose();
    super.dispose();
  }

  OpType get _opType => _type.index == 1 ? OpType.income : OpType.expense;

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
        _selected = null;
      });
      return;
    }
    setState(() {
      _kind = k;
      _range = rangeFor(k, DateTime.now());
      _selected = null;
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
      _selected = null;
    });
  }

  bool get _canForward => _kind != PeriodKind.custom && !_range.contains(DateTime.now()) && _range.end.isBefore(DateTime.now());

  Future<void> _pickDate() async {
    if (_kind == PeriodKind.custom) {
      _onPeriodTap(4);
      return;
    }
    final d = await showDatePicker(
      context: context,
      initialDate: _range.start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: Locale(L10n.locale),
    );
    if (d != null) setState(() => _range = rangeFor(_kind, d));
  }

  Future<void> _chooseAccount() async {
    final r = await showAccountPicker(context, selected: s.homeAccountId, withHideSwitch: true);
    if (r != null) s.selectHomeAccount(r.isEmpty ? null : r);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final effRange = _kind == PeriodKind.custom && _allTime ? null : _range;
    final sums = st.categorySums(_opType, effRange, accountId: st.homeAccountId);
    final total = sums.fold(0.0, (a, c) => a + c.sum);
    final cur = st.shownCurrency;
    final headerH = top + 130.0;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Зелёная шапка (Align — чтобы высота не растянулась на весь экран)
          Align(
            alignment: Alignment.topCenter,
            child: AnnotatedRegion(
              value: kLightStatus,
              child: Container(
                height: headerH,
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
                        child: HeaderIcon(icon: PI.list, size: 30, onTap: () => openMainMenu(context)),
                      ),
                      Positioned(
                        right: 6,
                        child: HeaderIcon(
                          icon: PI.receipt,
                          size: 30,
                          onTap: () => Navigator.push(
                            context,
                            pageRoute(
                              OperationsScreen(accountId: st.homeAccountId, type: _opType, kind: _kind, range: _range, allTime: _allTime),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _chooseAccount,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  st.homeAccount == null
                                      ? MoneyBagIcon(size: 26, color: p.onHeader.withValues(alpha: 0.9))
                                      : Icon(iconFor(st.homeAccount!.icon), size: 24, color: p.onHeader.withValues(alpha: 0.9)),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      st.homeAccount?.name ?? tr('Итого'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: p.onHeader, fontSize: 19, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: p.onHeader, size: 30),
                                ],
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  st.hideBalance ? '•••' : fmtMoney(st.shownBalance, cur),
                                  key: ValueKey('${st.shownBalance}${st.hideBalance}$cur'),
                                  style: TextStyle(color: p.onHeader, fontSize: 28, fontWeight: FontWeight.w700, height: 1.05),
                                ),
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
          // Карточка и список
          Positioned.fill(
            top: top + 95,
            child: RefreshIndicator(
              onRefresh: st.refresh,
              color: p.accent,
              backgroundColor: p.card,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 24),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  _card(p, st, sums, total, cur, effRange),
                  const SizedBox(height: 10),
                  for (var i = 0; i < sums.length; i++)
                    FadeSlideIn(
                      key: ValueKey('${_opType.name}${sums[i].category?.id}${_range.start}'),
                      index: i,
                      child: _CatRow(
                        sum: sums[i],
                        total: total,
                        currency: cur,
                        highlighted: _selected == i,
                        onTap: () => Navigator.push(
                          context,
                          pageRoute(
                            OperationsScreen(
                              accountId: st.homeAccountId,
                              type: _opType,
                              kind: _kind,
                              range: _range,
                              allTime: _allTime,
                              categoryIds: sums[i].category == null ? null : {sums[i].category!.id},
                            ),
                          ),
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

  Widget _card(Pal p, AppState st, List<CatSum> sums, double total, String cur, DateRange? effRange) {
    final label = rangeLabel(_kind, _range, allTime: _allTime);
    final segs = [for (final c in sums) DonutSegment(c.sum, c.category?.col ?? const Color(0xFF888888))];
    Widget center;
    if (sums.isEmpty) {
      center = Text(
        emptyLabel(_kind, _range, _opType == OpType.income),
        textAlign: TextAlign.center,
        style: TextStyle(color: p.text, fontSize: 17.5, height: 1.3, letterSpacing: 0.2),
      );
    } else if (_selected != null && _selected! < sums.length) {
      final c = sums[_selected!];
      center = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            c.category?.name ?? tr('Малые траты'),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.secondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              fmtMoney(c.sum, cur),
              style: TextStyle(color: p.text, fontSize: 21, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 2),
          Text('${(c.sum / total * 100).toStringAsFixed(1)}%', style: TextStyle(color: c.category?.col ?? p.secondary, fontSize: 15)),
        ],
      );
    } else {
      center = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              fmtMoney(total, cur),
              style: TextStyle(color: p.text, fontSize: 23, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 300) _shift(-1);
        if (v < -300 && _canForward) _shift(1);
      },
      child: Container(
        height: 348,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
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
                SizedBox(
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
                                letterSpacing: 0.15,
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
                const SizedBox(height: 4),
                Donut(segments: segs, center: center, selected: _selected, onSelect: (i) => setState(() => _selected = i)),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 18,
              child: YellowFab(
                onTap: () => Navigator.push(context, pageRoute(AddOperationScreen(type: _opType, accountId: st.homeAccountId))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  final CatSum sum;
  final double total;
  final String currency;
  final bool highlighted;
  final VoidCallback onTap;
  const _CatRow({required this.sum, required this.total, required this.currency, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = sum.category;
    final pct = total == 0 ? 0 : sum.sum / total * 100;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: highlighted ? p.selectedRow : p.card, borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              IconCircle(icon: c?.icon ?? 'dotsThree', color: c?.col ?? const Color(0xFF888888), size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c?.name ?? tr('Малые траты'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 3,
                          backgroundColor: p.bg.withValues(alpha: 0.5),
                          color: c?.col ?? const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtMoney(sum.sum, currency), style: TextStyle(color: p.text, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text('${pct.toStringAsFixed(pct < 10 ? 1 : 0)}%', style: TextStyle(color: p.secondary, fontSize: 13.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

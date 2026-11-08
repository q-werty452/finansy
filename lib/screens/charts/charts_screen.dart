import 'dart:math' as math;

import 'package:flutter/material.dart';
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

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with TickerProviderStateMixin {
  late final TabController _mode = TabController(length: 3, vsync: this);
  late final TabController _by = TabController(length: 4, vsync: this, initialIndex: 1);
  Set<String>? _accounts;

  @override
  void initState() {
    super.initState();
    _mode.addListener(() => setState(() {}));
    _by.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mode.dispose();
    _by.dispose();
    super.dispose();
  }

  List<DateRange> _buckets(AppState s) {
    final now = DateTime.now();
    final first = s.operations.isEmpty ? now : s.operations.map((o) => o.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final out = <DateRange>[];
    switch (_by.index) {
      case 0:
        final n = math.max(6, now.year - first.year + 1);
        for (var i = n - 1; i >= 0; i--) {
          out.add(DateRange(DateTime(now.year - i), DateTime(now.year - i + 1)));
        }
      case 1:
        final span = (now.year - first.year) * 12 + now.month - first.month + 1;
        final n = math.min(60, math.max(_mode.index == 0 ? 5 : 6, span));
        for (var i = n - 1; i >= 0; i--) {
          out.add(DateRange(DateTime(now.year, now.month - i), DateTime(now.year, now.month - i + 1)));
        }
      case 2:
        final cur = rangeFor(PeriodKind.week, now);
        final span = now.difference(first).inDays ~/ 7 + 1;
        final n = math.min(104, math.max(6, span));
        for (var i = n - 1; i >= 0; i--) {
          out.add(shiftRange(PeriodKind.week, cur, -i));
        }
      default:
        final today = dayStart(now);
        final span = now.difference(first).inDays + 1;
        final n = math.min(180, math.max(7, span));
        for (var i = n - 1; i >= 0; i--) {
          final d = DateTime(today.year, today.month, today.day - i);
          out.add(DateRange(d, DateTime(d.year, d.month, d.day + 1)));
        }
    }
    return out;
  }

  String _label(DateRange r) => switch (_by.index) {
    0 => '${r.start.year}',
    1 => df('LLL').format(r.start),
    2 => df('dd.MM').format(r.start),
    _ => '${r.start.day}',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final accs = _accounts ?? s.accounts.map((a) => a.id).toSet();
    final buckets = _buckets(s);
    final ops = s.opsFiltered(accountIds: accs).toList();

    final groups = <BarGroup>[];
    for (final r in buckets) {
      double inc = 0, exp = 0;
      for (final o in ops) {
        if (!r.contains(o.date)) continue;
        final v = s.opValue(o);
        if (o.type == OpType.income) {
          inc += v;
        } else {
          exp += v;
        }
      }
      final bars = switch (_mode.index) {
        0 => [
          (inc, ChartColors.income),
          (exp, ChartColors.expense),
          ((inc - exp).abs(), inc >= exp ? ChartColors.profit : ChartColors.loss),
        ],
        1 => [(exp, ChartColors.expense)],
        _ => [(inc, ChartColors.income)],
      };
      groups.add(BarGroup(_label(r), bars, sub: _by.index == 0 ? null : '${r.start.year}'));
    }

    final visible = _mode.index == 0 ? 5 : 6;
    final hasLegend = _mode.index == 0;

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
                  height: 58,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        tr('Графики'),
                        style: TextStyle(color: p.onHeader, fontSize: 19, fontWeight: FontWeight.w500),
                      ),
                      Positioned(
                        left: 4,
                        child: HeaderIcon(icon: PI.list, size: 30, onTap: () => openMainMenu(context)),
                      ),
                      Positioned(
                        right: 6,
                        child: IconButton(
                          icon: MoneyBagIcon(size: 30, color: p.onHeader),
                          onPressed: () async {
                            final r = await showAccountsMultiPicker(context, accs);
                            if (r != null) setState(() => _accounts = r);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: HeaderTabs(controller: _mode, labels: [tr('ОБЩИЙ'), tr('РАСХОДЫ'), tr('ДОХОДЫ')]),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: top + 91,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  child: Column(
                    children: [
                      CardTabs(controller: _by, labels: [tr('по годам'), tr('по месяцам'), tr('по неделям'), tr('по дням')]),
                      const SizedBox(height: 10),
                      BarChart(
                        key: ValueKey('${_mode.index}-${_by.index}'),
                        groups: groups,
                        visible: visible,
                        height: 150,
                        fmt: (v) => fmtMoney(v, s.baseCurrency),
                      ),
                      if (hasLegend) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          children: [
                            _legend(p, ChartColors.income, tr('- доходы')),
                            _legend(p, ChartColors.expense, tr('- расходы')),
                            _legend(p, ChartColors.profit, tr('- прибыль')),
                            _legend(p, ChartColors.loss, tr('- убыток')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Summary(ops: ops, mode: _mode.index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Pal p, Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(t, style: TextStyle(color: p.tabInactive, fontSize: 15)),
    ],
  );
}

class _Summary extends StatelessWidget {
  final List<Operation> ops;
  final int mode;
  const _Summary({required this.ops, required this.mode});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.read<AppState>();
    final month = rangeFor(PeriodKind.month, DateTime.now());
    double inc = 0, exp = 0;
    for (final o in ops.where((o) => month.contains(o.date))) {
      if (o.type == OpType.income) {
        inc += s.opValue(o);
      } else {
        exp += s.opValue(o);
      }
    }
    if (inc == 0 && exp == 0) return const SizedBox();
    Widget tile(String t, double v, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: TextStyle(color: p.secondary, fontSize: 13.5)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                fmtMoney(v, s.baseCurrency),
                style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
    return FadeSlideIn(
      child: Row(
        children: [
          if (mode != 1) tile(tr('Доходы'), inc, ChartColors.income),
          if (mode == 0) const SizedBox(width: 10),
          if (mode != 2) tile(tr('Расходы'), exp, ChartColors.expense),
          if (mode == 0) ...[
            const SizedBox(width: 10),
            tile(
              inc >= exp ? tr('- прибыль').substring(2) : tr('- убыток').substring(2),
              (inc - exp).abs(),
              inc >= exp ? ChartColors.profit : ChartColors.loss,
            ),
          ],
        ],
      ),
    );
  }
}

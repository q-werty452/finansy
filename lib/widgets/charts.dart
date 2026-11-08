import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class DonutSegment {
  final double value;
  final Color color;
  const DonutSegment(this.value, this.color);
}

/// Кольцевая диаграмма главного экрана
class Donut extends StatefulWidget {
  final List<DonutSegment> segments;
  final Widget center;
  final double size;
  final ValueChanged<int?>? onSelect;
  final int? selected;
  const Donut({super.key, required this.segments, required this.center, this.size = 220, this.onSelect, this.selected});

  @override
  State<Donut> createState() => _DonutState();
}

class _DonutState extends State<Donut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  List<DonutSegment> _old = const [];

  @override
  void didUpdateWidget(Donut old) {
    super.didUpdateWidget(old);
    if (!_same(old.segments, widget.segments)) {
      _old = old.segments;
      _c.forward(from: 0);
    }
  }

  bool _same(List<DonutSegment> a, List<DonutSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap(Offset local) {
    if (widget.onSelect == null || widget.segments.isEmpty) return;
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = (local - c).distance;
    final outer = widget.size / 2, inner = outer - widget.size * 0.16;
    if (d < inner - 6 || d > outer + 6) {
      widget.onSelect!(null);
      return;
    }
    var a = math.atan2(local.dy - c.dy, local.dx - c.dx) + math.pi / 2;
    if (a < 0) a += 2 * math.pi;
    final total = widget.segments.fold(0.0, (s, e) => s + e.value);
    var acc = 0.0;
    for (var i = 0; i < widget.segments.length; i++) {
      acc += widget.segments[i].value / total * 2 * math.pi;
      if (a <= acc) {
        HapticFeedback.selectionClick();
        widget.onSelect!(widget.selected == i ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTapUp: (d) => _tap(d.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => CustomPaint(
            painter: _DonutPainter(
              segments: widget.segments,
              old: _old,
              t: Curves.easeOutCubic.transform(_c.value),
              pal: p,
              selected: widget.selected,
            ),
            child: child,
          ),
          child: Center(
            child: SizedBox(
              width: widget.size * 0.5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c),
                ),
                child: KeyedSubtree(key: ValueKey(widget.selected), child: widget.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final List<DonutSegment> old;
  final double t;
  final Pal pal;
  final int? selected;
  _DonutPainter({required this.segments, required this.old, required this.t, required this.pal, this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final thick = size.width * 0.16;
    final mid = outer - thick / 2;
    final innerR = outer - thick;

    if (segments.isEmpty) {
      // Пустое кольцо: объёмный серо-зелёный градиент
      final ring = Paint()
        ..shader = RadialGradient(
          colors: [pal.ringDark, pal.ringLight, pal.ringDark],
          stops: [innerR / outer, (innerR + thick * 0.55) / outer, 1],
        ).createShader(Rect.fromCircle(center: c, radius: outer))
        ..style = PaintingStyle.stroke
        ..strokeWidth = thick;
      canvas.drawCircle(c, mid, ring);
      final glow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent, Colors.white.withValues(alpha: 0.06)],
        ).createShader(Rect.fromCircle(center: c, radius: outer))
        ..style = PaintingStyle.stroke
        ..strokeWidth = thick;
      canvas.drawCircle(c, mid, glow);
    } else {
      final total = segments.fold(0.0, (s, e) => s + e.value);
      var start = -math.pi / 2;
      final sweepAll = 2 * math.pi * t;
      final gap = segments.length > 1 ? 0.012 : 0.0;
      for (var i = 0; i < segments.length; i++) {
        final s = segments[i];
        final sweep = s.value / total * sweepAll;
        final sel = selected == i;
        final p = Paint()
          ..color = selected != null && !sel ? s.color.withValues(alpha: 0.55) : s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sel ? thick + 8 : thick;
        final arc = math.max(0.0, sweep - gap);
        if (arc > 0) canvas.drawArc(Rect.fromCircle(center: c, radius: mid), start + gap / 2, arc, false, p);
        start += sweep;
      }
    }

    // Внутренний круг и пунктир
    canvas.drawCircle(c, innerR, Paint()..color = pal.card);
    final dashR = innerR - 9;
    final dash = Paint()
      ..color = pal.text.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const n = 36;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: dashR), a, 2 * math.pi / n * 0.55, false, dash);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.segments != segments || o.selected != selected || o.pal != pal;
}

// ---------------------------------------------------------------------
//  Столбчатый график
// ---------------------------------------------------------------------
class BarGroup {
  final String label;
  final String? sub; // год под подписью, если меняется
  final List<(double, Color)> bars;
  const BarGroup(this.label, this.bars, {this.sub});
}

class BarChart extends StatefulWidget {
  final List<BarGroup> groups;
  final String Function(double) fmt;
  final double height;
  final int visible;
  const BarChart({super.key, required this.groups, required this.fmt, this.height = 190, this.visible = 6});

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  final _scroll = ScrollController();
  (int, int)? _sel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    if (old.groups.length != widget.groups.length || old.groups.firstOrNull?.label != widget.groups.firstOrNull?.label) {
      _sel = null;
      _c.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, cons) {
        final groupW = cons.maxWidth / widget.visible;
        final maxV = widget.groups.fold(0.0, (m, g) => g.bars.fold(m, (mm, b) => math.max(mm, b.$1.abs())));
        final years = <String>{
          for (final g in widget.groups)
            if (g.sub != null) g.sub!,
        };
        return Column(
          children: [
            SizedBox(
              height: widget.height + 40,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    final t = Curves.easeOutCubic.transform(_c.value);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var gi = 0; gi < widget.groups.length; gi++)
                          _group(p, widget.groups[gi], gi, groupW, maxV, t, gi == widget.groups.length - 1),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(years.isEmpty ? '' : years.join(' – '), style: TextStyle(color: p.tabInactive, fontSize: 16)),
          ],
        );
      },
    );
  }

  Widget _group(Pal p, BarGroup g, int gi, double w, double maxV, double t, bool last) {
    final n = g.bars.length;
    final barW = math.min(18.0, (w - 18) / n);
    return SizedBox(
      width: w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: widget.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var bi = 0; bi < n; bi++)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sel = _sel == (gi, bi) ? null : (gi, bi));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_sel == (gi, bi))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.fmt(g.bars[bi].$1), style: TextStyle(color: p.text, fontSize: 11)),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: barW,
                            height: maxV == 0 ? 0 : (g.bars[bi].$1.abs() / maxV) * (widget.height - 34) * t,
                            decoration: BoxDecoration(
                              color: g.bars[bi].$2.withValues(alpha: _sel == null || _sel == (gi, bi) ? 1 : 0.5),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1.2, color: p.tabInactive.withValues(alpha: 0.7)),
          SizedBox(
            height: 38,
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, child: Container(width: 1.4, height: 7, color: p.tabInactive.withValues(alpha: 0.7))),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(g.label, style: TextStyle(color: p.text, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

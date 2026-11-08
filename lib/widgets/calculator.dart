import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../util/format.dart';
import '../util/icons.dart';

Future<double?> showCalculator(BuildContext context, double initial) => showModalBottomSheet<double>(
  context: context,
  backgroundColor: context.pal.dialog,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
  builder: (_) => _Calc(initial: initial),
);

class _Calc extends StatefulWidget {
  final double initial;
  const _Calc({required this.initial});

  @override
  State<_Calc> createState() => _CalcState();
}

class _CalcState extends State<_Calc> {
  late String _expr = widget.initial == 0 ? '' : _trim(widget.initial);

  String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  double? _eval(String e) {
    if (e.isEmpty) return 0;
    try {
      final tokens = RegExp(r'(\d+\.?\d*|[+\-×÷])').allMatches(e).map((m) => m.group(0)!).toList();
      if (tokens.isEmpty) return 0;
      if ('+-×÷'.contains(tokens.last)) tokens.removeLast();
      // Сначала × и ÷
      final st = <String>[];
      for (var i = 0; i < tokens.length; i++) {
        final t = tokens[i];
        if ((t == '×' || t == '÷') && st.isNotEmpty && i + 1 < tokens.length) {
          final a = double.parse(st.removeLast());
          final b = double.parse(tokens[++i]);
          st.add((t == '×' ? a * b : (b == 0 ? 0 : a / b)).toString());
        } else {
          st.add(t);
        }
      }
      var r = double.parse(st.first);
      for (var i = 1; i + 1 < st.length; i += 2) {
        final b = double.parse(st[i + 1]);
        r = st[i] == '+' ? r + b : r - b;
      }
      return (r * 100).roundToDouble() / 100;
    } catch (_) {
      return null;
    }
  }

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == 'C') {
        _expr = '';
      } else if (k == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      } else if (k == '=') {
        final v = _eval(_expr);
        if (v != null) _expr = _trim(v);
      } else if ('+-×÷'.contains(k)) {
        if (_expr.isEmpty) return;
        if ('+-×÷'.contains(_expr[_expr.length - 1])) _expr = _expr.substring(0, _expr.length - 1);
        _expr += k;
      } else if (k == '.') {
        final last = RegExp(r'[\d.]*$').firstMatch(_expr)!.group(0)!;
        if (!last.contains('.')) _expr += last.isEmpty ? '0.' : '.';
      } else {
        _expr += k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final v = _eval(_expr);
    const keys = ['C', '÷', '×', '⌫', '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '=', '0', '00', '.', 'OK'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(_expr.isEmpty ? '0' : _expr.replaceAll('.', NumFmt.sep), style: TextStyle(color: p.secondary, fontSize: 20)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                v == null ? '—' : fmtNum(v),
                style: TextStyle(color: p.text, fontSize: 36, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                for (final k in keys)
                  Material(
                    color: k == 'OK' ? p.yellow : ('+-×÷=C⌫'.contains(k) ? p.card : p.card.withValues(alpha: 0.55)),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => k == 'OK' ? Navigator.pop(context, v ?? 0) : _press(k),
                      child: Center(
                        child: k == '⌫'
                            ? Icon(PI.backspace, color: p.text)
                            : Text(
                                k == '.' ? NumFmt.sep : k,
                                style: TextStyle(
                                  color: k == 'OK' ? p.onYellow : ('+-×÷='.contains(k) ? p.accent : p.text),
                                  fontSize: 22,
                                  fontWeight: k == 'OK' ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Линейная иконка «мешок с $» как в оригинале (в Phosphor такой нет)
class MoneyBagIcon extends StatelessWidget {
  final double size;
  final Color color;
  final String glyph;
  const MoneyBagIcon({super.key, this.size = 24, required this.color, this.glyph = r'$'});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _BagPainter(color, glyph)),
  );
}

class _BagPainter extends CustomPainter {
  final Color color;
  final String glyph;
  _BagPainter(this.color, this.glyph);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Бант
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.42, h * 0.11), width: w * 0.16, height: h * 0.12), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.58, h * 0.11), width: w * 0.16, height: h * 0.12), p);
    // Горловина
    canvas.drawLine(Offset(w * 0.36, h * 0.27), Offset(w * 0.64, h * 0.27), p);
    // Мешок
    final bag = Path()
      ..moveTo(w * 0.40, h * 0.27)
      ..cubicTo(w * 0.05, h * 0.42, w * 0.02, h * 0.95, w * 0.30, h * 0.95)
      ..lineTo(w * 0.70, h * 0.95)
      ..cubicTo(w * 0.98, h * 0.95, w * 0.95, h * 0.42, w * 0.60, h * 0.27);
    canvas.drawPath(bag, p);
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(color: color, fontSize: h * 0.42, fontWeight: FontWeight.w300, fontFamily: 'Roboto', height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.64 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_BagPainter o) => o.color != color || o.glyph != glyph;
}

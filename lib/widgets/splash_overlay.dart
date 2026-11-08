import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common.dart';

const kSplashGreen = Color(0xFF458763);

/// Продолжение системной заставки: монета подпрыгивает и уходит вниз, фон растворяется
class SplashOverlay extends StatefulWidget {
  final Widget child;
  const SplashOverlay({super.key, required this.child});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _done = false;
  static const _coin = AssetImage('assets/images/splash_coin.png');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_coin, context);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _c.forward().whenComplete(() => setState(() => _done = true));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        widget.child,
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: kLightStatus,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final drop = Curves.easeInBack.transform(Interval(0, 0.75).transform(_c.value));
              final fade = 1 - Curves.easeOut.transform(const Interval(0.45, 1).transform(_c.value));
              return IgnorePointer(
                ignoring: _c.value > 0.6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: fade,
                        child: const ColoredBox(color: kSplashGreen),
                      ),
                    ),
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, drop * (h / 2 + 120)),
                        child: Transform.rotate(
                          angle: drop * 0.6,
                          child: const Image(image: _coin, width: 120, height: 120),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

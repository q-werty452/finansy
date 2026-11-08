import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/prefs.dart';
import '../theme.dart';
import '../widgets/common.dart';

Future<void> showRateDialog(BuildContext context) => showAppDialog(context, (c) => const _RateDialog());

class _RateDialog extends StatefulWidget {
  const _RateDialog();

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70),
        child: Material(
          color: p.dialog,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('Мы очень сильно стараемся для Вас и каждый день улучшаем наше приложение!'),
                  style: TextStyle(color: p.text, fontSize: 16.5, height: 1.2, letterSpacing: 0.2),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('Пожалуйста, поставьте нам 5 звезд на странице приложения в App Store!'),
                  style: TextStyle(color: p.text, fontSize: 16.5, height: 1.2, letterSpacing: 0.2),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _a,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, 30 * (1 - Curves.easeOutBack.transform((_a.value * 1.6).clamp(0, 1)))),
                            child: child,
                          ),
                          child: Image.asset('assets/images/kitten.png', width: 200),
                        ),
                      ),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF12140A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.text.withValues(alpha: 0.85), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var i = 0; i < 5; i++)
                              AnimatedBuilder(
                                animation: _a,
                                builder: (_, _) {
                                  final t = ((_a.value - 0.3 - i * 0.1) / 0.25).clamp(0.0, 1.0);
                                  return Transform.scale(
                                    scale: 0.4 + 0.6 * Curves.elasticOut.transform(t),
                                    child: Icon(Icons.star_rounded, color: Color.lerp(p.card, p.yellow, t), size: 38),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(tr('Спасибо Вам большое!'), style: TextStyle(color: p.text, fontSize: 17, letterSpacing: 0.2)),
                const SizedBox(height: 24),
                YellowButton(
                  text: tr('5 ЗВЁЗДОЧЕК'),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await context.read<LocalPrefs>().setFlag('rated', true);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

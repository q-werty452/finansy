import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../state/prefs.dart';
import '../../theme.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';

/// Точки + цифровая клавиатура. onComplete возвращает false → тряска и сброс.
class PasscodePad extends StatefulWidget {
  final String title;
  final Future<bool> Function(String code) onComplete;
  const PasscodePad({super.key, required this.title, required this.onComplete});

  @override
  State<PasscodePad> createState() => PasscodePadState();
}

class PasscodePadState extends State<PasscodePad> with SingleTickerProviderStateMixin {
  String _code = '';
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  void reset() => setState(() => _code = '');

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _tap(String d) async {
    if (_code.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() => _code += d);
    if (_code.length == 4) {
      await Future.delayed(const Duration(milliseconds: 120));
      final ok = await widget.onComplete(_code);
      if (!ok && mounted) {
        HapticFeedback.heavyImpact();
        await _shake.forward(from: 0);
        if (mounted) setState(() => _code = '');
      }
    }
  }

  void _back() {
    if (_code.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget key(String d) => SizedBox(
      width: 110,
      height: 58,
      child: InkResponse(
        onTap: () => _tap(d),
        radius: 38,
        child: Center(
          child: Text(
            d,
            style: TextStyle(color: p.accent, fontSize: 40, fontWeight: FontWeight.w300),
          ),
        ),
      ),
    );
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.title,
            key: ValueKey(widget.title),
            style: TextStyle(color: p.text, fontSize: 17, letterSpacing: 0.2),
          ),
        ),
        const SizedBox(height: 34),
        AnimatedBuilder(
          animation: _shake,
          builder: (_, child) =>
              Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 14 * (1 - _shake.value), 0), child: child),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: i < _code.length ? 13 : 10,
                        height: i < _code.length ? 13 : 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i < _code.length ? p.accent : p.tabInactive),
                      ),
                      const SizedBox(height: 28),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 56,
                        height: 2.4,
                        color: i == _code.length ? p.header : p.tabInactive,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 70),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) key(d)]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 110),
            key('0'),
            SizedBox(
              width: 110,
              height: 58,
              child: InkResponse(
                onTap: _back,
                radius: 34,
                child: Icon(PI.backspace, color: p.accent, size: 34),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Экран блокировки при запуске
class LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final prefs = context.read<LocalPrefs>();
    return AnnotatedRegion(
      value: kLightStatus,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 50),
              ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(appIconAsset(prefs.appIcon), width: 72, height: 72)),
              const SizedBox(height: 40),
              PasscodePad(
                title: tr('Введите код-пароль'),
                onComplete: (c) async {
                  if (prefs.checkPasscode(c)) {
                    onUnlock();
                    return true;
                  }
                  return false;
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    tr('Сбросить код-пароль?'),
                    subtitle: tr('Для защиты все данные на этом устройстве будут удалены. Восстановить их можно из резервной копии.'),
                    danger: true,
                    yes: 'УДАЛИТЬ',
                  )) {
                    await prefs.setPasscode(null);
                    if (context.mounted) await context.read<AppState>().deleteAllData();
                    onUnlock();
                  }
                },
                child: Text(tr('Забыли код-пароль?'), style: TextStyle(color: p.secondary, fontSize: 15)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

String appIconAsset(int i) => 'assets/images/icon_${const ['coin', 'bag', 'piggy', 'cat'][i.clamp(0, 3)]}.png';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n.dart';
import '../../services/notifications.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import 'currency_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currency == null,
      onPopInvokedWithResult: (did, _) {
        if (!did) setState(() => _currency = null);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (c, a) => SlideTransition(
          position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a, child: c),
        ),
        child: _currency == null
            ? CurrencyScreen(
                key: const ValueKey('cur'),
                selected: L10n.lang == 'en' ? 'USD' : 'RUB',
                onNext: (c) => setState(() => _currency = c),
              )
            : BalanceScreen(key: const ValueKey('bal'), currency: _currency!, onBack: () => setState(() => _currency = null)),
      ),
    );
  }
}

class BalanceScreen extends StatefulWidget {
  final String currency;
  final VoidCallback onBack;
  const BalanceScreen({super.key, required this.currency, required this.onBack});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final _c = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => _saving = true);
    try {
      await context.read<AppState>().finishOnboarding(widget.currency, parseAmount(_c.text) ?? 0);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion(
      value: kLightStatus,
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            SizedBox(height: top + 52),
            Row(
              children: [
                SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(PI.caretLeft, color: p.secondary, size: 26),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr('Введите текущий баланс\nосновного счета'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text, fontSize: 24, height: 1.55, letterSpacing: 0.2),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                tr('Вы сможете добавить дополнительные счета в разделе "Счета"'),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.secondary, fontSize: 16, height: 1.6, letterSpacing: 0.2),
              ),
            ),
            const SizedBox(height: 34),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 50),
                SizedBox(
                  width: 152,
                  child: TextField(
                    controller: _c,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s-]'))],
                    style: TextStyle(color: p.text, fontSize: 24),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 1.8)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 1.8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(widget.currency, style: TextStyle(color: p.text, fontSize: 24)),
              ],
            ),
            const Spacer(),
            YellowButton(text: tr('Далее'), loading: _saving, onTap: _next),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  «Пользователи, которые используют напоминания…»
// ---------------------------------------------------------------------
Future<void> showNotificationPromo(BuildContext context) => showAppDialog(context, (c) {
  final p = c.pal;
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: p.dialog,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('Пользователи, которые используют напоминания, в два раза чаще достигают своих целей'),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 19, height: 1.3, letterSpacing: 0.2),
              ),
              const SizedBox(height: 18),
              const ReminderIllustration(),
              const SizedBox(height: 20),
              Text(
                tr('Приложение Финансы помогает выработать полезные привычки, которые останутся с вами надолго'),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 17.5, height: 1.3, letterSpacing: 0.2),
              ),
              const SizedBox(height: 26),
              YellowButton(
                text: tr('Включить уведомления'),
                onTap: () async {
                  await Notifications.requestPermission();
                  if (c.mounted) Navigator.pop(c);
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(tr('Пропустить'), style: TextStyle(color: p.accent, fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

/// Своя иллюстрация: телефон с графиком, колокольчик-переключатель, монеты и кошелёк
class ReminderIllustration extends StatefulWidget {
  const ReminderIllustration({super.key});

  @override
  State<ReminderIllustration> createState() => _ReminderIllustrationState();
}

class _ReminderIllustrationState extends State<ReminderIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF2B3518), mid = Color(0xFF639F86), light = Color(0xFFB8D4C4), pale = Color(0xFFE4EFE8);
    return SizedBox(
      width: 300,
      height: 200,
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, _) {
          final t = Curves.easeInOut.transform(_a.value);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 60,
                top: 30,
                child: Container(
                  width: 170,
                  height: 150,
                  decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(80)),
                ),
              ),
              Positioned(
                left: 70,
                bottom: 0,
                child: Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              // Телефон
              Positioned(
                left: 120,
                top: 60 - t * 3,
                child: Transform.rotate(
                  angle: 0.12,
                  child: Container(
                    width: 74,
                    height: 128,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: mid, borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(PI.trendUp, size: 22, color: Color(0xFF3C6B57)),
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final h in [18.0, 30.0, 24.0, 40.0])
                                Container(width: 8, height: h * (0.7 + 0.3 * t), color: const Color(0xFF3C6B57)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Переключатель с колокольчиком
              Positioned(
                left: 95,
                top: 0,
                child: Container(
                  width: 110,
                  height: 46,
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: mid, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Transform.rotate(
                        angle: (t - 0.5) * 0.4,
                        child: const Icon(Icons.notifications, color: Color(0xFF3C6B57), size: 28),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: mid,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3C6B57), width: 2),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              // Монеты
              for (final (x, y, s) in [(70.0, 55.0, 30.0), (100.0, 85.0, 26.0), (78.0, 135.0, 22.0)])
                Positioned(
                  left: x,
                  top: y - t * 4,
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: light,
                      shape: BoxShape.circle,
                      border: Border.all(color: mid, width: 2),
                    ),
                    child: Icon(PI.currencyDollar, size: s * 0.6, color: const Color(0xFF3C6B57)),
                  ),
                ),
              // Карта
              Positioned(
                left: 40,
                top: 105,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    width: 64,
                    height: 40,
                    decoration: BoxDecoration(
                      color: light,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: mid, width: 2),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, width: 40, color: mid),
                        const SizedBox(height: 5),
                        Container(height: 3, width: 26, color: mid),
                      ],
                    ),
                  ),
                ),
              ),
              // Кошелёк
              Positioned(
                left: 72,
                top: 140,
                child: Container(
                  width: 68,
                  height: 50,
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: mid, width: 2),
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.circle, size: 10, color: Color(0xFF3C6B57)),
                    ),
                  ),
                ),
              ),
              // Листья
              Positioned(
                right: 48,
                bottom: 14,
                child: Transform.rotate(
                  angle: 0.5 + t * 0.08,
                  child: const Icon(PI.leaf, size: 44, color: mid),
                ),
              ),
              Positioned(
                right: 30,
                top: 70,
                child: Transform.rotate(
                  angle: -0.3 - t * 0.08,
                  child: const Icon(PI.leaf, size: 30, color: light),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

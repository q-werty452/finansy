import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../l10n.dart';
import '../../state/prefs.dart';
import '../../theme.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import '../lock/lock_screen.dart';
import 'settings_pages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = <(IconData, String, Widget)>[
      (PI.lockKey, tr('Код-пароль'), const PasscodeScreen()),
      (PI.user, tr('Персонализация'), const PersonalizationScreen()),
      (PI.circlesThree, tr('Внешний вид'), const AppearanceScreen()),
      (PI.gearFine, tr('Расширенные настройки'), const AdvancedScreen()),
      (PI.database, tr('Данные'), const DataScreen()),
      (PI.slidersHorizontal, tr('Дополнительно'), const AdditionalScreen()),
    ];
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: tr('Настройки')),
          const SizedBox(height: 18),
          for (var i = 0; i < items.length; i++)
            FadeSlideIn(
              index: i,
              child: InkWell(
                onTap: () => Navigator.push(context, pageRoute(items[i].$3)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 5, 12, 5),
                  child: Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(color: p.iconTile, borderRadius: BorderRadius.circular(7)),
                        child: Icon(items[i].$1, color: p.accent.withValues(alpha: 0.75), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(items[i].$2, style: TextStyle(color: p.text, fontSize: 15.8, letterSpacing: 0.15)),
                      ),
                      Icon(PI.caretRight, color: p.secondary, size: 26),
                    ],
                  ),
                ),
              ),
            ),
          FadeSlideIn(
            index: items.length,
            child: InkWell(
              onTap: () => showSnack(context, tr('Покупки не найдены')),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    SizedBox(width: 33, child: Icon(PI.shoppingCart, color: p.text, size: 26)),
                    const SizedBox(width: 10),
                    Text(tr('Восстановить покупки'), style: TextStyle(color: p.text, fontSize: 15.8, letterSpacing: 0.15)),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr('Версия {v}', {'v': '${AppConfig.appVersion}_as'}), style: TextStyle(color: p.hint, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Код-пароль
// ---------------------------------------------------------------------
class PasscodeScreen extends StatelessWidget {
  const PasscodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final prefs = context.watch<LocalPrefs>();
    Widget link(String t, VoidCallback onTap, {Color? color}) => TextButton(
      onPressed: onTap,
      child: Text(t, style: TextStyle(color: color ?? p.accent, fontSize: 17.5, letterSpacing: 0.2)),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Код-пароль')),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              tr('Вы можете установить код-пароль из 4х цифр на вход в приложение.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontSize: 17, height: 1.3, letterSpacing: 0.15),
            ),
          ),
          const SizedBox(height: 18),
          if (!prefs.hasPasscode)
            link(tr('Установить код-пароль'), () => Navigator.push(context, pageRoute(const SetPasscodeScreen())))
          else ...[
            link(tr('Изменить код-пароль'), () => Navigator.push(context, pageRoute(const SetPasscodeScreen()))),
            link(tr('Отключить код-пароль'), () async {
              if (await confirm(context, '${tr('Отключить код-пароль')}?')) {
                await prefs.setPasscode(null);
                if (context.mounted) showSnack(context, tr('Код-пароль отключен'));
              }
            }, color: p.danger),
          ],
        ],
      ),
    );
  }
}

class SetPasscodeScreen extends StatefulWidget {
  const SetPasscodeScreen({super.key});

  @override
  State<SetPasscodeScreen> createState() => _SetPasscodeScreenState();
}

class _SetPasscodeScreenState extends State<SetPasscodeScreen> {
  String? _first;
  final _pad = GlobalKey<PasscodePadState>();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Установка код-пароля')),
          const SizedBox(height: 38),
          PasscodePad(
            key: _pad,
            title: _first == null ? tr('Придумайте код-пароль') : tr('Повторите код-пароль'),
            onComplete: (c) async {
              if (_first == null) {
                setState(() => _first = c);
                _pad.currentState?.reset();
                return true;
              }
              if (_first == c) {
                await context.read<LocalPrefs>().setPasscode(c);
                if (!context.mounted) return true;
                showSnack(context, tr('Код-пароль установлен'));
                Navigator.pop(context);
                return true;
              }
              showSnack(context, tr('Коды не совпадают'));
              setState(() => _first = null);
              return false;
            },
          ),
        ],
      ),
    );
  }
}

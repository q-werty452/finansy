import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../state/prefs.dart';
import '../theme.dart';
import '../util/format.dart';
import '../util/icons.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import '../widgets/money_bag.dart';
import 'accounts/accounts_screen.dart';
import 'categories/categories_screen.dart';
import 'charts/charts_screen.dart';
import 'contact_screen.dart';
import 'main/main_screen.dart';
import 'onboarding/onboarding.dart';
import 'profile_screen.dart';
import 'rate_dialog.dart';
import 'recurring/recurring_screen.dart';
import 'reminders/reminders_screen.dart';
import 'settings/settings_screen.dart';

enum Section { home, accounts, charts, categories, recurring, reminders, settings, contact, profile }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static void go(BuildContext context, Section s) => context.findAncestorStateOfType<_HomeShellState>()?.go(s);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  GlobalKey<ScaffoldState> get _key => mainScaffoldKey;
  Section _section = Section.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promos());
  }

  Future<void> _promos() async {
    final prefs = context.read<LocalPrefs>();
    if (!prefs.flag('notifPromoShown')) {
      await prefs.setFlag('notifPromoShown', true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) await showNotificationPromo(context);
    }
  }

  void go(Section s) {
    if (_key.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    if (s != _section) setState(() => _section = s);
  }

  Widget _body() => switch (_section) {
    Section.home => const MainScreen(),
    Section.accounts => const AccountsScreen(),
    Section.charts => const ChartsScreen(),
    Section.categories => const CategoriesScreen(),
    Section.recurring => const RecurringScreen(),
    Section.reminders => const RemindersScreen(),
    Section.settings => const SettingsScreen(),
    Section.contact => const ContactScreen(),
    Section.profile => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _section == Section.home,
      onPopInvokedWithResult: (did, _) {
        if (!did) go(Section.home);
      },
      child: Scaffold(
        key: _key,
        drawer: _AppDrawer(onGo: go),
        drawerScrimColor: Colors.black.withValues(alpha: 0.6),
        drawerEdgeDragWidth: 40,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: KeyedSubtree(key: ValueKey(_section), child: _body()),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final ValueChanged<Section> onGo;
  const _AppDrawer({required this.onGo});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final balance = s.hideBalance ? '•••' : fmtMoney(s.totalBalance, s.baseCurrency);
    final items = <(IconData, String, VoidCallback)>[
      (PI.chartDonut, tr('Главная'), () => onGo(Section.home)),
      (PI.moneyWavy, tr('Счета'), () => onGo(Section.accounts)),
      (PI.chartBar, tr('Графики'), () => onGo(Section.charts)),
      (PI.rows, tr('Категории'), () => onGo(Section.categories)),
      (PI.arrowsClockwise, tr('Регулярные платежи'), () => onGo(Section.recurring)),
      (PI.bell, tr('Напоминания'), () => onGo(Section.reminders)),
      (PI.gear, tr('Настройки'), () => onGo(Section.settings)),
      (
        PI.export,
        tr('Поделиться с друзьями'),
        () {
          Navigator.pop(context);
          SharePlus.instance.share(
            ShareParams(
              text: L10n.lang == 'en'
                  ? 'I track my money with Finansy — simple expense & income tracker. Try it!'
                  : 'Я веду учёт денег в приложении «Финансы» — простой учёт расходов и доходов. Попробуй!',
            ),
          );
        },
      ),
      (PI.star, tr('Оценить приложение'), () => showRateDialog(context)),
      (PI.envelopeSimple, tr('Связь с разработчиком'), () => onGo(Section.contact)),
    ];
    return Drawer(
      width: 320,
      backgroundColor: p.drawer,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onGo(Section.profile),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, top + 18, 12, 14),
              child: Row(
                children: [
                  Avatar(url: s.profile?.avatarUrl, name: s.profile?.name ?? '', size: 52),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.profile?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFEDEDDA), fontSize: 17.5, letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('Остаток: {v}', {'v': balance}),
                          style: const TextStyle(color: Color(0xFFEDEDDA), fontSize: 15.8, letterSpacing: 0.15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFF728571)),
          const SizedBox(height: 14),
          for (final it in items)
            InkWell(
              onTap: it.$3,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    it.$1 == PI.moneyWavy
                        ? const MoneyBagIcon(size: 28, color: Color(0xFFEDEDDA))
                        : Icon(it.$1, size: 26, color: const Color(0xFFEDEDDA)),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Text(
                        it.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFEDEDDA), fontSize: 16, letterSpacing: 0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: () => s.refresh(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.paddingOf(context).bottom + 18),
              child: Row(
                children: [
                  s.loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB2BDAB)))
                      : const Icon(PI.arrowsCounterClockwise, size: 22, color: Color(0xFFB2BDAB)),
                  const SizedBox(width: 14),
                  Text(
                    s.lastSync == null ? '' : df('dd.MM.yyyy HH:mm').format(s.lastSync!),
                    style: const TextStyle(color: Color(0xFFB2BDAB), fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

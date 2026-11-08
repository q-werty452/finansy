import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import 'account_edit_screen.dart';
import 'transfer_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(title: tr('Счета')),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: s.refresh,
                  color: p.accent,
                  backgroundColor: p.card,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, MediaQuery.paddingOf(context).bottom + 110),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      Center(
                        child: Text(tr('Итого:'), style: TextStyle(color: p.tabInactive, fontSize: 18.5, letterSpacing: 0.2)),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: s.totalBalance),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => Text(
                            s.hideBalance ? '•••' : fmtMoney(v, s.baseCurrency),
                            style: TextStyle(color: p.text, fontSize: 30, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _Action(
                              icon: PI.clockCounterClockwise,
                              label: tr('История переводов'),
                              onTap: () => Navigator.push(context, pageRoute(const TransferHistoryScreen())),
                            ),
                          ),
                          Expanded(
                            child: _Action(
                              icon: PI.arrowsLeftRight,
                              label: tr('Создать перевод'),
                              onTap: () {
                                if (s.accounts.length < 2) {
                                  showSnack(context, tr('Нужно минимум два счета'));
                                  return;
                                }
                                Navigator.push(context, pageRoute(const TransferScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      for (var i = 0; i < s.accounts.length; i++)
                        FadeSlideIn(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: p.card,
                              borderRadius: BorderRadius.circular(10),
                              elevation: 2,
                              shadowColor: Colors.black45,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => Navigator.push(context, pageRoute(AccountEditScreen(account: s.accounts[i]))),
                                child: SizedBox(
                                  height: 56,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      IconCircle(icon: s.accounts[i].icon, color: s.accounts[i].col, size: 32, iconSize: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          s.accounts[i].name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: p.text, fontSize: 17.5, letterSpacing: 0.2),
                                        ),
                                      ),
                                      Text(
                                        s.hideBalance ? '•••' : fmtMoney(s.accounts[i].balance, s.accounts[i].currency),
                                        style: TextStyle(color: p.text, fontSize: 17.5, letterSpacing: 0.2),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: Center(child: YellowFab(onTap: () => Navigator.push(context, pageRoute(const AccountEditScreen())))),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.25), blurRadius: 14)],
            ),
            child: Icon(icon, color: const Color(0xFFF4F4E8), size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: p.text, fontSize: 15.5, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

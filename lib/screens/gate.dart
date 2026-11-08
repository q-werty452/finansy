import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../state/prefs.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'lock/lock_screen.dart';
import 'onboarding/onboarding.dart';

class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget child;
    if (!s.loaded) {
      child = s.error != null ? _ErrorRetry(key: const ValueKey('err'), message: s.error!) : const Splash(key: ValueKey('splash'));
    } else if (s.needsOnboarding) {
      child = const OnboardingFlow(key: ValueKey('onb'));
    } else {
      child = const LockGate(key: ValueKey('app'), child: HomeShell());
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: child);
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(appIconAsset(context.read<LocalPrefs>().appIcon), width: 96, height: 96),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  const _ErrorRetry({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 17),
              ),
              const SizedBox(height: 28),
              YellowButton(text: tr('Повторить'), onTap: () => context.read<AppState>().load()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показывает экран код-пароля при запуске и после возврата из фона
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked = context.read<LocalPrefs>().hasPasscode;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    final s = context.read<AppState>();
    if (st == AppLifecycleState.paused || st == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      s.flush();
    }
    if (st == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away.inSeconds > 30 && context.read<LocalPrefs>().hasPasscode) setState(() => _locked = true);
      s.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_locked) Positioned.fill(child: LockScreen(onUnlock: () => setState(() => _locked = false))),
    ],
  );
}

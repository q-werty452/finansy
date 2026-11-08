import 'dart:io';

import 'package:finansy/screens/home_shell.dart';
import 'package:finansy/state/app_state.dart';
import 'package:finansy/state/prefs.dart';
import 'package:finansy/theme.dart';
import 'package:finansy/util/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('бургер открывает меню из любого раздела', (t) async {
    t.view.physicalSize = const Size(1320, 2868);
    t.view.devicePixelRatio = 3;
    SharedPreferences.setMockInitialValues({'notifPromoShown': true});
    final prefs = LocalPrefs();
    final state = AppState(prefs);
    await t.runAsync(() async {
      await initializeDateFormatting('ru');
      AppState.docsPath = (await Directory.systemTemp.createTemp('fin')).path;
      await prefs.load();
      await state.load();
      await state.finishOnboarding('RUB', 0);
    });
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: prefs),
          ChangeNotifierProvider.value(value: state),
        ],
        child: MaterialApp(theme: buildTheme(Pal.dark, Brightness.dark), home: const HomeShell()),
      ),
    );
    await t.pump(const Duration(seconds: 1));

    for (final section in ['Категории', 'Счета', 'Настройки', 'Напоминания', 'Регулярные платежи']) {
      await t.tap(find.byIcon(PI.list).first);
      await t.pumpAndSettle();
      expect(find.text('Связь с разработчиком'), findsOneWidget, reason: 'меню не открылось перед $section');
      await t.tap(find.text(section).last);
      await t.pumpAndSettle();
      expect(find.text('Связь с разработчиком'), findsNothing, reason: 'меню не закрылось после $section');
    }
    await t.tap(find.byIcon(PI.list).first);
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Связь с разработчиком'), findsOneWidget, reason: 'меню не открылось из раздела');
  });
}

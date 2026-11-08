import 'dart:io';
import 'dart:ui' as ui;

import 'package:finansy/data/models.dart';
import 'package:finansy/main.dart';
import 'package:finansy/screens/accounts/accounts_screen.dart';
import 'package:finansy/screens/categories/categories_screen.dart';
import 'package:finansy/screens/charts/charts_screen.dart';
import 'package:finansy/screens/contact_screen.dart';
import 'package:finansy/screens/home_shell.dart';
import 'package:finansy/screens/operations/add_operation_screen.dart';
import 'package:finansy/screens/operations/operations_screen.dart';
import 'package:finansy/services/export.dart';
import 'package:finansy/util/format.dart';
import 'package:finansy/util/icons.dart';
import 'package:finansy/screens/profile_screen.dart';
import 'package:finansy/screens/recurring/recurring_screen.dart';
import 'package:finansy/screens/reminders/reminders_screen.dart';
import 'package:finansy/screens/settings/settings_pages.dart';
import 'package:finansy/screens/settings/settings_screen.dart';
import 'package:finansy/state/app_state.dart';
import 'package:finansy/state/prefs.dart';
import 'package:finansy/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Рендер экранов в PNG (1320x2868, как скриншоты iPhone) для сверки с оригиналом
Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

final _key = GlobalKey();

Future<void> shot(WidgetTester t, String name) async {
  for (var i = 0; i < 15; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump();
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('${Platform.environment['SHOTS'] ?? '/tmp'}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('screens', (t) async {
    await t.runAsync(() async {
      await _font('Roboto', [
        'assets/fonts/Roboto-Regular.ttf',
        'assets/fonts/Roboto-Medium.ttf',
        'assets/fonts/Roboto-Bold.ttf',
        'assets/fonts/Roboto-Light.ttf',
      ]);
      await _font('PhosphorLight', ['assets/fonts/Phosphor-Light.ttf']);
      await _font('PhosphorRegular', ['assets/fonts/Phosphor-Regular.ttf']);
      await _font('MaterialIcons', ['/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
      await initializeDateFormatting('ru');
      AppState.docsPath = (await Directory.systemTemp.createTemp('fin')).path;
    });
    t.view.physicalSize = const Size(1320, 2868);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    SharedPreferences.setMockInitialValues({'notifPromoShown': true});
    final prefs = LocalPrefs();
    final state = AppState(prefs);
    await t.runAsync(() async {
      await prefs.load();
      await state.load();
    });

    Widget wrap(Widget child) => RepaintBoundary(
      key: _key,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: prefs),
          ChangeNotifierProvider.value(value: state),
        ],
        child: child,
      ),
    );
    Widget page(Widget home) =>
        wrap(MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(Pal.dark, Brightness.dark), home: home));

    await t.pumpWidget(wrap(const FinansyApp()));
    await shot(t, '01_currency');
    await t.runAsync(() => state.finishOnboarding('RUB', 100));
    await t.pump();
    await shot(t, '02_main_empty');

    final only = Platform.environment['ONLY'];
    Future<void> s(String name, Widget w) async {
      if (only != null && !name.contains(only)) return;
      await t.pumpWidget(page(w));
      await shot(t, name);
    }

    await s('10_add_expense', const AddOperationScreen());
    await s('11_add_income', const AddOperationScreen(type: OpType.income));
    await s('12_accounts', const AccountsScreen());
    await s('13_categories', const CategoriesScreen());
    await s('14_charts', const ChartsScreen());
    await s('15_settings', const SettingsScreen());
    await s('16_personalization', const PersonalizationScreen());
    await s('17_appearance', const AppearanceScreen());
    await s('18_advanced', const AdvancedScreen());
    await s('19_data', const DataScreen());
    await s('20_backup', const BackupScreen());
    await s('21_recurring', const RecurringScreen());
    await s('22_recurring_new', const RecurringEditScreen());
    await s('23_reminders', const RemindersScreen());
    await s('24_reminder_new', const ReminderEditScreen());
    await s('25_profile', const ProfileScreen());
    await s('26_contact', const ContactScreen());
    await s('27_passcode', const SetPasscodeScreen());

    await t.pumpWidget(page(const HomeShell()));
    await t.pump();
    t.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await shot(t, '28_drawer');

    final cats = state.categoriesOf(OpType.expense);
    final acc = state.accounts.first.id;
    for (final (i, a) in [(0, 1200.0), (3, 850.0), (6, 2300.0), (9, 400.0), (2, 600.0)]) {
      await state.saveOperation(
        type: OpType.expense,
        amount: a,
        accountId: acc,
        categoryId: cats[i].id,
        date: DateTime.now(),
        tags: [],
        comment: '',
        photos: [],
      );
    }
    await state.saveOperation(type: OpType.expense, amount: 30000, accountId: acc, categoryId: cats[4].id,
        date: DateTime.now().subtract(const Duration(days: 1)), tags: ['учёба'], comment: 'Курсы', photos: []);
    await t.pumpWidget(wrap(const FinansyApp()));
    await shot(t, '03_main_data');
    await t.pumpWidget(page(const OperationsScreen()));
    await shot(t, '29_operations');
    await t.tap(find.byIcon(PI.downloadSimple));
    await shot(t, '30_export');
    final d = ExportData(ops: state.operations, type: OpType.expense, period: rangeLabel(PeriodKind.week, rangeFor(PeriodKind.week, DateTime.now())),
        accountName: 'Итого', currency: 'RUB');
    await t.runAsync(() async {
      final dir = Directory(AppState.docsPath);
      final x = await exportExcel(state, d, dir: dir);
      final p = await exportPdf(state, d, dir: dir);
      final out = Platform.environment['SHOTS'] ?? '/tmp';
      await x.copy('$out/export.xlsx');
      await p.copy('$out/export.pdf');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/gate.dart';
import 'state/app_state.dart';
import 'state/prefs.dart';
import 'theme.dart';
import 'widgets/splash_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');
  final prefs = LocalPrefs();
  await prefs.load();
  final state = AppState(prefs);
  await state.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: prefs),
        ChangeNotifierProvider.value(value: state),
      ],
      child: const FinansyApp(),
    ),
  );
}

class FinansyApp extends StatelessWidget {
  const FinansyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<LocalPrefs>();
    return MaterialApp(
      title: 'Финансы',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Pal.light, Brightness.light),
      darkTheme: buildTheme(Pal.dark, Brightness.dark), 
      themeMode: prefs.themeMode,
      locale: Locale(prefs.lang),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: SplashOverlay(child: child!),
      ),
      home: const Gate(),
    );
  }
}

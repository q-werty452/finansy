import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Pal extends ThemeExtension<Pal> {
  final Color bg;
  final Color header;
  final Color drawer;
  final Color card;
  final Color popup;
  final Color dialog;
  final Color accent;
  final Color accentDim;
  final Color yellow;
  final Color onYellow;
  final Color text;
  final Color onHeader;
  final Color headerInactive;
  final Color secondary;
  final Color tabInactive;
  final Color hint;
  final Color line;
  final Color danger;
  final Color ringLight;
  final Color ringDark;
  final Color selectedRow;
  final Color iconTile;
  final Color switchThumbOff;
  final Color switchTrackOff;
  final Color divider;
  final Color infoBox;

  const Pal({
    required this.bg,
    required this.header,
    required this.drawer,
    required this.card,
    required this.popup,
    required this.dialog,
    required this.accent,
    required this.accentDim,
    required this.yellow,
    required this.onYellow,
    required this.text,
    required this.onHeader,
    required this.headerInactive,
    required this.secondary,
    required this.tabInactive,
    required this.hint,
    required this.line,
    required this.danger,
    required this.ringLight,
    required this.ringDark,
    required this.selectedRow,
    required this.iconTile,
    required this.switchThumbOff,
    required this.switchTrackOff,
    required this.divider,
    required this.infoBox,
  });

  static const dark = Pal(
    bg: Color(0xFF1A1E02),
    header: Color(0xFF274E3E),
    drawer: Color(0xFF264D3D),
    card: Color(0xFF31322A),
    popup: Color(0xFF31322A),
    dialog: Color(0xFF1A1E02),
    accent: Color(0xFF46BF8D),
    accentDim: Color(0xFF3D9F71),
    yellow: Color(0xFFFDC229),
    onYellow: Color(0xFF3A3A2C),
    text: Color(0xFFEDEDDA),
    onHeader: Color(0xFFFFFFFF),
    headerInactive: Color(0xFFB2BDAB),
    secondary: Color(0xFF9B9C84),
    tabInactive: Color(0xFFB5B5A5),
    hint: Color(0xFF6B6D54),
    line: Color(0xFF6B6D54),
    danger: Color(0xFFFF8F60),
    ringLight: Color(0xFFBCC6C1),
    ringDark: Color(0xFF9CABA5),
    selectedRow: Color(0xFF28381C),
    iconTile: Color(0xFF232A12),
    switchThumbOff: Color(0xFFB2C4BC),
    switchTrackOff: Color(0xFF30452A),
    divider: Color(0xFF4A4C38),
    infoBox: Color(0xFF3A4038),
  );

  static const light = Pal(
    bg: Color(0xFFF3F3EA),
    header: Color(0xFF274E3E),
    drawer: Color(0xFF264D3D),
    card: Color(0xFFFFFFFF),
    popup: Color(0xFFFFFFFF),
    dialog: Color(0xFFFAFAF3),
    accent: Color(0xFF2FA574),
    accentDim: Color(0xFF3D9F71),
    yellow: Color(0xFFFDC229),
    onYellow: Color(0xFF3A3A2C),
    text: Color(0xFF26281A),
    onHeader: Color(0xFFFFFFFF),
    headerInactive: Color(0xFFB2BDAB),
    secondary: Color(0xFF7A7B66),
    tabInactive: Color(0xFF8A8B78),
    hint: Color(0xFFA9AB95),
    line: Color(0xFFA9AB95),
    danger: Color(0xFFE5703F),
    ringLight: Color(0xFFD5DDD9),
    ringDark: Color(0xFFB3C0BA),
    selectedRow: Color(0xFFE2EBDD),
    iconTile: Color(0xFFE6EBDD),
    switchThumbOff: Color(0xFFFFFFFF),
    switchTrackOff: Color(0xFFC9CFC3),
    divider: Color(0xFFD9DACB),
    infoBox: Color(0xFFE6E9E0),
  );

  @override
  Pal copyWith() => this;

  @override
  Pal lerp(ThemeExtension<Pal>? other, double t) => t < 0.5 ? this : (other as Pal? ?? this);
}

extension PalX on BuildContext {
  Pal get pal => Theme.of(this).extension<Pal>()!;
}

// Цвета графиков и категорий из оригинала
class ChartColors {
  static const income = Color(0xFF639F86);
  static const expense = Color(0xFFFDC229);
  static const profit = Color(0xFF72B7F6);
  static const loss = Color(0xFFFF8F60);
}

ThemeData buildTheme(Pal p, Brightness b) {
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    colorScheme: ColorScheme(
      brightness: b,
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: p.yellow,
      onSecondary: p.onYellow,
      error: p.danger,
      onError: Colors.white,
      surface: p.bg,
      onSurface: p.text,
    ),
    extensions: [p],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text, fontFamily: 'Roboto'),
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: p.divider,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.35),
      selectionHandleColor: p.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      hintStyle: TextStyle(color: p.hint, fontSize: 17),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.line, width: 1.2)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 1.6)),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.danger, width: 1.2)),
      focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.danger, width: 1.6)),
      errorStyle: TextStyle(color: p.danger, fontSize: 12.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.switchThumbOff),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent.withValues(alpha: 0.45) : p.switchTrackOff,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(p.bg),
      side: BorderSide(color: p.text.withValues(alpha: 0.75), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.text.withValues(alpha: 0.75)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.card,
      contentTextStyle: TextStyle(color: p.text, fontSize: 15, fontFamily: 'Roboto'),
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.popup,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(color: p.text, fontSize: 17, fontFamily: 'Roboto'),
      elevation: 6,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.dialog,
      headerBackgroundColor: p.card,
      headerForegroundColor: p.text,
      dayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : p.text),
      dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : null),
      todayForegroundColor: WidgetStatePropertyAll(p.accent),
      todayBorder: BorderSide(color: p.accent),
      rangeSelectionBackgroundColor: p.accentDim.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.dialog,
      dialHandColor: p.accent,
      hourMinuteColor: p.card,
      hourMinuteTextColor: p.text,
      dialBackgroundColor: p.card,
      dayPeriodColor: p.card,
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.accent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
  );
}

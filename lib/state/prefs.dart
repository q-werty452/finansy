import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// Настройки конкретного устройства (не синхронизируются)
class LocalPrefs extends ChangeNotifier {
  late SharedPreferences _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    L10n.lang = lang;
  }

  SharedPreferences get raw => _p;

  /// 'default' | 'light' | 'dark'
  String get theme => _p.getString('theme') ?? 'default';
  set theme(String v) {
    _p.setString('theme', v);
    notifyListeners();
  }

  ThemeMode get themeMode => theme == 'light' ? ThemeMode.light : ThemeMode.dark;

  String get lang => _p.getString('lang') ?? 'ru';
  set lang(String v) {
    _p.setString('lang', v);
    L10n.lang = v;
    notifyListeners();
  }

  int get appIcon => _p.getInt('appIcon') ?? 0;
  set appIcon(int v) {
    _p.setInt('appIcon', v);
    notifyListeners();
  }

  // Код-пароль хранится только как sha256 и только на устройстве
  bool get hasPasscode => _p.getString('passcode') != null;
  bool checkPasscode(String code) => _p.getString('passcode') == _hash(code);
  Future<void> setPasscode(String? code) async {
    if (code == null) {
      await _p.remove('passcode');
    } else {
      await _p.setString('passcode', _hash(code));
    }
    notifyListeners();
  }

  String _hash(String c) => sha256.convert(utf8.encode('finansy:$c')).toString();

  bool flag(String k) => _p.getBool(k) ?? false;
  Future<void> setFlag(String k, bool v) => _p.setBool(k, v);

  int counter(String k) => _p.getInt(k) ?? 0;
  Future<void> bump(String k) => _p.setInt(k, counter(k) + 1);
}

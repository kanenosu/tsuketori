import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマ・通知などのアプリ設定（要件 6.9 / 11.4）。
///
/// MVP ではテーマモードのみ永続化する。
class SettingsState extends ChangeNotifier {
  SettingsState({SharedPreferences? preferences}) : _prefs = preferences;

  static const _themeModeKey = 'tsuketori.themeMode';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_themeModeKey);
    _themeMode = _decode(raw);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_themeModeKey, mode.name);
  }

  ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

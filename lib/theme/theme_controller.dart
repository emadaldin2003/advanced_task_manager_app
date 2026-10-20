// theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'theme_dark';
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_prefsKey) ?? false;
      _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    final next = value ? ThemeMode.dark : ThemeMode.light;
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  // تمت إضافة هذه الدالة لحل مشكلة زر تبديل الوضع الليلي
  Future<void> toggle() => setDark(!isDark);
}
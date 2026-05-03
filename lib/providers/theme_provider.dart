import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default colors for the app
class AppColors {
  static const Color darkBackground = Color(0xFF32415C);
  static const Color darkAccent = Color(0xFFF5A623);
  static const Color lightAccent = Color(0xFF1A2B49);
  static const Color lightBackground = Color(0xFFF7F1E8);
}

const String _storageKey = 'theme_preferences';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Accent is #1A2B49 in light mode, #F5A623 in dark mode
  Color get accentColor =>
      _isDarkMode ? AppColors.darkAccent : AppColors.lightAccent;

  Future<void>? _loadFuture;

  Future<void> ensureLoaded() => _loadFuture ??= _loadPreferences();

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _isDarkMode = map['theme'] == 'dark';
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {'theme': _isDarkMode ? 'dark' : 'light'};
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await _savePreferences();
    notifyListeners();
  }

  Color get backgroundColor =>
      _isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
}

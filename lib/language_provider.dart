import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _prefsKey = 'language_code';
  static bool _langDetectInitialized = false;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool _hasSavedLanguage = false;
  bool get hasSavedLanguage => _hasSavedLanguage;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null || code.isEmpty) {
      _hasSavedLanguage = false;
      return;
    }
    _hasSavedLanguage = true;
    _locale = Locale(_normalizeCode(code));
  }

  Future<void> saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
  }

  Future<void> changeLanguage(String code) async {
    _locale = Locale(_normalizeCode(code));
    await saveLanguage();
    _hasSavedLanguage = true;
    notifyListeners();
  }

  static String detectLanguage(String text) {
    return langdetect.detect(text);
  }

  static Future<void> ensureLangDetectInitialized() async {
    if (_langDetectInitialized) return;
    await langdetect.initLangDetect();
    _langDetectInitialized = true;
  }

  static String detectInitialLanguageCode() {
    // NLP-only-on-first-launch: detect from system locale text.
    // Example: "en_US" -> detect(...) => "en"
    final systemText = Platform.localeName;
    try {
      final detected = detectLanguage(systemText);
      return _normalizeCode(detected);
    } catch (_) {
      // Fallback to basic system locale if NLP fails
      final fallback = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return _normalizeCode(fallback);
    }
  }

  static String _normalizeCode(String code) {
    final c = code.trim().toLowerCase();
    if (c.startsWith('ar')) return 'ar';
    return 'en';
  }
}


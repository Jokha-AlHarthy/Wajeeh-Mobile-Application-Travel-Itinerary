import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  const AppLocalizations._(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(loc != null, 'AppLocalizations not found in context');
    return loc!;
  }

  String t(String key, [Map<String, String>? args]) {
    var value = _strings[key] ?? key;
    if (args == null || args.isEmpty) return value;
    args.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final code = (locale.languageCode == 'ar') ? 'ar' : 'en';
    final raw = await rootBundle.loadString('assets/lang/$code.json');
    final decoded = jsonDecode(raw);
    final map = <String, String>{};
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final k = entry.key?.toString();
        if (k == null) continue;
        map[k] = entry.value?.toString() ?? '';
      }
    }
    return AppLocalizations._(Locale(code), map);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationContextExt on BuildContext {
  String tr(String key, [Map<String, String>? args]) =>
      AppLocalizations.of(this).t(key, args);
}


import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/language_provider.dart';
import 'package:wajeeh/localization/app_localizations.dart';

/// Mirrors [MyApp] wiring: outer [Directionality] from [LanguageProvider] +
/// [MaterialApp] locale / delegates (see `lib/main.dart`).
class _MultilingualHarness extends StatelessWidget {
  const _MultilingualHarness({required this.language});

  final LanguageProvider language;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageProvider>.value(
      value: language,
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) {
          return Directionality(
            key: const ValueKey('app_text_direction'),
            textDirection: lang.locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MaterialApp(
              locale: lang.locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: Builder(
                  builder: (inner) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            inner.tr('select_language'),
                            key: const Key('localized_title'),
                          ),
                          ElevatedButton(
                            key: const Key('to_ar'),
                            onPressed: () async {
                              await lang.changeLanguage('ar');
                            },
                            child: const Text('to_ar'),
                          ),
                          ElevatedButton(
                            key: const Key('to_en'),
                            onPressed: () async {
                              await lang.changeLanguage('en');
                            },
                            child: const Text('to_en'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var previousOnError = FlutterError.onError;

  setUp(() {
    previousOnError = FlutterError.onError;
    SharedPreferences.setMockInitialValues({});

    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('google_fonts') ||
          message.contains('GoogleFonts') ||
          message.contains('Failed to load font')) {
        return;
      }
      previousOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
  });

  group('Multilingual support (English / Arabic)', () {
    testWidgets(
      'default language, EN↔AR switching, copy, RTL/LTR, prefs, unsupported',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        // --- Default: English, LTR, no saved flag until load ---
        final language = LanguageProvider();
        expect(language.locale.languageCode, 'en');
        expect(language.hasSavedLanguage, isFalse);

        await tester.pumpWidget(_MultilingualHarness(language: language));
        await tester.pumpAndSettle();

        expect(find.text('Select your Language'), findsOneWidget);
        expect(
          tester
              .widget<Directionality>(
                find.byKey(const ValueKey('app_text_direction')),
              )
              .textDirection,
          TextDirection.ltr,
        );

        // --- English → Arabic: copy + RTL + persistence ---
        await tester.tap(find.byKey(const Key('to_ar')));
        await tester.pumpAndSettle();

        expect(language.locale.languageCode, 'ar');
        expect(find.text('اختر لغتك'), findsOneWidget);
        expect(
          tester
              .widget<Directionality>(
                find.byKey(const ValueKey('app_text_direction')),
              )
              .textDirection,
          TextDirection.rtl,
        );

        final prefsAfterAr = await SharedPreferences.getInstance();
        expect(prefsAfterAr.getString('language_code'), 'ar');
        expect(language.hasSavedLanguage, isTrue);

        // --- Arabic → English: copy + LTR ---
        await tester.tap(find.byKey(const Key('to_en')));
        await tester.pumpAndSettle();

        expect(language.locale.languageCode, 'en');
        expect(find.text('Select your Language'), findsOneWidget);
        expect(
          tester
              .widget<Directionality>(
                find.byKey(const ValueKey('app_text_direction')),
              )
              .textDirection,
          TextDirection.ltr,
        );

        // --- loadSavedLanguage restores Arabic from disk ---
        SharedPreferences.setMockInitialValues({'language_code': 'ar'});
        final restored = LanguageProvider();
        await restored.loadSavedLanguage();
        expect(restored.locale.languageCode, 'ar');
        expect(restored.hasSavedLanguage, isTrue);

        await tester.pumpWidget(_MultilingualHarness(language: restored));
        await tester.pumpAndSettle();

        expect(find.text('اختر لغتك'), findsOneWidget);
        expect(
          tester
              .widget<Directionality>(
                find.byKey(const ValueKey('app_text_direction')),
              )
              .textDirection,
          TextDirection.rtl,
        );

        // --- Unsupported codes normalize to English ---
        final unsupported = LanguageProvider();
        await unsupported.changeLanguage('fr');
        expect(unsupported.locale.languageCode, 'en');

        await tester.pumpWidget(_MultilingualHarness(language: unsupported));
        await tester.pumpAndSettle();
        expect(find.text('Select your Language'), findsOneWidget);

        SharedPreferences.setMockInitialValues({'language_code': 'ja'});
        final fromDisk = LanguageProvider();
        await fromDisk.loadSavedLanguage();
        expect(fromDisk.locale.languageCode, 'en');

        await tester.pumpWidget(_MultilingualHarness(language: fromDisk));
        await tester.pumpAndSettle();
        expect(find.text('Select your Language'), findsOneWidget);
      },
    );
  });

  test('AppLocalizations delegate marks only en and ar as supported', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('ar')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
    expect(AppLocalizations.delegate.isSupported(const Locale('ar', 'SA')), isTrue);
  });
}

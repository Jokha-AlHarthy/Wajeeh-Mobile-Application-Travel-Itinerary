import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/app_theme.dart';
import 'package:wajeeh/providers/theme_provider.dart';

/// Mirrors app wiring: [MaterialApp.theme] from [AppTheme.buildTheme] +
/// [ThemeProvider]. Toggle is test-only UI (lives in this file only).
class _ThemeToggleHarness extends StatelessWidget {
  const _ThemeToggleHarness({required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            theme: AppTheme.buildTheme(theme),
            home: Scaffold(
              body: Builder(
                builder: (inner) {
                  final t = Theme.of(inner);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'brightness:${t.brightness}',
                        key: const Key('brightness_text'),
                      ),
                      Switch(
                        key: const Key('dark_mode_switch'),
                        value: theme.isDarkMode,
                        onChanged: (v) => theme.setDarkMode(v),
                      ),
                    ],
                  );
                },
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

  group('Theme toggle (light / dark)', () {
    testWidgets(
      'ThemeProvider toggle updates app Theme brightness and scaffold color',
      (tester) async {
        final themeProvider = ThemeProvider();
        await themeProvider.ensureLoaded();

        await tester.pumpWidget(
          _ThemeToggleHarness(themeProvider: themeProvider),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        while (tester.takeException() != null) {}

        ThemeData themeOfText() => Theme.of(
              tester.element(find.byKey(const Key('brightness_text'))),
            );

        expect(themeProvider.isDarkMode, isFalse);
        expect(themeProvider.accentColor, AppColors.lightAccent);
        expect(themeOfText().brightness, Brightness.light);

        await tester.tap(find.byKey(const Key('dark_mode_switch')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        while (tester.takeException() != null) {}

        expect(themeProvider.isDarkMode, isTrue);
        expect(themeProvider.accentColor, AppColors.darkAccent);
        expect(themeOfText().brightness, Brightness.dark);

        await tester.tap(find.byKey(const Key('dark_mode_switch')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        while (tester.takeException() != null) {}

        expect(themeProvider.isDarkMode, isFalse);
        expect(themeProvider.accentColor, AppColors.lightAccent);
        expect(themeOfText().brightness, Brightness.light);
      },
    );

    testWidgets('setDarkMode persists and reloads on new ThemeProvider',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      final first = ThemeProvider();
      await first.ensureLoaded();
      await first.setDarkMode(true);

      final second = ThemeProvider();
      await second.ensureLoaded();

      expect(second.isDarkMode, isTrue);

      await tester.pumpWidget(
        _ThemeToggleHarness(themeProvider: second),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      while (tester.takeException() != null) {}

      expect(second.accentColor, AppColors.darkAccent);
      final t = Theme.of(
        tester.element(find.byKey(const Key('brightness_text'))),
      );
      expect(t.brightness, Brightness.dark);
    });
  });
}

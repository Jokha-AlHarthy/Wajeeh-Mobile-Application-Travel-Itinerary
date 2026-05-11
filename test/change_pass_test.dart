import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wajeeh/localization/app_localizations.dart';
import 'package:wajeeh/pages/ChangePass.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var previousOnError = FlutterError.onError;

  setUp(() {
    previousOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();

      if (message.contains('Unable to load asset') &&
          message.contains('images/logo.png')) {
        return;
      }

      previousOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
  });

  Widget buildPage() {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ChangePass(),
    );
  }

  Future<void> loadPage(WidgetTester tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    while (tester.takeException() != null) {}
  }

  String tr(WidgetTester tester, String key) {
    final context = tester.element(find.byType(ChangePass));
    return AppLocalizations.of(context).t(key);
  }

  group('ChangePass validation tests', () {
    testWidgets('empty fields shows validation errors', (tester) async {
      await loadPage(tester);

      expect(find.byType(ChangePass), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);

      final saveText = tr(tester, 'save');
      expect(find.text(saveText), findsOneWidget);

      await tester.tap(find.text(saveText));
      await tester.pump();

      while (tester.takeException() != null) {}

      expect(find.text(tr(tester, 'enter_old_password_error')), findsOneWidget);
      expect(find.text(tr(tester, 'enter_new_password_error')), findsOneWidget);
      expect(find.text(tr(tester, 'confirm_password_error')), findsOneWidget);
    });


  });
}
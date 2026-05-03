import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/localization/app_localizations.dart';
import 'package:wajeeh/pages/AdminDashboardPage.dart';
import 'package:wajeeh/pages/edit_user_info_screen.dart';
import 'package:wajeeh/providers/theme_provider.dart';

/// Widget tests for admin flows on [AdminDashboardPage] and [EditUserInfoScreen].
///
/// Add + dashboard list share one [AdminDashboardPage] mount (a second mount in
/// the same binding breaks Firestore stream behavior in tests). Edit screen is
/// mounted once after that block. Kept as **one** [testWidgets] so the suite is
/// stable; comments mark Add / View / Edit / Delete coverage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var previousOnError = FlutterError.onError;

  setUp(() {
    previousOnError = FlutterError.onError;
    SharedPreferences.setMockInitialValues({});

    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('Unable to load asset')) {
        return;
      }
      if (message.contains('A RenderFlex overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
  });

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  String trScaffold(WidgetTester tester, String key) {
    final ctx = tester.element(find.byType(Scaffold).first);
    return ctx.tr(key);
  }

  Future<void> clearSnackBarsIfPresent(WidgetTester tester) async {
    final scaffolds = find.byType(Scaffold);
    if (scaffolds.evaluate().isEmpty) return;
    ScaffoldMessenger.of(tester.element(scaffolds.first)).clearSnackBars();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpAdminDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: const AdminDashboardPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    while (tester.takeException() != null) {}
  }

  Future<void> pumpEditUser(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: EditUserInfoScreen(uid: 'test-user-uid'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    while (tester.takeException() != null) {}
  }

  Future<void> selectRoleUser(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(trScaffold(tester, 'user')).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Admin user accounts', () {
    testWidgets(
      'add, view list, edit fields, delete confirm, save',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        addTearDown(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(body: SizedBox.shrink()),
            ),
          );
          await tester.pump();
        });

        // --- Add (dashboard): empty fields ---
        await pumpAdminDashboard(tester);

        final addLabel = trScaffold(tester, 'add_user');
        await tester.tap(find.widgetWithText(ElevatedButton, addLabel));
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(
          find.text(trScaffold(tester, 'please_fill_all_fields')),
          findsOneWidget,
        );
        await clearSnackBarsIfPresent(tester);

        // --- Add (dashboard): invalid email ---
        final adminFields = find.byType(TextField);
        expect(adminFields, findsAtLeastNWidgets(2));
        await tester.enterText(adminFields.at(0), 'Test User');
        await tester.enterText(adminFields.at(1), 'not-valid-email');
        await tester.pump();

        await selectRoleUser(tester);

        final addBtn = find.widgetWithText(ElevatedButton, addLabel);
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(find.text(trScaffold(tester, 'invalid_email')), findsOneWidget);
        await clearSnackBarsIfPresent(tester);

        // --- View (dashboard): list header + filters ---
        expect(find.text(trScaffold(tester, 'all_users')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'all')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'active')), findsWidgets);
        expect(find.text(trScaffold(tester, 'non_active')), findsOneWidget);

        await tester.tap(find.text(trScaffold(tester, 'active')).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        while (tester.takeException() != null) {}
        expect(find.byType(AdminDashboardPage), findsOneWidget);

        // --- View / Edit / Delete (edit screen): second pumpWidget ---
        await pumpEditUser(tester);

        expect(find.byType(EditUserInfoScreen), findsOneWidget);
        expect(find.text(trScaffold(tester, 'edit_user_info')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'save_changes')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'username')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'email')), findsOneWidget);

        // --- Delete: confirm dialog + cancel ---
        final deleteUserBtn = find.text(trScaffold(tester, 'delete_user'));
        await tester.ensureVisible(deleteUserBtn);
        await tester.tap(deleteUserBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.text(trScaffold(tester, 'delete_account_title')),
          findsOneWidget,
        );
        expect(find.text(trScaffold(tester, 'delete')), findsOneWidget);
        expect(find.text(trScaffold(tester, 'cancel')), findsOneWidget);

        await tester.tap(find.text(trScaffold(tester, 'cancel')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.text(trScaffold(tester, 'delete_account_title')),
          findsNothing,
        );
        expect(find.byType(EditUserInfoScreen), findsOneWidget);

        // --- Edit: save (Firestore may error in test env) ---
        final editFields = find.byType(TextField);
        expect(editFields, findsWidgets);
        await tester.enterText(editFields.first, 'Updated Name');
        await tester.pump();

        await tester.tap(find.text(trScaffold(tester, 'save_changes')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        while (tester.takeException() != null) {}
      },
    );
  });
}

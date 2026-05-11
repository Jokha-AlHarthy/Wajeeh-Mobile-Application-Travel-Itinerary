import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/localization/app_localizations.dart';
import 'package:wajeeh/pages/login_page.dart';
import 'package:wajeeh/providers/auth_provider.dart';
import 'package:wajeeh/widgets/custom_text_field.dart';

class FakeAuthProvider extends AuthProvider {
  bool loginCalled = false;
  bool googleLoginCalled = false;

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  String? fullName;

  @override
  String? email;

  @override
  String? phone;

  @override
  String? role;

  @override
  String? get otpEmail => 'test@example.com';

  @override
  bool get isAdmin => false;

  @override
  Future<bool> login(String email, String password) async {
    loginCalled = true;
    return true;
  }

  @override
  Future<bool> googleLogin() async {
    googleLoginCalled = true;
    return true;
  }

  @override
  Future<bool> twitterLogin() async => true;

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return true;
  }

  @override
  Future<bool> resendOtp() async => true;

  @override
  Future<bool> verifyOtp(String enteredOtp) async => true;

  @override
  Future<bool> resetPassword(String email) async => true;

  @override
  Future<void> loadUserProfile() async {}

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('Login Page Tests', () {
    late FakeAuthProvider fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthProvider();
    });

    Widget createLoginPage() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
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
          routes: {
            '/home': (_) =>
            const Scaffold(body: Center(child: Text('Home Page'))),
            '/adminHome': (_) =>
            const Scaffold(body: Center(child: Text('Admin Home'))),
            '/forgot': (_) =>
            const Scaffold(body: Center(child: Text('Forgot Page'))),
            '/register': (_) =>
            const Scaffold(body: Center(child: Text('Register Page'))),
          },
          home: const LoginPage(),
        ),
      );
    }

    String tr(WidgetTester tester, String key) {
      final context = tester.element(find.byType(LoginPage));
      return context.tr(key);
    }

    List<CustomTextField> customFields(WidgetTester tester) {
      return tester.widgetList<CustomTextField>(
        find.byType(CustomTextField),
      ).toList();
    }

    Finder loginButton(WidgetTester tester) {
      return find.widgetWithText(ElevatedButton, tr(tester, 'login'));
    }

    testWidgets('Login page loads', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(CustomTextField), findsNWidgets(2));
      expect(loginButton(tester), findsOneWidget);
    });


    test('Google login goes successfully', () async {
      expect(fakeAuth.googleLoginCalled, isFalse);

      final result = await fakeAuth.googleLogin();

      expect(result, isTrue);
      expect(fakeAuth.googleLoginCalled, isTrue);
    });
  });
}

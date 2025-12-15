import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/pages/login_page.dart';
import 'package:wajeeh/providers/auth_provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
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
    return true;
  }

  @override
  Future<bool> googleLogin() async {
    return true;
  }

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
  group('Login Page Tests', () {
    late FakeAuthProvider fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthProvider();
    });

    Widget createLoginPage() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: MaterialApp(
          routes: {
            '/home': (_) => const Scaffold(body: Center(child: Text('Home Page'))),
          },
          home: const LoginPage(),
        ),
      );
    }

    testWidgets('Login page loads', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text('Log in to access your trips'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Log in'), findsWidgets);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create a new account'), findsOneWidget);
    });

    testWidgets('Empty login shows error', (tester) async {
      await tester.pumpWidget(createLoginPage());

      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Invalid Credentials'), findsOneWidget);
    });

    testWidgets('Valid login navigates to home', (tester) async {
      await tester.pumpWidget(createLoginPage());

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Google login triggers navigation', (tester) async {
      await tester.pumpWidget(createLoginPage());

      final googleButton = find.byWidgetPredicate(
            (widget) =>
        widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'images/google.png',
      );

      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}

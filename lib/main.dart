import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wajeeh/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/HomePage.dart';
import 'pages/forgot_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'pages/WelcomeScreen.dart';
import 'pages/OnboardingScreen.dart';
import 'pages/OnboardingScreenTwo.dart';
import 'pages/OnboardingScreenThree.dart';
import 'pages/TermsPage.dart';
import 'pages/PrivacyPolicyPage.dart';
import 'pages/OtpVerificationPage.dart';
import 'pages/Location_page.dart';
import 'pages/Language_page.dart';
import 'pages/SettingPage.dart';
import 'pages/SearchPage.dart';
import 'pages/ChangePass.dart';
import 'pages/AdminHomePage.dart';
import 'pages/AdminProfilePage.dart';
import 'pages/ai_trip_screen.dart';
import 'pages/ai_trip_step1_screen.dart';
import 'pages/ai_trip_step2_screen.dart';
import 'pages/ai_trip_step3_screen.dart';
import 'pages/ai_trip_step4_screen.dart';
import 'pages/ai_trip_step5_screen.dart';
import 'pages/ai_trip_review_screen.dart';
import 'pages/ai_trip_loading.dart';
import 'pages/ai_trip_overview_list.dart';
//import 'pages/ai_trip_details_plan.dart';
import 'pages/user_feedback_screen.dart';
import 'pages/notifications_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const OnboardingScreen(),
        routes: {
          "/register": (_) => const RegisterPage(),
          "/login": (_) => const LoginPage(),
          "/home": (_) => const HomePage(),
          "/forgot": (_) => const ForgotPasswordPage(),
          "/welcome": (_) => const WelcomePage(),
          "/onboarding2": (_) => const OnboardingScreenTwo(),
          "/onboarding3": (_) => const OnboardingScreenThree(),
          "/privacy": (_) => const PrivacyPolicyPage(),
          "/terms": (_) => const TermsPage(),
          "/language":(_)=> const LanguageSelectionPage(),
          "/location": (_) => const LocationSelectionPage(),
          "/otp": (_) => const OtpVerificationPage(),
          "/search": (_) => const SearchPage(),
          "/setting": (_) => const SettingPage(),
          "/ChangePass": (_) => const ChangePass(),
          "/adminHome": (_) => const AdminHomePage(),
          "/adminProfile": (_) => const AdminProfilePage(),
          "/ai_trip": (_) => const AiTripScreen(),
          "/ai_trip_step1":(_)=>const AiTripStep1Screen(),
          "/ai_trip_step2":(_)=>const AiTripStep2Screen(),
          "/ai_trip_step3":(_)=>const AiTripStep3Screen(),
          "/ai_trip_step4":(_)=>const AiTripStep4Screen(),
          "/ai_trip_step5":(_)=>const AiTripStep5Screen(),
          "/ai_trip_review":(_)=>const ReviewSummaryScreen(),
          "/ai_trip_loading":(_)=>const TripLoadingDialog(),
          "/ai_trip_overview_list":(_)=>const TripOverviewScreen(),
          //"ai_trip_details_plan":(_)=>const TripDetailsScreen(),
          "user_feedback":(_)=>const UserFeedbackScreen(),
          "notifications":(_)=>const NotificationsScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

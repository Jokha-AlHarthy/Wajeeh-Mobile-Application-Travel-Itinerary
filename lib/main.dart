import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'package:wajeeh/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_chat_service.dart';
import 'providers/travel_provider.dart';
import 'providers/theme_provider.dart';
import 'app_navigator_key.dart';
import 'widgets/user_ai_chat_overlay.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/HomePage.dart';
import 'pages/forgot_password_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'pages/user_feedback_screen.dart';
import 'pages/notifications_screen.dart';
import 'pages/language_screen.dart';
import 'pages/profile_screen.dart';
import 'pages/trip_history.dart';
//import 'pages/trip_detail_screen.dart';
//import 'pages/rate_screen.dart';
import 'pages/FavoritePage.dart';
import 'pages/AdminContentPage.dart';
import 'pages/AdminDashboardPage.dart';
import 'pages/AdminFeedbackManage.dart';
import 'pages/edit_location_screen.dart';
import 'pages/TripPlanScreen.dart';
import 'pages/saved_itinerary_screen.dart';
import 'language_provider.dart';
import 'localization/app_localizations.dart';
import 'services/internet_connectivity.dart';

/// Injected at build/run time — do **not** hardcode keys in source.
/// Example: `flutter run --dart-define=GEMINI_API_KEY=...`
const String _kGeminiApiKeyFromEnv = String.fromEnvironment('GEMINI_API_KEY');
const String _kOpenRouteServiceKeyFromEnv =
    String.fromEnvironment('OPENROUTESERVICE_API_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.ensureLoaded();

  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLanguage();
  if (!languageProvider.hasSavedLanguage) {
    await LanguageProvider.ensureLangDetectInitialized();
    final detectedCode = LanguageProvider.detectInitialLanguageCode();
    await languageProvider.changeLanguage(detectedCode);
  }

  runApp(
    MyApp(
      themeProvider: themeProvider,
      languageProvider: languageProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;
  static final ValueNotifier<String?> _routeName =
      ValueNotifier<String?>(null);
  static final RouteNameObserver _routeObserver =
      RouteNameObserver(_routeName);

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TravelProvider()),
        ChangeNotifierProvider(create: (_) {
          final ai = AiChatService();
          ai.maybeConfigureFromEnvironment();
          return ai;
        }),
      ],
      child: _TravelUserScope(
        child: Consumer2<ThemeProvider, LanguageProvider>(
          builder: (context, theme, language, _) {
            return Directionality(
              textDirection: language.locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MaterialApp(
              navigatorKey: wajeehRootNavigatorKey,
              theme: AppTheme.buildTheme(theme),
              debugShowCheckedModeBanner: false,
              locale: language.locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              navigatorObservers: [_routeObserver],
              builder: (context, child) => UserAiChatOverlay(
                routeNameListenable: _routeName,
                geminiApiKey: _kGeminiApiKeyFromEnv.isEmpty
                    ? null
                    : _kGeminiApiKeyFromEnv,
                openRouteServiceApiKey: _kOpenRouteServiceKeyFromEnv.isEmpty
                    ? null
                    : _kOpenRouteServiceKeyFromEnv,
                child: child ?? const SizedBox.shrink(),
              ),
              home: Theme(
                data: AppTheme.originalLight,
                child: const _StartupRouter(),
              ),
              routes: {
          "/register": (_) => Theme(
            data: AppTheme.originalLight,
            child: const RegisterPage(),
          ),
          "/login": (_) => Theme(
            data: AppTheme.originalLight,
            child: const LoginPage(),
          ),
          "/home": (_) => const HomePage(),
          "/forgot": (_) => Theme(
            data: AppTheme.originalLight,
            child: const ForgotPasswordPage(),
          ),
          "/welcome": (_) => Theme(
            data: AppTheme.originalLight,
            child: const WelcomePage(),
          ),
          "/onboarding2": (_) => Theme(
            data: AppTheme.originalLight,
            child: const OnboardingScreenTwo(),
          ),
          "/onboarding3": (_) => Theme(
            data: AppTheme.originalLight,
            child: const OnboardingScreenThree(),
          ),
          "/privacy": (_) => Theme(
            data: AppTheme.originalLight,
            child: const PrivacyPolicyPage(),
          ),
          "/terms": (_) => Theme(
            data: AppTheme.originalLight,
            child: const TermsPage(),
          ),
          "/language":(_)=> Theme(
            data: AppTheme.originalLight,
            child: const LanguageSelectionPage(),
          ),
          "/location": (_) => Theme(
            data: AppTheme.originalLight,
            child: const LocationSelectionPage(),
          ),
          "/otp": (_) => Theme(
            data: AppTheme.originalLight,
            child: const OtpVerificationPage(),
          ),
          "/search": (_) => const SearchPage(),
          "/setting": (_) => const SettingPage(),
          "/ChangePass": (_) => const ChangePass(),
          "/adminHome": (_) => const AdminHomePage(),
          "/adminProfile": (_) => const AdminProfilePage(),
          "/user_feedback":(_)=>const UserFeedbackScreen(),
          "/editLocation": (_) => const EditLocationScreen(),
          "/notifications":(_)=>const NotificationsScreen(),
          "/languagePreference":(_)=> const LanguageScreen(),
          "/profile":(_)=> const ProfileScreen(),
          "/trip_history":(_)=>const TripHistory(),
          //"/trip_detail":(_)=>const TripDetailScreen(),
          //"/rate":(_)=>const RateScreen(),
          "/favorite":(_)=> const FavoritePage(),
          "/adminContent":(_)=> const AdminContentPage(),
          "/adminDashboard":(_)=> const AdminDashboardPage(),
          "/adminFeedback":(_)=> const AdminFeedbackManage(),
          "/trip_planing":(_)=>const TripPlanScreen(),
        },
            ),
          );
        },
        ),
      ),
    );
  }
}

/// Keeps favorites, trip history, and trip-plan draft in sync with the signed-in Firebase user.
class _TravelUserScope extends StatefulWidget {
  const _TravelUserScope({required this.child});

  final Widget child;

  @override
  State<_TravelUserScope> createState() => _TravelUserScopeState();
}

class _TravelUserScopeState extends State<_TravelUserScope> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    final travel = context.read<TravelProvider>();
    Future<void> applyUser(User? user) =>
        travel.setStorageUserId(user?.uid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      applyUser(FirebaseAuth.instance.currentUser);
    });
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(applyUser);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  static const _onboardingDoneKey = 'onboarding_done_v1';
  late final Future<Widget> _nextScreen = _resolveStartScreen();

  Future<Widget> _resolveStartScreen() async {
    // If app starts offline, go straight to Saved Itinerary (or show friendly empty).
    final online = await InternetConnectivity.hasInternet();
    if (!mounted) return const SizedBox.shrink();
    if (!online) {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      final scope = (user != null && user.uid.isNotEmpty) ? user.uid : 'guest';
      final scopedKey = 'offline_saved_trips_v1_$scope';
      final legacyKey = 'offline_saved_trips_v1';

      bool hasSaved = false;
      try {
        final raw = prefs.getString(scopedKey) ?? prefs.getString(legacyKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          hasSaved = decoded is List && decoded.isNotEmpty;
        }
      } catch (_) {
        hasSaved = false;
      }

      if (!mounted) return const SizedBox.shrink();
      if (hasSaved) {
        return const SavedItineraryScreen(startedOffline: true);
      }

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 44, color: Colors.grey.shade600),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('offline_no_saved_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('offline_no_saved_body'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await prefs.setBool(_onboardingDoneKey, true);
      if (!mounted) return const SizedBox.shrink();
      final auth = context.read<AuthProvider>();
      await auth.loadUserProfile();
      if (!mounted) return const SizedBox.shrink();
      return auth.isAdmin ? const AdminHomePage() : const HomePage();
    }

    final onboardingDone = prefs.getBool(_onboardingDoneKey) ?? false;
    if (onboardingDone) return const WelcomePage();

    await prefs.setBool(_onboardingDoneKey, true);
    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _nextScreen,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'floating_ai_chat_widget.dart';

/// Tracks the current route name so we can hide the chat on admin pages.
class RouteNameObserver extends NavigatorObserver {
  RouteNameObserver(this.currentRouteName);

  final ValueNotifier<String?> currentRouteName;

  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == currentRouteName.value) return;
    currentRouteName.value = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _set(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _set(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _set(previousRoute);
  }
}

class UserAiChatOverlay extends StatelessWidget {
  const UserAiChatOverlay({
    super.key,
    required this.child,
    required this.routeNameListenable,
    this.geminiApiKey,
    this.openRouteServiceApiKey,
  });

  final Widget child;
  final ValueListenable<String?> routeNameListenable;
  final String? geminiApiKey;
  final String? openRouteServiceApiKey;

  bool _isAdminRouteName(String? name) {
    if (name == null) return false;
    final n = name.toLowerCase();
    return n.startsWith('/admin') || n.contains('admin');
  }

  /// Routes for splash, onboarding, welcome, login, register, OTP, etc.
  bool _isPreAuthenticationRoute(String? name) {
    if (name == null || name.isEmpty) return true;
    switch (name) {
      case '/welcome':
      case '/login':
      case '/register':
      case '/forgot':
      case '/otp':
      case '/onboarding2':
      case '/onboarding3':
      case '/language':
      case '/location':
      case '/privacy':
      case '/terms':
        return true;
      default:
        return false;
    }
  }

  void _syncMainAppUnlockForRoute(BuildContext context, String? routeName) {
    if (routeName == '/home' || routeName == '/adminHome') {
      context.read<AuthProvider>().unlockMainApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ValueListenableBuilder<String?>(
      valueListenable: routeNameListenable,
      builder: (context, routeName, _) {
        _syncMainAppUnlockForRoute(context, routeName);

        final hide = auth.isAdmin || _isAdminRouteName(routeName);
        final onPreAuthScreen = _isPreAuthenticationRoute(routeName);

        final mq = MediaQuery.of(context);
        // Sit above system inset + typical bottom nav (AppFooter uses a tall center control).
        final fabBottom = mq.padding.bottom + 96;

        final showFab = auth.isAuthenticated &&
            auth.mainAppUnlocked &&
            !hide &&
            !onPreAuthScreen;

        return Stack(
          children: [
            child,
            if (showFab)
              Positioned.fill(
                child: FloatingAiChatWidget(
                  geminiApiKey: geminiApiKey,
                  openRouteServiceApiKey: openRouteServiceApiKey,
                  fabBottomReserve: fabBottom - mq.padding.bottom,
                ),
              ),
          ],
        );
      },
    );
  }
}


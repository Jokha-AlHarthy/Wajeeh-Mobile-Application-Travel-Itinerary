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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ValueListenableBuilder<String?>(
      valueListenable: routeNameListenable,
      builder: (context, routeName, _) {
        final hide = auth.isAdmin || _isAdminRouteName(routeName);

        final mq = MediaQuery.of(context);
        // Sit above system inset + typical bottom nav (AppFooter uses a tall center control).
        final fabBottom = mq.padding.bottom + 96;

        final showFab = !hide && auth.isAuthenticated;

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


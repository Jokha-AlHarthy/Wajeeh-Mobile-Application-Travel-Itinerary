import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../pages/AdminHomePage.dart';
import '../pages/AdminDashboardPage.dart';
import '../pages/AdminContentPage.dart';
import '../pages/AdminFeedbackManage.dart';
import '../pages/AdminProfilePage.dart';

class AdminFooter extends StatelessWidget {
  final int currentIndex;

  const AdminFooter({super.key, required this.currentIndex});

  void _navigate(BuildContext context, Widget page, int index) {
    if (currentIndex != index) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final barColor = themeProvider.isDarkMode
        ? const Color(0xFFF5A623)
        : const Color(0xFFF7F1E8);

    final activeColor = Colors.black;
    final inactiveColor =
    themeProvider.isDarkMode ? const Color(0xFF0C1C3D) : Colors.grey;

    return Container(
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // HOME
            IconButton(
              onPressed: () => _navigate(
                context,
                const AdminHomePage(),
                0,
              ),
              icon: Icon(
                Icons.home,
                size: 28,
                color:
                currentIndex == 0 ? activeColor : inactiveColor,
              ),
            ),

            // DASHBOARD
            IconButton(
              onPressed: () => _navigate(
                context,
                const AdminDashboardPage(),
                1,
              ),
              icon: Image.asset(
                "images/manage-user-icon.png",
                height: 26,
                color:
                currentIndex == 1 ? activeColor : inactiveColor,
              ),
            ),

            // CENTER BUTTON
            GestureDetector(
              onTap: () => _navigate(
                context,
                const AdminContentPage(),
                2,
              ),
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF0C1C3D)
                      : const Color(0xFFF5A000),
                ),
                child: Transform.rotate(
                  angle: -0.8,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            // FEEDBACK
            IconButton(
              onPressed: () => _navigate(
                context,
                const AdminFeedbackManage(),
                3,
              ),
              icon: Image.asset(
                "images/user-feedback-icon.png",
                height: 26,
                color:
                currentIndex == 3 ? activeColor : inactiveColor,
              ),
            ),

            // PROFILE
            IconButton(
              onPressed: () => _navigate(
                context,
                const AdminProfilePage(),
                4,
              ),
              icon: Icon(
                Icons.group_outlined,
                size: 28,
                color:
                currentIndex == 4 ? activeColor : inactiveColor,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;

  const AppFooter({super.key, required this.currentIndex});

  static const Color bg = Color(0xffF5EFE4);
  static const Color darkBlue = Color(0xff1A2B49);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // HOME
            IconButton(
              onPressed: () {
                if (currentIndex != 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: Icon(
                currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
                color: currentIndex == 0 ? darkBlue : Colors.grey.shade700,
              ),
            ),

            // EXPLORE / AI TRIP
            IconButton(
              onPressed: () {
                if (currentIndex != 1) {
                  Navigator.pushReplacementNamed(context, '/ai_trip');
                }
              },
              icon: Icon(
                Icons.explore,
                color: currentIndex == 1 ? darkBlue : Colors.grey.shade700,
              ),
            ),

            // CENTER BUTTON
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: darkBlue,
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: -0.9,
                child: IconButton(
                  onPressed: () {
                    // TODO add your center button navigation
                  },
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // HEART
            IconButton(
              onPressed: () {
                if (currentIndex != 3) {
                  Navigator.pushReplacementNamed(context, '/favorite');
                }
              },
              icon: Icon(
                currentIndex == 3 ? Icons.favorite : Icons.favorite_border,
                color: currentIndex == 3 ? darkBlue : Colors.grey.shade700,
              ),
            ),

            // SETTINGS
            IconButton(
              onPressed: () {
                if (currentIndex != 4) {
                  Navigator.pushReplacementNamed(context, '/setting');
                }
              },
              icon: Icon(
                Icons.group_outlined,
                color: currentIndex == 4 ? darkBlue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


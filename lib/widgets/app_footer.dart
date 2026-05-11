import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/travel_provider.dart';
import '../services/itinerary_walkthrough.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;

  const AppFooter({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final barColor =
        isDark ? const Color(0xFFF5A623) : const Color(0xFFF5EFE4);

    final activeColor =
    isDark ? const Color(0xFF1A2B49) : theme.colorScheme.primary;
    final inactiveColor =
        isDark ? const Color.fromARGB(255, 255, 255, 255) : Colors.grey.shade700;

    final centerButtonColor =
        isDark ? const Color(0xFF1A2B49) : const Color(0xFFF5A000);

    return Container(
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
              onPressed: () {
                if (currentIndex != 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: Icon(
                currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
                color: currentIndex == 0 ? activeColor : inactiveColor,
              ),
            ),

            // EXPLORE
            IconButton(
              onPressed: () {
                if (currentIndex != 1) {
                  Navigator.pushReplacementNamed(context, '/trip_history');
                }
              },
              icon: Icon(
                Icons.explore,
                color: currentIndex == 1 ? activeColor : inactiveColor,
              ),
            ),

            // CENTER BUTTON
            GestureDetector(
              onTap: () async {
                if (currentIndex != 2) {
                  final travel = context.read<TravelProvider>();
                  final walkthrough = ItineraryWalkthroughController.instance;

                  final shouldStart = await walkthrough.shouldAutoStart(
                    hasTripHistory: travel.savedTrips.isNotEmpty,
                  );
                  if (!context.mounted) return;

                  Navigator.pushReplacementNamed(
                    context,
                    '/trip_planing',
                    arguments: <String, dynamic>{
                      if (shouldStart) 'startWalkthrough': true,
                      'source': 'footer_center',
                    },
                  );
                }
              },
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: centerButtonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -0.8,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // FAVORITES
            IconButton(
              onPressed: () {
                if (currentIndex != 3) {
                  Navigator.pushReplacementNamed(context, '/favorite');
                }
              },
              icon: Icon(
                currentIndex == 3 ? Icons.favorite : Icons.favorite_border,
                color: currentIndex == 3 ? activeColor : inactiveColor,
              ),
            ),

            // PROFILE
            IconButton(
              onPressed: () {
                if (currentIndex != 4) {
                  Navigator.pushReplacementNamed(context, '/setting');
                }
              },
              icon: Icon(
                Icons.group_outlined,
                color: currentIndex == 4 ? activeColor : inactiveColor,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'ai_trip_step5_screen.dart';
import 'notifications_screen.dart';


class AiTripStep4Screen extends StatefulWidget {
  const AiTripStep4Screen({super.key});

  @override
  State<AiTripStep4Screen> createState() => _AiTripStep4ScreenState();
}

class _AiTripStep4ScreenState extends State<AiTripStep4Screen> {
  final List<String> options = [
    "Adventure",
    "Historical",
    "Beach",
    "Relaxing",
    "Nature Escapes",
    "Road Trip",
    "Food Tourism",
    "Cultural Exploration",
    "Camp",
  ];

  final Set<String> selectedOptions = {
    "Historical",
    "Relaxing",
    "Road Trip",
    "Food Tourism",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Step 4",
          style: TextStyle(
            color: Color(0xff1A2B49),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },

              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications,
                    size: 28,
                    color: Colors.black,
                  ),
                  Positioned(
                    right: -1,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "3",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Choose an interest for your trip",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose several references for your trip so\nthat they are more suitable and accurate",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 25),

            Wrap(
              spacing: 16,
              runSpacing: 13,
              children: options.map((option) {
                final bool isSelected = selectedOptions.contains(option);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedOptions.remove(option);
                      } else {
                        selectedOptions.add(option);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xffF2A400) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xff1A2B49),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xff1A2B49),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiTripStep5Screen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A2B49),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Next Step",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

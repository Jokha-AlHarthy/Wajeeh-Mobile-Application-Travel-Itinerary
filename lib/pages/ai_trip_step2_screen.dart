import 'package:flutter/material.dart';
import 'ai_trip_step3_screen.dart';
import 'notifications_screen.dart';

class AiTripStep2Screen extends StatefulWidget {
  const AiTripStep2Screen({super.key});

  @override
  State<AiTripStep2Screen> createState() => _AiTripStep2ScreenState();
}

class _AiTripStep2ScreenState extends State<AiTripStep2Screen> {
  int selectedIndex = 2; // Default: "With Family" is selected

  final options = [
    {"title": "Only Me", "subtitle": "Traveling alone, just me"},
    {"title": "With a Couple", "subtitle": "A romantic trip just for us"},
    {
      "title": "With Family",
      "subtitle": "Exciting trip with all family members",
    },
    {"title": "My Friend", "subtitle": "Traveling with friends hanging out"},
    {
      "title": "Business Trip",
      "subtitle": "Traveling with goals, not just plans",
    },
  ];

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
          "Step 2",
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
              "Who is this trip with?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Let's start by choosing who you’re going to go with",
              style: TextStyle(fontSize: 16, color: Color(0xff1A2B49)),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.orange : Color(0xff1A2B49),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xfffff6e9)
                            : Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option["title"]!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.orange
                                  : Color(0xff1A2B49),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option["subtitle"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xff1A2B49),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiTripStep3Screen(),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

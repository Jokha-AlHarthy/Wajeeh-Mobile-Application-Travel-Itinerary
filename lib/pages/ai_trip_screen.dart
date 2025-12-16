import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import "trip_planning_screen.dart";

class AiTripScreen extends StatefulWidget {
  const AiTripScreen({super.key});
  @override
  State<AiTripScreen> createState() => _AiTripScreenState();
}
class _AiTripScreenState extends State<AiTripScreen> {
  bool isAiSelected = true;
  void navigate(bool aiSelected) {
    if (aiSelected == isAiSelected) return;
    setState(() {
      isAiSelected = aiSelected;
    });
    if (!aiSelected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF5EFE4),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            Image.asset("images/logo.png", height: 55),
            GestureDetector(
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
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 300,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: isAiSelected
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: 156,
                          decoration: BoxDecoration(
                            color: const Color(0xff1A2B49),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TripPlanningScreen(),
                                  ),
                                );
                              },
                              child: Center(
                                child: Text(
                                  "Trip Planning",
                                  style: TextStyle(
                                    color: isAiSelected
                                        ? Color(0xff1A2B49)
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => navigate(true),
                              child: Center(
                                child: Text(
                                  "AI Trip Planning",
                                  style: TextStyle(
                                    color: isAiSelected
                                        ? Colors.white
                                        : Color(0xff1A2B49),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset("images/plan.jpg", fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      "images/ai_robot.png",
                      height: 110,
                      width: 70,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff1A2B49),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          "Hi I’m JRN,\nyour AI Trip Planner",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -8,
                        left: 1,
                        child: ClipPath(
                          clipper: _BubbleTailClipper(),
                          child: Container(
                            width: 16,
                            height: 16,
                            color: const Color(0xff1A2B49),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                "Let’s start planning your vacation\ntrip automatically with AI",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1A2B49),
                ),
              ),
              const SizedBox(height: 10),
              buildCheckItem("Create the most appropriate travel path"),
              const SizedBox(height: 6),
              buildCheckItem("Adjust the length of your trip"),
              const SizedBox(height: 6),
              buildCheckItem("Set a budget according to what you want"),
              const SizedBox(height: 6),
              buildCheckItem("Alone or with family, everything can be arranged",),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1A2B49),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, "/ai_trip_step1");
                  },
                  child: const Text(
                    "Start making a plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 1),
    );
  }
  Widget buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
class _BubbleTailClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(5, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 7);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

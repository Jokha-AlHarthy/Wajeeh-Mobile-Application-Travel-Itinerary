import 'package:flutter/material.dart';
import 'ai_trip_screen.dart';
import 'notifications_screen.dart';
import 'trip_detail_screen.dart';
import 'rate_screen.dart';
import 'package:wajeeh/widgets/app_footer.dart';

class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({super.key});
  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}
class _TripPlanningScreenState extends State<TripPlanningScreen> {
  bool isAiSelected = false;
  final List<Map<String, dynamic>> trips = [
    {
      "status": "On Going",
      "statusColor": const Color(0xFF1A2B49),
      "title": "Trip to Dubai",
      "country": "United Arab Emirates",
      "rating": "4.8",
      "persons": "4 Person",
      "date": "Wed, 21 May 2025",
      "price": "OMR 1,170",
      "image": "images/burj_khalifa.jpg",
    },
    {
      "status": "Completed",
      "statusColor": const Color(0xFF198754),
      "title": "Trip to Muscat",
      "country": "Sultanate of Oman",
      "rating": "4.5",
      "persons": "2 Person",
      "date": "Wed, 24 Aug 2024",
      "price": "OMR 600",
      "image": "images/oman_museum.jpg",
    },
    {
      "status": "Completed",
      "statusColor": const Color(0xFF198754),
      "title": "Trip to Manama",
      "country": "Bahrain",
      "rating": "4.2",
      "persons": "1 Person",
      "date": "Wed, 24 Apr 2024",
      "price": "OMR 250",
      "image": "images/manama.jpg",
    },
  ];
  void navigate(bool aiSelected) {
    if (aiSelected == isAiSelected) return;
    setState(() {
      isAiSelected = aiSelected;
    });
    if (aiSelected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AiTripScreen()),
      );
    }
  }
  void openRateOverlay(Map<String, dynamic> trip) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        pageBuilder: (context, animation, secondaryAnimation) {
          return RateScreen(
            placeTitle: trip["title"],
            country: trip["country"],
            rating: double.tryParse(trip["rating"]) ?? 4.8,
            image: trip["image"],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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
                                Navigator.pushReplacement(
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
                                        ? const Color(0xff1A2B49)
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
                                        : const Color(0xff1A2B49),
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
            
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final t = trips[index];
                  bool isOngoing = t["status"] == "On Going";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 22),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xffF5EFE4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                t["image"] as String,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (t["statusColor"] as Color)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          t["status"] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: t["statusColor"] as Color,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        t["date"] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t["title"] as String,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D2B49),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        t["country"] as String,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        t["rating"] as String,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        t["persons"] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        t["price"] as String,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B49),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!isOngoing) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => openRateOverlay(t),
                                  child: Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF0D2B49),
                                        width: 2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "Rate",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D2B49),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TripDetailScreen(
                                        title: t["title"],
                                        dates: t["date"],
                                        travellers: t["persons"],
                                        budget: t["price"],
                                        image: t["image"],
                                        country: t["country"],
                                        rating:
                                            double.tryParse(t["rating"]) ?? 4.8,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF0D2B49),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Detail",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 1),
    );
  }
}

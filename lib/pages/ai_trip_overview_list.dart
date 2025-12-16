import 'package:flutter/material.dart';
import 'ai_trip_details_plan.dart';
import 'notifications_screen.dart';

class TripOverviewScreen extends StatelessWidget {
  const TripOverviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final trips = [
      {
        "title": "Oman Journey #1",
        "city": "Muscat",
        "hotel": "4 Star Hotel",
        "travellers": "With Family",
        "dates": "21–24 May 2025",
        "price": "164 OMR",
        "tags": ["Relaxing", "Road Trip", "2+"],
        "image": "images/Shatti-Al-Qurum.jpg",
      },
      {
        "title": "Oman Journey #2",
        "city": "Nizwa",
        "hotel": "4 Star Hotel",
        "travellers": "With Family",
        "dates": "21–24 May 2025",
        "price": "160 OMR",
        "tags": ["Relaxing", "Road Trip", "2+"],
        "image": "images/Nizwa.jpg",
      },
      {
        "title": "Oman Journey #3",
        "city": "Sur",
        "hotel": "4 Star Hotel",
        "travellers": "With Family",
        "dates": "21–24 May 2025",
        "price": "160 OMR",
        "tags": ["Relaxing", "Road Trip", "2+"],
        "image": "images/sur.jpg",
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "2025 May",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff1A2B49),
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final t = trips[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripDetailsScreen(
                    title: t["title"] as String,
                    dates: t["dates"] as String,
                    travellers: t["travellers"] as String,
                    budget: t["price"] as String,
                    image: t["image"] as String,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xffF5EFE4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xff1A2B49), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.asset(
                      t["image"] as String,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          t["title"] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1A2B49),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t["city"] as String,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(width: 50),
                            const Icon(Icons.location_city, size: 18),
                            Text(
                              t["hotel"] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Person",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff1A2B49),
                              ),
                            ),
                            Text(
                              t["travellers"] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Date",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff1A2B49),
                              ),
                            ),
                            Text(
                              t["dates"] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 10,
                                children: [
                                  for (var tag in t["tags"] as List<String>)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xff1A2B49),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              t["price"] as String,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1A2B49),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

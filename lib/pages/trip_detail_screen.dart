import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'rate_screen.dart';
import 'package:wajeeh/widgets/app_footer.dart';


class TripDetailScreen extends StatelessWidget {
  final String title;
  final String country;
  final String dates;
  final String travellers;
  final String budget;
  final String image;
  final double rating;

  const TripDetailScreen({
    super.key,
    required this.title,
    required this.country,
    required this.dates,
    required this.travellers,
    required this.budget,
    required this.image,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: const Color(0xffF5EFE4),
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 55),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, size: 28, color: Colors.black),
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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Detail My Trip",
              style: TextStyle(
                color: Color(0xff1A2B49),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Color(0xffF5EFE4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              image,
                              width: 115,
                              height: 95,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: Colors.black87),
                                    const SizedBox(width: 4),
                                    Text(
                                      country,
                                      style: const TextStyle(
                                          fontSize: 14, color: Color(0xff1A2B49)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    Text(
                                      rating.toString(),
                                      style: const TextStyle(fontSize: 14),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Details
                      _detailRow("Date Booking", dates, "Package Includes", "Transport and Meals"),
                      const SizedBox(height: 8),
                      _detailRow("Person", travellers, "Status", "On Going", statusColor: Colors.green),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xff1A2B49)),
                      const SizedBox(height: 8),

                      // Activities Title
                      const Text(
                        "Activities",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1A2B49),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day 1
                      const Text(
                        "Day 1: Cultural & Historical Dubai",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xff1A2B49),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _tableHeader(),
                      _activityRow("Visit Al Fahidi Fort", "Thu, 22 May 2024", "10:00 AM"),
                      _divider(),
                      _activityRow("Explore Al Bastakiya District", "Thu, 22 May 2024", "11:30 AM"),
                      _divider(),
                      _activityRow("Lunch at a Traditional Emirati Restaurant", "Thu, 22 May 2024", "1:00 PM"),
                      const SizedBox(height: 8),

                      // Day 2
                      const Text(
                        "Day 2: Adventure and Nature",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xff1A2B49),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _tableHeader(),
                      _activityRow("Jumeirah Beach", "Fri, 23 May 2024", "8:00 AM"),
                      _divider(),
                      _activityRow("Visit Palm Jumeirah and Atlantis The Palm", "Fri, 23 May 2024", "12:30 PM"),
                      _divider(),
                      _activityRow("Evening BBQ Dinner at Desert Camp", "Fri, 23 May 2024", "6:30 PM"),
                      const SizedBox(height: 8),

                      // Buttons
                      Row(
                        children: [
                          _roundedButton("Save Itinerary Offline", const Color(0xff1A2B49)),
                          const SizedBox(width: 8),
                          _roundedButton("Download PDF", Color(0xff1A2B49)),
                          const SizedBox(width: 8),
                          _roundedButton("Delete Itinerary", Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Navigate to RateScreen
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) => RateScreen(
                      placeTitle: title,
                      country: country,
                      rating: rating,
                      image: image,
                    ),
                  ),
                );
              },
              child: const Text(
                "Done! Now judge us ⭐",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 18),


          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 1),

    );
  }

  // Components
  Widget _detailRow(String label1, String value1, String label2, String value2, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _detailColumn(label1, value1, statusColor),
        _detailColumn(label2, value2, statusColor),
      ],
    );
  }

  Widget _detailColumn(String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 15, color: color ?? Colors.black)),
      ],
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: const [
          Expanded(
            flex: 5,
            child: Text(
              "Activity",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xff1A2B49),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Date",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xff1A2B49),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Time",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xff1A2B49),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(String activity, String date, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: Text(activity, style: const TextStyle(fontSize: 13, color: Color(0xff1A2B49)))),
          Expanded(flex: 3, child: Text(date, style: const TextStyle(fontSize: 13, color: Color(0xff1A2B49)))),
          Expanded(flex: 2, child: Text(time, style: const TextStyle(fontSize: 13, color: Color(0xff1A2B49)))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: double.infinity, height: 1, color: const Color(0xFFE6E6E6));
  }

  Widget _roundedButton(String text, Color color) {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }
}

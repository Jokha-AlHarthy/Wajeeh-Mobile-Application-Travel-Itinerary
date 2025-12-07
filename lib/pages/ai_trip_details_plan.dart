import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'HomePage.dart';

class TripDetailsScreen extends StatelessWidget {
  final String title;
  final String dates;
  final String travellers;
  final String budget;
  final String image;

  const TripDetailsScreen({
    super.key,
    required this.title,
    required this.dates,
    required this.travellers,
    required this.budget,
    required this.image,
  });

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
          "Details Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff1A2B49),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                image,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "We have adjusted and created the most suitable plan for your trip "
              "according to the criteria you have provided, we hope you like it",
              style: TextStyle(
                color: Color(0xff1A2B49),
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xffF5EFE4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xff1A2B49), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          icon: Icons.calendar_today,
                          title: dates,
                          subtitle: "Travel Dates",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile(
                          icon: Icons.monetization_on_outlined,
                          title: budget,
                          subtitle: "Travel Budget",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          icon: Icons.location_city,
                          title: "4 Star",
                          subtitle: "Place of residence",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile(
                          icon: Icons.place,
                          title: "3 Places",
                          subtitle: "Destination",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dayButton("21 May", selected: true),
                _dayButton("22 May", selected: false),
                _dayButton("23 May", selected: false),
                _dayButton("24 May", selected: false),
              ],
            ),

            const SizedBox(height: 22),

            const Text(
              "08:30 : Head to Qurum Beach",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xff1A2B49),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 80),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1A2B49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, "/home");
                },
                child: const Text(
                  "Select this Plan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xff1A2B49).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff1A2B49),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xff1A2B49), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayButton(String text, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Color(0xff1A2B49) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Color(0xff1A2B49).withValues(alpha: selected ? 1.0 : 0.9),
          width: selected ? 0 : 2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Color(0xff1A2B49),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

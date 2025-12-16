import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final notifications = [
    {
      "title": "Reminder: Passport Expiry",
      "time": "Yesterday, 08:30 AM",
      "body": "Your passport expires in 28 days. Renew it before your trip to Kuwait.",
      "isRead": false,
    },
    {
      "title": "Weather Alert: Rain in Kuwait",
      "time": "Tomorrow, 10:00 AM",
      "body": "Heavy rain expected on Day 2 of your Kuwait trip. Consider indoor activities.",
      "isRead": false,
    },
    {
      "title": "Flight Update: Delayed",
      "time": "Today at 3:35 PM",
      "body":
          "Your flight Airbus A330 to Kuwait has been delayed by 1h 30m. Check details.",
      "isRead": false,
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE4),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: const Color(0xffF5EFE4),
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 55),
        actions: [
          Transform.rotate(
            angle: 0.2,
            child: const Icon(
              Icons.notifications_none,
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Notifications Center",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xff1A2B49), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...notifications.map((n) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5EFE4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xff1A2B49)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n["title"] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff1A2B49),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n["time"] as String,
                            style: const TextStyle(
                              color: Color(0xff1A2B49),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            n["body"] as String,
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    n["isRead"] = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff0C1B33),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    n["isRead"] == true
                                        ? "Read"
                                        : "Mark as read",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 28,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE04F4F),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

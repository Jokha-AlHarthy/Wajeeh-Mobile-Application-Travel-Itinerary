import 'package:flutter/material.dart';
import '../widgets/admin_footer.dart';

class AdminFeedbackManage extends StatelessWidget {
  const AdminFeedbackManage({super.key});

  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);
  static const Color deleteRed = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    final feedbackList = [
      {
        "user": "Sara",
        "category": "App Experience",
        "rating": "4",
        "comment": "The app is user friendly",
        "date": "2025-11-09 14:56:22",
      },
      {
        "user": "Malath",
        "category": "Destinations",
        "rating": "3",
        "comment": "Loved the recommendations for places to visit",
        "date": "2025-12-07 18:17:35",
      },
      {
        "user": "Asil",
        "category": "Itinerary Planning",
        "rating": "5",
        "comment": "Loved how easy it was to organize my Oman trip!",
        "date": "2025-11-06 8:30:10",
      },
    ];

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    "images/logo.png",
                    height: 70,
                  ),
                  const SizedBox(height: 8),

                  // Title
                  const Text(
                    "User Feedback",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Feedback cards
                        ...feedbackList.map(
                              (fb) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FeedbackCard(
                              user: fb["user"]!,
                              category: fb["category"]!,
                              rating: fb["rating"]!,
                              comment: fb["comment"]!,
                              date: fb["date"]!,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkBlue,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Read All",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 140,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: deleteRed,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Delete All",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String user;
  final String category;
  final String rating;
  final String comment;
  final String date;

  static const Color darkBlue = Color(0xFF0C1C3D);
  static const Color deleteRed = Color(0xFFE74C3C);
  static const Color cream = Color(0xFFF7F1E8);

  const _FeedbackCard({
    required this.user,
    required this.category,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: deleteRed,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          _labelLine("User", user),
          const SizedBox(height: 4),
          _labelLine("Category", category),
          const SizedBox(height: 2),
          _labelLine("Rating", rating),
          const SizedBox(height: 4),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 12,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 4),
          _labelLine("Date", date),
        ],
      ),
    );
  }

  Widget _labelLine(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkBlue,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

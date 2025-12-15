import 'package:flutter/material.dart';
import '../widgets/admin_footer.dart';

class AdminContentPage extends StatelessWidget {
  const AdminContentPage({super.key});

  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);

  @override
  Widget build(BuildContext context) {
    final interests = [
      "Adventure",
      "Historical",
      "Beach",
      "Camp",
      "Relaxing",
      "Nature Escapes",
      "Road Trip",
      "Food Tourism",
      "Cultural Exploration",
    ];

    final filters = [
      "Hotels & Stays",
      "Food & Restaurants",
      "Transportation",
      "Culture & Heritage",
      "Shopping & Souvenirs",
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
                  Image.asset(
                    "images/logo.png",
                    height: 70,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Admin Content\nManagement",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Manage AI Trip Interests",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border:
                            Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: interests
                                    .map((t) => _buildTagPill(t))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),

                              _buildAddFieldWithButton(
                                placeholder: "Add new category",
                                buttonText: "Add Interest",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Manage Filters",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border:
                            Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: filters
                                    .map((t) => _buildTagPill(t))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildAddFieldWithButton(
                                placeholder: "Add new filter",
                                buttonText: "Add filter",
                              ),
                            ],
                          ),
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

  Widget _buildTagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.close,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildAddFieldWithButton({
    required String placeholder,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 6),

          SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkBlue,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}



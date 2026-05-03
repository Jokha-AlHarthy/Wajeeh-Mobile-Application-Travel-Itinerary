import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_footer.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);

  final TextEditingController interestController = TextEditingController();
  final TextEditingController filterController = TextEditingController();

  List<Map<String, String>> interests = [];
  List<Map<String, String>> filters = [];

  @override
  void initState() {
    super.initState();
    loadInterests();
    loadFilters();
  }

  Future<void> loadInterests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('interests')
        .get();

    setState(() {
      interests = snapshot.docs
          .map((doc) => {"id": doc.id, "name": doc['name'].toString()})
          .toList();
    });
  }

  Future<void> loadFilters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('filters')
        .get();

    setState(() {
      filters = snapshot.docs
          .map((doc) => {"id": doc.id, "name": doc['name'].toString()})
          .toList();
    });
  }

  Future<void> addInterest() async {
    if (interestController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('interests')
        .add({'name': interestController.text.trim()});

    interestController.clear();
    loadInterests();
  }

  Future<void> addFilter() async {
    if (filterController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('filters')
        .add({'name': filterController.text.trim()});

    filterController.clear();
    loadFilters();
  }

  Future<void> deleteInterest(String id) async {
    await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('interests')
        .doc(id)
        .delete();

    loadInterests();
  }

  Future<void> deleteFilter(String id) async {
    await FirebaseFirestore.instance
        .collection('content')
        .doc('data')
        .collection('filters')
        .doc(id)
        .delete();

    loadFilters();
  }

  @override
  void dispose() {
    interestController.dispose();
    filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
      themeProvider.isDarkMode ? const Color(0xFF3F4E67) : cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("images/logo.png", height: 70),
                  const SizedBox(height: 8),
                  Text(
                    context.tr("admin_content_management"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFFF5A623)
                          : darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF566C8A)
                          : cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF8FA9C4)
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr("manage_user_interests"),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : darkBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF5F7594)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFF8FA9C4)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: interests
                                    .map(
                                      (t) => _buildTagPill(
                                    t['name']!,
                                    t['id']!,
                                    isInterest: true,
                                  ),
                                )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildAddFieldWithButton(
                                controller: interestController,
                                placeholder: context.tr("add_new_category"),
                                buttonText: context.tr("add_interest"),
                                onPressed: addInterest,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.tr("manage_filters"),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : darkBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF5F7594)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFF8FA9C4)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: filters
                                    .map(
                                      (t) => _buildTagPill(
                                    t['name']!,
                                    t['id']!,
                                    isInterest: false,
                                  ),
                                )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildAddFieldWithButton(
                                controller: filterController,
                                placeholder: context.tr("add_new_filter"),
                                buttonText: context.tr("add_filter"),
                                onPressed: addFilter,
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
      bottomNavigationBar: const AdminFooter(currentIndex: 2),
    );
  }

  Widget _buildTagPill(String text, String id, {required bool isInterest}) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF566C8A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr(text),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (isInterest) {
                deleteInterest(id);
              } else {
                deleteFilter(id);
              }
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFieldWithButton({
    required TextEditingController controller,
    required String placeholder,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF566C8A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade400,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkBlue,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_localizations.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  int rating = 3;
  bool hasTrip = false;
  final List<String> categories = [
    "category_app_experience",
    "category_destinations",
    "category_suggestion",
    "category_complaints",
    "category_other",
  ];

  String? selectedCategory;
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> checkUserTrips() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("travelStorage")
        .doc("v1")
        .get();

    final data = doc.data();
    final savedTrips = data?["savedTrips"] as List? ?? [];

    if (!mounted) return;

    setState(() {
      hasTrip = savedTrips.isNotEmpty;

      if (!hasTrip && selectedCategory == "category_destinations") {
        selectedCategory = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkUserTrips();
  }

  String getFeedbackType() {
    if (selectedCategory == "category_destinations" && hasTrip) {
      return "trip";
    }
    return "general";
  }

  Future<void> submitFeedback() async {
    if (selectedCategory == null || commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("complete_all_fields"))),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("feedback").add({
      "type": getFeedbackType(),
      "user":
          FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.email ??
          "Unknown",
      "category": selectedCategory,
      "rating": rating,
      "comment": commentController.text.trim(),
      "date": Timestamp.now(),
      "isRead": false,
    });

    if (!mounted) return;

    commentController.clear();

    setState(() {
      rating = 3;
      selectedCategory = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr("feedback_submitted_success"))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? const Color(0xFF89B0D8)
        : theme.colorScheme.primary;

    final textColor = isDark
        ? const Color(0xFF89B0D8)
        : theme.colorScheme.onSurface;

    final visibleCategories = hasTrip
        ? categories
        : categories.where((e) => e != "category_destinations").toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(color: theme.colorScheme.onSurface),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 42, fit: BoxFit.contain),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
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
                  Icon(
                    Icons.notifications,
                    size: 28,
                    color: theme.colorScheme.onSurface,
                  ),
                  PositionedDirectional(
                    end: -1,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final bool isSmallScreen = screenWidth < 360;
            final bool isTablet = screenWidth >= 700;

            final double pagePadding = isTablet ? 32 : 20;
            final double formPadding = isSmallScreen
                ? 18
                : (isTablet ? 28 : 24);
            final double titleSpacing = isSmallScreen ? 16 : 24;
            final double fieldSpacing = isSmallScreen ? 18 : 24;
            final double starSize = isSmallScreen ? 28 : 32;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        context.tr("user_feedback"),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: titleSpacing),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(formPadding),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr("we_value_opinion"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 20 : 22,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr("rate_overall_experience"),
                              style: TextStyle(
                                color: textColor,
                                fontSize: isSmallScreen ? 14 : 15,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Responsive stars
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(5, (i) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      setState(() => rating = i + 1);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.star,
                                        size: starSize,
                                        color: i < rating
                                            ? borderColor
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            SizedBox(height: fieldSpacing),

                            Text(
                              context.tr("category"),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                alignment: AlignmentDirectional.centerStart,
                                isExpanded: true,
                                value: selectedCategory,
                                underline: const SizedBox(),
                                iconEnabledColor: theme.colorScheme.primary,
                                hint: Text(
                                  context.tr("select"),
                                  style: const TextStyle(
                                    color: Color(0xff8A8A8A),
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Color(0xff1A2B49),
                                ),
                                items: visibleCategories.map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(
                                      context.tr(e),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff1A2B49),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => selectedCategory = v);
                                },
                              ),
                            ),

                            SizedBox(height: fieldSpacing),

                            Container(
                              constraints: const BoxConstraints(minHeight: 120),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: TextField(
                                  controller: commentController,
                                  minLines: 5,
                                  maxLines: 7,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: const TextStyle(
                                    color: Color(0xff1A2B49),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(12),
                                    hintText: context.tr("write_feedback"),
                                    hintStyle: const TextStyle(
                                      color: Color(0xff8A8A8A),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: fieldSpacing + 4),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: submitFeedback,
                                child: Text(
                                  context.tr("submit"),
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xff1A2B49)
                                        : Colors.white,
                                    fontSize: 16,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

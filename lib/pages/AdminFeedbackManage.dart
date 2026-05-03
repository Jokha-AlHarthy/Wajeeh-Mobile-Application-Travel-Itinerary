import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/admin_footer.dart';
import '../localization/app_localizations.dart';
import '../providers/theme_provider.dart';

class AdminFeedbackManage extends StatefulWidget {
  const AdminFeedbackManage({super.key});

  @override
  State<AdminFeedbackManage> createState() => _AdminFeedbackManageState();
}

class _AdminFeedbackManageState extends State<AdminFeedbackManage> {
  final ScrollController _scrollController = ScrollController();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String selectedFilter = "all";

  final List<String> categories = [
    "all",
    "category_app_experience",
    "category_destinations",
    "category_suggestion",
    "category_complaints",
    "category_other",
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String categoryLabel(BuildContext context, String category) {
    switch (category) {
      case "all":
        return context.tr("all");
      case "category_app_experience":
        return context.tr("category_app_experience");
      case "category_destinations":
        return context.tr("category_destinations");
      case "category_suggestion":
        return context.tr("category_suggestion");
      case "category_complaints":
        return context.tr("category_complaints");
      case "category_other":
        return context.tr("category_other");
      default:
        return category;
    }
  }

  String translateButtonLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == "ar"
        ? "ترجمة"
        : "Translate";
  }

  String translationDialogTitle(BuildContext context) {
    return Localizations.localeOf(context).languageCode == "ar"
        ? "ترجمة الملاحظة"
        : "Feedback Translation";
  }

  String translationErrorText(BuildContext context) {
    return Localizations.localeOf(context).languageCode == "ar"
        ? "فشلت الترجمة"
        : "Translation failed";
  }

  Future<String> translateFeedbackText(
    String text, {
    required String targetLanguage,
  }) async {
    final callable = _functions.httpsCallable("translateFeedback");

    final result = await callable.call(<String, dynamic>{
      "text": text,
      "targetLanguage": targetLanguage,
    });

    final data = result.data as Map<dynamic, dynamic>;
    final translatedText = data["translatedText"]?.toString();

    if (translatedText == null || translatedText.isEmpty) {
      throw Exception("No translated text returned.");
    }

    return translatedText;
  }

  Future<void> showTranslationDialog(String comment) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final targetLanguage = Localizations.localeOf(context).languageCode == "ar"
        ? "ar"
        : "en";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3B4C66) : Colors.white,
        title: Text(
          translationDialogTitle(context),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C1C3D),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: FutureBuilder<String>(
          future: translateFeedbackText(
            comment,
            targetLanguage: targetLanguage,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 70,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text(
                translationErrorText(context),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              );
            }

            return SingleChildScrollView(
              child: Text(
                snapshot.data ?? comment,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr("cancel"),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance.collection("feedback").doc(id).update({
      "isRead": true,
    });
  }

  Future<void> markAllAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("feedback")
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final bool isRead = data["isRead"] == true;

      if (!isRead) {
        await doc.reference.update({"isRead": true});
      }
    }
  }

  Future<void> confirmDelete(String id) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3B4C66) : Colors.white,
        title: Text(
          context.tr("confirm_delete"),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C1C3D),
          ),
        ),
        content: Text(
          context.tr("delete_feedback_confirm"),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr("cancel"),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr("delete"),
              style: const TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection("feedback").doc(id).delete();
    }
  }

  Future<void> confirmDeleteAll() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF3B4C66) : Colors.white,
        title: Text(
          context.tr("delete_all_feedback"),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0C1C3D),
          ),
        ),
        content: Text(
          context.tr("delete_all_feedback_confirm"),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr("cancel"),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr("delete_all"),
              style: const TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
          .collection("feedback")
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final Color scaffoldBg = isDark
        ? const Color(0xFF344766)
        : const Color(0xFFF7F1E8);

    final Color outerCardBg = isDark
        ? const Color(0xFF4A6286)
        : const Color(0xFFFDF7EE);

    final Color itemBg = isDark
        ? const Color(0xFF5E7597)
        : const Color(0xFFF7F1E8);

    final Color unreadBg = isDark
        ? const Color(0xFF6D5A2E)
        : const Color(0xFFFFF3CD);

    final Color titleColor = isDark
        ? const Color(0xFFF5A623)
        : const Color(0xFF0C1C3D);

    final Color textColor = isDark ? Colors.white : const Color(0xFF0C1C3D);

    final Color subTextColor = isDark
        ? const Color(0xFFBDD0EA)
        : Colors.black54;

    final Color borderColor = isDark
        ? const Color(0xFF8FB3D9)
        : Colors.grey.shade400;

    final Color dropdownBg = isDark ? const Color(0xFF4A6286) : Colors.white;

    final Color readAllColor = isDark
        ? const Color(0xFFF5A623)
        : const Color(0xFF0C1C3D);

    const Color deleteRed = Color(0xFFF44336);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Image.asset("images/logo.png", height: 70),
                  const SizedBox(height: 20),
                  Text(
                    context.tr("user_feedback"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: dropdownBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedFilter,
                      underline: const SizedBox(),
                      dropdownColor: dropdownBg,
                      iconEnabledColor: textColor,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: categories.map((e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            categoryLabel(context, e),
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: outerCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection("feedback")
                                  .orderBy("date", descending: true)
                                  .limit(100)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      "Error loading feedback",
                                      style: TextStyle(color: textColor),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      context.tr("no_feedback_available"),
                                      style: TextStyle(color: textColor),
                                    ),
                                  );
                                }

                                List<QueryDocumentSnapshot> allDocs =
                                    snapshot.data!.docs;

                                if (selectedFilter != "all") {
                                  allDocs = allDocs.where((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final category =
                                        data["category"]?.toString() ?? "";
                                    return category == selectedFilter;
                                  }).toList();
                                }

                                if (allDocs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      context.tr("no_feedback_available"),
                                      style: TextStyle(color: textColor),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  itemCount: allDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = allDocs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final bool isRead = data["isRead"] == true;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (!isRead) {
                                            await markAsRead(doc.id);
                                          }
                                        },
                                        child: _FeedbackCard(
                                          type: data["type"]?.toString() ?? "general",
                                          user: data["user"]?.toString() ?? "",
                                          category: categoryLabel(
                                            context,
                                            data["category"]?.toString() ?? "",
                                          ),
                                          rating:
                                              data["rating"]?.toString() ?? "",
                                          comment:
                                              data["comment"]?.toString() ?? "",
                                          date: formatDate(
                                            data["date"] as Timestamp,
                                          ),
                                          isRead: isRead,
                                          onDelete: () => confirmDelete(doc.id),
                                          onTranslate: () =>
                                              showTranslationDialog(
                                                data["comment"]?.toString() ??
                                                    "",
                                              ),
                                          translateButtonText:
                                              translateButtonLabel(context),
                                          itemBg: itemBg,
                                          unreadBg: unreadBg,
                                          textColor: textColor,
                                          subTextColor: subTextColor,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 118,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: markAllAsRead,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: readAllColor,
                                    foregroundColor: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr("read_all"),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 118,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: confirmDeleteAll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: deleteRed,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr("delete_all"),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(currentIndex: 3),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String type;
  final String user;
  final String category;
  final String rating;
  final String comment;
  final String date;
  final bool isRead;
  final VoidCallback onDelete;
  final VoidCallback onTranslate;
  final String translateButtonText;
  final Color itemBg;
  final Color unreadBg;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _FeedbackCard({
    required this.type,
    required this.user,
    required this.category,
    required this.rating,
    required this.comment,
    required this.date,
    required this.isRead,
    required this.onDelete,
    required this.onTranslate,
    required this.translateButtonText,
    required this.itemBg,
    required this.unreadBg,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color deleteRed = Color(0xFFF44336);
    const Color translateBlue = Color(0xFF10264C);
    const Color unreadBorder = Color(0xFFFF9800);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isRead ? itemBg : unreadBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? borderColor : unreadBorder,
          width: isRead ? 1.2 : 2,
        ),
        boxShadow: isRead
            ? []
            : [
                BoxShadow(
                 color: unreadBorder.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onTranslate,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    translateButtonText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: translateBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deleteRed,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.tr("delete"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _labelLine(
            context.tr("feedback_type"),
            type == "trip"
                ? context.tr("trip_feedback")
                : context.tr("general_feedback"),
            textColor,
            subTextColor,
          ),

          _labelLine(context.tr("user"), user, textColor, subTextColor),
          const SizedBox(height: 4),

          _labelLine(context.tr("category"), category, textColor, subTextColor),
          const SizedBox(height: 4),
          _labelLine(context.tr("rating"), rating, textColor, subTextColor),

          const SizedBox(height: 6),
          Text(comment, style: TextStyle(fontSize: 12, color: subTextColor)),

          const SizedBox(height: 6),
          _labelLine(context.tr("date"), date, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _labelLine(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$label: ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

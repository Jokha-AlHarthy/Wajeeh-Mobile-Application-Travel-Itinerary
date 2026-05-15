import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../constants/place_category_options.dart';
import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';

class MyPreferencePage extends StatefulWidget {
  const MyPreferencePage({super.key});

  @override
  State<MyPreferencePage> createState() => _MyPreferencePageState();
}

class _MyPreferencePageState extends State<MyPreferencePage> {
  List<String> selectedCountries = [];
  String? selectedBudget;
  List<String> selectedTripTypes = [];
  List<String> selectedInterests = [];

  final List<Map<String, String>> countries = [
    {"code": "OM", "image": "images/oman.png"},
    {"code": "QA", "image": "images/qatar.png"},
    {"code": "KW", "image": "images/kuwait.png"},
    {"code": "BHR", "image": "images/bahrain.png"},
    {"code": "KSA", "image": "images/saudi.png"},
    {"code": "UAE", "image": "images/uae.png"},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedInterests());
  }

  void _loadSavedInterests() {
    final saved = context.read<AuthProvider>().preferredInterests;
    if (saved.isEmpty || !mounted) return;
    setState(() {
      selectedInterests = List<String>.from(saved);
    });
  }

  void toggleCountry(String code) {
    setState(() {
      if (selectedCountries.contains(code)) {
        selectedCountries.remove(code);
      } else {
        selectedCountries.add(code);
      }
    });
  }

  Future<void> savePreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedCountries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("select_at_least_one_country"))),
      );
      return;
    }

    for (var country in selectedCountries) {
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'country': country,
        'year': DateTime.now().year,
        'budget': selectedBudget,
        'tripType': selectedTripTypes,
        'interest': normalizePreferenceInterestKeys(selectedInterests),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final interestKeys =
        normalizePreferenceInterestKeys(selectedInterests);

    await context.read<AuthProvider>().markPreferencesCompleted(
          interestKeys: interestKeys,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr("preference_saved_success"))),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  void openInterestDropdown() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(context.tr("select_interests")),
              content: SingleChildScrollView(
                child: Column(
                  children: placeCategoryFilterKeys.map((key) {
                    final isSelected = selectedInterests.contains(key);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(context.tr(key)),
                      onChanged: (val) {
                        setState(() {
                          if (isSelected) {
                            selectedInterests.remove(key);
                          } else {
                            selectedInterests.add(key);
                          }
                        });

                        setStateDialog(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr("done")),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelColor = isDark
        ? const Color(0xFF89B0D8)
        : theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          context.tr("your_preference"),
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr("where_prefer_to_go"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: countries.map((country) {
                        final code = country["code"]!;
                        final image = country["image"]!;
                        final isSelected = selectedCountries.contains(code);

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          child: GestureDetector(
                            onTap: () => toggleCountry(code),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(image, height: 40),
                                ),
                                const SizedBox(height: 6),
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (val) => toggleCountry(code),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    context.tr("determine_travel_budget"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: [
                      _budgetButton(context, "budget_cheap", isDark),
                      _budgetButton(context, "budget_balanced", isDark),
                      _budgetButton(context, "budget_luxury", isDark),
                      _budgetButton(context, "budget_flexible", isDark),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    context.tr("who_plan_to_trip_with"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: [
                      _tripButton(context, "trip_only_me", isDark),
                      _tripButton(context, "trip_with_couple", isDark),
                      _tripButton(context, "trip_my_friend", isDark),
                      _tripButton(context, "trip_with_family", isDark),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    context.tr("choose_interest_for_trip"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: openInterestDropdown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF89B0D8)
                            : (theme.cardTheme.color ??
                            theme.colorScheme.surface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedInterests.isEmpty
                                  ? context.tr("interest")
                                  : selectedInterests
                                      .map((k) => context.tr(k))
                                      .join(", "),
                              style: const TextStyle(
                                color: Color(0xFF1A2B49),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: savePreference,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        context.tr("save_my_preference"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF1A2B49)
                              : Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _budgetButton(BuildContext context, String title, bool isDark) {
    final theme = Theme.of(context);
    final isSelected = selectedBudget == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBudget = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8D7BB)
              : (isDark
              ? const Color(0xFF89B0D8)
              : (theme.cardTheme.color ?? theme.colorScheme.surface)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF5A623)
                : const Color(0xFF1A2B49),
          ),
        ),
        child: Text(
          context.tr(title),
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFF5A623)
                : const Color(0xFF1A2B49),
          ),
        ),
      ),
    );
  }

  Widget _tripButton(BuildContext context, String title, bool isDark) {
    final theme = Theme.of(context);
    final isSelected = selectedTripTypes.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedTripTypes.remove(title);
          } else {
            selectedTripTypes.add(title);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8D7BB)
              : (isDark
              ? const Color(0xFF89B0D8)
              : (theme.cardTheme.color ?? theme.colorScheme.surface)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF5A623)
                : const Color(0xFF1A2B49),
          ),
        ),
        child: Text(
          context.tr(title),
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFF5A623)
                : const Color(0xFF1A2B49),
          ),
        ),
      ),
    );
  }
}

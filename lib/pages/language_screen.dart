import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../language_provider.dart';
import '../localization/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? selectedLanguage;

  @override
  void initState() {
    super.initState();

    selectedLanguage = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(color: theme.colorScheme.onSurface),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 55),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Text(
              context.tr('select_language'),
              textAlign: TextAlign.start, // ✅ RTL FIX
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xffF5A623)
                    : const Color(0xff1A2B49),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              context.tr('language_preference_subtitle'),
              textAlign: TextAlign.start, // ✅ RTL FIX
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF89B0D8)
                    : const Color(0xff1A2B49),
              ),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: AlignmentDirectional.centerStart, // ✅ FIXED
              child: Text(
                context.tr('language'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF89B0D8)
                      : const Color(0xff1A2B49),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                alignment: AlignmentDirectional.centerStart, // ✅ FIXED
                hint: Text(
                  context.tr('select'),
                  style: const TextStyle(color: Color(0xff1A2B49)),
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xff1A2B49)),
                items: [
                  DropdownMenuItem(
                    value: "en",
                    child: Text(
                      context.tr('english'),
                      textAlign: TextAlign.start, // ✅ FIXED
                      style: const TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "ar",
                    child: Text(
                      context.tr('arabic'),
                      textAlign: TextAlign.start, // ✅ FIXED
                      style: const TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;

                  setState(() {
                    selectedLanguage = v; // store only
                  });
                },
              ),
            ),

            const SizedBox(height: 300),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xffF5A623)
                      : theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (selectedLanguage != null) {
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).changeLanguage(selectedLanguage!);
                  }

                  Navigator.pushNamed(context, '/setting');
                },
                child: Text(
                  context.tr('save'),
                  style: TextStyle(
                    color: isDark ? const Color(0xff1A2B49) : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

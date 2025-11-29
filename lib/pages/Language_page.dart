import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f1e8),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 70),

            // Logo
            Center(
              child: Image.asset(
                "images/logo.png",
                height: 70,
              ),
            ),

            const SizedBox(height: 40),

            // Title
            const Text(
              "Select your Language",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1C3D),
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            const Text(
              "Choose your preferred language to start\nplanning your trip effortlessly",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF0C1C3D),
              ),
            ),

            const SizedBox(height: 40),

            // Dropdown Label
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Language",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1C3D),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Dropdown
            Container(
              width: 500,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF0C1C3D)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  hint: const Text("Select"),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(
                      value: "English",
                      child: Text("English"),
                    ),
                    DropdownMenuItem(
                      value: "Arabic",
                      child: Text("Arabic"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value;
                    });
                  },
                ),
              ),
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedLanguage == null
                    ? null
                    : () {
                  Navigator.pushReplacementNamed(context, "/location");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1C3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

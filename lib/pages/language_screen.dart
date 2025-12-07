import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),

      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: const Color(0xffF5EFE4),
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

            const Text(
              "Select your Language",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,

                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Select how you want Wajeeh to speak to you",
              style: TextStyle(color: Color(0xff1A2B49)),
            ),

            const SizedBox(height: 15),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Language",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1A2B49),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff1A2B49)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                hint: const Text(
                  "Select",
                  style: TextStyle(color: Color(0xff1A2B49)),
                ),
                isExpanded: true,
                dropdownColor: const Color(0xffffffff),
                style: const TextStyle(color: Color(0xff1A2B49)),
                items: const [
                  DropdownMenuItem(
                    value: "English",
                    child: Text(
                      "English",
                      style: TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Arabic",
                    child: Text(
                      "Arabic",
                      style: TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => selectedLanguage = v),
              ),
            ),
            const SizedBox(height: 300),


            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A2B49),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/setting');
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

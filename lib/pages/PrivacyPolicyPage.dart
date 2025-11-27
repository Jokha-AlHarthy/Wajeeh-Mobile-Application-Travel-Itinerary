import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // Transparent background so home screen stays visible
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.0),
          ),
        ),

        // RIGHT SIDE PANEL
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.70,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Color(0xFF0C2340),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "X",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text(
                        """
1. Introduction
Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our services. By using our website or app, you agree to the terms described here.

2. Information We Collect
We may collect the following information when you use our service:
• Personal Information: Name, email address, phone number, payment details.
• Account Details: Login credentials, booking history, saved preferences.
• Usage Data: IP address, browser type, device information, and interactions with the app.
• Location Data: If you enable location sharing, we may collect your real-time location to improve search results and recommendations.

3. How We Use Your Information
We use your information to:
• Process bookings and payments.
• Provide customer support.
• Send booking confirmations and updates.
• Improve and personalize our services.
• Comply with legal requirements.

4. Sharing Your Information
We do not sell your personal information.
We may share your data only with:
• Travel service providers (airlines, hotels) to fulfill bookings.
• Payment processors to complete transactions.
• Legal authorities if required by law.

5. Data Storage & Security
We store your data securely and take steps to protect it against unauthorized access, alteration, or destruction.

6. Your Rights
You have the right to:
• Access, correct, or delete your data.
• Withdraw consent to data processing.
• Opt out of marketing communications.

7. Cookies
We use cookies to improve your browsing experience, remember your preferences, and provide relevant offers.

8. Changes to This Policy
We may update this policy from time to time. Changes will be posted on this page with the updated date.

""",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                          decoration: TextDecoration.none
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

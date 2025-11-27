import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // Tap outside to close (transparent overlay)
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
                          "Terms",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
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
Welcome to Wajeeh. By accessing or using our website or mobile app, you agree to these Terms & Conditions. If you do not agree, please do not use our services.

2. Services Provided
Wajeeh allows users to search, compare, and book travel services including flights, hotels, and trip packages through third-party providers.

3. User Responsibilities
When using Wajeeh, you agree to:
• Provide accurate and truthful information during booking.
• Ensure you meet all travel requirements (passport, visas, vaccinations).
• Use the service for personal, non-commercial purposes only.
• Not engage in fraudulent or harmful activity on our platform.

4. Booking & Payment
• Prices are subject to change until the booking is confirmed.
• Bookings are confirmed only upon receipt of payment.
• All payments are processed securely via trusted payment gateways.

5. Cancellations & Refunds
• Cancellation and refund policies are determined by the travel provider.
• Tajawal is not responsible for refund decisions made by third-party providers.
• Some bookings may be non-refundable.

6. Liability Disclaimer
• Tajawal acts as an intermediary between you and the travel service providers.
• We are not liable for delays, cancellations, or service issues caused by third-party providers.
• All travel is undertaken at your own risk.

7. Intellectual Property
All content, trademarks, and logos are owned by us or our partners and may not be used without permission.

8. Privacy Policy
Your use of Wajeeh is also governed by our Privacy Policy.

9. Changes to Terms
We may update these Terms at any time. Continued use of Wajeeh means you accept the updated terms.

""",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                          decoration: TextDecoration.none,
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

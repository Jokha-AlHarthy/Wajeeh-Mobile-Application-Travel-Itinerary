import 'package:flutter/material.dart';
import 'PrivacyPolicyPage.dart';
import 'TermsPage.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("images/logo.png", height: 150),
              const SizedBox(height: 20),
              const Text(
                "Plan your dream trip in minutes",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5A623),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Seamlessly plan and book your perfect getaway with ease",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0C1C3D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Image.asset("images/illustration.png", height: 350),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space the buttons
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/register");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C1C3D), // Dark blue background
                      minimumSize: const Size(150, 55), // Adjusted size for buttons to be side by side
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // No border radius
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                    child: const Text("Sign Up"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/login");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // White background for Log In button
                      side: const BorderSide(color: Color(0xFF0C1C3D), width: 2), // Border color with thickness
                      minimumSize: const Size(150, 55), // Adjusted size for buttons to be side by side
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // No border radius
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                    child: const Text(
                      "Log In",
                      style: TextStyle(color: Color(0xFF0C1C3D)), // Text color is dark blue
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          barrierColor: Colors.transparent,
                          pageBuilder: (_, __, ___) => const PrivacyPolicyPage(),
                        ),
                      );

                    },
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0C1C3D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 60),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          barrierColor: Colors.transparent,
                          pageBuilder: (_, __, ___) => const TermsPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Terms",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0C1C3D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

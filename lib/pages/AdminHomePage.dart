import 'package:flutter/material.dart';
import 'AdminProfilePage.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),

      /// BODY
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),

            // Logo
            Image.asset("images/logo.png", height: 150),

            const SizedBox(height: 10),

            // Welcome Text
            const Text(
              "Welcome Back\nAdmin!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5B546), // gold-ish
              ),
            ),

            const SizedBox(height: 20),

            // Illustration
            Image.asset(
              "images/illustration.png",
              height: 260,
            ),

            /// FOOTER NAVBAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              color: Color(0xFFF7F1E8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Home icon
                  const Icon(
                    Icons.home,
                    size: 28,
                    color: Color(0xFF0C1C3D),
                  ),

                  /// Headset icon from image
                  Image.asset(
                    "images/manage-user-icon.png",
                    height: 28,
                    color: Colors.grey, // remove if your image already has color
                  ),

                  /// Center icon — circular rotated send icon
                  Container(
                    height: 55,
                    width: 55,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C1C3D),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: -0.8, // rotates the send icon to match your photo
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  /// Quotation marks from image
                  Image.asset(
                    "images/user-feedback-icon.png",
                    height: 32,
                    color: Colors.grey, // remove if your image has its own color
                  ),

                  /// Users icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProfilePage(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.group_outlined,
                      size: 28,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/admin_footer.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),

      /// BODY
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Image.asset("images/logo.png", height: 150),

              const SizedBox(height: 30),

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

              const SizedBox(height: 50),

              // Illustration
              Image.asset(
                "images/illustration.png",
                height: 260,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      /// FOOTER
      bottomNavigationBar: const AdminFooter(),
    );
  }
}

import 'package:flutter/material.dart';

class AdminFooter extends StatelessWidget {
  const AdminFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      color: const Color(0xFFF7F1E8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, "/adminHome"),
            child: const Icon(
              Icons.home,
              size: 28,
              color: Color(0xFF0C1C3D),
            ),
          ),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/adminDashboard"),
            child: Image.asset(
              "images/manage-user-icon.png",
              height: 26,
              color: Colors.grey,
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/adminContent");
            },
            child: Container(
              height: 55,
              width: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0C1C3D),
              ),
              child: Transform.rotate(
                angle: -0.8,
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/adminFeedback"),
            child: Image.asset(
              "images/user-feedback-icon.png",
              height: 26,
              color: Colors.grey,
            ),
          ),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/adminProfile"),
            child: Icon(
              Icons.group_outlined,
              size: 28,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

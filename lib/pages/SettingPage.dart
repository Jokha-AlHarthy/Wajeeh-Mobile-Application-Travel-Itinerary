import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const Color cream = Color(0xffF7F1E8);
  static const Color darkBlue = Color(0xFF0C1C3D);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // LOAD FROM YOUR PROVIDER
    final String name = auth.fullName ?? "User";
    final String email = auth.email ?? "No email";

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SizedBox(width: 40),
                  Text(
                    "Setting",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  Icon(Icons.notifications_active_outlined, color: darkBlue),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // USER INFO ---------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PERSONAL INFO
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Personal Info",
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            _settingTile(icon: Icons.person, title: "Profile"),

            // SECURITY
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "Security",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _settingTile(
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                Navigator.pushNamed(context, '/ChangePass');
              },
            ),

            // GENERAL
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("General",
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            _settingTile(icon: Icons.translate, title: "Language"),
            _settingTile(icon: Icons.chat_bubble_outline, title: "Feedback"),

            // ABOUT
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("About",
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            _settingTile(
                icon: Icons.description_outlined,
                title: "Policies and Terms"),

            const Spacer(),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // FOOTER (same)
      bottomNavigationBar: Container(
        color: cream,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon:
                  const Icon(Icons.home_filled, color: darkBlue)),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.explore_outlined,
                    color: Colors.grey.shade700),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: darkBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.favorite_border,
                    color: Colors.grey.shade700),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.group_outlined, color: darkBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable tile
Widget _settingTile({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: const Color(0xFF0C1C3D)),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap, // <-- use it here
  );
}

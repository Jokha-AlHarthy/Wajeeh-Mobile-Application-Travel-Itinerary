import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as myAuth;

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const Color cream = Color(0xffF7F1E8);
  static const Color darkBlue = Color(0xFF0C1C3D);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<myAuth.AuthProvider>(context);

    final String name = auth.fullName ?? "User";
    final String email = auth.email ?? "No email";

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),

                  const Text(
                    "Setting",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications,
                          size: 28,
                          color: darkBlue,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              "3",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: AssetImage("images/user.png"),
                    ),
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Personal Info",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _settingTile(
              icon: Icons.person,
              title: "Profile",
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),

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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "General",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _settingTile(
              icon: Icons.translate,
              title: "Language",
              onTap: () {
                Navigator.pushNamed(context, '/languagePreference');
              },
            ),
            _settingTile(
              icon: Icons.chat_bubble_outline,
              title: "Feedback",
              onTap: () {
                Navigator.pushNamed(context, '/user_feedback');
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "About",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _settingTile(
              icon: Icons.description_outlined,
              title: "Policies and Terms",
            ),

            // -------- Static Dark Mode Toggle (UI only) --------
            ListTile(
              leading: const Icon(
                Icons.nightlight_round,
                color: Color(0xFF0C1C3D),
              ),
              title: const Text(
                "Dark Mode",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context),

                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 4),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want\nto logout?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1C3D),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (_) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1C3D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _settingTile({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: const Color(0xFF0C1C3D)),
    title: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

 

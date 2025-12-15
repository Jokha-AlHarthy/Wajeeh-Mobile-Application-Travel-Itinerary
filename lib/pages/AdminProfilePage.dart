import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'ChangePass.dart';
import '../widgets/admin_footer.dart';


class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  bool darkMode = false;
  DateTime? dob;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    final auth = context.read<app_auth.AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;

    firstName.text = (auth.fullName ?? '').trim();
    email.text = (auth.email ?? user?.email ?? '').trim();
    lastName.text = '';

    _init = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1C3D),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("images/headerPic.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue.shade300,
                        child: const Icon(Icons.person,
                            size: 32, color: Colors.white),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 24,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit,
                          size: 18, color: Colors.green),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              _field("First Name", firstName),
              const SizedBox(height: 10),
              _field("Last Name", lastName, hint: "Last Name"),
              const SizedBox(height: 10),
              _field("E-mail", email),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  "Date of Birth",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dob == null
                          ? "Date of Birth"
                          : "${dob!.day} ${_monthName(dob!.month)} ${dob!.year}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black38),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preferences",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C1C3D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _settingRow(
                      icon: Icons.nightlight_round,
                      title: "Dark Mode",
                      trailing: Switch(
                        value: darkMode,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => darkMode = v),
                      ),
                    ),
                    _settingRow(
                      icon: Icons.language,
                      title: "Language",
                      trailingText: "English",
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePass()),
                        );
                      },
                      child: _settingRow(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C1C3D),
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: ElevatedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(),
    );
  }


  Widget _field(String label, TextEditingController c, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0C1C3D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: c,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF0C1C3D)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          if (trailing != null) trailing,
          if (trailingText != null)
            Text(trailingText,
                style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        context, "/login", (_) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Log Out",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C1C3D),
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      color: const Color(0xFFF7F1E8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, "/adminHome"),
            child: const Icon(Icons.home,
                size: 28, color: Color(0xFF0C1C3D)),
          ),
          Image.asset(
            "images/manage-user-icon.png",
            height: 26,
            color: Colors.grey.shade700,
          ),
          Container(
            height: 55,
            width: 55,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0C1C3D),
            ),
            child: Transform.rotate(
              angle: -0.8,
              child: const Icon(Icons.send,
                  color: Colors.white, size: 26),
            ),
          ),
          Image.asset(
            "images/user-feedback-icon.png",
            height: 26,
            color: Colors.grey.shade700,
          ),
          const Icon(
            Icons.group_outlined,
            size: 28,
            color: Color(0xFF0C1C3D),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[m];
  }
}

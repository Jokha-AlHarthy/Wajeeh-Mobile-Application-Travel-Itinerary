import 'package:flutter/material.dart';
import '../widgets/admin_footer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);
  static const Color orange = Color(0xFFF5B546);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    "images/logo.png",
                    height: 70,
                  ),
                  const SizedBox(height: 8),

                  // Title
                  const Text(
                    "Admin Dashboard",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ===== Card: Add User =====
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Add User",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Username
                        _buildTextField(
                          controller: _usernameController,
                          hint: "Username",
                        ),
                        const SizedBox(height: 10),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          hint: "Email",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),

                        // Password
                        _buildTextField(
                          controller: _passwordController,
                          hint: "Password",
                          obscure: true,
                        ),
                        const SizedBox(height: 10),

                        // Role dropdown
                        _buildRoleDropdown(),

                        const SizedBox(height: 16),

                        // Add User button (full width)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // backend 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBlue,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Add User",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== All User Title =====
                  const Text(
                    "All User",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ===== Users Table =====
                  _buildUsersTable(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(),
    );
  }

  // ---------- Widgets helpers ----------

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: darkBlue, width: 1.2),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: "Role",
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: darkBlue, width: 1.2),
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down),
      items: const [
        DropdownMenuItem(
          value: "User",
          child: Text("User"),
        ),
        DropdownMenuItem(
          value: "Admin",
          child: Text("Admin"),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
        });
      },
    );
  }

  Widget _buildUsersTable() {
    final users = [
      {
        "username": "urfavEda",
        "email": "EdaDavid@gmail.com",
        "role": "User",
      },
      {
        "username": "Admin",
        "email": "admin@gmail.com",
        "role": "Admin",
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Colors.black, width: 1),
            verticalInside: BorderSide(color: Colors.black, width: 1),
          ),
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: orange,
              ),
              children: const [
                _TableHeaderCell(text: "Username"),
                _TableHeaderCell(text: "Email"),
                _TableHeaderCell(text: "Role"),
                _TableHeaderCell(text: "Actions"),
              ],
            ),
            ...users.map(
                  (user) => TableRow(
                children: [
                  _TableDataCell(text: user["username"]!),
                  _TableDataCell(text: user["email"]!),
                  _TableDataCell(text: user["role"]!),
                  const _TableActionCell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


class _TableDataCell extends StatelessWidget {
  final String text;
  const _TableDataCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableActionCell extends StatelessWidget {
  const _TableActionCell();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit button
          SizedBox(
            height: 24,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C1C3D), // dark blue
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                const VisualDensity(horizontal: -4, vertical: -4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Edit",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Delete button
          SizedBox(
            height: 24,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                const VisualDensity(horizontal: -4, vertical: -4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';
import '../localization/error_mapper.dart';

class EditUserInfoScreen extends StatefulWidget {
  final String uid;

  const EditUserInfoScreen({super.key, required this.uid});

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  static const Color bgColor = Color(0xFFF5EFE6);
  static const Color darkBlue = Color(0xFF0C1C3D);

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedRole = "user";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return "${date.day} ${_monthName(date.month)} ${date.year}";
    } catch (_) {
      return raw;
    }
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(widget.uid).get();
    if (!mounted) return;

    final data = doc.data();

    if (data != null) {
      setState(() {
        _usernameController.text = data['fullName'] ?? "";
        _emailController.text = data['email'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        final rawDob = data['dob'] ?? "";
        _dobController.text = _formatDate(rawDob);
        _selectedRole = (data['role'] ?? "user").toString().toLowerCase();
      });
    }
  }

  Future<void> _confirmDeleteUser() async {
    final deleteTitleText = context.tr("delete_account_title");
    final deleteText = context.tr("delete");

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _buildDangerDialog(
        title: deleteTitleText,
        isDeleteStyle: true,
        confirmText: deleteText,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirm == true) {
      await _deleteUser();
    }
  }

  Future<void> _confirmSuspendUser() async {
    final suspendAccountText = context.tr("suspend_account");
    final unsuspendAccountText = context.tr("unsuspend_account");
    final suspendMessageText = context.tr("suspend_account_message");
    final unsuspendMessageText = context.tr("unsuspend_account_message");
    final suspendText = context.tr("suspend");
    final unsuspendText = context.tr("unsuspend");

    final doc = await _firestore.collection('users').doc(widget.uid).get();
    if (!mounted) return;

    final data = doc.data();
    final bool isActive = data?["isActive"] ?? true;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _buildDangerDialog(
        title: isActive ? suspendAccountText : unsuspendAccountText,
        message: isActive ? suspendMessageText : unsuspendMessageText,
        isDeleteStyle: false,
        confirmText: isActive ? suspendText : unsuspendText,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirm == true) {
      await _toggleSuspendUser();
    }
  }

  Widget _buildDangerDialog({
    required String title,
    String? message,
    required bool isDeleteStyle,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final dialogBg =
    isDark ? const Color(0xFF566C8A) : const Color(0xFFF3EBDD);

    final dialogTitleColor =
    isDark ? Colors.white : const Color(0xFF3B4B6B);

    final dialogMessageColor =
    isDark ? Colors.white70 : const Color(0xFF3B4B6B);

    final cancelButtonColor =
    isDark ? const Color(0xFF0C1C3D) : const Color(0xFF1D315A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: dialogTitleColor,
                height: 1.2,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: dialogMessageColor,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: isDeleteStyle
                      ? const Color(0xFFEA3730)
                      : const Color(0xFFF5A000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: cancelButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.tr("cancel"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSuspendUser() async {
    final suspendedText = context.tr("account_suspended_successfully");
    final unsuspendedText = context.tr("account_unsuspended");

    try {
      final doc = await _firestore.collection('users').doc(widget.uid).get();
      if (!mounted) return;

      final data = doc.data();
      final bool isActive = data?["isActive"] ?? true;

      await _firestore.collection('users').doc(widget.uid).update({
        "isActive": !isActive,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? suspendedText : unsuspendedText),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteUser() async {
    final deletedText = context.tr("user_deleted_success");

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid == widget.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error_operation_not_allowed'))),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(widget.uid).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(deletedText)),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(mapErrorToKey(e.code)))),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(mapErrorToKeyFromObject(e)))),
      );
    }
  }

  Future<void> _saveChanges() async {
    final updatedText = context.tr("user_updated_success");

    await _firestore.collection('users').doc(widget.uid).update({
      "fullName": _usernameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "dob": _dobController.text.trim(),
      "role": _selectedRole.toLowerCase(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updatedText)),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
      themeProvider.isDarkMode ? const Color(0xFF3F4E67) : bgColor,
      appBar: AppBar(
        backgroundColor:
        themeProvider.isDarkMode ? const Color(0xFF3F4E67) : bgColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: themeProvider.isDarkMode ? Colors.white : darkBlue,
        ),
        centerTitle: true,
        title: Text(
          context.tr("edit_user_info"),
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context.tr("username"),
                    _usernameController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildRoleDropdown()),
              ],
            ),
            _buildField(
              context.tr("email"),
              _emailController,
              readOnly: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context.tr("phone_number"),
                    _phoneController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    context.tr("date_of_birth"),
                    _dobController,
                    readOnly: true,
                    suffix: const Icon(Icons.calendar_today),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 220,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.tr("save_changes"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              context.tr("danger_zone"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(widget.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final isActive = data?["isActive"] ?? true;

                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _confirmSuspendUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.orange : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isActive
                          ? context.tr("suspend_account")
                          : context.tr("unsuspend_account"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _confirmDeleteUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.tr("delete_user"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller, {
        bool obscure = false,
        bool readOnly = false,
        Widget? suffix,
      }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            readOnly: readOnly,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF566C8A)
                  : readOnly
                  ? Colors.grey.shade400
                  : Colors.grey.shade300,
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("role"),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            alignment: AlignmentDirectional.centerStart,
            initialValue: _selectedRole,
            dropdownColor: isDark ? const Color(0xFF566C8A) : Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor:
              isDark ? const Color(0xFF566C8A) : Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            items: [
              DropdownMenuItem(
                value: "user",
                child: Text(context.tr("user")),
              ),
              DropdownMenuItem(
                value: "admin",
                child: Text(context.tr("admin")),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePass extends StatefulWidget {
  const ChangePass({super.key});

  @override
  State<ChangePass> createState() => _ChangePassState();
}

class _ChangePassState extends State<ChangePass> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isLoading = false;

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  static const Color cream = Color(0xffF7F1E8);
  static const Color darkBlue = Color(0xFF0C1C3D);

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      return;
    }

    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();

    if (!isPasswordStrong(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 chars and include upper, lower, number, and special character.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to change password')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: darkBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Image.asset("images/logo.png", height: 40),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 40),

                const Center(
                  child: Column(
                    children: [
                      Text(
                        "Create a\nNew Password",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Enter your new password",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Old Password",
                  style: TextStyle(
                    fontSize: 14,
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _oldPassController,
                  obscureText: !_showOld,
                  decoration: _inputDecoration(
                    "Enter old password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showOld
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: darkBlue,
                      ),
                      onPressed: () {
                        setState(() => _showOld = !_showOld);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your old password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  "New Password",
                  style: TextStyle(
                    fontSize: 14,
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPassController,
                  obscureText: !_showNew,
                  decoration: _inputDecoration(
                    "Enter new password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: darkBlue,
                      ),
                      onPressed: () {
                        setState(() => _showNew = !_showNew);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (!isPasswordStrong(value)) {
                      return 'Must be 8+ chars, include upper, lower, number, and special symbol';
                    }
                    if (value.trim() ==
                        _oldPassController.text.trim()) {
                      return 'New password must be different from old password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontSize: 14,
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: !_showConfirm,
                  decoration: _inputDecoration(
                    "Confirm your password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: darkBlue,
                      ),
                      onPressed: () {
                        setState(() => _showConfirm = !_showConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value.trim() !=
                        _newPassController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _changePassword,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBlue),
      ),
    );
  }
}

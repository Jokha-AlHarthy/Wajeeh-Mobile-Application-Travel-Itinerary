import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_localizations.dart';
import '../localization/error_mapper.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('no_logged_in_user'))));
      return;
    }

    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();

    if (!isPasswordStrong(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('password_strength_error'))),
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

// ✅ Update Firestore FIRST
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        "forcePasswordChange": false,
      });

// ✅ Get user role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc['role'];

// ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('password_changed_success'))),
      );

// ✅ Navigate based on role (IMPORTANT FIX)
      Navigator.pushNamedAndRemoveUntil(
        context,
        role == 'admin' ? '/adminDashboard' : '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(mapErrorToKey(e.code)))),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('something_went_wrong'))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }


  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      icon: Icon(Icons.arrow_back, color: accentColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Image.asset("images/logo.png", height: 40),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 40),

                Center(
                  child: Column(
                    children: [
                      Text(
                        context.tr('create_new_password'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('enter_new_password'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF89B0D8)
                              : theme.textTheme.bodySmall?.color ??
                                    Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  context.tr('old_password'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF89B0D8)
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _oldPassController,
                  obscureText: !_showOld,
                  style: const TextStyle(color: Color(0xff1A2B49)),
                  decoration: _inputDecoration(
                    context,
                    context.tr('enter_old_password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showOld ? Icons.visibility_off : Icons.visibility,
                        color: accentColor,
                      ),
                      onPressed: () {
                        setState(() => _showOld = !_showOld);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('enter_old_password_error');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                Text(
                  context.tr('new_password'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF89B0D8)
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPassController,
                  obscureText: !_showNew,
                  style: const TextStyle(color: Color(0xff1A2B49)),
                  decoration: _inputDecoration(
                    context,
                    context.tr('enter_new_password_hint'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNew ? Icons.visibility_off : Icons.visibility,
                        color: accentColor,
                      ),
                      onPressed: () {
                        setState(() => _showNew = !_showNew);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('enter_new_password_error');
                    }
                    if (!isPasswordStrong(value)) {
                      return context.tr('password_rules_short');
                    }
                    if (value.trim() == _oldPassController.text.trim()) {
                      return context.tr('new_password_must_differ');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                Text(
                  context.tr('confirm_password'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF89B0D8)
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: !_showConfirm,
                  style: const TextStyle(color: Color(0xff1A2B49)),
                  decoration: _inputDecoration(
                    context,
                    context.tr('confirm_password_hint'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility_off : Icons.visibility,
                        color: accentColor,
                      ),
                      onPressed: () {
                        setState(() => _showConfirm = !_showConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('confirm_password_error');
                    }
                    if (value.trim() != _newPassController.text.trim()) {
                      return context.tr('passwords_do_not_match');
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
                      backgroundColor: accentColor,
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
                        : Text(
                            context.tr('save'),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xff1A2B49)
                                  : Colors.white,
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

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint, {
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff8A8A8A)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}

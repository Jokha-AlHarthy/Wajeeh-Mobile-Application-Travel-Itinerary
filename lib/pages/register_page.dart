import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final phone = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    phone.dispose();
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xfff7f1e8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("images/logo.png", height: 150),

              const SizedBox(height: 25),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sign up to access your trips",
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              CustomTextField(
                hint: "Full Name",
                controller: fullName,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 12),

              CustomTextField(
                hint: "Email",
                controller: email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),

              const SizedBox(height: 12),

              CustomTextField(
                hint: "Phone number",
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: Icons.phone_outlined,
              ),

              const SizedBox(height: 12),

              // ⭐ PASSWORD WITH EYE ICON
              CustomTextField(
                hint: "Password",
                controller: password,
                obscure: !showPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Color(0xFF0C1C3D),
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ⭐ CONFIRM PASSWORD WITH EYE ICON
              CustomTextField(
                hint: "Confirm password",
                controller: confirmPassword,
                obscure: !showConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Color(0xFF0C1C3D),
                  ),
                  onPressed: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, "/login"),
                  child: const Text(
                    "Already have account? Log in",
                    style: TextStyle(
                      color: Color(0xFF0C1C3D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SIGN UP BUTTON (unchanged)
              SizedBox(
                width: 155,
                height: 55,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    // SAME VALIDATIONS…
                    if (password.text.trim() !=
                        confirmPassword.text.trim()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Passwords do not match")),
                      );
                      return;
                    }

                    if (fullName.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Please enter your full name")),
                      );
                      return;
                    }

                    if (email.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Please enter your email address")),
                      );
                      return;
                    }

                    if (phone.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Please enter your phone number")),
                      );
                      return;
                    }

                    if (!isPasswordStrong(password.text.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Password must include uppercase, lowercase, number, special character and be at least 8 characters.",
                          ),
                        ),
                      );
                      return;
                    }

                    final ok = await auth.register(
                      email: email.text.trim(),
                      password: password.text.trim(),
                      fullName: fullName.text.trim(),
                      phone: phone.text.trim(),
                    );

                    if (!mounted) return;

                    if (ok) {
                      Navigator.pushReplacementNamed(
                        context,
                        "/otp",
                        arguments: email.text.trim(),
                      );
                    } else if (auth.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(auth.error!)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C1C3D),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Sign Up",
                    style:
                    TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                      child:
                      Container(height: 1, color: Colors.grey.shade400)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "or sign up with",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                      child:
                      Container(height: 1, color: Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: auth.isLoading
                    ? null
                    : () async {
                  final ok = await auth.googleLogin();
                  if (ok) {
                    Navigator.pushReplacementNamed(
                      context,
                      "/otp",
                      arguments: auth.otpEmail,
                    );
                  }
                },
                child: Image.asset(
                  "images/google.png",
                  height: 35,
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

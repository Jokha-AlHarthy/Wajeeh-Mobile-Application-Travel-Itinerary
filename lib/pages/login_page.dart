import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool isValidEmail(String value) {
    final regex = RegExp(
        r"^[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9.-]{1,255}\.[A-Za-z]{2,10}$");
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffF7F1E8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("images/logo.png", height: 170),
              const SizedBox(height: 40),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Log in to access your trips",
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                hint: "Password",
                controller: password,
                obscure: !showPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF0C1C3D),
                  ),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, "/forgot"),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFF0C1C3D),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: 155,
                height: 55,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final mail = email.text.trim();
                    final pass = password.text.trim();
                    if (mail.isEmpty && pass.isEmpty) {
                      showMessage(
                          "Please enter all required fields");
                      return;
                    }

                    if (mail.isEmpty) {
                      showMessage(
                          "Please enter your email address");
                      return;
                    }

                    if (!isValidEmail(mail)) {
                      showMessage("Invalid Credentials");
                      return;
                    }

                    if (pass.isEmpty) {
                      showMessage(
                          "Please enter your password");
                      return;
                    }

                    final ok = await auth.login(mail, pass);

                    if (!mounted) return;

                    if (ok) {
                      if (auth.isAdmin) {
                        Navigator.pushReplacementNamed(
                            context, "/adminHome");
                      } else {
                        Navigator.pushReplacementNamed(
                            context, "/home");
                      }
                    } else {
                      showMessage("Invalid Credentials");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF0C1C3D),
                      width: 2,
                    ),
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
                      color: Color(0xFF0C1C3D),
                    ),
                  )
                      : const Text(
                    "Log in",
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF0C1C3D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 1,
                          color: Colors.grey.shade400)),
                  const Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or"),
                  ),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                "Login using",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0C1C3D),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: auth.isLoading
                    ? null
                    : () async {
                  final ok =
                  await auth.googleLogin();
                  if (!mounted) return;

                  if (ok) {
                    Navigator.pushReplacementNamed(
                        context, "/home");
                  } else {
                    showMessage("Invalid Credentials");
                  }
                },
                child: Image.asset(
                  "images/google.png",
                  height: 35,
                ),
              ),

              const SizedBox(height: 20),

              TextButton(onPressed: () =>Navigator.pushReplacementNamed(context, "/register"),
                child: const Text(
                  "Create a new account",
                  style: TextStyle(
                    color: Color(0xFF0C1C3D),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

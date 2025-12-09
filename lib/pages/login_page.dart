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

              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Log in to access your trips",
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 5),

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

              const SizedBox(height: 5),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/forgot"),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFF0C1C3D),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              SizedBox(
                width: 155,
                height: 55,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final ok = await auth.login(
                      email.text.trim(),
                      password.text.trim(),
                    );

                    if (!mounted) return;
                    if (ok) {
                      if (auth.isAdmin) {
                        Navigator.pushReplacementNamed(
                            context, "/adminHome");
                      } else {
                        Navigator.pushReplacementNamed(
                            context, "/home");
                      }
                    } else if (auth.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(auth.error!)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF0C1C3D),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
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
                    child: Container(height: 1, color: Colors.grey.shade400),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or"),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade400),
                  ),
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
                  final ok = await auth.googleLogin();
                  if (!mounted) return;
                  if (ok) {
                    Navigator.pushReplacementNamed(context, "/home");
                  } else if (auth.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.error!)),
                    );
                  }
                },
                child: Image.asset("images/google.png", height: 35),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, "/register"),
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

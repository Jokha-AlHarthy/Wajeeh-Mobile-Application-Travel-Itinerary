import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_text_field.dart';
import '../localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChangePass.dart';
import '../providers/auth_provider.dart' as myAuth;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool isValidEmail(String value) {
    final regex = RegExp(
      r"^[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9.-]{1,255}\.[A-Za-z]{2,10}$",
    );
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<myAuth.AuthProvider>(context);

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
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('login_subtitle'),
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              CustomTextField(
                hint: context.tr('email'),
                controller: email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),

              const SizedBox(height: 12),

              CustomTextField(
                hint: context.tr('password'),
                controller: password,
                obscure: !showPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF0C1C3D),
                  ),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/forgot"),
                  child: Text(
                    context.tr('forgot_password_cta'),
                    style: const TextStyle(color: Color(0xFF0C1C3D), fontSize: 13),
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
                      showMessage(context.tr('enter_all_required_fields'));
                      return;
                    }

                    if (mail.isEmpty) {
                      showMessage(context.tr('enter_email_address'));
                      return;
                    }

                    if (!isValidEmail(mail)) {
                      showMessage(context.tr('invalid_credentials'));
                      return;
                    }

                    if (pass.isEmpty) {
                      showMessage(context.tr('enter_password'));
                      return;
                    }

                    final ok = await auth.login(mail, pass);

                    if (!mounted) return;

                    if (!ok) {
                      if (auth.error == 'account_suspended') {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.tr('account_suspended_title')),
                            content: Text(context.tr('account_suspended')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      showMessage(
                        auth.error != null
                            ? context.tr(auth.error!)
                            : context.tr('invalid_credentials'),
                      );
                      return;
                    }

                    final user = FirebaseAuth.instance.currentUser;

                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .get();

                    if (!mounted) return;

                    final data = doc.data();

                    if (data?['forcePasswordChange'] == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePass(),
                        ),
                      );
                      return;
                    }

                    if (auth.isAdmin) {
                      Navigator.pushReplacementNamed(context, "/adminHome");
                    } else {
                      Navigator.pushReplacementNamed(context, "/home");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0C1C3D), width: 2),
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
                      : Text(
                    context.tr('login'),
                    style: const TextStyle(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(context.tr('or')),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.grey.shade400),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                context.tr('login_using'),
                style: const TextStyle(fontSize: 15, color: Color(0xFF0C1C3D)),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: auth.isLoading
                        ? null
                        : () async {
                      final ok = await auth.googleLogin();
                      if (!mounted) return;

                      if (!ok) {
                        if (auth.error == 'account_suspended') {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              title: Text(context.tr('account_suspended_title')),
                              content: Text(context.tr('account_suspended')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        showMessage(
                          auth.error != null
                              ? context.tr(auth.error!)
                              : context.tr('invalid_credentials'),
                        );
                        return;
                      }

                      Navigator.pushReplacementNamed(context, "/home");
                    },
                    child: Image.asset("images/google.png", height: 35),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: auth.isLoading
                        ? null
                        : () async {
                      final ok = await auth.twitterLogin();
                      if (!mounted) return;

                      if (!ok) {
                        if (auth.error == 'account_suspended') {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              title: Text(context.tr('account_suspended_title')),
                              content: Text(context.tr('account_suspended')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        showMessage(
                          auth.error != null
                              ? context.tr(auth.error!)
                              : context.tr('invalid_credentials'),
                        );
                        return;
                      }

                      Navigator.pushReplacementNamed(context, "/home");
                    },
                    child: Image.asset("images/twitter.png", height: 35),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, "/register"),
                child: Text(
                  context.tr('create_new_account'),
                  style: const TextStyle(color: Color(0xFF0C1C3D), fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  const email = "teamwajeeh@gmail.com";
                  try {
                    final mailtoUri = Uri.parse("mailto:$email");
                    await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    try {
                      final gmailUri = Uri.parse(
                        "https://mail.google.com/mail/?view=cm&to=$email",
                      );
                      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(context.tr('contact_us')),
                          content: Text(
                            "${context.tr('no_gmail_app_copy_email')}\n\n$email",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(context.tr('cancel')),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: email));
                                Navigator.pop(ctx);
                                showMessage(context.tr('gmail_copied'));
                              },
                              child: Text(context.tr('copy_gmail')),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF0C1C3D)),
                label: Text(
                  context.tr('contact_us'),
                  style: const TextStyle(color: Color(0xFF0C1C3D), fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

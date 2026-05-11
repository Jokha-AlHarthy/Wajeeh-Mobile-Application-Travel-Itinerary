import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../localization/app_localizations.dart';

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

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool isValidFullName(String name) {
    final regex =
    RegExp(r"^[A-Za-z]{2,30}(?:[ '-][A-Za-z]{2,30})+$");
    return regex.hasMatch(name);
  }

  bool isValidEmail(String value) {
    final regex = RegExp(
        r"^[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9.-]{1,255}\.[A-Za-z]{2,10}$");
    return regex.hasMatch(value);
  }

  bool isValidPasswordFormat(String pass) {
    final regex = RegExp(
        r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$");
    return regex.hasMatch(pass);
  }

  bool isValidPhone(String number) {
    final regex = RegExp(r"^[79]\d{7}$");
    return regex.hasMatch(number);
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

              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('signup_subtitle'),
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF0C1C3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              CustomTextField(
                hint: context.tr('full_name'),
                controller: fullName,
                prefixIcon: Icons.person_outline,
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
                hint: context.tr('phone_number'),
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                prefixIcon: Icons.phone_outlined,
              ),

              const SizedBox(height: 12),

              CustomTextField(
                hint: context.tr('password'),
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

              const SizedBox(height: 12),

              CustomTextField(
                hint: context.tr('confirm_password'),
                controller: confirmPassword,
                obscure: !showConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF0C1C3D),
                  ),
                  onPressed: () {
                    setState(() =>
                    showConfirmPassword = !showConfirmPassword);
                  },
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, "/login"),
                  child: Text(
                    context.tr('already_have_account_login'),
                    style: const TextStyle(
                      color: Color(0xFF0C1C3D),
                      fontSize: 14,
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
                    final full =
                    fullName.text.trim();
                    final mail =
                    email.text.trim();
                    final tel =
                    phone.text.trim();
                    final pass =
                    password.text.trim();
                    final cPass =
                    confirmPassword.text.trim();

                    if (full.isEmpty &&
                        mail.isEmpty &&
                        tel.isEmpty &&
                        pass.isEmpty &&
                        cPass.isEmpty) {
                      showMessage(context.tr('enter_all_required_fields'));
                      return;
                    }

                    if (full.isEmpty) {
                      showMessage(context.tr('enter_full_name'));
                      return;
                    }
                    if (!isValidFullName(full)) {
                      showMessage(context.tr('enter_valid_full_name'));
                      return;
                    }

                    if (mail.isEmpty) {
                      showMessage(context.tr('enter_email_address'));
                      return;
                    }
                    if (!isValidEmail(mail)) {
                      showMessage(context.tr('enter_valid_email_address'));
                      return;
                    }

                    if (tel.isEmpty) {
                      showMessage(context.tr('enter_phone_number'));
                      return;
                    }
                    if (!isValidPhone(tel)) {
                      showMessage(context.tr('enter_valid_phone_number'));
                      return;
                    }

                    if (pass.isEmpty ||
                        cPass.isEmpty) {
                      showMessage(context.tr('enter_password_and_confirm'));
                      return;
                    }

                    if (!isValidPasswordFormat(pass)) {
                      showMessage(context.tr('password_format_error'));
                      return;
                    }

                    if (pass != cPass) {
                      showMessage(context.tr('passwords_do_not_match'));
                      return;
                    }

                    final ok = await auth.register(
                      email: mail,
                      password: pass,
                      fullName: full,
                      phone: tel,
                    );

                    if (!mounted) return;

                    if (ok) {
                      Navigator.pushReplacementNamed(
                        context,
                        "/otp",
                        arguments: mail,
                      );
                    } else if (auth.error != null) {
                      showMessage(context.tr(auth.error!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF0C1C3D),
                    shape:
                    const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.zero,
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                          context.tr('sign_up'),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 1,
                          color:
                          Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      context.tr('or_sign_up_with'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                      child: Container(
                          height: 1,
                          color:
                          Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: auth.isLoading
                        ? null
                        : () async {
                      final ok = await auth.googleLogin();

                      if (!mounted) return;
                      if (ok) {
                        Navigator.pushReplacementNamed(
                          context,
                          "/otp",
                          arguments: auth.otpEmail,
                        );
                      } else if (auth.error != null) {
                        showMessage(context.tr(auth.error!));
                      }
                    },
                    child: Image.asset(
                      "images/google.png",
                      height: 35,
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: auth.isLoading
                        ? null
                        : () async {
                      final ok = await auth.twitterLogin();

                      if (!mounted) return;
                      if (ok) {
                        if (auth.otpEmail != null && auth.otpEmail!.isNotEmpty) {
                          Navigator.pushReplacementNamed(
                            context,
                            "/otp",
                            arguments: auth.otpEmail,
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, "/home");
                        }
                      } else if (auth.error != null) {
                        showMessage(context.tr(auth.error!));
                      }
                    },
                    child: Image.asset(
                      "images/twitter.png",
                      height: 35,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

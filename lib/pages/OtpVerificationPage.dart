import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../localization/app_localizations.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final otp1 = TextEditingController();
  final otp2 = TextEditingController();
  final otp3 = TextEditingController();
  final otp4 = TextEditingController();

  @override
  void dispose() {
    otp1.dispose();
    otp2.dispose();
    otp3.dispose();
    otp4.dispose();
    super.dispose();
  }

  Widget otpBox(TextEditingController c) => Container(
    width: 60,
    height: 60,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF0C1C3D), width: 1.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: c,
      textAlign: TextAlign.center,
      maxLength: 1,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(counterText: "", border: InputBorder.none),
      onChanged: (v) {
        if (v.length == 1) FocusScope.of(context).nextFocus();
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userEmail = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Color(0xfff7f1e8),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Color(0xFF0C1C3D))),
                ],
              ),
              const SizedBox(height: 80),

              Image.asset("images/logo.png", height: 190),

              SizedBox(height: 80),

              Text(context.tr('enter_otp'),
                  style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFF0C1C3D),
                      fontWeight: FontWeight.bold)),

              SizedBox(height: 10),

              Text(
                "${context.tr('otp_sent_to')}\n$userEmail",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF0C1C3D)),
              ),
              SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  otpBox(otp1),
                  otpBox(otp2),
                  otpBox(otp3),
                  otpBox(otp4),
                ],
              ),

              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0C1C3D)),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    final otp = otp1.text + otp2.text + otp3.text + otp4.text;

                    if (otp.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('enter_all_4_numbers'))));
                      return;
                    }

                    final ok = await auth.verifyOtp(otp);

                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            auth.error != null
                                ? context.tr(auth.error!)
                                : context.tr('wrong_otp'),
                          )));
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: SizedBox(
                            width: 330,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4CAF50).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check_circle,
                                        color: Color(0xFF4CAF50), size: 60),
                                  ),

                                  SizedBox(height: 20),

                                  Text(
                                    context.tr('signed_up_successfully'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFF0C1C3D),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  Text(
                                    context.tr('signup_success_subtitle'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  SizedBox(height: 25),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushReplacementNamed(context, "/language");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF0C1C3D),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: Text(
                                        context.tr('continue'),
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: auth.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(context.tr('verify_otp'),
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),

              SizedBox(height: 18),

              GestureDetector(
                onTap: auth.isLoading
                    ? null
                    : () async {
                  final ok = await auth.resendOtp();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? context.tr('otp_resent')
                          : auth.error != null
                              ? context.tr(auth.error!)
                              : context.tr('failed_to_resend'))));
                },
                child: Text(
                  context.tr('resend_code'),
                  style: TextStyle(
                      color: Color(0xFF0C1C3D),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

              Text("Enter OTP",
                  style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFF0C1C3D),
                      fontWeight: FontWeight.bold)),

              SizedBox(height: 10),

              Text(
                "We have sent a 4-digit code to:\n$userEmail",
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
                          SnackBar(content: Text("Enter all 4 numbers")));
                      return;
                    }

                    final ok = await auth.verifyOtp(otp);

                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(auth.error ?? "Wrong OTP")));
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
                                    "You have signed up \nsuccessfully",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFF0C1C3D),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  Text(
                                    "You’re all set! Start exploring & creating your perfect itinerary today",
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
                                        "Continue",
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
                      : Text("Verify OTP",
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
                          ? "OTP resent"
                          : auth.error ?? "Failed to resend")));
                },
                child: Text(
                  "Resend Code",
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

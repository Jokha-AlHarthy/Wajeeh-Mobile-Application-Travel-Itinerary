import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// REGISTER USER
  Future<User?> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;

    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "email": email,
        "fullName": fullName,
        "phone": phone,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    return user;
  }


  /// LOGIN
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// GOOGLE LOGIN
  /// GOOGLE LOGIN
  Future<User?> signInWithGoogle() async {
    final google = GoogleSignIn();

    try {
      await google.signOut();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await google.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final user = userCred.user;

    if (user != null) {
      // 🔥 SAVE TO FIRESTORE (important!)
      await _db.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "email": user.email,
        "fullName": user.displayName ?? "",
        "phone": "",
        "authProvider": "google",       // ← IMPORTANT!
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));        // use merge so it doesn’t overwrite
    }

    return user;
  }



  /// RESET PASSWORD
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  /// Generate 4-digit OTP
  String generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(10000);
    return random.toString().padLeft(4, '0');
  }

  /// Send OTP via EmailJS API
  Future<void> sendOtpEmail(String email, String otp) async {
    const gmailServie = 'service_nih4p2l';
    const utasService = 'service_6vcoa8a';
    const templateId = 'template_s3flqzp';
    const iCloudService = 'service_0qrfdab';
    const userId = 'UEp7gbJPHMwQBO07G';
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

    final domain = email.split('@').last.toLowerCase();
    late String selectedService;

    if (domain == "gmail.com") {
      selectedService = gmailServie;
    } else if (domain == "utas.edu.om") {
      selectedService = utasService;
    } else if (domain == "icloud.com"){
      selectedService = iCloudService;
    } else {
      throw Exception("Unsupported email domain");
    }

    final now = DateTime.now().add(Duration(minutes: 15));
    final timeFormatted = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    await http.post(
      url,
      headers: {
        "origin": "http://localhost",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "service_id": selectedService,
        "template_id": templateId,
        "user_id": userId,
        "template_params": {
          "email": email,
          "passcode": otp,
          "time": timeFormatted,
        },
      }),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool isLoading = false;
  String? error;

  String? _generatedOtp;
  String? _otpEmail;
  String? get otpEmail => _otpEmail;

  /// LOGIN
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.login(email, password);
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// REGISTER + SEND OTP
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = await _auth.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (user == null) throw Exception("Registration failed.");

      _otpEmail = email;

      // generate otp
      _generatedOtp = _auth.generateOtp();

      // send email
      await _auth.sendOtpEmail(email, _generatedOtp!);

      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// RESEND OTP
  Future<bool> resendOtp() async {
    try {
      if (_otpEmail == null) {
        error = "No email found to resend OTP.";
        return false;
      }

      isLoading = true;
      notifyListeners();

      _generatedOtp = _auth.generateOtp();

      await _auth.sendOtpEmail(_otpEmail!, _generatedOtp!);

      return true;
    } catch (e) {
      error = "Failed to resend OTP.";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// OTP VERIFICATION
  Future<bool> verifyOtp(String enteredOtp) async {
    if (_generatedOtp == null) {
      error = "OTP not generated.";
      return false;
    }

    if (enteredOtp.trim() != _generatedOtp) {
      error = "Wrong OTP.";
      return false;
    }

    return true;
  }

  /// GOOGLE LOGIN
  Future<bool> googleLogin() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = await _auth.signInWithGoogle();
      if (user == null) return false;

      _otpEmail = user.email;

      // generate OTP
      _generatedOtp = _auth.generateOtp();

      // send OTP email
      await _auth.sendOtpEmail(_otpEmail!, _generatedOtp!);

      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// RESET PASSWORD
  Future<bool> resetPassword(String email) async {
    try {
      isLoading = true;
      notifyListeners();

      print("🔍 Searching in Firestore for email: $email");

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      print("Firestore docs found: ${query.docs.length}");

      if (query.docs.isEmpty) {
        error = "No account found with this email.";
        return false;
      }

      print("Sending reset email to: $email");
      await _auth.sendPasswordReset(email);

      return true;

    } catch (e) {
      print(" ERROR in resetPassword: $e");
      error = _messageFromError(e);
      return false;

    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  /// LOGOUT
  Future<void> logout() async {
    await _auth.logout();
  }

  String _messageFromError(Object e) {
    if (e is FirebaseAuthException) return e.message ?? e.code;
    return e.toString();
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        "role": "user",
        "isActive": true,
        "createdAt": FieldValue.serverTimestamp(),
        "lastSeen": FieldValue.serverTimestamp(),
        "location": "",
        "gender": "male",
        "dob": null,
        "photoUrl": "",
        "coverUrl": "",
        "isDefaultPhoto": true,
        "isDefaultCover": true,
      }, SetOptions(merge: true));
    }
    return user;
  }

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final google = GoogleSignIn();

    try {
      await google.signOut();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await google.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final existingUser = await _db
        .collection("users")
        .where("email", isEqualTo: googleUser.email)
        .limit(1)
        .get();

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final loginCred = await _auth.signInWithCredential(credential);
    final user = loginCred.user;

    if (user == null) return null;

    if (existingUser.docs.isNotEmpty) {
      return user;
    }

    await _db.collection('users').doc(user.uid).set({
      "uid": user.uid,
      "email": user.email,
      "fullName": user.displayName ?? "",
      "phone": "",
      "authProvider": "google",
      "role": "user",
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
      "lastSeen": FieldValue.serverTimestamp(),
      "location": "",
      "gender": "male",
      "dob": null,
      "photoUrl": "",
      "coverUrl": "",
      "isDefaultPhoto": true,
      "isDefaultCover": true,
    }, SetOptions(merge: true));

    return user;
  }

  Future<User?> signInWithTwitter() async {
    const apiKey = 'jiAjdnEyt7PyKSvGDMxXKSel5';
    const apiSecretKey = '5RAA5f1dULvttuFEpLUxMYgbSXYP0pGeem08rEBTXN6AaFbVXA';
    const redirectURI = 'wajeeh://';

    final twitterLogin = TwitterLogin(
      apiKey: apiKey,
      apiSecretKey: apiSecretKey,
      redirectURI: redirectURI,
    );

    final authResult = await twitterLogin.login();
    if (authResult.status != TwitterLoginStatus.loggedIn) return null;
    if (authResult.authToken == null || authResult.authTokenSecret == null) {
      return null;
    }

    final credential = TwitterAuthProvider.credential(
      accessToken: authResult.authToken!,
      secret: authResult.authTokenSecret!,
    );

    final loginCred = await _auth.signInWithCredential(credential);
    final user = loginCred.user;

    if (user == null) return null;

    final existingUser = await _db.collection("users").doc(user.uid).get();
    if (existingUser.exists) {
      return user;
    }

    await _db.collection('users').doc(user.uid).set({
      "uid": user.uid,
      "email": user.email ?? "",
      "fullName": user.displayName ?? "",
      "phone": "",
      "authProvider": "twitter",
      "role": "user",
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
      "lastSeen": FieldValue.serverTimestamp(),
      "location": "",
      "gender": "male",
      "dob": null,
      "photoUrl": user.photoURL ?? "",
      "coverUrl": "",
      "isDefaultPhoto": user.photoURL == null || user.photoURL!.isEmpty,
      "isDefaultCover": true,
    }, SetOptions(merge: true));

    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  String generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(10000);
    return random.toString().padLeft(4, '0');
  }

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
    } else if (domain == "icloud.com") {
      selectedService = iCloudService;
    } else if (domain.endsWith('.edu')) {
      // Prefer the UTAS/academic service for .edu, but allow fallback.
      selectedService = utasService;
    } else {
      // EmailJS service selection should not block valid recipient domains
      // (e.g. academic .edu). Default to the Gmail service for all others.
      selectedService = gmailServie;
    }

    final now = DateTime.now().add(const Duration(minutes: 15));
    final timeFormatted =
        "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    Future<http.Response> sendWith(String serviceId) {
      return http.post(
        url,
        headers: {
          "origin": "http://localhost",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "service_id": serviceId,
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

    var res = await sendWith(selectedService);
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    // Retry with Gmail service once (common reliable fallback).
    if (selectedService != gmailServie) {
      res = await sendWith(gmailServie);
      if (res.statusCode >= 200 && res.statusCode < 300) return;
    }

    throw Exception('otp-send-failed:${res.statusCode}');
  }

  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
    File? profileImageFile,
    File? coverImageFile,
  }) async {
    String? newPhotoUrl;
    String? newCoverUrl;

    if (profileImageFile != null) {
      final ref = FirebaseStorage.instance.ref("users/$uid/profile.jpg");
      await ref.putFile(profileImageFile);
      newPhotoUrl = await ref.getDownloadURL();
    }

    if (coverImageFile != null) {
      final ref = FirebaseStorage.instance.ref("users/$uid/cover.jpg");
      await ref.putFile(coverImageFile);
      newCoverUrl = await ref.getDownloadURL();
    }

    final merged = <String, dynamic>{
      ...data,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (newPhotoUrl != null) {
      merged["photoUrl"] = newPhotoUrl;
      merged["isDefaultPhoto"] = false;
    }

    if (newCoverUrl != null) {
      merged["coverUrl"] = newCoverUrl;
      merged["isDefaultCover"] = false;
    }

    await _db
        .collection("users")
        .doc(uid)
        .set(merged, SetOptions(merge: true));
  }

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await FirebaseStorage.instance.ref("users/$uid/profile.jpg").delete();
    } catch (_) {}

    await _db.collection("users").doc(uid).set({
      "photoUrl": "",
      "isDefaultPhoto": true,
    }, SetOptions(merge: true));
  }

  Future<void> deleteCoverPhoto(String uid) async {
    try {
      await FirebaseStorage.instance.ref("users/$uid/cover.jpg").delete();
    } catch (_) {}

    await _db.collection("users").doc(uid).set({
      "coverUrl": "",
      "isDefaultCover": true,
    }, SetOptions(merge: true));
  }

  Future<void> setUserActiveStatus({
    required String uid,
    required bool isActive,
  }) async {
    await _db.collection('users').doc(uid).set({
      "isActive": isActive,
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateLastActivity({required String uid}) async {
    await _db.collection('users').doc(uid).set({
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("not-logged-in");
    }

    await _db.collection('users').doc(user.uid).set({
      "location": {
        "latitude": latitude,
        "longitude": longitude,
        "geoPoint": GeoPoint(latitude, longitude),
        "updatedAt": FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
}

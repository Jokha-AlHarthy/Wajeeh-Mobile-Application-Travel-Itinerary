import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/place_category_options.dart';
import '../services/auth_service.dart';
import '../localization/error_mapper.dart';
import '../utils/user_profile_image.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool isLoading = false;
  String? error;

  String? _generatedOtp;
  String? _otpEmail;
  String? get otpEmail => _otpEmail;

  String? fullName;
  String? email;
  String? phone;

  String? role;

  String? locationText;
  double? latitude;
  double? longitude;
  bool get isAdmin => role == 'admin';

  /// True when Firebase has a signed-in user (regular user session).
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  String? photoUrl;
  String? coverUrl;
  String? profilePhotoBase64;
  String? coverPhotoBase64;

  String? location;
  String? gender;
  String? dob;

  bool isDefaultPhoto = true;
  bool isDefaultCover = true;

  /// Place-category filter keys (e.g. `filter_museum`) — aligned with Home filters.
  List<String> preferredInterests = [];

  /// When true, the post-registration preference dialog will not be shown.
  bool preferencePromptShown = true;

  bool hasCompletedPreferences = false;

  Future<List<String>> _interestsFromLatestTrip(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: uid)
          .limit(25)
          .get();
      if (snap.docs.isEmpty) return [];

      DateTime? bestTime;
      List<String> best = [];
      for (final d in snap.docs) {
        final data = d.data();
        final ts = data['createdAt'];
        DateTime? t;
        if (ts is Timestamp) t = ts.toDate();
        if (t != null && (bestTime == null || t.isAfter(bestTime))) {
          bestTime = t;
          final raw = data['interest'];
          if (raw is List) {
            best = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          }
        }
      }
      return best;
    } catch (e) {
      debugPrint('interestsFromLatestTrip: $e');
      return [];
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      error = null;
      isLoading = true;
      notifyListeners();

      await _auth.login(email, password);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = userDoc.data();

        if (data != null && data['isActive'] == false) {
          await _auth.logout();
          error = 'account_suspended';
          return false;
        }

        await _auth.updateLastActivity(uid: user.uid);

        String? token = await FirebaseMessaging.instance.getToken();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          "deviceToken": token,
        }, SetOptions(merge: true));
      }

      await loadUserProfile();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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

      if (user == null) throw Exception("registration-failed");

      _otpEmail = email;
      _generatedOtp = _auth.generateOtp();
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

  Future<bool> resendOtp() async {
    try {
      if (_otpEmail == null) {
        error = mapErrorToKey('no-otp-email');
        return false;
      }

      isLoading = true;
      notifyListeners();

      _generatedOtp = _auth.generateOtp();
      await _auth.sendOtpEmail(_otpEmail!, _generatedOtp!);

      return true;
    } catch (e) {
      error = mapErrorToKey('resend-otp-failed');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String enteredOtp) async {
    if (_generatedOtp == null) {
      error = mapErrorToKey('otp-not-generated');
      return false;
    }
    if (enteredOtp.trim() != _generatedOtp) {
      error = mapErrorToKey('wrong-otp');
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _auth.updateLastActivity(uid: user.uid);
    }

    await loadUserProfile();
    return true;
  }

  Future<bool> googleLogin() async {
    try {
      error = null;
      isLoading = true;
      notifyListeners();

      final user = await _auth.signInWithGoogle();
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null && data['isActive'] == false) {
        await _auth.logout();
        error = 'account_suspended';
        return false;
      }

      String? token = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "deviceToken": token,
        "lastSeen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _otpEmail = user.email;
      if (_otpEmail != null && _otpEmail!.isNotEmpty) {
        _generatedOtp = _auth.generateOtp();
        await _auth.sendOtpEmail(_otpEmail!, _generatedOtp!);
      }

      await loadUserProfile();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> twitterLogin() async {
    try {
      error = null;
      isLoading = true;
      notifyListeners();

      final user = await _auth.signInWithTwitter();
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null && data['isActive'] == false) {
        await _auth.logout();
        error = 'account_suspended';
        return false;
      }

      String? token = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "deviceToken": token,
        "lastSeen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      String? emailForOtp = user.email;
      if (emailForOtp == null || emailForOtp.isEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          emailForOtp = data?['email']?.toString();
        }
      }

      if (emailForOtp != null && emailForOtp.isNotEmpty) {
        _otpEmail = emailForOtp;
        _generatedOtp = _auth.generateOtp();
        await _auth.sendOtpEmail(_otpEmail!, _generatedOtp!);
      }

      await loadUserProfile();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading = true;
      notifyListeners();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        error = mapErrorToKey('no-account-found');
        return false;
      }

      await _auth.sendPasswordReset(email);
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        fullName =
            (data['fullName'] ?? data['username'] ?? user.displayName ?? '')
                .toString();

        email = (data['email'] ?? user.email ?? '').toString();
        phone = (data['phone'] ?? '').toString();
        role = (data['role'] ?? '').toString();

        photoUrl = (data['photoUrl'] ?? '').toString();
        coverUrl = (data['coverUrl'] ?? '').toString();
        profilePhotoBase64 = (data['profilePhotoBase64'] ?? '').toString();
        coverPhotoBase64 = (data['coverPhotoBase64'] ?? '').toString();
        gender = (data['gender'] ?? 'male').toString();

        final rawDob = data['dob'];
        dob = rawDob == null ? null : rawDob.toString();

        isDefaultPhoto = !hasCustomProfileImage(
          photoUrl: photoUrl,
          profilePhotoBase64: profilePhotoBase64,
        );
        isDefaultCover = !hasCustomCoverImage(
          coverUrl: coverUrl,
          coverPhotoBase64: coverPhotoBase64,
        );

        if (data['location'] != null &&
            data['location'] is Map &&
            (data['location'] as Map)['placeName'] != null) {
          locationText = (data['location'] as Map)['placeName'].toString();
        } else {
          locationText = null;
        }

        preferencePromptShown = data['preferencePromptShown'] == true;
        hasCompletedPreferences = data['hasCompletedPreferences'] == true;

        preferredInterests = [];
        final pi = data['preferredInterests'];
        if (pi is List) {
          preferredInterests = normalizePreferenceInterestKeys(
            pi.map((e) => e.toString()),
          );
        }
        if (preferredInterests.isEmpty) {
          final tripInterests = await _interestsFromLatestTrip(user.uid);
          preferredInterests = normalizePreferenceInterestKeys(tripInterests);
        }
      } else {
        fullName = user.displayName ?? '';
        email = user.email ?? '';
        phone = '';
        role = null;

        photoUrl = '';
        coverUrl = '';
        profilePhotoBase64 = '';
        coverPhotoBase64 = '';
        gender = 'male';
        dob = null;

        isDefaultPhoto = true;
        isDefaultCover = true;

        locationText = null;
        preferencePromptShown = true;
        hasCompletedPreferences = false;
        preferredInterests = [];
        preferredInterests = normalizePreferenceInterestKeys(
          await _interestsFromLatestTrip(user.uid),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('loadUserProfile error: $e');
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String location,
    required String gender,
    String? dob,
    File? profileImageFile,
    File? coverImageFile,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = mapErrorToKey('not-logged-in');
        return false;
      }

      final full = "${firstName.trim()} ${lastName.trim()}".trim();

      await _auth.updateUserProfile(
        uid: user.uid,
        data: {
          "fullName": full,
          "email": email.trim(),
          "location": location.trim(),
          "gender": gender,
          "dob": dob,
        },
        profileImageFile: profileImageFile,
        coverImageFile: coverImageFile,
      );

      await loadUserProfile();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfilePhoto() async {
    if (isDefaultPhoto) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _auth.deleteProfilePhoto(user.uid);
    await loadUserProfile();
  }

  Future<void> deleteCoverPhoto() async {
    if (isDefaultCover) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _auth.deleteCoverPhoto(user.uid);
    await loadUserProfile();
  }

  bool get shouldShowPreferencePrompt =>
      !preferencePromptShown && !hasCompletedPreferences;

  Future<void> markPreferencePromptSkipped() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    preferencePromptShown = true;
    notifyListeners();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'preferencePromptShown': true},
      SetOptions(merge: true),
    );
  }

  Future<void> markPreferencesCompleted({
    required List<String> interestKeys,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final normalized = normalizePreferenceInterestKeys(interestKeys);
    preferredInterests = normalized;
    preferencePromptShown = true;
    hasCompletedPreferences = true;
    notifyListeners();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'preferredInterests': normalized,
        'preferencePromptShown': true,
        'hasCompletedPreferences': true,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveLocationWithName(double lat, double lng, String placeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("not-logged-in");

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      "location": {
        "latitude": lat,
        "longitude": lng,
        "placeName": placeName,
        "updatedAt": FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    locationText = placeName;
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  Future<void> saveLocation(double lat, double lng) async {
    await _auth.saveUserLocation(latitude: lat, longitude: lng);
  }

  Future<void> logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "lastSeen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _auth.logout();
  }

  String _messageFromError(Object e) {
    return mapErrorToKeyFromObject(e);
  }
}

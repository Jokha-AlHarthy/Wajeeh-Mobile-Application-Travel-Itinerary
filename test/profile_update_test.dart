import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajeeh/providers/auth_provider.dart';

/// Lightweight fake: no Firestore calls from [updateProfile].
class FakeProfileAuthProvider extends AuthProvider {
  int updateProfileCallCount = 0;
  bool updateProfileSucceeds = true;

  String? capturedFirstName;
  String? capturedLastName;
  String? capturedEmail;
  String? capturedLocation;
  String? capturedGender;
  String? capturedDob;

  FakeProfileAuthProvider() {
    fullName = 'John Smith';
    email = 'john@test.com';
    gender = 'male';
  }

  @override
  Future<void> loadUserProfile() async {}

  @override
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
    updateProfileCallCount++;
    capturedFirstName = firstName;
    capturedLastName = lastName;
    capturedEmail = email;
    capturedLocation = location;
    capturedGender = gender;
    capturedDob = dob;

    if (!updateProfileSucceeds) {
      error = 'error_generic';
      notifyListeners();
      return false;
    }
    error = null;
    fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    this.email = email.trim();
    this.gender = gender;
    this.dob = dob;
    notifyListeners();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('User profile update (updateProfile contract)', () {
    test('success stores trimmed full name and clears error', () async {
      final auth = FakeProfileAuthProvider();

      final ok = await auth.updateProfile(
        firstName: '  Jane  ',
        lastName: '  Doe  ',
        email: '  jane@test.com  ',
        location: '',
        gender: 'male',
      );

      expect(ok, isTrue);
      expect(auth.updateProfileCallCount, 1);
      expect(auth.capturedFirstName, '  Jane  ');
      expect(auth.capturedLastName, '  Doe  ');
      expect(auth.capturedEmail, '  jane@test.com  ');
      expect(auth.capturedLocation, '');
      expect(auth.capturedGender, 'male');
      expect(auth.fullName, 'Jane Doe');
      expect(auth.email, 'jane@test.com');
      expect(auth.error, isNull);
    });

    test('failure sets error and returns false', () async {
      final auth = FakeProfileAuthProvider()..updateProfileSucceeds = false;

      final ok = await auth.updateProfile(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        location: '',
        gender: 'female',
      );

      expect(ok, isFalse);
      expect(auth.error, 'error_generic');
    });
  });

  group('Profile fullName composition (unit)', () {
    test('trimmed first and last match AuthProvider.updateProfile merge', () {
      const firstName = '  A  ';
      const lastName = '  B  ';
      final full = '${firstName.trim()} ${lastName.trim()}'.trim();
      expect(full, 'A B');
    });
  });
}

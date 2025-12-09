import 'package:flutter_test/flutter_test.dart';
import 'package:wajeeh/validators.dart';

void main() {
  group('Form Validators', () {

    // Testing the full name field
    group('validateFullName', () {
      test('should return error if full name is empty', () {
        expect(FormValidators.validateFullName(''), 'Please enter your full name');
      });

      test('should return error if full name is null', () {
        expect(FormValidators.validateFullName(null), 'Please enter your full name');
      });

      test('should return error if full name is only numbers', () {
        expect(FormValidators.validateFullName('12345'), 'Full name cannot be just numbers');
      });

      test('should return null if full name is valid string', () {
        expect(FormValidators.validateFullName('Jokha Al-Harthy'), null);
      });

      test('should return null if full name contains letters and numbers', () {
        expect(FormValidators.validateFullName('Jokha 123'), null);
      });
    });

    //Testing the email field
    group('validateEmail', () {
      test('should return error if email is empty', () {
        expect(FormValidators.validateEmail(''), 'Please enter your Email');
      });

      test('should return error if email format is invalid', () {
        expect(FormValidators.validateEmail('wrongemail'), 'Please enter a valid Email');
      });

      test('should return null if email is valid', () {
        expect(FormValidators.validateEmail('test@example.com'), null);
      });
    });

    //Testing the phone number field
    group('validatePhone', () {
      test('should return error if phone is empty', () {
        expect(FormValidators.validatePhone(''), 'Please enter your Phone Number');
      });

      test('should return error if phone length is incorrect', () {
        expect(FormValidators.validatePhone('1234'), 'Phone Number must be 8 or 9 digits');
        expect(FormValidators.validatePhone('1234567890'), 'Phone Number must be 8 or 9 digits');
      });

      test('should return null if phone is valid 8 or 9 digits', () {
        expect(FormValidators.validatePhone('12345678'), null);
        expect(FormValidators.validatePhone('123456789'), null);
      });
    });

  });
}

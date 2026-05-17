import 'package:firebase_auth/firebase_auth.dart';

String mapErrorToKey(String code) {
  switch (code) {
    case 'user-not-found':
      return 'error_user_not_found';
    case 'wrong-password':
      return 'error_wrong_password';
    case 'email-already-in-use':
      return 'error_email_in_use';
    case 'invalid-email':
      return 'error_invalid_email';
    case 'weak-password':
      return 'error_weak_password';
    case 'too-many-requests':
      return 'error_too_many_requests';
    case 'network-request-failed':
      return 'error_network';
    case 'invalid-credential':
      return 'error_invalid_credentials';
    case 'user-disabled':
      return 'error_user_disabled';
    case 'operation-not-allowed':
      return 'error_operation_not_allowed';
    case 'requires-recent-login':
      return 'error_requires_recent_login';
    case 'account-exists-with-different-credential':
      return 'error_account_exists_different_credential';
    case 'credential-already-in-use':
      return 'error_credential_already_in_use';
    case 'unsupported-email-domain':
      return 'error_unsupported_email_domain';
    case 'no-account-found':
      return 'error_no_account_found';
    case 'registration-failed':
      return 'error_registration_failed';
    case 'otp-not-generated':
      return 'error_otp_not_generated';
    case 'wrong-otp':
      return 'error_wrong_otp';
    case 'resend-otp-failed':
      return 'error_resend_otp_failed';
    case 'otp-send-failed':
      return 'error_otp_send_failed';
    case 'no-otp-email':
      return 'error_no_otp_email';
    case 'not-logged-in':
      return 'error_not_logged_in';
    case 'permission-denied':
      return 'error_operation_not_allowed';
    default:
      return 'error_generic';
  }
}

String mapErrorToKeyFromObject(Object error) {
  if (error is FirebaseAuthException) {
    return mapErrorToKey(error.code);
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('user-not-found')) return mapErrorToKey('user-not-found');
  if (raw.contains('wrong-password')) return mapErrorToKey('wrong-password');
  if (raw.contains('email-already-in-use')) {
    return mapErrorToKey('email-already-in-use');
  }
  if (raw.contains('invalid-email')) return mapErrorToKey('invalid-email');
  if (raw.contains('weak-password')) return mapErrorToKey('weak-password');
  if (raw.contains('too-many-requests')) {
    return mapErrorToKey('too-many-requests');
  }
  if (raw.contains('network-request-failed')) {
    return mapErrorToKey('network-request-failed');
  }
  if (raw.contains('unsupported email domain')) {
    return mapErrorToKey('unsupported-email-domain');
  }
  if (raw.contains('otp-send-failed')) return mapErrorToKey('otp-send-failed');
  if (raw.contains('not logged in')) return mapErrorToKey('not-logged-in');

  return mapErrorToKey('generic');
}

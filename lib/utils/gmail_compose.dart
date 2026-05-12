import 'package:flutter/foundation.dart';

import 'gmail_send_impl_stub.dart'
    if (dart.library.io) 'gmail_send_impl_io.dart' as gmail_impl;

/// Opens the **Gmail app** with compose fields prefilled (no browser / generic mail).
///
/// Returns `false` if Gmail is not available (e.g. web, or app not installed).
Future<bool> openGmailCompose({
  required String subject,
  required String body,
}) async {
  if (kIsWeb) {
    return false;
  }
  return gmail_impl.openGmailInNativeAppImpl(subject, body);
}

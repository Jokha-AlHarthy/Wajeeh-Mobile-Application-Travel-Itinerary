import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Gmail app (not the browser). Android uses an explicit intent;
/// iOS uses the `googlegmail` URL scheme. Android falls back to the scheme if
/// the intent cannot be resolved.
Future<bool> openGmailInNativeAppImpl(String subject, String body) async {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      package: 'com.google.android.gm',
      type: 'text/plain',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      arguments: <String, dynamic>{
        'android.intent.extra.SUBJECT': subject,
        'android.intent.extra.TEXT': body,
      },
    );

    try {
      final can = await intent.canResolveActivity();
      if (can == true) {
        await intent.launch();
        return true;
      }
    } catch (_) {}
  }

  if (Platform.isIOS || Platform.isAndroid) {
    final gmailUri = Uri(
      scheme: 'googlegmail',
      host: 'co',
      queryParameters: <String, String>{
        'to': '',
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(gmailUri)) {
        final ok = await launchUrl(
          gmailUri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return true;
      }
    } catch (_) {}
  }

  return false;
}

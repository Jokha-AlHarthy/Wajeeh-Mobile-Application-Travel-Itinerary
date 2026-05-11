import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Firebase Messaging
  Future<void> init() async {
    await _messaging.requestPermission();

    String? token = await _messaging.getToken();

    print("DEVICE TOKEN: $token");
  }

  /// Add Notification to Firestore
  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    DateTime? scheduledAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": user.uid,
      "title": title,
      "message": message,
      "type": type,
      "isRead": false,
      "createdAt": Timestamp.now(),
      "scheduledAt":
      scheduledAt != null ? Timestamp.fromDate(scheduledAt) : null,
    });
  }
}

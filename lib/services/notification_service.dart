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
    String? tripId,
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
      "tripId": tripId,
    });
  }

  static Future<void> addNotificationForUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    DateTime? scheduledAt,
    String? tripId,
  }) async {
    try {
      print("TRY CREATE SHARED NOTIFICATION FOR USER: $userId");

      final doc = await FirebaseFirestore.instance.collection("notifications").add({
        "userId": userId,
        "title": title,
        "message": message,
        "type": type,
        "isRead": false,
        "createdAt": Timestamp.now(),
        "scheduledAt":
        scheduledAt != null ? Timestamp.fromDate(scheduledAt) : null,
        "tripId": tripId,
      });

      print("SHARED NOTIFICATION CREATED: ${doc.id}");
    } catch (e) {
      print("FAILED TO CREATE SHARED NOTIFICATION: $e");
    }
  }
}



import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {

    await _messaging.requestPermission();

    String? token = await _messaging.getToken();
    print("DEVICE TOKEN: $token");
  }
}
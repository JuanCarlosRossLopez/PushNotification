import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log(
    'BG message: ${message.messageId} title=${message.notification?.title} data=${message.data}',
  );
}

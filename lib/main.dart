import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/notifications/notification_service.dart';
import 'firebase_messaging_handler.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.init();
  await _ensureFcmDefaultChannel();
  await _requestPermissions();
  _configureForegroundHandlers(notificationService);
  runApp(const ProviderScope(child: TurismoApp()));
}

Future<void> _requestPermissions() async {
  final messaging = FirebaseMessaging.instance;
  if (Platform.isIOS) {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    final androidImpl = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }
}

void _configureForegroundHandlers(NotificationService local) {
  FirebaseMessaging.onMessage.listen((message) {
    final title = message.notification?.title ?? 'Mensaje';
    final body = message.notification?.body ?? 'Tienes una notificación';
    // Mostrar con notificaciones locales en foreground
    local.showLocal(title: title, body: body);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    log('onMessageOpenedApp: ${message.data}');
    // TO DO Navegar a pantalla con datos deep link
  });
}

Future<void> _ensureFcmDefaultChannel() async {
  const channel = AndroidNotificationChannel(
    'default_channel_fcm',
    'General (FCM)',
    description: 'Canal por defecto para mensajes FCM',
    importance: Importance.high,
    playSound: true,
  );
  final plugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await plugin?.createNotificationChannel(channel);

  // Suscripción
  await FirebaseMessaging.instance.subscribeToTopic('ofertas');
  // Token del dispositivo (para envíos dirigidos)
  final token = await FirebaseMessaging.instance.getToken();
  print('FCM token: $token');
}

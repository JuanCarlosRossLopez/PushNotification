import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Asegúrate de que estas rutas sean correctas en tu proyecto
import 'core/notifications/notification_service.dart';
import 'firebase_messaging_handler.dart'; // Contiene firebaseMessagingBackgroundHandler
import 'app.dart'; // Contiene el widget principal TurismoApp

/// Función principal de la aplicación.
/// Inicializa Firebase, el servicio de notificaciones locales,
/// configura el canal por defecto y solicita permisos.
Future<void> main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa Firebase
  await Firebase.initializeApp();

  // 2. Configura el handler para mensajes en segundo plano (Background)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 3. Inicializa el servicio de notificaciones locales
  final notificationService = NotificationService();
  await notificationService.init();

  // 4. Asegura la creación del canal de notificaciones por defecto de FCM
  await _ensureFcmDefaultChannel();

  // 5. Solicita los permisos de notificaciones
  await _requestPermissions();

  // 6. Configura los handlers para mensajes en primer plano (Foreground)
  _configureForegroundHandlers(notificationService);

  // 7. Ejecuta la aplicación
  runApp(const ProviderScope(child: TurismoApp()));
}

/// Solicita los permisos de notificaciones al usuario, dependiendo de la plataforma.
Future<void> _requestPermissions() async {
  final messaging = FirebaseMessaging.instance;

  if (Platform.isIOS) {
    // Permisos para iOS
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    // Permiso de POST_NOTIFICATIONS para Android 13 (API 33) y superior
    final androidImpl = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }
}

/// Configura los listeners para manejar mensajes de FCM cuando la aplicación
/// está en primer plano (Foreground) o cuando se abre desde una notificación.
void _configureForegroundHandlers(NotificationService local) {
  FirebaseMessaging.onMessage.listen((message) {
    final title = message.notification?.title ?? 'Mensaje';
    final body = message.notification?.body ?? 'Tienes una notificación';

    final imageUrlFromNotification =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl;

    final imageUrlFromData = message.data['image_url'] as String?;

    final finalImageUrl = imageUrlFromNotification ?? imageUrlFromData;

    log(
      'FCM onMessage (Foreground): Título: $title, Cuerpo: $body, Image URL: $finalImageUrl',
    );

    if (finalImageUrl != null) {
      local.showBigPicture(title: title, body: body, imageUrl: finalImageUrl);
    } else {
      local.showLocal(title: title, body: body);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    log('FCM onMessageOpenedApp: ${message.data}');
  });
}

/// Crea el canal de notificaciones por defecto que se especificó
/// en el AndroidManifest.xml para que FCM lo use.
Future<void> _ensureFcmDefaultChannel() async {
  // El ID del canal debe coincidir con el valor en AndroidManifest.xml
  const channel = AndroidNotificationChannel(
    'default_channel_fcm',
    'General (FCM)',
    description: 'Canal por defecto para mensajes de Firebase Cloud Messaging',
    importance: Importance.high,
    playSound: true,
  );

  final plugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await plugin?.createNotificationChannel(channel);
  log('Canal de notificación "default_channel_fcm" creado.');

  // Suscripción
  await FirebaseMessaging.instance.subscribeToTopic('ofertas');
  // Token del dispositivo (para envíos dirigidos)
  final token = await FirebaseMessaging.instance.getToken();
  print('FCM token: $token');
}

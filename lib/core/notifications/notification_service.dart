import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'default_channel_fcm';
  static const _channelName = 'General (FCM)';
  static const _channelDesc = 'Canal de notificaciones generales para FCM';

  /// Inicializa el servicio de notificaciones
  Future<void> init() async {
    // Pedir permisos en Android 13+ o iOS
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('Permiso de notificaciones denegado');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _local.initialize(settings);

    // Crear canal de notificaciones
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Notificación simple
  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Notificación con imagen (BigPictureStyle)
  Future<void> showBigPicture({
    required String title,
    required String body,
    required String imageUrl,
  }) async {
    try {
      // Descargar la imagen a un archivo temporal
      final response = await http.get(Uri.parse(imageUrl));
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/big_picture.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      final bigPicture = BigPictureStyleInformation(
        FilePathAndroidBitmap(file.path),
        contentTitle: title,
        summaryText: body,
        hideExpandedLargeIcon: false,
      );

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        styleInformation: bigPicture,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      print('❌ Error al mostrar notificación con imagen: $e');
      // Si falla la imagen, muestra una noti normal
      await showLocal(title: title, body: body);
    }
  }
}

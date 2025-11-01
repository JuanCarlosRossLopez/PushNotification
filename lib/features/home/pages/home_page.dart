import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:practica_guiada_2_riverpod_notificaciones_flutter/core/notifications/notification_service.dart';

/// Widget principal que muestra el Token FCM y un botón de prueba.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Servicio de notificaciones locales
  final _service = NotificationService();

  String? token;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _getToken();
  }

  /// Inicializa notificaciones locales
  Future<void> _initNotifications() async {
    await _service.init();
  }

  /// Obtiene el token de registro de Firebase Cloud Messaging.
  Future<void> _getToken() async {
    token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print('🔑 FCM Token: $token'); // ← Aquí se imprime en consola
    } else {
      print('⚠️ No se pudo obtener el token todavía');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo FCM Flutter')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón para probar una notificación local inmediata
              ElevatedButton(
                onPressed: () {
                  _service.showLocal(
                    title: 'Notificación local',
                    body: 'Hola desde Flutter 🚀',
                  );
                },
                child: const Text('Mostrar notificación local'),
              ),
              const SizedBox(height: 32),

              const Text(
                'Token FCM (para enviar mensajes):',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Muestra el token en pantalla
              SelectableText(
                token ?? "Cargando...",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

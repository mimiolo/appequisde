import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static Future<void> init() async {
    if (kIsWeb) return; // ⚡ Evitar crash en Web
    if (_inicializado) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    try {
      await _plugin.initialize(settings);
    } catch (e) {
      print('⚠️ No se pudo inicializar notificaciones: $e');
    }
    _inicializado = true;
  }

  static Future<void> mostrar({
    required String titulo,
    required String cuerpo,
    int id = 0,
  }) async {
    if (kIsWeb) return; // ⚡ Evitar crash en Web
    await init();
    final android = AndroidNotificationDetails(
      'seguridad_app',
      'Seguridad App',
      channelDescription: 'Notificaciones de la app',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF8B7FD9),
    );
    const ios = DarwinNotificationDetails();
    final detalles = NotificationDetails(android: android, iOS: ios);
    try {
      await _plugin.show(id, titulo, cuerpo, detalles);
    } catch (e) {
      print('⚠️ Error al mostrar notificación: $e');
    }
  }
}

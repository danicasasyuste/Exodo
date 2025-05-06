import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('|');
          if (parts.length == 3) {
            final municipio = parts[0];
            final tipo = parts[1];
            final respuesta = parts[2] == 'yes';
            FirebaseService.guardarRespuesta(municipio: municipio, tipoPregunta: tipo, respuesta: respuesta);
          }
        }
      },
    );
  }

  static Future<void> mostrarPregunta(String municipio, String tipo, String texto) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pregunta_id', 'Preguntas Clima',
      importance: Importance.max,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('yes', 'Sí', showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('no', 'No', showsUserInterface: false, cancelNotification: true),
      ],
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      texto,
      'Toca para responder',
      details,
      payload: '$municipio|$tipo|',
    );
  }

  static Future<void> notificarCambioEstado(String mensaje) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'estado_id', 'Cambio Estado',
      importance: Importance.high,
    );
    await _plugin.show(
      1,
      'Actualización del clima',
      mensaje,
      const NotificationDetails(android: androidDetails),
    );
  }
}
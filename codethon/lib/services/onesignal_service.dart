import 'dart:convert';
import 'package:http/http.dart' as http;

class OneSignalService {
  static const String _appId = '76df6edf-f7b8-4c71-9c70-7f25a558f2f9';
  static const String _apiKey = 'os_v2_app_o3pw5x7xxbghdhdqp4s2kwhs7gndpzzoaioujuvmqfhbgnggsce6sm7zqhuw5rgsw4pb7uz3gwlrbscidwkuvmsg47ly7c4o6u6k3qa';

  static Future<void> enviarNotificacion({
    required String titulo,
    required String mensaje,
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $_apiKey',
    };

    final body = jsonEncode({
      'app_id': _appId,
      'included_segments': ['All'],
      'headings': {'en': titulo},
      'contents': {'en': mensaje},
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error al enviar notificación: ${response.body}');
    }

    print('✅ Notificación enviada: ${response.body}');
  }
}

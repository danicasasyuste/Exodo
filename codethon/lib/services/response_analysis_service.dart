import 'firebase_service.dart';

class ResponseAnalysisService {
  static Future<bool> debeModificarEstado(
      String municipio, String tipoPregunta) async {
    final respuestas =
        await FirebaseService.obtenerRespuestas(municipio, tipoPregunta);
    if (respuestas.length < 5) return false;

    final noCount = respuestas.where((r) => r == false).length;
    final porcentajeNo = noCount / respuestas.length;

    return porcentajeNo >= 0.7;
  }
}

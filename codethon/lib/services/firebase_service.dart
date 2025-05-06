import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> guardarRespuesta({
    required String municipio,
    required String tipoPregunta,
    required bool respuesta,
  }) async {
    await FirebaseFirestore.instance.collection('respuestas').add({
      'municipio': municipio,
      'tipo': tipoPregunta,
      'respuesta': respuesta,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<bool>> obtenerRespuestas(String municipio, String tipoPregunta) async {
    final snapshot = await FirebaseFirestore.instance
      .collection('respuestas')
      .where('municipio', isEqualTo: municipio)
      .where('tipo', isEqualTo: tipoPregunta)
      .orderBy('timestamp', descending: true)
      .limit(100)
      .get();

    return snapshot.docs.map((doc) => doc['respuesta'] as bool).toList();
  }
}

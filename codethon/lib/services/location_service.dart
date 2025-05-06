import 'package:geolocator/geolocator.dart';
import '../models/municipio.dart';
import 'dart:math';

class LocationService {
  static Future<Position> obtenerUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) throw Exception('Ubicación no habilitada');

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) throw Exception('Permiso denegado');
    }

    return await Geolocator.getCurrentPosition();
  }

  static Municipio municipioMasCercano(Position posicion, List<Municipio> municipios) {
    Municipio? masCercano;
    double menorDistancia = double.infinity;
    for (var m in municipios) {
      double distancia = _distanciaGeografica(posicion.latitude, posicion.longitude, m.latitud, m.longitud);
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        masCercano = m;
      }
    }
    return masCercano!;
  }

  static double _distanciaGeografica(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // radio tierra en km
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);
    final a = 
      sin(dLat/2) * sin(dLat/2) +
      cos(_gradosARadianes(lat1)) * cos(_gradosARadianes(lat2)) *
      sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  static double _gradosARadianes(double grados) => grados * pi / 180;
}
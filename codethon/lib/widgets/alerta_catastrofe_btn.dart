import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/onesignal_service.dart';
import 'package:geocoding/geocoding.dart';


class IconoAlertaCatastrofe extends StatelessWidget {
  const IconoAlertaCatastrofe({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Colors.red.shade400,
        size: 28,
      ),
      tooltip: 'Alerta de catástrofe',
      onPressed: () => _mostrarPopupAlerta(context),
    );
  }

  void _mostrarPopupAlerta(BuildContext rootContext) {
    final List<String> tipos = [
      'Inundación',
      'Huracán',
      'Terremoto',
      'Incendio',
      'Deslizamiento',
      'Apagon',
    ];
    String? seleccionado;

    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Selecciona tipo de catástrofe'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: seleccionado,
                hint: const Text('Tipo de alerta'),
                isExpanded: true,
                items: tipos.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => seleccionado = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                if (seleccionado != null) {
                  Navigator.of(dialogContext).pop();
                  final messenger = ScaffoldMessenger.of(rootContext);

                  try {
                    final pos = await _pedirPermisosYObtenerUbicacion(rootContext);
                    if (pos != null) {
                      print('📍 Posición obtenida: ${pos.latitude}, ${pos.longitude}');
                      await _guardarAlertaYVerificar(seleccionado!, pos);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('✅ Alerta confirmada')),
                        );
                      });
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo obtener tu ubicación actual.'),
                          ),
                        );
                      });
                    }
                  } catch (e, s) {
                    print('❌ Error en el proceso de alerta: $e\n$s');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ubicación denegada permanentemente. Habilítala desde los ajustes.',
                          ),
                        ),
                      );
                    });
                  }
                }
              },
              child: const Text('Confirmar alerta'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirAjustesSistema() async {
    const url = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('❌ No se pudo abrir los ajustes del sistema');
    }
  }

  Future<Position?> _pedirPermisosYObtenerUbicacion(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Servicio de ubicación deshabilitado');
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      print('🔄 Permiso tras pedir: $permiso');
    }

    if (permiso == LocationPermission.deniedForever) {
      print('⛔ Permiso denegado permanentemente');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permiso de ubicación requerido'),
            content: const Text(
              'Has denegado el permiso de ubicación permanentemente.\n\nPara usar esta función, actívalo manualmente en los ajustes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _abrirAjustesSistema();
                },
                child: const Text('Abrir ajustes'),
              ),
            ],
          ),
        );
      });
      return null;
    }

    if (permiso == LocationPermission.always || permiso == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    return null;
  }

  Future<void> _guardarAlertaYVerificar(String tipo, Position pos) async {
    final ahora = DateTime.now();

    await FirebaseFirestore.instance.collection('alertas').add({
      'tipo': tipo,
      'timestamp': ahora.toIso8601String(),
      'location': GeoPoint(pos.latitude, pos.longitude),
    });

    await _verificarCondicionesYNotificar(tipo, pos);
  }

Future<void> _verificarCondicionesYNotificar(String tipo, Position pos) async {
  final tiempoLimite = DateTime.now().subtract(const Duration(minutes: 15));
  final query = await FirebaseFirestore.instance
      .collection('alertas')
      .where('tipo', isEqualTo: tipo)
      .get();

  int conteo = 0;
  GeoPoint? referencia;
  for (var doc in query.docs) {
    final data = doc.data();
    final geo = data['location'] as GeoPoint;
    final fecha = DateTime.parse(data['timestamp']);
    final distancia = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      geo.latitude,
      geo.longitude,
    );

    if (distancia < 5000 && fecha.isAfter(tiempoLimite)) {
      conteo++;
      referencia ??= geo; // guardamos la primera ubicación válida como referencia
    }
  }

  if (conteo >= 1 && referencia != null) {
    print('conteo alerta $conteo');

    // 🌍 Obtener el nombre del municipio desde la ubicación de referencia
    String municipio = 'tu zona';
    try {
      final placemarks = await placemarkFromCoordinates(referencia.latitude, referencia.longitude);
      if (placemarks.isNotEmpty) {
        municipio = placemarks.first.locality ??
                    placemarks.first.subAdministrativeArea ??
                    placemarks.first.name ??
                    'tu zona';
      }
    } catch (e) {
      print('🌐 Error al obtener el municipio: $e');
    }

    await OneSignalService.enviarNotificacion(
      titulo: '⚠️ Alerta de $tipo en $municipio',
      mensaje: 'Se ha detectado una alerta de tipo "$tipo" cerca de $municipio. ¡Toma precauciones!',
      );
    }
  }
}

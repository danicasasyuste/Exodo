import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart' show Lottie;

class MapaIconosScreen extends StatelessWidget {
  const MapaIconosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa del Tiempo',
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: const WeatherIconMap(),
    );
  }
}

class WeatherIconMap extends StatefulWidget {
  const WeatherIconMap({super.key});

  @override
  State<WeatherIconMap> createState() => _WeatherIconMapState();
}

bool get isNight {
  final hour = DateTime.now().hour;
  return hour >= 20 || hour < 6;
}

Color get card => isNight ? const Color(0xFF1B263B) : Colors.white;
Color get texto => isNight ? const Color(0xFFE0E1DD) : Colors.black87;

class _WeatherIconMapState extends State<WeatherIconMap> {
  final String apiKey = '8eba0ec11c7728b0913cd629b626e0dd';
  final String mapboxAccessToken =
      'pk.eyJ1IjoiZGFuaWNhc2FzeXVzdGUiLCJhIjoiY205NXAzODJtMTQwMDJ3czR2M3R3eXBmMyJ9.f5Y7nFqBe3HByh48MJHn_g';

  final MapController mapController = MapController();

  final List<Map<String, dynamic>> mainCities = [
    {"name": "Valencia", "lat": 39.4699, "lon": -0.3763},
    {"name": "Castellón", "lat": 39.9864, "lon": -0.0513},
    {"name": "Alicante", "lat": 38.3450, "lon": -0.4800},
    {"name": "Gandia", "lat": 38.9682, "lon": -0.1800},
    {"name": "Paterna", "lat": 39.5033, "lon": -0.4443},
    {"name": "Torrent", "lat": 39.4379, "lon": -0.4643},
    {"name": "Sagunto", "lat": 39.6796, "lon": -0.2728},
    {"name": "Xàbia", "lat": 38.7920, "lon": 0.1650},
    {"name": "Requena", "lat": 39.4889, "lon": -1.1006},
    {"name": "Xàtiva", "lat": 38.9871, "lon": -0.5189},
    {"name": "Vinaròs", "lat": 40.4705, "lon": 0.4743},
    {"name": "Elche", "lat": 38.2669, "lon": -0.6983},
    {"name": "Elda", "lat": 38.4771, "lon": -0.7915},
    {"name": "Petrer", "lat": 38.4786, "lon": -0.7754},
    {"name": "Orihuela", "lat": 38.0850, "lon": -0.9460},
    {"name": "Benidorm", "lat": 38.5340, "lon": -0.1310},
    {"name": "Dénia", "lat": 38.8400, "lon": 0.1057},
    {"name": "Torrevieja", "lat": 37.9774, "lon": -0.6830},
    {"name": "Villena", "lat": 38.6372, "lon": -0.8650},
    {"name": "Vila-real", "lat": 39.9383, "lon": -0.1017},
    {"name": "Almassora", "lat": 39.9358, "lon": -0.0647},
    {"name": "Burriana", "lat": 39.8893, "lon": -0.0839},
    {"name": "Onda", "lat": 39.9664, "lon": -0.2640},
    {"name": "Benicàssim", "lat": 40.0547, "lon": 0.0635},
    {"name": "La Vall d'Uixó", "lat": 39.8232, "lon": -0.2334},
  ];

  final List<Map<String, dynamic>> smallTowns = [
    {"name": "Rocafort", "lat": 39.5349, "lon": -0.4187},
    {"name": "Godella", "lat": 39.5192, "lon": -0.4130},
    {"name": "Moncada", "lat": 39.5460, "lon": -0.3935},
    {"name": "Burjassot", "lat": 39.5131, "lon": -0.4116},
    {"name": "Massamagrell", "lat": 39.5679, "lon": -0.3350},
    {"name": "Tavernes Blanques", "lat": 39.5050, "lon": -0.3667},
    {"name": "Albal", "lat": 39.3917, "lon": -0.4074},
    {"name": "Catarroja", "lat": 39.4060, "lon": -0.4140},
    {"name": "Silla", "lat": 39.3655, "lon": -0.4175},
    {"name": "Mislata", "lat": 39.4746, "lon": -0.4149},
    {"name": "Picanya", "lat": 39.4330, "lon": -0.4330},
    {"name": "Mutxamel", "lat": 38.4156, "lon": -0.4457},
    {"name": "Sant Joan d'Alacant", "lat": 38.3980, "lon": -0.4364},
    {"name": "Aspe", "lat": 38.3457, "lon": -0.7674},
    {"name": "Callosa de Segura", "lat": 38.1254, "lon": -0.8783},
    {"name": "Crevillent", "lat": 38.2491, "lon": -0.8074},
    {"name": "Santa Pola", "lat": 38.1910, "lon": -0.5561},
    {"name": "Benicarló", "lat": 40.4176, "lon": 0.4262},
    {"name": "Almenara", "lat": 39.7445, "lon": -0.2334},
    {"name": "Nules", "lat": 39.8574, "lon": -0.1522},
    {"name": "Peñíscola", "lat": 40.3560, "lon": 0.4034},
    {"name": "Llíria", "lat": 39.6285, "lon": -0.5985},
    {"name": "Chelva", "lat": 39.7503, "lon": -0.9875},
    {"name": "Casinos", "lat": 39.7163, "lon": -0.7160},
  ];

  final Map<String, Map<String, dynamic>> weatherData = {};
  bool isLoading = true;
  double currentZoom = 8.8;
  bool isNight = false;

  LatLng? userLocation;
  LatLng? closestLocation;

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    _findClosestLocation();
  }

  void _findClosestLocation() {
    if (userLocation == null || weatherData.isEmpty) return;

    double minDistance = double.infinity;
    LatLng? nearest;

    weatherData.forEach((name, data) {
      final city = [
        ...mainCities,
        ...smallTowns,
      ].firstWhere((c) => c['name'] == name, orElse: () => {});
      if (city.isNotEmpty) {
        final LatLng pos = LatLng(city['lat'], city['lon']);
        final double dist = Distance().as(
          LengthUnit.Kilometer,
          userLocation!,
          pos,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearest = pos;
        }
      }
    });

    setState(() {
      closestLocation = nearest;
    });
  }

  final LatLngBounds valenciaBounds = LatLngBounds(
    LatLng(37.8, -1.5),
    LatLng(40.9, 0.9),
  );

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _fetchWeatherData();
    _checkIfNight();
  }

  void _checkIfNight() {
    final now = DateTime.now();
    final hour = now.hour;
    setState(() {
      isNight = hour < 7 || hour >= 20;
    });
  }

  Future<void> _fetchWeatherData() async {
    List<Map<String, dynamic>> allPlaces = [...mainCities, ...smallTowns];
    for (var city in allPlaces) {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${city["lat"]}&lon=${city["lon"]}&appid=$apiKey&units=metric&lang=es';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weatherData[city['name']] = {
          "icon": data['weather'][0]['icon'],
          "temp": data['main']['temp'].round(),
          "desc": data['weather'][0]['description'],
          "feels_like": data['main']['feels_like'].round(),
          "humidity": data['main']['humidity'],
          "wind": data['wind']['speed'].toString(),
        };
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  String getMapboxStyle() {
    return isNight ? 'mapbox/navigation-night-v1' : 'mapbox/navigation-day-v1';
  }

  Color getColorForIcon(String icon) {
    if (isNight) return Colors.grey.shade800;
    if (icon.startsWith('01')) return Colors.amber;
    if (icon.startsWith('02')) return Colors.lightBlueAccent;
    if (icon.startsWith('03') || icon.startsWith('04')) return Colors.grey;
    if (icon.startsWith('09') || icon.startsWith('10')) return Colors.blue;
    if (icon.startsWith('11')) return Colors.deepPurple;
    if (icon.startsWith('13')) return Colors.cyan;
    if (icon.startsWith('50')) return Colors.brown.shade200;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allPlaces = [...mainCities, ...smallTowns];

    List<Marker> markers =
        allPlaces.map((city) {
          final isMainCity = mainCities.any((c) => c['name'] == city['name']);
          final weather = weatherData[city['name']];
          final point = LatLng(city['lat'], city['lon']);

          if (!isMainCity && currentZoom <= 10) {
            return Marker(
              width: 20,
              height: 20,
              point: point,
              child: GestureDetector(
                onTap: () {
                  mapController.move(
                    point,
                    (currentZoom + 2.5).clamp(8.8, 18.0),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          } else if (weather != null) {
            final bgColor = getColorForIcon(weather["icon"]);
            final isClosest =
                closestLocation != null &&
                city['lat'] == closestLocation!.latitude &&
                city['lon'] == closestLocation!.longitude;

            return Marker(
              width: 113,
              height: 137,
              point: point,
              child: GestureDetector(
                onTap: () => showWeatherDialog(city['name'], weather, bgColor),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isClosest ? Colors.red : Colors.transparent,
                      width: 3,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [bgColor, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://openweathermap.org/img/wn/${weather["icon"]}@2x.png',
                        width: 35,
                        height: 35,
                      ),
                      Text(
                        '${weather["temp"]}ºC',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                      Text(
                        city['name'],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${weather["desc"]}',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Marker(point: LatLng(0, 0), child: SizedBox.shrink());
          }
        }).toList();

    return Scaffold(
      body: Stack(
        children: [
          isLoading
              ? Container(
                color:
                    isNight ? const Color(0xFF1B263B) : Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset('assets/lottie/load.json'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cargando mapa del tiempo...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isNight ? const Color(0xFFE0E1DD) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(39.5, -0.6),
                  initialZoom: 8.2,
                  minZoom: 8.1,
                  maxZoom: 18.0,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: valenciaBounds,
                  ),
                  onPositionChanged: (position, hasGesture) {
                    if (position.zoom != null) {
                      setState(() {
                        currentZoom = position.zoom!;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/${getMapboxStyle()}/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken',
                    additionalOptions: {'access_token': mapboxAccessToken},
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 130,
                      size: const Size(50, 50),
                      centerMarkerOnClick: true,
                      markers: markers,
                      builder: (context, cluster) {
                        final markerCount = cluster.length;
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                markerCount <= 5
                                    ? Colors.green.withAlpha(180)
                                    : markerCount <= 15
                                    ? Colors.orange.withAlpha(180)
                                    : Colors.red.withAlpha(180),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$markerCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                if (closestLocation != null) {
                  mapController.move(closestLocation!, 15.5);
                }
              },
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    189,
                    228,
                    247,
                  ).withAlpha((0.85 * 255).round()),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color.fromARGB(
                    255,
                    26,
                    95,
                    178,
                  ), // Azul más oscuro para contraste
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showWeatherDialog(
    String cityName,
    Map<String, dynamic> data,
    Color bgColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withAlpha(230), bgColor.withAlpha(180)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/${data["icon"]}@2x.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 10),
                Text(
                  cityName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${data["temp"]}ºC',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.lightBlue,
                  ),
                ),
                Text(
                  '${data["desc"]}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text('Sensación térmica: ${data["feels_like"]}ºC'),
                Text('Humedad: ${data["humidity"]}%'),
                Text('Viento: ${data["wind"]} m/s'),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

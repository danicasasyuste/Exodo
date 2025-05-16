import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';

class MapaLluviaScreen extends StatefulWidget {
  const MapaLluviaScreen({super.key});

  @override
  State<MapaLluviaScreen> createState() => _MapaLluviaScreenState();
}

class _MapaLluviaScreenState extends State<MapaLluviaScreen> {
  final LatLng center = const LatLng(39.4699, -0.3763);
  final double fixedZoom = 7.4;

  List<int> _rainFrames = [];
  int _currentFrameIndex = 0;
  Timer? _animationTimer;
  bool _isPlaying = true;
  double _animationSpeed = 1.0;
  bool isLoading = true;
  late DateTime _startTime;

  bool get isNight {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }

  Color get fondo =>
      isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F0FA);
  Color get texto => isNight ? const Color(0xFFE0E1DD) : Colors.black87;

  final String mapboxToken =
      'pk.eyJ1IjoiZGFuaWNhc2FzeXVzdGUiLCJhIjoiY205NXAzODJtMTQwMDJ3czR2M3R3eXBmMyJ9.f5Y7nFqBe3HByh48MJHn_g';

  String getMapboxStyleUrl() {
    final hour = DateTime.now().hour;
    final isNight = hour >= 20 || hour < 6;
    final style =
        isNight ? 'mapbox/navigation-night-v1' : 'mapbox/navigation-day-v1';
    return 'https://api.mapbox.com/styles/v1/$style/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    fetchRainViewerFrames();
  }

  Future<void> fetchRainViewerFrames() async {
    final response = await http.get(
      Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> pastFrames = data['radar']['past'];
      final timestamps =
          pastFrames.map<int>((frame) => frame['time'] as int).toList();

      if (timestamps.isNotEmpty && mounted) {
        final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
        final delay = elapsed < 2000 ? 2000 - elapsed : 0;

        await Future.delayed(Duration(milliseconds: delay));

        setState(() {
          _rainFrames = timestamps;
          _currentFrameIndex =
              timestamps.length >= 4 ? 3 : 0;
          _isPlaying = false;
        });

        // Esperar 1 segundo más para que el primer frame se muestre
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void startAnimation() {
    _animationTimer?.cancel();
    const int baseMs = 700;
    _animationTimer = Timer.periodic(
      Duration(milliseconds: (baseMs ~/ _animationSpeed)),
      (_) {
        if (!mounted) return;
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % _rainFrames.length;
        });
      },
    );
  }

  void togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        startAnimation();
      } else {
        _animationTimer?.cancel();
      }
    });
  }

  void nextFrame() {
    _animationTimer?.cancel();
    setState(() {
      _currentFrameIndex = (_currentFrameIndex + 1) % _rainFrames.length;
      _isPlaying = false;
    });
  }

  void previousFrame() {
    _animationTimer?.cancel();
    setState(() {
      _currentFrameIndex =
          (_currentFrameIndex - 1 + _rainFrames.length) % _rainFrames.length;
      _isPlaying = false;
    });
  }

  void changeSpeed(double newSpeed) {
    setState(() {
      _animationSpeed = newSpeed;
      if (_isPlaying) {
        startAnimation();
      }
    });
  }

  String getFormattedTime(int unixTimestamp) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000).toLocal();
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radarTile =
        _rainFrames.isNotEmpty
            ? TileLayer(
              key: ValueKey(_rainFrames[_currentFrameIndex]),
              urlTemplate:
                  'https://tilecache.rainviewer.com/v2/radar/${_rainFrames[_currentFrameIndex]}/256/{z}/{x}/{y}/2/1_1.png',
              userAgentPackageName: 'com.example.app',
              tileProvider: NetworkTileProvider(),
            )
            : const SizedBox();

    return Scaffold(
      body:
          isLoading
              ? Container(
                color: fondo,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset('assets/lottie/load2.json'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cargando animación de lluvia...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: texto,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: fixedZoom,
                      minZoom: fixedZoom,
                      maxZoom: fixedZoom,
                      interactionOptions: const InteractionOptions(
                        enableScrollWheel: false,
                        enableMultiFingerGestureRace: true,
                      ),
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(
                          const LatLng(37.0, -3.0),
                          const LatLng(42.0, 1.5),
                        ),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: getMapboxStyleUrl(),
                        userAgentPackageName: 'com.example.app',
                        tileProvider: NetworkTileProvider(),
                      ),
                      radarTile,
                    ],
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _rainFrames.isNotEmpty
                                ? getFormattedTime(
                                  _rainFrames[_currentFrameIndex],
                                )
                                : '',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: previousFrame,
                              icon: const Icon(Icons.skip_previous),
                              iconSize: 22,
                              color: Colors.grey[700],
                            ),
                            IconButton(
                              onPressed: togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              iconSize: 22,
                              color: Colors.grey[800],
                            ),
                            IconButton(
                              onPressed: nextFrame,
                              icon: const Icon(Icons.skip_next),
                              iconSize: 22,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 16),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: _animationSpeed,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black54,
                                ),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                items: const [
                                  DropdownMenuItem(
                                    value: 0.5,
                                    child: Text('0.5x'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.0,
                                    child: Text('1x'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2.0,
                                    child: Text('2x'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) changeSpeed(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 30,
                    right: 30,
                    child:
                        _rainFrames.isNotEmpty
                            ? SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF4DD0E1),
                                inactiveTrackColor: const Color(0xFFB2EBF2),
                                thumbColor: const Color(0xFF00ACC1),
                                overlayColor: const Color(0x294DD0E1),
                              ),
                              child: Slider(
                                value: _currentFrameIndex.toDouble(),
                                min: 0,
                                max: (_rainFrames.length - 1).toDouble(),
                                divisions: _rainFrames.length - 1,
                                onChanged: (value) {
                                  _animationTimer?.cancel();
                                  setState(() {
                                    _currentFrameIndex = value.round();
                                    _isPlaying = false;
                                  });
                                },
                              ),
                            )
                            : const SizedBox(),
                  ),
                ],
              ),
    );
  }
}

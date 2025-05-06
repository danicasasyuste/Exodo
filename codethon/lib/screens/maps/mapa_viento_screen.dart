import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';

class MapaVientoScreen extends StatefulWidget {
  const MapaVientoScreen({super.key});

  @override
  State<MapaVientoScreen> createState() => _MapaVientoScreenState();
}

class _MapaVientoScreenState extends State<MapaVientoScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  late DateTime _startTime;

  bool get isNight {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }

  Color get card => isNight ? const Color(0xFF1B263B) : Colors.white;
  Color get texto => isNight ? const Color(0xFFE0E1DD) : Colors.black87;

  final String windyBaseUrl =
      'https://embed.windy.com/embed2.html'
      '?lat=39.4699&lon=-0.3763'
      '&detailLat=39.4699&detailLon=-0.3763'
      '&zoom=10'
      '&level=surface'
      '&menu=false'
      '&message=false'
      '&marker=false'
      '&calendar=hidden'
      '&pressure=false'
      '&detail=false'
      '&location=hidden'
      '&embed=true'
      '&metricWind=default'
      '&metricTemp=default'
      '&type=map'
      '&overlay=wind'
      '&disableZoom=true'
      '&disablePanning=true';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) async {
                final elapsed =
                    DateTime.now().difference(_startTime).inMilliseconds;
                final delay = elapsed < 2000 ? 2000 - elapsed : 0;
                await Future.delayed(Duration(milliseconds: delay));
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(windyBaseUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: OverflowBox(
                maxWidth: MediaQuery.of(context).size.width * 1.5,
                maxHeight: MediaQuery.of(context).size.height * 1.5,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1.3,
                  height: MediaQuery.of(context).size.height * 1.3,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      IgnorePointer(
                        ignoring: false,
                        child: Container(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: card,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Lottie.asset('assets/lottie/load3.json'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando mapa de viento...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: texto.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import './maps/mapa_iconos_screen.dart';
import './maps/mapa_lluvia_screen.dart';
import './maps/mapa_viento_screen.dart';

enum CapaTipo { iconos, lluvia, viento }

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.35,
    initialPage: 1000,
  );

  final List<_CapaData> capas = [
    _CapaData(CapaTipo.iconos, 'assets/lottie/radar.json', 'Iconos'),
    _CapaData(CapaTipo.lluvia, 'assets/lottie/rain.json', 'Lluvia'),
    _CapaData(CapaTipo.viento, 'assets/lottie/wind.json', 'Viento'),
  ];

  CapaTipo capaActual = CapaTipo.lluvia;

  bool get isNight {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }

  Widget _buildMap() {
    switch (capaActual) {
      case CapaTipo.iconos:
        return const MapaIconosScreen();
      case CapaTipo.lluvia:
        return const MapaLluviaScreen();
      case CapaTipo.viento:
        return const MapaVientoScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final index = (_pageController.page?.round() ?? 0) % capas.length;
      setState(() {
        capaActual = capas[index].tipo;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Paleta dinámica según sea de noche o no
    final Color fondo =
        isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F0FA);
    final Color card = isNight ? const Color(0xFF1B263B) : Colors.white;
    final Color texto = isNight ? const Color(0xFFE0E1DD) : Colors.black87;
    final Color icono = isNight ? const Color(0xFFA5B3C5) : Colors.black87;
    final Color sombra = isNight ? const Color(0xFF415A77) : Colors.black12;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: icono),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mapas',
                    style: TextStyle(
                      fontSize: 20,
                      color: texto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Mapa
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: card,
                    boxShadow: [
                      BoxShadow(
                        color: sombra,
                        blurRadius: 20,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildMap(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Carrusel de botones animados con Lottie
            SizedBox(
              height: 130,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final capa = capas[index % capas.length];
                  final isCurrent =
                      (_pageController.page ?? _pageController.initialPage)
                              .round() %
                          capas.length ==
                      index % capas.length;

                  final scale = isCurrent ? 1.0 : 0.8;
                  final opacity = isCurrent ? 1.0 : 0.4;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: sombra,
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: capa.tipo == CapaTipo.lluvia ? 60 : 50,
                                height: capa.tipo == CapaTipo.lluvia ? 60 : 50,
                                child: Lottie.asset(
                                  capa.lottiePath,
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                capa.label,
                                style: TextStyle(fontSize: 13, color: texto),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CapaData {
  final CapaTipo tipo;
  final String lottiePath;
  final String label;

  _CapaData(this.tipo, this.lottiePath, this.label);
}

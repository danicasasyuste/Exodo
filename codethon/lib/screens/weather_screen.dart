import 'package:codethon/widgets/alerta_catastrofe_btn.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import '../models/weather_override.dart';
import 'calendar_screen.dart';
import 'map_screen.dart';
import '../widgets/global_btn_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'encuesta_clima_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class MunicipioValenciano {
  final String nombre;
  final String query;

  MunicipioValenciano({required this.nombre, required this.query});
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  List<Weather>? _forecast;
  List<Weather>? _hourlyForecast;
  final TextEditingController _searchController = TextEditingController();
  final WeatherOverride _override = WeatherOverride();
  Timer? _verificacionTimer;
  String _selectedCity = '39.4699,-0.3763';
  //bool _showClearIcon = false;
  Timer? _updateTimer;
  bool _showLoading = true;
  final int _pageIndex = 0;
  final PageController _pageController = PageController();
  final Map<String, int> _conteoClima = {};
  String? _climaColaborativo;
  int _climaPageIndex = 0;
  int votosTotal = 0;
  Map<String, int> votosPorClima = {};
  String? climaMasVotado;

  void _showHourlyPopup(BuildContext context) {
    if (_hourlyForecast == null || _hourlyForecast!.isEmpty) return;

    final bool isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;
    final Color fondoPopup = isNight ? const Color(0xFF1B263B) : Colors.white;
    final Color textoPopup = isNight ? const Color(0xFFE0E1DD) : Colors.black87;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: fondoPopup,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          title: Text(
            'Clima por horas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textoPopup,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: ListView.builder(
              itemCount: _hourlyForecast!.length,
              itemBuilder: (context, index) {
                final item = _hourlyForecast![index];
                final hora = DateFormat.Hm('es_ES').format(item.date);
                final icon = item.iconUrl;
                final temp = item.temperature;
                final desc = _translateDescription(item.description);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Image.network(icon, width: 34, height: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$hora - $desc',
                              style: TextStyle(color: textoPopup, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${temp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textoPopup,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: textoPopup)),
            ),
          ],
        );
      },
    );
  }

  final List<MunicipioValenciano> municipiosValencianos = [
    MunicipioValenciano(nombre: 'Valencia', query: '39.4699,-0.3763'),
    MunicipioValenciano(nombre: 'Manises', query: '39.4893,-0.4632'),
    MunicipioValenciano(nombre: 'Gandía', query: '38.9685,-0.1819'),
    MunicipioValenciano(nombre: 'Ontinyent', query: '38.8210,-0.6095'),
    MunicipioValenciano(nombre: 'Sagunto', query: '39.6792,-0.2733'),
    MunicipioValenciano(nombre: 'Xirivella', query: '39.4663,-0.4301'),
    MunicipioValenciano(nombre: 'Alzira', query: '39.1511,-0.4396'),
    MunicipioValenciano(nombre: 'Mislata', query: '39.4750,-0.4143'),
    MunicipioValenciano(nombre: 'Cullera', query: '39.1610,-0.2529'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTodo();

    _updateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) {
        _fetchWeather();
        _fetchColaborativo();
      }
    });

    _verificacionTimer = Timer.periodic(const Duration(minutes: 10), (_) {});
  }

  Future<void> _loadTodo() async {
    await _fetchWeather();
    await _fetchColaborativo();
    setState(() {
      _showLoading = false;
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _verificacionTimer?.cancel();
    _searchController.dispose();
    GlobalConfig.mostrarBotonAsistente.value = true;

    super.dispose();
  }

  Future<void> _fetchColaborativo() async {
    final now = DateTime.now();
    final limite = now.subtract(const Duration(minutes: 15));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('reportes_clima')
            .where('query', isEqualTo: _selectedCity.trim())
            .where('timestamp', isGreaterThan: Timestamp.fromDate(limite))
            .get();

    final conteo = <String, int>{};
    for (final doc in snapshot.docs) {
      final clima = doc['clima'] as String;
      conteo[clima] = (conteo[clima] ?? 0) + 1;
    }
    debugPrint('Consultando Firebase para $_selectedCity');
    debugPrint('Documentos encontrados: ${snapshot.docs.length}');
    for (final doc in snapshot.docs) {
      debugPrint('→ Clima: ${doc['clima']} | Query: ${doc['query']}');
    }

    _conteoClima
      ..clear()
      ..addAll(conteo);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.getWeather(_selectedCity);
      final forecast = await _weatherService.getForecast(_selectedCity);
      final hourly = await _weatherService.getHourlyForecast(_selectedCity);

      if (!mounted) return;

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _hourlyForecast = hourly;
      });

      // Acceso seguro a .description
      if ((_currentWeather?.description ?? '').toLowerCase().contains(
        'rain',
      )) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar los datos: $e')));
    }
  }

  String getLottieAssetUnified(String description) {
    final desc = description.toLowerCase();
    final bool isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;

    if (desc.contains('thunder') ||
        desc.contains('storm') ||
        desc.contains('tormenta')) {
      return 'assets/lottie/weather/lighting.json';
    } else if (desc.contains('rain') || desc.contains('lluvia')) {
      return isNight
          ? 'assets/lottie/weather/night-rain.json'
          : 'assets/lottie/weather/rain-light.json';
    } else if (desc.contains('fog') ||
        desc.contains('mist') ||
        desc.contains('niebla') ||
        desc.contains('neblina')) {
      return 'assets/lottie/weather/fog.json';
    } else if (desc.contains('cloud') || desc.contains('nube')) {
      return isNight
          ? 'assets/lottie/weather/night-cloud.json'
          : 'assets/lottie/weather/cloudy.json';
    } else if (desc.contains('clear') ||
        desc.contains('sunny') ||
        desc.contains('despejado') ||
        desc.contains('soleado')) {
      return isNight
          ? 'assets/lottie/weather/night.json'
          : 'assets/lottie/weather/sunny.json';
    } else {
      return isNight
          ? 'assets/lottie/weather/night.json'
          : 'assets/lottie/weather/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;

    final Color fondo =
        isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F0FA);
    final Color card = isNight ? const Color(0xFF1B263B) : Colors.white;
    final Color texto = isNight ? const Color(0xFFE0E1DD) : Colors.black87;
    final Color icono = isNight ? const Color(0xFFA5B3C5) : Colors.black87;
    final Color dropDown =
        isNight ? const Color(0xFF1B263B) : const Color(0xFFE6F0FA);
    final Color sombra =
        isNight ? const Color.fromARGB(30, 65, 90, 119) : Colors.black12;
    final String backgroundImage =
        isNight
            ? 'assets/images/maps_card_night.jpg'
            : 'assets/images/maps_card.jpg';

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child:
            _showLoading || _currentWeather == null
                ? Center(child: Lottie.asset('assets/lottie/intro.json'))
                : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchWeather();
                    await _fetchColaborativo();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: icono,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton2<
                                          MunicipioValenciano
                                        >(
                                          isExpanded: true,
                                          customButton: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  municipiosValencianos
                                                      .firstWhere(
                                                        (m) =>
                                                            m.query ==
                                                            _selectedCity,
                                                        orElse:
                                                            () =>
                                                                municipiosValencianos[0],
                                                      )
                                                      .nombre,
                                                  style: TextStyle(
                                                    color: texto,
                                                    fontSize: 20,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: icono,
                                              ),
                                            ],
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: dropDown,
                                            ),
                                            offset: const Offset(0, -8),
                                            maxHeight:
                                                kMinInteractiveDimension * 5,
                                          ),
                                          value: municipiosValencianos
                                              .firstWhere(
                                                (m) => m.query == _selectedCity,
                                                orElse:
                                                    () =>
                                                        municipiosValencianos[0],
                                              ),
                                          items:
                                              municipiosValencianos.map((m) {
                                                return DropdownMenuItem(
                                                  value: m,
                                                  child: Text(
                                                    m.nombre,
                                                    style: TextStyle(
                                                      color: texto,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (
                                            MunicipioValenciano? newValue,
                                          ) {
                                            if (newValue != null) {
                                              setState(() {
                                                _selectedCity =
                                                    newValue.query.trim();
                                              });
                                              _fetchWeather();
                                              _fetchColaborativo();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // DERECHA: botones sin desbordes
                              Wrap(
                                spacing: 4,
                                children: [
                                  const IconoAlertaCatastrofe(),
                                  IconButton(
                                    icon: Icon(
                                      Icons.calendar_today,
                                      color: icono,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const CalendarScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.how_to_vote,
                                      color: icono,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierColor: Colors.black54,
                                        builder:
                                            (context) =>
                                                const EncuestaClimaPopup(),
                                      );
                                      _fetchColaborativo();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Desliza hacia abajo para actualizar',
                            style: TextStyle(
                              fontSize: 12,
                              color: texto.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 320,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PageView(
                                onPageChanged: (index) {
                                  setState(() {
                                    _climaPageIndex = index;
                                  });
                                },
                                children: [
                                  // 🔹 Clima desde API
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        child: Lottie.asset(
                                          getLottieAssetUnified(
                                            _currentWeather!.description,
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _showHourlyPopup(context),
                                        child: Text(
                                          '${_currentWeather!.temperature}°C',
                                          style: TextStyle(
                                            fontSize: 60,
                                            fontWeight: FontWeight.bold,
                                            color: texto,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _override.overrideActiva &&
                                                !_override.lluvia
                                            ? 'Sin lluvia (verificado)'
                                            : _translateDescription(
                                              _currentWeather!.description,
                                            ),
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: texto.withAlpha(230),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // 🔸 Clima colaborativo
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        _conteoClima.isEmpty
                                            ? [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Lottie.asset(
                                                    'assets/lottie/load-votaciones.json',
                                                    height: 150,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Aún no hay datos de la comunidad 🕵️‍♂️',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: texto,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Sé el primero en reportar el clima de tu zona',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: texto.withOpacity(
                                                        0.7,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ]
                                            : [
                                              Builder(
                                                builder: (_) {
                                                  final total = _conteoClima
                                                      .values
                                                      .fold<int>(
                                                        0,
                                                        (sum, val) => sum + val,
                                                      );
                                                  final mayor = _conteoClima
                                                      .entries
                                                      .reduce(
                                                        (a, b) =>
                                                            a.value > b.value
                                                                ? a
                                                                : b,
                                                      );
                                                  final porcentaje =
                                                      ((mayor.value / total) *
                                                              100)
                                                          .toStringAsFixed(1);

                                                  return Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        height: 150,
                                                        child: Lottie.asset(
                                                          getLottieAssetUnified(
                                                            mayor.key,
                                                          ), // clima correcto
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '${_currentWeather!.temperature}°C',
                                                        style: TextStyle(
                                                          fontSize: 60,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: texto,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons.person,
                                                            size: 30,
                                                            color:
                                                                Color.fromARGB(
                                                                  255,
                                                                  27,
                                                                  136,
                                                                  179,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            '${_translateDescription(mayor.key)} ($porcentaje%)',
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color: texto
                                                                  .withAlpha(
                                                                    230,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                  ),
                                ],
                              ),

                              // ⬅️ Flecha izquierda si estamos en la derecha (colaborativo)
                              if (_climaPageIndex == 1)
                                Positioned(
                                  left: 8,
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    size: 20,
                                    color: texto.withOpacity(0.5),
                                  ),
                                ),

                              // ➡️ Flecha derecha si estamos en la izquierda (API)
                              if (_climaPageIndex == 0)
                                Positioned(
                                  right: 8,
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 20,
                                    color: texto.withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _infoCard(
                              Icons.water_drop,
                              'Humedad',
                              '${_currentWeather?.humidity ?? 0}%',
                              card,
                              texto,
                            ),
                            _infoCard(
                              Icons.air,
                              'Viento',
                              '${_currentWeather?.windSpeed ?? 0} km/h',
                              card,
                              texto,
                            ),
                            _infoCard(
                              Icons.speed,
                              'Presión',
                              '${_currentWeather?.pressure ?? 0} hPa',
                              card,
                              texto,
                            ),
                            _infoCard(
                              Icons.thermostat,
                              'Sensación',
                              (_currentWeather?.feelsLike ?? 0).toStringAsFixed(
                                1,
                              ),
                              card,
                              texto,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _forecast == null
                            ? const CircularProgressIndicator()
                            : Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: sombra,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 15,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children:
                                        _forecast!.take(4).map((day) {
                                          return Column(
                                            children: [
                                              Text(
                                                DateFormat.E('es_ES')
                                                    .format(day.date)
                                                    .substring(0, 3)
                                                    .replaceFirstMapped(
                                                      RegExp(r'^[a-zA-Z]'),
                                                      (m) =>
                                                          m[0]!.toUpperCase(),
                                                    ),
                                                style: TextStyle(
                                                  color: texto,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Image.network(
                                                day.iconUrl,
                                                width: 32,
                                                height: 32,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${day.temperature}°C',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: texto,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 112,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: card,
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: AssetImage(backgroundImage),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: sombra,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const MapsScreen(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.map,
                                              color: icono,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Mapas',
                                              style: TextStyle(
                                                color: texto,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildVistaColaborativa(BuildContext context) {
    final bool isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;
    final Color texto = isNight ? Colors.white70 : Colors.black87;

    return SafeArea(
      child: Center(
        child:
            _conteoClima.isEmpty
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 60, color: texto),
                    const SizedBox(height: 12),
                    Text(
                      'Sin votos recientes',
                      style: TextStyle(color: texto, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Participa con el botón superior derecho',
                      style: TextStyle(
                        color: texto.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt, size: 60, color: texto),
                    const SizedBox(height: 12),
                    Text(
                      'Clima colaborativo actual:',
                      style: TextStyle(color: texto, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _climaColaborativo ?? '—',
                      style: TextStyle(
                        color: texto,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  String _translateDescription(String desc) {
    final lower = desc.toLowerCase();

    const traducciones = {
      'clear sky': 'Cielo despejado',
      'few clouds': 'Pocas nubes',
      'scattered clouds': 'Nubes dispersas',
      'broken clouds': 'Nubes fragmentadas',
      'overcast clouds': 'Cielo cubierto',
      'light rain': 'Lluvia ligera',
      'moderate rain': 'Lluvia moderada',
      'heavy intensity rain': 'Lluvia intensa',
      'very heavy rain': 'Lluvia muy intensa',
      'extreme rain': 'Lluvia extrema',
      'freezing rain': 'Lluvia helada',
      'light intensity shower rain': 'Chubascos de intensidad ligera',
      'shower rain': 'Chubascos',
      'heavy intensity shower rain': 'Chubascos de intensidad fuerte',
      'ragged shower rain': 'Chubascos irregulares',
      'light snow': 'Nieve ligera',
      'snow': 'Nieve',
      'heavy snow': 'Nieve intensa',
      'sleet': 'Aguanieve',
      'light shower sleet': 'Aguanieve ligera',
      'shower sleet': 'Aguanieve',
      'light rain and snow': 'Lluvia y nieve ligera',
      'rain and snow': 'Lluvia y nieve',
      'light shower snow': 'Chubascos de nieve ligera',
      'shower snow': 'Chubascos de nieve',
      'heavy shower snow': 'Chubascos de nieve intensa',
      'mist': 'Neblina',
      'smoke': 'Humo',
      'haze': 'Calina',
      'sand/dust whirls': 'Remolinos de arena/polvo',
      'fog': 'Niebla',
      'sand': 'Arena',
      'dust': 'Polvo',
      'volcanic ash': 'Ceniza volcánica',
      'squalls': 'Ráfagas',
      'tornado': 'Tornado',
      'thunderstorm with light rain': 'Tormenta con lluvia ligera',
      'thunderstorm with rain': 'Tormenta con lluvia',
      'thunderstorm with heavy rain': 'Tormenta con lluvia intensa',
      'light thunderstorm': 'Tormenta ligera',
      'thunderstorm': 'Tormenta',
      'heavy thunderstorm': 'Tormenta fuerte',
      'ragged thunderstorm': 'Tormenta irregular',
      'thunderstorm with light drizzle': 'Tormenta con llovizna ligera',
      'thunderstorm with drizzle': 'Tormenta con llovizna',
      'thunderstorm with heavy drizzle': 'Tormenta con llovizna intensa',
      'light intensity drizzle': 'Llovizna de intensidad ligera',
      'drizzle': 'Llovizna',
      'heavy intensity drizzle': 'Llovizna de intensidad fuerte',
      'light intensity drizzle rain': 'Lluvia ligera con llovizna',
      'drizzle rain': 'Lluvia con llovizna',
      'heavy intensity drizzle rain': 'Lluvia intensa con llovizna',
      'shower rain and drizzle': 'Chubascos y llovizna',
      'heavy shower rain and drizzle': 'Chubascos intensos y llovizna',
      'shower drizzle': 'Llovizna intermitente',
      'light intensity rain': 'Lluvia de intensidad ligera',
      'moderate or heavy rain shower': 'Chubasco moderado o fuerte',
      'torrential rain shower': 'Chubasco torrencial',
      'patchy rain possible': 'Posible lluvia intermitente',
      'patchy light drizzle': 'Llovizna ligera aislada',
      'patchy light rain': 'Lluvia ligera aislada',
      'patchy moderate rain': 'Lluvia moderada aislada',
      'patchy heavy rain': 'Lluvia intensa aislada',
      'patchy light snow': 'Nieve ligera aislada',
      'patchy moderate snow': 'Nieve moderada aislada',
      'patchy heavy snow': 'Nieve intensa aislada',
      'patchy sleet': 'Aguanieve aislada',
      'light sleet showers': 'Chubascos de aguanieve ligera',
      'moderate or heavy sleet showers':
          'Chubascos de aguanieve moderada o fuerte',
      'moderate or heavy snow showers': 'Chubascos de nieve moderada o fuerte',
      'patchy freezing drizzle': 'Llovizna helada aislada',
      'moderate or heavy freezing rain': 'Lluvia helada moderada o fuerte',
      'light showers of ice pellets': 'Chubascos de granizo pequeño',
      'moderate or heavy showers of ice pellets':
          'Chubascos intensos de granizo',
      'patchy light rain with thunder': 'Lluvia ligera con truenos dispersos',
      'moderate or heavy rain with thunder':
          'Lluvia moderada o fuerte con truenos',
      'patchy light snow with thunder': 'Nieve ligera con truenos dispersos',
      'moderate or heavy snow with thunder':
          'Nieve moderada o fuerte con truenos',
      'isolated thunderstorms': 'Tormentas aisladas',
      'scattered thunderstorms': 'Tormentas dispersas',
      'thundery outbreaks possible': 'Posibles brotes tormentosos',
      'thundery outbreaks in nearby': 'Posibles brotes tormentosos cerca',
      'patchy rain nearby': 'Lluvias intermitentes',
      'partly cloudy': 'Parcialmente nublado',
      'sunny': 'Soleado',
      'clear': 'Despejado',
      'cloudy': 'Nublado',
    };

    for (final entrada in traducciones.entries) {
      if (lower.contains(entrada.key)) {
        return entrada.value;
      }
    }

    return toBeginningOfSentenceCase(desc) ?? desc;
  }

  Widget _infoCard(
    IconData icon,
    String label,
    String value,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: textColor),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 12)),
          Text(
            value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

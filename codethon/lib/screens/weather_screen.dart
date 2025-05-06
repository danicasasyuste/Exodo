import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import '../models/weather_override.dart';
import '../services/response_analysis_service.dart';
import '../services/notification_service.dart';

import '../screens/map_screen.dart';

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
    MunicipioValenciano(nombre: 'Torrent', query: '39.4375,-0.4647'),
    MunicipioValenciano(nombre: 'Gandía', query: '38.9681,-0.1830'),
    MunicipioValenciano(nombre: 'Paterna', query: '39.5021,-0.4408'),
    MunicipioValenciano(nombre: 'Sagunto', query: '39.6796,-0.2784'),
    MunicipioValenciano(nombre: 'Xirivella', query: '39.4667,-0.4333'),
    MunicipioValenciano(nombre: 'Alzira', query: '39.1506,-0.4356'),
    MunicipioValenciano(nombre: 'Ontinyent', query: '38.8167,-0.6000'),
    MunicipioValenciano(nombre: 'Mislata', query: '39.4766,-0.4162'),
    MunicipioValenciano(nombre: 'Manises', query: '39.4889,-0.4632'),
    MunicipioValenciano(nombre: 'Cullera', query: '39.1667,-0.25'),
    MunicipioValenciano(nombre: 'Burjassot', query: '39.50952,-0.41346'),
  ];

  @override
  void initState() {
    super.initState();

    _fetchWeather();

    _updateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchWeather();
    });
    _verificacionTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _evaluarRespuestas();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _verificacionTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar los datos: $e')));
    }
    if (_currentWeather!.description.toLowerCase().contains('rain')) {
      NotificationService.mostrarPregunta(
        _selectedCity,
        'lluvia',
        '¿Sigue lloviendo en tu zona?',
      );
    }
  }

  Future<void> _evaluarRespuestas() async {
    final modificar = await ResponseAnalysisService.debeModificarEstado(
      _selectedCity,
      'lluvia',
    );
    if (modificar) {
      setState(() {
        _override.overrideActiva = true;
        _override.lluvia = false;
      });
      NotificationService.notificarCambioEstado('✅ Ha dejado de llover');
    } else {
      setState(() {
        _override.overrideActiva = false;
      });
    }
  }

  String getLottieAsset(String description) {
    final desc = description.toLowerCase();
    final bool isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;

    if (desc.contains('thunder') || desc.contains('storm')) {
      return 'assets/lottie/weather/lighting.json';
    } else if (desc.contains('rain')) {
      return isNight
          ? 'assets/lottie/weather/night-rain.json'
          : 'assets/lottie/weather/rain-light.json';
    } else if (desc.contains('fog') || desc.contains('mist')) {
      return 'assets/lottie/weather/fog.json';
    } else if (desc.contains('cloud')) {
      return isNight
          ? 'assets/lottie/weather/night-cloud.json'
          : 'assets/lottie/weather/cloudy.json';
    } else if (desc.contains('clear') || desc.contains('sunny')) {
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
            : 'assets/images/maps_card_night.jpg';

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child:
            _showLoading || _currentWeather == null
                ? Center(
                  child: Lottie.asset(
                    'assets/lottie/intro.json',
                    width: 180,
                    onLoaded: (composition) {
                      Future.delayed(composition.duration, () {
                        _fetchWeather();
                        setState(() {
                          _showLoading = false;
                        });
                      });
                    },
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: icono, size: 37),
                                const SizedBox(width: 8),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton2<MunicipioValenciano>(
                                    isExpanded: true,
                                    customButton: SizedBox(
                                      width: 150, // o el ancho que tú prefieras
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                                fontSize: 23,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: icono,
                                            size: 32,
                                          ),
                                        ],
                                      ),
                                    ),

                                    dropdownStyleData: DropdownStyleData(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: dropDown,
                                      ),
                                      offset: const Offset(0, -8),
                                      maxHeight: kMinInteractiveDimension * 5,
                                    ),
                                    value: municipiosValencianos.firstWhere(
                                      (m) => m.query == _selectedCity,
                                      orElse: () => municipiosValencianos[0],
                                    ),
                                    items:
                                        municipiosValencianos.map((m) {
                                          return DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m.nombre,
                                              style: TextStyle(color: texto),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (MunicipioValenciano? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedCity = newValue.query;
                                        });
                                        _fetchWeather();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.calendar_today, color: icono, size: 28),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: Center(
                          child: Lottie.asset(
                            getLottieAsset(_currentWeather!.description),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${municipiosValencianos.firstWhere((m) => m.query == _selectedCity, orElse: () => municipiosValencianos[0]).nombre} tiene',
                              style: TextStyle(
                                fontSize: 20,
                                color: texto.withAlpha(230),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                              _override.overrideActiva && !_override.lluvia
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
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoCard(
                            Icons.water_drop,
                            'Humedad',
                            '${_currentWeather!.humidity}%',
                            card,
                            texto,
                          ),
                          _infoCard(
                            Icons.air,
                            'Viento',
                            '${_currentWeather!.windSpeed} km/h',
                            card,
                            texto,
                          ),
                          _infoCard(
                            Icons.speed,
                            'Presión',
                            '${_currentWeather!.pressure} hPa',
                            card,
                            texto,
                          ),
                          _infoCard(
                            Icons.thermostat,
                            'Sensación',
                            '${_currentWeather!.feelsLike}°C',
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
                                  horizontal: 8,
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
                                                    (m) => m[0]!.toUpperCase(),
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
                                      offset: Offset(0, 2),
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
      'patchy rain nearby': 'Lluvias intermitentes en las cercanías',
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

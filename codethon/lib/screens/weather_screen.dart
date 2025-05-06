import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = '39.4699,-0.3763';
  bool _showClearIcon = false;
  Timer? _updateTimer;

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

    _searchController.addListener(() {
      setState(() {
        _showClearIcon = _searchController.text.isNotEmpty;
      });
    });

    _fetchWeather();

    _updateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchWeather();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.getWeather(_selectedCity);
      final forecast = await _weatherService.getForecast(_selectedCity);
      if (!mounted) return;
      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar los datos: $e')));
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
    final Color sombra =
        isNight ? const Color.fromARGB(30, 65, 90, 119) : Colors.black12;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child:
            _currentWeather == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: sombra,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: icono),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<MunicipioValenciano>(
                                  value: municipiosValencianos.firstWhere(
                                    (m) => m.query == _selectedCity,
                                    orElse: () => municipiosValencianos[0],
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: icono,
                                  ),
                                  dropdownColor: card,
                                  style: TextStyle(color: texto),
                                  onChanged: (MunicipioValenciano? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCity = newValue.query;
                                      });
                                      _fetchWeather();
                                    }
                                  },
                                  items:
                                      municipiosValencianos.map((m) {
                                        return DropdownMenuItem(
                                          value: m,
                                          child: Text(m.nombre),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
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
                              '${_searchController.text.isNotEmpty ? _searchController.text : 'Tu ubicación'} tiene',
                              style: TextStyle(
                                fontSize: 20,
                                color: texto.withAlpha(230),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_currentWeather!.temperature}°C',
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: texto,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _translateDescription(
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
                                  image: const DecorationImage(
                                    image: AssetImage(
                                      'assets/images/maps_card_bg.png',
                                    ),
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
    };

    for (final entrada in traducciones.entries) {
      if (lower.contains(entrada.key)) {
        return entrada.value;
      }
    }

    return desc;
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class MunicipioValenciano {
  final String nombre; // Para mostrar en el buscador y app bar
  final String query; // Para usar en el parámetro `q` de la API

  MunicipioValenciano({required this.nombre, required this.query});
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  List<Weather>? _forecast;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCity = '39.4699,-0.3763'; // Por defecto: Valencia

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
  }

  Future<void> _fetchWeather() async {
  try {
    final weather = await _weatherService.getWeather(_selectedCity);
    final forecast = await _weatherService.getForecast(_selectedCity);
    setState(() {
      _currentWeather = weather;
      _forecast = forecast;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cargar los datos: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _searchController.text.isNotEmpty
              ? _searchController.text
              : "Municipio",
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWeather),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        child:
            _currentWeather == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 88.0,
                      ),
                      child: Autocomplete<MunicipioValenciano>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return municipiosValencianos.where(
                            (municipio) => municipio.nombre
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()),
                          );
                        },
                        displayStringForOption:
                            (MunicipioValenciano option) => option.nombre,
                        onSelected: (MunicipioValenciano selection) {
                          setState(() {
                            _selectedCity = selection.query;
                            _searchController.text = selection.nombre;
                          });
                          _fetchWeather();
                          _searchFocusNode.unfocus();
                        },
                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onEditingComplete,
                        ) {
                          controller.text = _searchController.text;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (value) {
                              _searchController.text = value;
                            },
                            onSubmitted: (_) => onEditingComplete(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Buscar municipio...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 100),
                    Text(
                      '${_currentWeather!.temperature}°C',
                      style: const TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _currentWeather!.description,
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoCard(
                          Icons.water_drop,
                          'Humedad',
                          '${_currentWeather!.humidity}%',
                        ),
                        _buildInfoCard(
                          Icons.air,
                          'Viento',
                          '${_currentWeather!.windSpeed} km/h',
                        ),
                        _buildInfoCard(
                          Icons.speed,
                          'Presión',
                          '${_currentWeather!.pressure} hPa',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _forecast == null
                        ? const CircularProgressIndicator()
                        : SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _forecast!.length,
                            itemBuilder: (context, index) {
                              final day = _forecast![index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ForecastDetailScreen(day: day),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 90,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat.EEEE(
                                          'es_ES',
                                        ).format(day.date),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Image.network(
                                        day.iconUrl,
                                        width: 45,
                                        height: 45,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${day.temperature}°C',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class ForecastDetailScreen extends StatelessWidget {
  final Weather day;

  const ForecastDetailScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(DateFormat.EEEE('es_ES').format(day.date)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(day.iconUrl, width: 100, height: 100),
                const SizedBox(height: 20),
                Text(
                  '${day.temperature}°C',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  day.description,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailIcon(
                      Icons.water_drop,
                      '${day.humidity}%',
                      'Humedad',
                    ),
                    _buildDetailIcon(
                      Icons.air,
                      '${day.windSpeed} km/h',
                      'Viento',
                    ),
                    _buildDetailIcon(
                      Icons.speed,
                      day.pressure > 0 ? '${day.pressure} hPa' : '—',
                      'Presión',
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

  Widget _buildDetailIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

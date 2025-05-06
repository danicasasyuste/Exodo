import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/weather.dart';

class WeatherService {
  final String _apiKey = 'ab5ff60e7788472badf195210253003';
  final String _baseUrl = 'http://api.weatherapi.com/v1';
  final Logger _logger = Logger();

  /// Clima actual
  Future<Weather> getWeather(String city) async {
    final url = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$city&aqi=no');
    final response = await http.get(url);

    _logger.i('GET current weather → ${response.statusCode}');
    _logger.d(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      _logger.e('Error al obtener clima: ${error['error']['message']}');
      throw Exception('Error: ${error['error']['message']}');
    }
  }

  /// Pronóstico diario para varios días
  Future<List<Weather>> getForecast(String city) async {
    final url = Uri.parse(
      '$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=7&aqi=no&alerts=no',
    );
    final response = await http.get(url);

    _logger.i('GET forecast → ${response.statusCode}');
    _logger.d(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> forecastDays = data['forecast']['forecastday'];
      return forecastDays
          .map((json) => Weather.fromJsonForecast(json))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      _logger.e('Error al obtener pronóstico: ${error['error']['message']}');
      throw Exception('Error: ${error['error']['message']}');
    }
  }

  /// Pronóstico por horas (día actual)
  Future<List<Weather>> getHourlyForecast(String city) async {
    final url = Uri.parse(
      '$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=1&aqi=no&alerts=no',
    );
    final response = await http.get(url);

    _logger.i('GET hourly forecast → ${response.statusCode}');
    _logger.d(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> hourlyData = data['forecast']['forecastday'][0]['hour'];
      return hourlyData.map((json) => Weather.fromJsonHourly(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      _logger.e('Error al obtener el pronóstico por hora: ${error['error']['message']}');
      throw Exception('Error: ${error['error']['message']}');
    }
  }
}

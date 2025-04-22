import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  final String _apiKey = 'ab5ff60e7788472badf195210253003';
  final String _baseUrl = 'http://api.weatherapi.com/v1';

  Future<Weather> getWeather(String city) async {
    final url = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$city&aqi=no');
    final response = await http.get(url);

    print('Respuesta: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Error: ${error['error']['message']}');
    }
  }

  Future<List<Weather>> getForecast(String city) async {
    final url = Uri.parse('$_baseUrl/forecast.json?key=$_apiKey&q=$city&days=7&aqi=no&alerts=no');
    final response = await http.get(url);
    

    print('Respuesta: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> forecastDays = data['forecast']['forecastday'];
      return forecastDays.map((json) => Weather.fromJsonForecast(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Error: ${error['error']['message']}');
    }
  }
}

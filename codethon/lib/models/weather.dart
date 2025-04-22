class Weather {
  final DateTime date;
  final String description;
  final String iconUrl;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int pressure;

  Weather({
    required this.date,
    required this.description,
    required this.iconUrl,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      date: DateTime.parse(json['location']['localtime']),
      description: json['current']['condition']['text'],
      iconUrl: 'https:${json['current']['condition']['icon']}',
      temperature: json['current']['temp_c'].toDouble(),
      humidity: json['current']['humidity'],
      windSpeed: json['current']['wind_kph'].toDouble(),
      pressure: json['current']['pressure_mb'].toInt(),
    );
  }

  factory Weather.fromJsonForecast(Map<String, dynamic> json) {
    return Weather(
      date: DateTime.parse(json['date']),
      description: json['day']['condition']['text'],
      iconUrl: 'https:${json['day']['condition']['icon']}',
      temperature: json['day']['avgtemp_c'].toDouble(),
      humidity: json['day']['avghumidity'].toInt(),
      windSpeed: json['day']['maxwind_kph'].toDouble(),
      pressure: 0, // WeatherAPI no da presión diaria en forecast
    );
  }
}

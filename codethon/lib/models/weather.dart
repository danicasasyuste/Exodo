class Weather {
  final DateTime date;
  final String description;
  final String iconUrl;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int pressure;

  final bool willRain;
  final bool isThunderstorm;

  Weather({
    required this.date,
    required this.description,
    required this.iconUrl,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.willRain,
    required this.isThunderstorm,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return Weather(
      date: DateTime.parse(json['location']['localtime']),
      description: current['condition']['text'] ?? '',
      iconUrl: 'https:${current['condition']['icon'] ?? ''}',
      temperature: (current['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      humidity: current['humidity'] ?? 0,
      windSpeed: (current['wind_kph'] as num?)?.toDouble() ?? 0.0,
      pressure: (current['pressure_mb'] as num?)?.toInt() ?? 0,
      willRain: current['will_it_rain'] == 1,
      isThunderstorm: (current['chance_of_tstorm'] ?? 0) > 50,
    );
  }

  factory Weather.fromJsonHourly(Map<String, dynamic> json) {
    return Weather(
      date: DateTime.parse(json['time']),
      description: json['condition']['text'] ?? '',
      iconUrl: 'https:${json['condition']['icon'] ?? ''}',
      temperature: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['wind_kph'] as num?)?.toDouble() ?? 0.0,
      pressure: (json['pressure_mb'] as num?)?.toInt() ?? 0,
      willRain: json['will_it_rain'] == 1,
      isThunderstorm: (json['chance_of_tstorm'] ?? 0) > 50,
    );
  }

  factory Weather.fromJsonForecast(Map<String, dynamic> json) {
    final day = json['day'];
    return Weather(
      date: DateTime.parse(json['date']),
      description: day['condition']['text'] ?? '',
      iconUrl: 'https:${day['condition']['icon'] ?? ''}',
      temperature: (day['avgtemp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (day['avgtemp_c'] as num?)?.toDouble() ?? 0.0,
      humidity: day['avghumidity'] ?? 0,
      windSpeed: (day['maxwind_kph'] as num?)?.toDouble() ?? 0.0,
      pressure: 0, // aún no disponible en el forecast
      willRain: day['daily_will_it_rain'] == 1,
      isThunderstorm: (day['daily_chance_of_tstorm'] ?? 0) > 50,
    );
  }
}

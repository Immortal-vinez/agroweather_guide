class Weather {
  factory Weather.fromJson(Map<String, dynamic> json) {
    double rainfall = 0.0;
    if (json.containsKey('rain')) {
      if (json['rain'] is Map && json['rain'].containsKey('1h')) {
        rainfall = (json['rain']['1h'] as num?)?.toDouble() ?? 0.0;
      } else if (json['rain'] is num) {
        rainfall = (json['rain'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return Weather(
      description:
          json['weather'] != null && json['weather'].isNotEmpty
              ? json['weather'][0]['description'] ?? ''
              : '',
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      condition:
          json['weather'] != null && json['weather'].isNotEmpty
              ? json['weather'][0]['main'] ?? ''
              : '',
      forecast:
          json['weather'] != null && json['weather'].isNotEmpty
              ? json['weather'][0]['description'] ?? ''
              : '',
      rainfall: rainfall,
    );
  }
  final String description;
  final double temperature;
  final String condition;
  final String forecast;
  final double rainfall;

  Weather({
    required this.description,
    required this.temperature,
    required this.condition,
    required this.forecast,
    required this.rainfall,
  });
}

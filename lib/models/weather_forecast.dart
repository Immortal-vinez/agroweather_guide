class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String condition;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000, isUtc: true),
      temperature: (json['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String condition;
  final double rainfall;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.rainfall,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    double rain = 0.0;
    if (json.containsKey('rain')) {
      rain = (json['rain'] as num?)?.toDouble() ?? 0.0;
    }
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000, isUtc: true),
      minTemp: (json['temp']['min'] as num).toDouble(),
      maxTemp: (json['temp']['max'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
      rainfall: rain,
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final double precipitationMm; // daily sum
  final int weatherCode; // open-meteo WMO code

  const DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.precipitationMm,
    required this.weatherCode,
  });
}

class DailyForecastService {
  Future<List<DailyForecast>> fetch7Day({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode',
        'timezone': 'auto',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Failed to load forecast (${res.statusCode})');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final daily = j['daily'] as Map<String, dynamic>?;
    if (daily == null) return [];
    final List dates = daily['time'] as List? ?? const [];
    final List tmax = daily['temperature_2m_max'] as List? ?? const [];
    final List tmin = daily['temperature_2m_min'] as List? ?? const [];
    final List prcp = daily['precipitation_sum'] as List? ?? const [];
    final List codes = daily['weathercode'] as List? ?? const [];

    final len = [dates.length, tmax.length, tmin.length, prcp.length, codes.length]
        .reduce((a, b) => a < b ? a : b);
    final now = DateTime.now();
    final List<DailyForecast> out = [];
    for (int i = 0; i < len && out.length < 7; i++) {
      final dStr = dates[i] as String;
      final d = DateTime.tryParse(dStr) ?? now.add(Duration(days: i));
      out.add(
        DailyForecast(
          date: d,
          minTemp: (tmin[i] as num?)?.toDouble() ?? 0,
          maxTemp: (tmax[i] as num?)?.toDouble() ?? 0,
          precipitationMm: (prcp[i] as num?)?.toDouble() ?? 0,
          weatherCode: (codes[i] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return out;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String condition; // clear, rain, clouds, etc.
  final double precipitationMm; // total precipitation if available
  final double pop; // probability of precipitation 0..1

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.precipitationMm,
    required this.pop,
  });
}

class ForecastService {
  final String apiKey;
  ForecastService(this.apiKey);

  bool get _hasKey => apiKey.isNotEmpty;

  Future<List<DailyForecast>> fetchDailyForecast({
    required double lat,
    required double lon,
    int days = 7,
  }) async {
    if (_hasKey) {
      final result = await _fetchOpenWeather(lat: lat, lon: lon, days: days);
      if (result != null) return result;
    }
    // Fallback to Open-Meteo free API
    final fallback = await _fetchOpenMeteo(lat: lat, lon: lon, days: days);
    return fallback ?? <DailyForecast>[];
  }

  Future<List<DailyForecast>?> _fetchOpenWeather({
    required double lat,
    required double lon,
    int days = 7,
  }) async {
    try {
      // OpenWeather One Call 3.0 (daily)
      final uri = Uri.https('api.openweathermap.org', '/data/3.0/onecall', {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
        'exclude': 'minutely,hourly,current,alerts',
        'units': 'metric',
        'appid': apiKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final List d = j['daily'] as List? ?? [];
      final out = <DailyForecast>[];
      for (final e in d.take(days)) {
        final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000,
                isUtc: true)
            .toLocal();
        final temp = e['temp'] as Map<String, dynamic>?;
        final min = (temp?['min'] as num?)?.toDouble() ?? 0;
        final max = (temp?['max'] as num?)?.toDouble() ?? 0;
        final weather = (e['weather'] as List?)?.isNotEmpty == true
            ? e['weather'][0] as Map<String, dynamic>
            : null;
        final main = (weather?['main'] as String?) ?? 'Clear';
        final rainMm = (e['rain'] as num?)?.toDouble() ?? 0.0;
        final snowMm = (e['snow'] as num?)?.toDouble() ?? 0.0;
        final pop = (e['pop'] as num?)?.toDouble() ?? 0.0;
        out.add(
          DailyForecast(
            date: dt,
            minTemp: min,
            maxTemp: max,
            condition: main,
            precipitationMm: rainMm + snowMm,
            pop: pop,
          ),
        );
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<List<DailyForecast>?> _fetchOpenMeteo({
    required double lat,
    required double lon,
    int days = 7,
  }) async {
    try {
      final params = {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lon.toStringAsFixed(4),
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
        'forecast_days': days.toString(),
        'timezone': 'auto',
      };
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', params);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final daily = j['daily'] as Map<String, dynamic>?;
      if (daily == null) return null;
      final times = (daily['time'] as List).cast<String>();
      final tmax = (daily['temperature_2m_max'] as List).cast<num>();
      final tmin = (daily['temperature_2m_min'] as List).cast<num>();
      final wcode = (daily['weather_code'] as List).cast<num>();
      final prsum = (daily['precipitation_sum'] as List).cast<num>();
      final popMax =
          (daily['precipitation_probability_max'] as List?)?.cast<num?>();
      final out = <DailyForecast>[];
      for (int i = 0; i < times.length && i < days; i++) {
        final date = DateTime.parse(times[i]);
        out.add(DailyForecast(
          date: date,
          minTemp: tmin[i].toDouble(),
          maxTemp: tmax[i].toDouble(),
          condition: _mapWmo(wcode[i].toInt()),
          precipitationMm: prsum[i].toDouble(),
          pop: (popMax != null && i < popMax.length && popMax[i] != null)
              ? (popMax[i]! / 100.0)
              : 0.0,
        ));
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  String _mapWmo(int code) {
    // Simplified WMO code mapping
    if (code == 0) return 'Clear';
    if ([1, 2, 3].contains(code)) return 'Clouds';
    if ([45, 48].contains(code)) return 'Fog';
    if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
    if ([61, 63, 65, 80, 81, 82].contains(code)) return 'Rain';
    if ([66, 67].contains(code)) return 'Freezing Rain';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'Snow';
    if ([95, 96, 97].contains(code)) return 'Thunderstorm';
    return 'Clouds';
  }

  // 3-hourly forecast (OpenWeather 5-day/3-hour endpoint)
  Future<List<ThreeHourForecast>> fetch3HourlyForecast({
    required double lat,
    required double lon,
    int limit = 16, // ~2 days worth by default
  }) async {
    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
        'units': 'metric',
        'appid': apiKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return <ThreeHourForecast>[];
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (j['list'] as List?) ?? const [];
      final out = <ThreeHourForecast>[];
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final dt = DateTime.fromMillisecondsSinceEpoch((m['dt'] as int) * 1000,
                isUtc: true)
            .toLocal();
        final main = (m['main'] as Map<String, dynamic>?);
        final temp = (main?['temp'] as num?)?.toDouble() ?? 0.0;
        final weather = (m['weather'] as List?)?.isNotEmpty == true
            ? m['weather'][0] as Map<String, dynamic>
            : null;
        final condition = (weather?['main'] as String?) ?? 'Clear';
        final pop = (m['pop'] as num?)?.toDouble() ?? 0.0;
        out.add(ThreeHourForecast(
            time: dt, temp: temp, condition: condition, pop: pop));
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return <ThreeHourForecast>[];
    }
  }
}

class ThreeHourForecast {
  final DateTime time;
  final double temp;
  final String condition;
  final double pop; // 0..1
  ThreeHourForecast({
    required this.time,
    required this.temp,
    required this.condition,
    required this.pop,
  });
}

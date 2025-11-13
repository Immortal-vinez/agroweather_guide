import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class SeasonalOutlook {
  final String periodLabel; // e.g., "Nov–Jan"
  final double rainfallAnomaly; // percent
  final double tempAnomaly; // °C
  final String rainfallCategory; // Above / Near / Below
  final String tempCategory; // Above / Near / Below
  final String summary;

  const SeasonalOutlook({
    required this.periodLabel,
    required this.rainfallAnomaly,
    required this.tempAnomaly,
    required this.rainfallCategory,
    required this.tempCategory,
    required this.summary,
  });
}

class SeasonalForecastService {
  final String? apiBaseUrl;
  SeasonalForecastService({String? apiBaseUrl})
      : apiBaseUrl = apiBaseUrl ?? Env.seasonalApiUrl;

  Future<SeasonalOutlook?> fetchOutlook({
    required double latitude,
    required double longitude,
    DateTime? ref,
  }) async {
    final now = ref ?? DateTime.now();
    final tripleEnd = DateTime(now.year, now.month + 3, 0);
    final period = '${_mmm(now)}–${_mmm(tripleEnd)}';

    // If a custom API base is provided, try that first (must return JSON fields like below)
    final base = apiBaseUrl;
    if (base != null && base.isNotEmpty) {
      try {
        final uri = Uri.parse(
          '$base/outlook?lat=${latitude.toStringAsFixed(4)}&lon=${longitude.toStringAsFixed(4)}&year=${now.year}&month=${now.month}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body) as Map<String, dynamic>;
          final rain = (j['rainfallAnomalyPct'] as num?)?.toDouble() ?? 0.0;
          final temp = (j['tempAnomalyC'] as num?)?.toDouble() ?? 0.0;
          final rainCat = j['rainfallCategory'] as String? ?? _catPct(rain);
          final tempCat = j['tempCategory'] as String? ?? _catTemp(temp);
          final summary = j['summary'] as String? ??
              _buildSummary(period, rain, temp, rainCat, tempCat);
          return SeasonalOutlook(
            periodLabel: period,
            rainfallAnomaly: rain,
            tempAnomaly: temp,
            rainfallCategory: rainCat,
            tempCategory: tempCat,
            summary: summary,
          );
        }
      } catch (_) {
        // fall through to Open-Meteo
      }
    }

    // Default: Open-Meteo Seasonal API (ECMWF SEAS5)
    try {
      final uri = Uri.https(
        'seasonal-api.open-meteo.com',
        '/v1/seasonal',
        {
          'latitude': latitude.toStringAsFixed(4),
          'longitude': longitude.toStringAsFixed(4),
          'models': 'ecmwf_seas5',
          'monthly_mean_2m_temperature_anomaly': 'true',
          'monthly_mean_precipitation_anomaly': 'true',
          'timezone': 'auto',
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      // The API returns arrays per month; we can average the next 3 months
      double avgPctRain = 0.0;
      double avgTemp = 0.0;
      int n = 0;
      // Parse helpers
      List<dynamic>? ra = j['monthly_mean_precipitation_anomaly'] as List?;
      List<dynamic>? ta = j['monthly_mean_2m_temperature_anomaly'] as List?;
      if (ra != null && ra.isNotEmpty) {
        for (final v in ra.take(3)) {
          if (v is num) {
            avgPctRain += v.toDouble();
            n++;
          }
        }
      }
      if (ta != null && ta.isNotEmpty) {
        int m = 0;
        for (final v in ta.take(3)) {
          if (v is num) {
            avgTemp += v.toDouble();
            m++;
          }
        }
        if (m > 0) avgTemp = avgTemp / m;
      }
      if (n > 0) avgPctRain = avgPctRain / n;
      final rainCat = _catPct(avgPctRain);
      final tempCat = _catTemp(avgTemp);
      final summary = _buildSummary(period, avgPctRain, avgTemp, rainCat, tempCat);
      return SeasonalOutlook(
        periodLabel: period,
        rainfallAnomaly: avgPctRain,
        tempAnomaly: avgTemp,
        rainfallCategory: rainCat,
        tempCategory: tempCat,
        summary: summary,
      );
    } catch (_) {
      return null;
    }
  }

  String _mmm(DateTime d) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1];

  String _catPct(double pct) {
    if (pct >= 10) return 'Above';
    if (pct <= -10) return 'Below';
    return 'Near';
  }

  String _catTemp(double c) {
    if (c >= 0.5) return 'Above';
    if (c <= -0.5) return 'Below';
    return 'Near';
  }

  String _buildSummary(String period, double rain, double temp, String rainCat, String tempCat) {
    final rainArrow = rain > 0 ? '↑' : (rain < 0 ? '↓' : '→');
    final tempArrow = temp > 0 ? '↑' : (temp < 0 ? '↓' : '→');
    return 'Outlook $period: Rain $rainCat $rainArrow ${rain.toStringAsFixed(0)}%, Temp $tempCat $tempArrow ${temp.toStringAsFixed(1)}°C';
  }
}

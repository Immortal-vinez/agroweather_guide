import 'package:weather/weather.dart';
import 'package:flutter/material.dart';

// Helper functions must be top-level, not inside build or widget methods
String weekdayName(DateTime date) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return days[date.weekday % 7];
}

IconData weatherIcon(String? condition) {
  if (condition == null) return Icons.cloud;
  switch (condition.toLowerCase()) {
    case 'rain':
      return Icons.beach_access;
    case 'clouds':
      return Icons.cloud;
    case 'clear':
      return Icons.wb_sunny;
    case 'snow':
      return Icons.ac_unit;
    case 'storm':
      return Icons.flash_on;
    default:
      return Icons.cloud;
  }
}

class WeatherForecastSection extends StatelessWidget {
  final List<Weather> hourly;
  final List<Weather> daily;
  const WeatherForecastSection({
    super.key,
    required this.hourly,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
    final bool noHourly = hourly.isEmpty;
    final bool noDaily = daily.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Hourly Forecast',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
        if (noHourly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.grey, size: 32),
                SizedBox(height: 8),
                Text(
                  'No hourly forecast data available',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final h = hourly[i];
                return Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFF81D4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        h.date != null ? '${h.date!.hour}:00' : '--:--',
                        style: TextStyle(color: Colors.black54),
                      ),
                      Icon(
                        weatherIcon(h.weatherMain),
                        color: Color(0xFFFFEB3B),
                      ),
                      Text(
                        h.temperature != null
                            ? '${h.temperature!.celsius?.toStringAsFixed(0)}°C'
                            : '--°C',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Daily Forecast',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
        if (noDaily)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey, size: 32),
                SizedBox(height: 8),
                Text(
                  'No daily forecast data available',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: daily.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final d = daily[i];
                return Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: Color(0xFF81D4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        d.date != null ? weekdayName(d.date!) : '--',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        weatherIcon(d.weatherMain),
                        color: Color(0xFF90A4AE),
                      ),
                      Text(
                        d.tempMax != null && d.tempMin != null
                            ? '${d.tempMax!.celsius?.toStringAsFixed(0)}°/${d.tempMin!.celsius?.toStringAsFixed(0)}°'
                            : '--/--',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        d.weatherMain ?? '--',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        d.rainLast3h != null
                            ? 'Rain: ${d.rainLast3h!.toStringAsFixed(1)} mm'
                            : 'Rain: -- mm',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

extension on Weather {
  // ignore: strict_top_level_inference
  get rainLast3h => null;
}

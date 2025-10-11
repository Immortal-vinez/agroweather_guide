import '../models/weather_forecast.dart';
import 'package:flutter/material.dart';

// Helper functions must be top-level, not inside build or widget methods
String weekdayName(DateTime date) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return days[date.weekday % 7];
}

IconData weatherIcon(String condition) {
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
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  const WeatherForecastSection({
    super.key,
    required this.hourly,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hourly.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                      '${h.time.hour}:00',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Icon(weatherIcon(h.condition), color: Color(0xFFFFEB3B)),
                    Text(
                      '${h.temperature.toStringAsFixed(0)}°C',
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
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: daily.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                      weekdayName(d.date),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Icon(weatherIcon(d.condition), color: Color(0xFF90A4AE)),
                    Text(
                      '${d.maxTemp.toStringAsFixed(0)}°/${d.minTemp.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      d.condition,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Rain: ${d.rainfall.toStringAsFixed(1)} mm',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
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

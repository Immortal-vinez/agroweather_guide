import 'package:flutter/material.dart';
import '../models/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;
  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF81D4FA), // Sky Blue
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Weather",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  weather.condition.toLowerCase().contains('sun')
                      ? Icons.wb_sunny
                      : Icons.cloud,
                  color: Color(0xFFFFEB3B),
                ), // Sunshine Yellow
                const SizedBox(width: 8),
                Text(
                  '${weather.temperature.toStringAsFixed(1)}°C, ${weather.condition}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Forecast: ${weather.forecast}',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

/// Weather service using Agro Monitoring API for agricultural weather data
class WeatherService {
  static const String _baseUrl = 'https://api.agromonitoring.com/agro/1.0';
  final String apiKey;
  final bool demoMode;

  WeatherService(this.apiKey, {this.demoMode = false});

  /// Fetch current weather using Agro Monitoring API
  Future<Weather> fetchCurrentWeather(double lat, double lon) async {
    if (demoMode || apiKey.isEmpty) {
      return _getDemoWeatherData();
    }

    final url = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey',
    );

    try {
      print('🌤️ Fetching weather from Agro Monitoring API...');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received');
        return Weather.fromJson(data);
      } else if (response.statusCode == 401) {
        print('❌ Invalid API key');
        print('🔑 Get your key at: https://agromonitoring.com/api');
        return _getDemoWeatherData();
      } else {
        print('⚠️ Weather API error: ${response.statusCode}');
        return _getDemoWeatherData();
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') ||
          errorMsg.contains('ClientException')) {
        print('🌐 Web CORS Error: Browser blocked request');
        print(
            '💡 Use mobile/desktop app or run Chrome with --disable-web-security');
      }
      return _getDemoWeatherData();
    }
  }

  // Demo weather data for testing without internet
  Weather _getDemoWeatherData() {
    // Generate different weather scenarios based on time of day
    final hour = DateTime.now().hour;
    final scenarios = [
      // Morning scenario
      Weather(
        description: 'Clear sky',
        temperature: 22.0,
        condition: 'Clear',
        forecast: 'Perfect morning for farming activities',
        rainfall: 0.0,
        humidity: 70.0,
        windSpeed: 2.1,
        pressure: 1015,
      ),
      // Afternoon scenario
      Weather(
        description: 'Partly cloudy',
        temperature: 28.5,
        condition: 'Clouds',
        forecast: 'Good conditions for crop growth',
        rainfall: 1.2,
        humidity: 60.0,
        windSpeed: 3.5,
        pressure: 1012,
      ),
      // Evening scenario
      Weather(
        description: 'Light rain',
        temperature: 24.0,
        condition: 'Rain',
        forecast: 'Light rain expected - good for irrigation',
        rainfall: 5.8,
        humidity: 85.0,
        windSpeed: 4.2,
        pressure: 1008,
      ),
    ];

    // Return different scenarios based on time
    if (hour < 12) return scenarios[0]; // Morning
    if (hour < 18) return scenarios[1]; // Afternoon
    return scenarios[2]; // Evening
  }
}

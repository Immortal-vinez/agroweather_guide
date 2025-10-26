import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_forecast.dart';
import '../models/weather.dart';

class WeatherService {
  Future<Weather> fetchCurrentWeather(double lat, double lon) async {
    // Demo or missing key - return sample weather data to keep UI responsive
    if (demoMode || apiKey.isEmpty || apiKey.toLowerCase() == 'demo') {
      return _getDemoWeatherData();
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Weather.fromJson(data);
      } else {
        throw Exception(
          'Failed to load current weather (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load current weather: $e');
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

  final String apiKey;
  final bool demoMode;
  WeatherService(this.apiKey, {this.demoMode = false});

  Future<List<HourlyForecast>> fetchHourlyForecast(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&units=metric&appid=$apiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> hourly = data['hourly'];
        return hourly.map((e) => HourlyForecast.fromJson(e)).toList();
      } else {
        throw Exception(
          'Failed to load hourly forecast (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load hourly forecast: $e');
    }
  }

  Future<List<DailyForecast>> fetchDailyForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&appid=$apiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> daily = data['daily'];
        return daily.map((e) => DailyForecast.fromJson(e)).toList();
      } else {
        throw Exception(
          'Failed to load daily forecast (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load daily forecast: $e');
    }
  }

  Future<List<Weather>> fetchWeatherForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&appid=$apiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> daily = data['daily'];
        // Note: daily items from One Call have a different shape than current weather
        // Expose as DailyForecast instead of mapping to Weather to avoid schema mismatch.
        return daily
            .map((e) => DailyForecast.fromJson(e))
            .map(
              (d) => Weather(
                description: d.condition,
                temperature: d.maxTemp,
                condition: d.condition,
                forecast: d.condition,
                rainfall: d.rainfall,
                humidity: 0,
                windSpeed: 0,
                pressure: 0,
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load weather forecast (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load weather forecast: $e');
    }
  }
}

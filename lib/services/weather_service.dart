import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_forecast.dart';
import '../models/weather.dart';

class WeatherService {
  Future<Weather> fetchCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Weather.fromJson(data);
    } else {
      throw Exception('Failed to load current weather');
    }
  }

  final String apiKey;
  WeatherService(this.apiKey);

  Future<List<HourlyForecast>> fetchHourlyForecast(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&units=metric&appid=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hourly = data['hourly'];
      return hourly.map((e) => HourlyForecast.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load hourly forecast');
    }
  }

  Future<List<DailyForecast>> fetchDailyForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&appid=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> daily = data['daily'];
      return daily.map((e) => DailyForecast.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load daily forecast');
    }
  }
}

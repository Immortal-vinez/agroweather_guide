// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/field_polygon.dart';
import '../models/agro_weather_data.dart';

/// Service to interact with OpenWeather Agro Monitoring API
/// Documentation: https://agromonitoring.com/api
class AgroMonitoringService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.agromonitoring.com/agro/1.0';

  AgroMonitoringService(this._apiKey);

  /// Create a polygon on the Agro API
  /// Returns the polygon with the API-assigned ID
  Future<FieldPolygon?> createPolygon(FieldPolygon polygon) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
      final body = json.encode(polygon.toGeoJson());

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return FieldPolygon.fromJson(data);
      } else if (response.statusCode == 401) {
        print('❌ Invalid API key for Agro Monitoring API');
        print('🔑 The Agro Monitoring API requires a separate subscription.');
        print('📝 Visit: https://home.openweathermap.org/api_keys');
        print('💡 Enable "Agro Monitoring" service for your API key');
        return null;
      } else {
        print('Failed to create polygon: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') || errorMsg.contains('CORS')) {
        print('🌐 Web CORS Error: Browser blocked the request');
        print(
            '💡 Run Chrome with: flutter run -d chrome --web-browser-flag "--disable-web-security"');
        print(
            '📱 Or use the mobile/desktop app for full field mapping features');
      } else {
        print('Error creating polygon: $e');
      }
      return null;
    }
  }

  /// Get all polygons for the user
  Future<List<FieldPolygon>> getAllPolygons() async {
    if (_apiKey.isEmpty) return [];

    try {
      final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FieldPolygon.fromJson(json)).toList();
      } else {
        print('Failed to get polygons: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting polygons: $e');
      return [];
    }
  }

  /// Get a specific polygon by ID
  Future<FieldPolygon?> getPolygon(String polygonId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl/polygons/$polygonId?appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FieldPolygon.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting polygon: $e');
      return null;
    }
  }

  /// Update a polygon
  Future<bool> updatePolygon(FieldPolygon polygon) async {
    if (_apiKey.isEmpty || polygon.id == null) return false;

    try {
      final url = Uri.parse('$_baseUrl/polygons/${polygon.id}?appid=$_apiKey');
      final body = json.encode(polygon.toGeoJson());

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating polygon: $e');
      return false;
    }
  }

  /// Delete a polygon
  Future<bool> deletePolygon(String polygonId) async {
    if (_apiKey.isEmpty) return false;

    try {
      final url = Uri.parse('$_baseUrl/polygons/$polygonId?appid=$_apiKey');
      final response = await http.delete(url);
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting polygon: $e');
      return false;
    }
  }

  /// Get current weather for a polygon
  Future<AgroWeatherData?> getCurrentWeather(String polygonId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url =
          Uri.parse('$_baseUrl/weather?polyid=$polygonId&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AgroWeatherData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting current weather: $e');
      return null;
    }
  }

  /// Get weather forecast for a polygon
  Future<List<AgroWeatherData>> getWeatherForecast(String polygonId) async {
    if (_apiKey.isEmpty) return [];

    try {
      final url = Uri.parse(
          '$_baseUrl/weather/forecast?polyid=$polygonId&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AgroWeatherData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting weather forecast: $e');
      return [];
    }
  }

  /// Get current soil data for a polygon
  Future<SoilData?> getCurrentSoil(String polygonId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl/soil?polyid=$polygonId&appid=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SoilData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting soil data: $e');
      return null;
    }
  }

  /// Get NDVI data for a polygon
  /// startDate and endDate in Unix timestamp
  Future<List<NdviData>> getNdviData(
    String polygonId, {
    int? startDate,
    int? endDate,
  }) async {
    if (_apiKey.isEmpty) return [];

    try {
      var url = '$_baseUrl/ndvi/history?polyid=$polygonId&appid=$_apiKey';
      if (startDate != null) url += '&start=$startDate';
      if (endDate != null) url += '&end=$endDate';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NdviData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting NDVI data: $e');
      return [];
    }
  }

  /// Get satellite imagery for a polygon
  Future<List<SatelliteImage>> getSatelliteImages(
    String polygonId, {
    int? startDate,
    int? endDate,
    String type = 'truecolor',
  }) async {
    if (_apiKey.isEmpty) return [];

    try {
      var url = '$_baseUrl/image/search?polyid=$polygonId&appid=$_apiKey';
      if (startDate != null) url += '&start=$startDate';
      if (endDate != null) url += '&end=$endDate';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SatelliteImage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting satellite images: $e');
      return [];
    }
  }

  /// Get complete field data (weather, soil, NDVI)
  Future<FieldData> getCompleteFieldData(FieldPolygon field) async {
    if (field.id == null) {
      return FieldData(
        polygonId: '',
        fieldName: field.name,
      );
    }

    final polygonId = field.id!;

    // Fetch all data in parallel
    final results = await Future.wait([
      getCurrentWeather(polygonId),
      getWeatherForecast(polygonId),
      getCurrentSoil(polygonId),
      getNdviData(polygonId,
          startDate: DateTime.now()
                  .subtract(const Duration(days: 90))
                  .millisecondsSinceEpoch ~/
              1000),
      getSatelliteImages(polygonId,
          startDate: DateTime.now()
                  .subtract(const Duration(days: 30))
                  .millisecondsSinceEpoch ~/
              1000),
    ]);

    return FieldData(
      polygonId: polygonId,
      fieldName: field.name,
      currentWeather: results[0] as AgroWeatherData?,
      weatherForecast: results[1] as List<AgroWeatherData>,
      currentSoil: results[2] as SoilData?,
      historicalNdvi: results[3] as List<NdviData>,
      latestNdvi: (results[3] as List<NdviData>).isNotEmpty
          ? (results[3] as List<NdviData>).last
          : null,
      satelliteImages: results[4] as List<SatelliteImage>,
    );
  }
}

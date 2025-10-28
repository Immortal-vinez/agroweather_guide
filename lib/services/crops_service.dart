import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/crop.dart';

class CropsService {
  static const String _cacheKey = 'crops_cache_json';
  static const String _cacheUpdatedAtKey = 'crops_cache_updated_at';

  Future<List<Crop>> loadCrops() async {
    // 1) Try remote if URL provided
    if (Env.hasCropsUrl) {
      try {
        final response = await http
            .get(Uri.parse(Env.cropsDataUrl))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          await _saveCache(response.body);
          return _parseCropsJson(response.body);
        }
      } catch (_) {
        // Ignore network errors and try cache/asset fallback
      }
    }

    // 2) Try cache
    final cached = await _readCache();
    if (cached != null) {
      try {
        return _parseCropsJson(cached);
      } catch (_) {
        // Corrupt cache, fall through to asset
      }
    }

    // 3) Fallback to bundled asset
    try {
      final String data = await rootBundle.loadString('lib/data/crops.json');
      return _parseCropsJson(data);
    } catch (_) {
      // As a last resort, return an empty list instead of crashing
      return <Crop>[];
    }
  }

  List<Crop> _parseCropsJson(String data) {
    final List<dynamic> jsonResult = json.decode(data);
    return jsonResult
        .map(
          (e) => Crop(
            name: e['name'],
            // Normalize common synonyms to keep filters consistent
            season: (e['season'] == 'Wet') ? 'Rainy' : e['season'],
            careTip: e['careTip'],
            minTemp: (e['minTemp'] as num).toDouble(),
            maxTemp: (e['maxTemp'] as num).toDouble(),
            icon: e['icon'],
          ),
        )
        .toList();
  }

  Future<void> _saveCache(String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, body);
    await prefs.setString(_cacheUpdatedAtKey, DateTime.now().toIso8601String());
  }

  Future<String?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLocation {
  final String name;
  final double lat;
  final double lon;
  const SavedLocation({
    required this.name,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lon': lon};
  static SavedLocation fromJson(Map<String, dynamic> j) => SavedLocation(
    name: j['name'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
  );
}

class LocationsService {
  static const _kList = 'saved_locations_v1';
  static const _kActive = 'active_location_v1';

  Future<List<SavedLocation>> getSaved() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kList);
    if (s == null || s.isEmpty) return [];
    try {
      final List list = jsonDecode(s) as List;
      return list
          .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<SavedLocation> list) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(list.map((e) => e.toJson()).toList());
    await sp.setString(_kList, s);
  }

  Future<void> add(SavedLocation loc) async {
    final list = await getSaved();
    // dedupe by name
    final filtered =
        list.where((e) => e.name != loc.name).toList()..insert(0, loc);
    await saveAll(filtered);
  }

  Future<void> removeByName(String name) async {
    final list = await getSaved();
    final filtered = list.where((e) => e.name != name).toList();
    await saveAll(filtered);
    final active = await getActive();
    if (active?.name == name) {
      await setActive(null);
    }
  }

  Future<SavedLocation?> getActive() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kActive);
    if (s == null || s.isEmpty) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return SavedLocation.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<void> setActive(SavedLocation? loc) async {
    final sp = await SharedPreferences.getInstance();
    if (loc == null) {
      await sp.remove(_kActive);
    } else {
      await sp.setString(_kActive, jsonEncode(loc.toJson()));
    }
  }
}

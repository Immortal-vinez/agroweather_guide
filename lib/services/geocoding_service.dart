import 'package:geocoding/geocoding.dart' as geo;

class GeocodingService {
  Future<String?> placeNameFrom(double lat, double lon) async {
    try {
      final list = await geo.placemarkFromCoordinates(lat, lon);
      if (list.isEmpty) return null;
      final p = list.first;
      final city =
          p.locality?.isNotEmpty == true
              ? p.locality
              : (p.subAdministrativeArea?.isNotEmpty == true
                  ? p.subAdministrativeArea
                  : null);
      final country = p.country;
      if (city != null && country != null) return '$city, $country';
      if (city != null) return city;
      if (country != null) return country;
      return p.administrativeArea ?? p.name;
    } catch (_) {
      return null;
    }
  }

  Future<({double lat, double lon, String label})?> searchPlace(
    String query,
  ) async {
    try {
      final results = await geo.locationFromAddress(query);
      if (results.isEmpty) return null;
      final loc = results.first;
      // Try reverse lookup to get a clean label
      final label = await placeNameFrom(loc.latitude, loc.longitude) ?? query;
      return (lat: loc.latitude, lon: loc.longitude, label: label);
    } catch (_) {
      return null;
    }
  }
}

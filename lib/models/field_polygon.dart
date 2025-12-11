import 'package:latlong2/latlong.dart';

/// Represents a field polygon for Agro Monitoring API
class FieldPolygon {
  final String? id; // Agro API polygon ID
  final String name;
  final List<LatLng> coordinates;
  final DateTime createdAt;
  final double? area; // in hectares

  FieldPolygon({
    this.id,
    required this.name,
    required this.coordinates,
    DateTime? createdAt,
    this.area,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to GeoJSON format required by Agro Monitoring API
  Map<String, dynamic> toGeoJson() {
    // Agro API requires coordinates as [lon, lat] and closing the polygon
    final coords =
        coordinates.map((ll) => [ll.longitude, ll.latitude]).toList();
    // Close the polygon if not already closed
    if (coords.first[0] != coords.last[0] ||
        coords.first[1] != coords.last[1]) {
      coords.add(coords.first);
    }

    return {
      'name': name,
      'geo_json': {
        'type': 'Feature',
        'properties': {},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [coords],
        },
      },
    };
  }

  /// Create from Agro API response
  factory FieldPolygon.fromJson(Map<String, dynamic> json) {
    final geometry = json['geo_json']['geometry'];
    final coords = (geometry['coordinates'][0] as List)
        .map((c) => LatLng(c[1] as double, c[0] as double))
        .toList();

    // Remove the closing coordinate if present
    if (coords.length > 1 &&
        coords.first.latitude == coords.last.latitude &&
        coords.first.longitude == coords.last.longitude) {
      coords.removeLast();
    }

    return FieldPolygon(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Field',
      coordinates: coords,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
          : DateTime.now(),
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
    );
  }

  /// Save to local storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates
          .map((ll) => {'lat': ll.latitude, 'lon': ll.longitude})
          .toList(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'area': area,
    };
  }

  /// Load from local storage
  factory FieldPolygon.fromLocalJson(Map<String, dynamic> json) {
    return FieldPolygon(
      id: json['id'],
      name: json['name'],
      coordinates: (json['coordinates'] as List)
          .map((c) => LatLng(c['lat'] as double, c['lon'] as double))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
    );
  }

  /// Calculate approximate area in hectares using Haversine formula
  double calculateArea() {
    if (coordinates.length < 3) return 0.0;

    // Simple shoelace formula (approximate for small areas)
    double area = 0.0;

    for (int i = 0; i < coordinates.length; i++) {
      final p1 = coordinates[i];
      final p2 = coordinates[(i + 1) % coordinates.length];

      area += (p2.longitude - p1.longitude) * (p2.latitude + p1.latitude);
    }

    area = area.abs() / 2.0;

    // Convert to hectares (approximate)
    // 1 degree ≈ 111 km, so area in km² then convert to hectares
    area = area * 111 * 111 * 100; // rough conversion to hectares

    return area;
  }

  FieldPolygon copyWith({
    String? id,
    String? name,
    List<LatLng>? coordinates,
    DateTime? createdAt,
    double? area,
  }) {
    return FieldPolygon(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      createdAt: createdAt ?? this.createdAt,
      area: area ?? this.area,
    );
  }
}

/// Weather data from Agro Monitoring API for a specific polygon
class AgroWeatherData {
  final int timestamp;
  final double? temp; // Temperature in Kelvin
  final double? humidity; // Humidity %
  final double? windSpeed; // Wind speed m/s
  final double? precipitation; // Precipitation mm
  final double? clouds; // Cloud coverage %
  final String? weatherMain;
  final String? weatherDescription;

  const AgroWeatherData({
    required this.timestamp,
    this.temp,
    this.humidity,
    this.windSpeed,
    this.precipitation,
    this.clouds,
    this.weatherMain,
    this.weatherDescription,
  });

  factory AgroWeatherData.fromJson(Map<String, dynamic> json) {
    return AgroWeatherData(
      timestamp: json['dt'] ?? 0,
      temp: json['main']?['temp']?.toDouble(),
      humidity: json['main']?['humidity']?.toDouble(),
      windSpeed: json['wind']?['speed']?.toDouble(),
      precipitation:
          json['rain']?['1h']?.toDouble() ?? json['rain']?['3h']?.toDouble(),
      clouds: json['clouds']?['all']?.toDouble(),
      weatherMain: json['weather']?[0]?['main'],
      weatherDescription: json['weather']?[0]?['description'],
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  double? get tempCelsius => temp != null ? temp! - 273.15 : null;
  double? get tempFahrenheit =>
      temp != null ? (temp! - 273.15) * 9 / 5 + 32 : null;
}

/// Soil data from Agro Monitoring API
class SoilData {
  final int timestamp;
  final double? surfaceTemp; // Surface temperature (t0) in Kelvin
  final double? temp10cm; // Temperature at 10cm depth (t10) in Kelvin
  final double? soilMoisture; // Soil moisture percentage (0-100)

  SoilData({
    required this.timestamp,
    this.surfaceTemp,
    this.temp10cm,
    this.soilMoisture,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      timestamp: json['dt'] ?? 0,
      surfaceTemp: json['t0']?.toDouble(),
      temp10cm: json['t10']?.toDouble(),
      soilMoisture: json['moisture']?.toDouble(),
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  double? get surfaceTempCelsius =>
      surfaceTemp != null ? surfaceTemp! - 273.15 : null;
  double? get temp10cmCelsius => temp10cm != null ? temp10cm! - 273.15 : null;

  // Moisture is already in percentage from the API
  double? get moisturePercent => soilMoisture;
}

/// NDVI (Normalized Difference Vegetation Index) data
class NdviData {
  final int timestamp;
  final double? mean; // Mean NDVI value
  final double? min;
  final double? max;
  final double? std; // Standard deviation
  final String? imageUrl; // URL to NDVI image

  NdviData({
    required this.timestamp,
    this.mean,
    this.min,
    this.max,
    this.std,
    this.imageUrl,
  });

  factory NdviData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return NdviData(
      timestamp: json['dt'] ?? 0,
      mean: data?['mean']?.toDouble(),
      min: data?['min']?.toDouble(),
      max: data?['max']?.toDouble(),
      std: data?['std']?.toDouble(),
      imageUrl: json['image']?['ndvi'],
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  /// Interpret NDVI values
  String get healthDescription {
    if (mean == null) return 'No data';
    if (mean! < 0.2) return 'Bare soil / No vegetation';
    if (mean! < 0.4) return 'Sparse vegetation';
    if (mean! < 0.6) return 'Moderate vegetation';
    if (mean! < 0.8) return 'Dense vegetation';
    return 'Very dense vegetation';
  }

  /// Health rating 0-100
  int get healthRating {
    if (mean == null) return 0;
    return ((mean! + 1) * 50).clamp(0, 100).round();
  }
}

/// Satellite image metadata
class SatelliteImage {
  final int timestamp;
  final String type; // 'truecolor', 'falsecolor', 'ndvi', 'evi', etc.
  final String? imageUrl;
  final double? cloudCoverage; // Cloud coverage percentage

  SatelliteImage({
    required this.timestamp,
    required this.type,
    this.imageUrl,
    this.cloudCoverage,
  });

  factory SatelliteImage.fromJson(Map<String, dynamic> json) {
    return SatelliteImage(
      timestamp: json['dt'] ?? 0,
      type: json['type'] ?? 'unknown',
      imageUrl: json['image']?['truecolor'] ??
          json['image']?['falsecolor'] ??
          json['image']?['ndvi'],
      cloudCoverage: json['cl']?.toDouble(),
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

/// Complete field data combining all metrics
class FieldData {
  final String polygonId;
  final String fieldName;
  final AgroWeatherData? currentWeather;
  final List<AgroWeatherData> weatherForecast;
  final SoilData? currentSoil;
  final NdviData? latestNdvi;
  final List<NdviData> historicalNdvi;
  final List<SatelliteImage> satelliteImages;
  final DateTime lastUpdated;

  FieldData({
    required this.polygonId,
    required this.fieldName,
    this.currentWeather,
    this.weatherForecast = const [],
    this.currentSoil,
    this.latestNdvi,
    this.historicalNdvi = const [],
    this.satelliteImages = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

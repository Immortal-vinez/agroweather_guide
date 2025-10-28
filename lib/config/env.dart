class Env {
  // Provide your OpenWeatherMap API key at build/run time:
  // flutter run --dart-define=OPENWEATHER_API_KEY=your_key
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static bool get hasApiKey => openWeatherApiKey.isNotEmpty;

  // Optional remote crops JSON URL. If provided, we'll fetch crops remotely and cache.
  // Example: flutter run --dart-define=CROPS_DATA_URL=https://example.com/crops.json
  static const String cropsDataUrl = String.fromEnvironment('CROPS_DATA_URL');

  static bool get hasCropsUrl => cropsDataUrl.isNotEmpty;
}

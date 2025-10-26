class Env {
  // Provide your OpenWeatherMap API key at build/run time:
  // flutter run --dart-define=OPENWEATHER_API_KEY=your_key
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static bool get hasApiKey => openWeatherApiKey.isNotEmpty;
}

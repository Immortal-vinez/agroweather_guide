class Env {
  // Agro Monitoring API Key (Primary API for weather and agricultural data)
  // Get your free key at: https://agromonitoring.com/api
  // Provides: weather, soil data, satellite imagery, NDVI, field management
  static const String agroMonitoringApiKey = String.fromEnvironment(
    'AGRO_MONITORING_API_KEY',
    defaultValue: 'd09f3febf9772eda3a0fd47f6e6829db',
  );

  static bool get hasApiKey => agroMonitoringApiKey.isNotEmpty;

  // Optional remote crops JSON URL. If provided, we'll fetch crops remotely and cache.
  // Example: flutter run --dart-define=CROPS_DATA_URL=https://example.com/crops.json
  static const String cropsDataUrl = String.fromEnvironment('CROPS_DATA_URL');

  static bool get hasCropsUrl => cropsDataUrl.isNotEmpty;

  // Optional seasonal forecast API base URL (if using a proxy/server).
  // If not set, the app will use Open-Meteo Seasonal API by default.
  static String? get seasonalApiUrl {
    const v = String.fromEnvironment('SEASONAL_API_URL');
    return v.isEmpty ? null : v;
  }

  // OpenAI API key for AI chatbot (ChatGPT)
  // Get your key at: https://platform.openai.com/api-keys
  // Run with: flutter run --dart-define=OPENAI_API_KEY=your_key
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Add your key here or use --dart-define
  );

  static bool get hasChatEnabled => openAiApiKey.isNotEmpty;
}

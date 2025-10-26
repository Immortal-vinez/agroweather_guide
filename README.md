# agroweather_guide

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AgroWeather Guide

A Flutter app to help farmers make informed decisions using current weather and simple insights.

## Live Weather Data

This app is wired to fetch live weather from OpenWeatherMap. For security, the API key is not hardcoded. Provide it at build/run time using a Dart define:

1) Get a free API key from https://openweathermap.org/api

2) Run the app with your key (replace YOUR_KEY):

```
flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

On release/CI builds, pass the same define to build commands (apk/appbundle/ipa/web):

```
flutter build apk --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

If no key is provided, the app falls back to demo data so you can still explore the UI.

### Notes
- Location permission is required to fetch weather for your current location. If unavailable, the app falls back to a default location (Nairobi).
- Network timeouts and errors show a friendly message. Optionally add offline handling using connectivity_plus.

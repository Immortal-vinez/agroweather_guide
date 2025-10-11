import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroWeather Guide',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5E6), // Soft Beige
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF4CAF50), // Leaf Green
          onPrimary: Colors.white,
          secondary: Color(0xFF81D4FA), // Sky Blue
          onSecondary: Colors.black,
          error: Color(0xFFFFEB3B), // Sunshine Yellow (for alerts)
          onError: Colors.black, // Charcoal
          surface: Colors.white,
          onSurface: Color(0xFF333333), // Charcoal
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50), // Leaf Green
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4CAF50), // Leaf Green
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)), // Charcoal
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          titleLarge: TextStyle(color: Color(0xFF333333)),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

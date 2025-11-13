import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  // Start background-ish reminder checks (in-app periodic)
  ReminderService().start();
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
        scaffoldBackgroundColor: const Color(0xFFE3F2FD), // Light Blue 50
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF64B5F6), // Blue 300
          onPrimary: Colors.white,
          secondary: Color(0xFF90CAF9), // Blue 200
          onSecondary: Colors.black,
          error: Color(0xFFFF5252),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF203040),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF64B5F6),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF203040)),
          bodyMedium: TextStyle(color: Color(0xFF203040)),
          titleLarge: TextStyle(color: Color(0xFF203040)),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

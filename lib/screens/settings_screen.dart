// ignore_for_file: use_build_context_synchronously

import '../widgets/gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preference keys
  static const _kAnim = 'settings_enable_weather_animations';
  static const _kFollow = 'settings_location_follow';
  static const _kCelsius = 'settings_use_celsius';
  static const _kNotifHour = 'settings_reminder_hour';
  static const _kNotifMinute = 'settings_reminder_minute';

  // Cached values
  bool _enableAnimations = true;
  bool _followLocation = true;
  bool _useCelsius = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableAnimations = prefs.getBool(_kAnim) ?? true;
      _followLocation = prefs.getBool(_kFollow) ?? true;
      _useCelsius = prefs.getBool(_kCelsius) ?? true;
      final h = prefs.getInt(_kNotifHour);
      final m = prefs.getInt(_kNotifMinute);
      if (h != null && m != null) {
        _reminderTime = TimeOfDay(hour: h, minute: m);
      }
      _loading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setReminderTime(TimeOfDay t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotifHour, t.hour);
    await prefs.setInt(_kNotifMinute, t.minute);
  }

  Future<void> _clearCaches() async {
    final prefs = await SharedPreferences.getInstance();
    // Known caches/keys used in this app
    await prefs.remove('crops_cache_json');
    await prefs.remove('crops_cache_updated_at');
    await prefs.remove('saved_locations_v1');
    await prefs.remove('active_location_v1');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cached data cleared')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final hasApiKey = Env.hasApiKey;
    final apiKeyStatus =
        hasApiKey ? '✓ API Key Configured' : '⚠ API Key Not Set';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.agriculture, color: Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            const Text('AgroWeather Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Weather, crops, planning, and alerts for farmers.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // API Status Section
              const Text(
                'API Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    hasApiKey ? Icons.check_circle : Icons.warning,
                    color: hasApiKey ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apiKeyStatus,
                    style: TextStyle(
                      color: hasApiKey ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (!hasApiKey) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Running in Demo Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF6C00),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To enable live weather data and field monitoring:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Get a FREE API key from:\\nhttps://openweathermap.org/api',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '2. Run with:\\nflutter run --dart-define=OPENWEATHER_API_KEY=your_key',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✓ Real-time weather data',
                          style: TextStyle(fontSize: 13)),
                      Text('✓ Weather forecasts',
                          style: TextStyle(fontSize: 13)),
                      Text('✓ Field-specific monitoring',
                          style: TextStyle(fontSize: 13)),
                      Text('✓ Soil data & NDVI',
                          style: TextStyle(fontSize: 13)),
                      Text('✓ Agro Monitoring API',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Features Section
              const Text(
                'Features',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text('• Current weather & forecasts',
                  style: TextStyle(fontSize: 13)),
              const Text('• Crop library & planning',
                  style: TextStyle(fontSize: 13)),
              const Text('• Interactive field mapping',
                  style: TextStyle(fontSize: 13)),
              const Text('• Vegetation health (NDVI)',
                  style: TextStyle(fontSize: 13)),
              const Text('• Soil monitoring', style: TextStyle(fontSize: 13)),
              const Text('• Task reminders & alerts',
                  style: TextStyle(fontSize: 13)),
              const Text('• Offline support', style: TextStyle(fontSize: 13)),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Data Sources
              const Text(
                'Data Sources',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                '• OpenWeather API - Weather data',
                style: TextStyle(fontSize: 13),
              ),
              const Text(
                '• Agro Monitoring API - Field data',
                style: TextStyle(fontSize: 13),
              ),
              const Text(
                '• OpenStreetMap - Map tiles',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const GradientAppBar(title: Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Weather', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _enableAnimations,
                  onChanged: (v) async {
                    setState(() => _enableAnimations = v);
                    await _setBool(_kAnim, v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v
                              ? 'Weather animations enabled'
                              : 'Weather animations disabled',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  title: const Text('Animations'),
                  subtitle: const Text('Show animated weather effects'),
                  secondary:
                      const Icon(Icons.animation, color: Color(0xFF4CAF50)),
                ),
                const Divider(),
                Text('Location', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _followLocation,
                  onChanged: (v) async {
                    setState(() => _followLocation = v);
                    await _setBool(_kFollow, v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v
                              ? 'Auto-follow location enabled'
                              : 'Auto-follow location disabled',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  title: const Text('Auto-follow location'),
                  subtitle: const Text('Update city and weather as you move'),
                  secondary:
                      const Icon(Icons.my_location, color: Color(0xFF4CAF50)),
                ),
                const Divider(),
                Text('Units', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _useCelsius,
                  onChanged: (v) async {
                    setState(() => _useCelsius = v);
                    await _setBool(_kCelsius, v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(v ? 'Units set to °C' : 'Units set to °F'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  title: const Text('Use Celsius'),
                  subtitle: const Text('Toggle °C / °F'),
                  secondary:
                      const Icon(Icons.thermostat, color: Color(0xFF4CAF50)),
                ),
                const Divider(),
                Text('Notifications', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.alarm, color: Color(0xFF4CAF50)),
                  title: const Text('Daily reminder time'),
                  subtitle: Text(
                      'At ${_reminderTime.format(context)} (for task alerts)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                      await _setReminderTime(picked);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Reminder time set to ${picked.format(context)}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                Text('Storage', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  leading:
                      const Icon(Icons.delete_sweep, color: Color(0xFF4CAF50)),
                  title: const Text('Clear cached data'),
                  subtitle:
                      const Text('Remove cached crops and saved locations'),
                  onTap: _clearCaches,
                ),
                const Divider(),
                Text('About', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.info, color: Color(0xFF4CAF50)),
                  title: const Text('About'),
                  subtitle: const Text('AgroWeather Guide'),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
    );
  }
}

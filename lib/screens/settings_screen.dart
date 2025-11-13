import '../widgets/gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                    showAboutDialog(
                      context: context,
                      applicationName: 'AgroWeather Guide',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.agriculture),
                      children: const [
                        Text(
                            'Weather, crops, planning, and alerts for farmers.'),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

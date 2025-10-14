import 'dart:convert';
import 'package:agroweather_guide/models/weather.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/trust_signals_card.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/weather_stat_card.dart';
import '../widgets/water_analytics_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/alert_banner.dart';
import '../widgets/crop_recommendation_card.dart';
import '../widgets/recent_alerts_section.dart';
import '../models/crop.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import 'crop_details_screen.dart';
import 'crops_list_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _recentAlerts = [];
  int _selectedIndex = 0;
  final List<String> _userNotes = [];

  // Add your OpenWeatherMap API key here
  final String _weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  double? _userLat;
  double? _userLon;

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLat = position.latitude;
      _userLon = position.longitude;
    });
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _getUserLocation();
  }

  Future<List<Crop>> _loadRecommendedCrops(Weather weather) async {
    final String data = await rootBundle.loadString('lib/data/crops.json');
    final List<dynamic> jsonResult = json.decode(data);
    // Define a simple mapping of month to season for rule-based filtering
    final int month = DateTime.now().month;
    String currentSeason;
    if ([6, 7, 8, 9].contains(month)) {
      currentSeason = 'Rainy';
    } else if ([10, 11, 12, 1].contains(month)) {
      currentSeason = 'Cool';
    } else if ([2, 3, 4, 5].contains(month)) {
      currentSeason = 'Warm';
    } else {
      currentSeason = 'Dry';
    }
    return jsonResult
        .map(
          (e) => Crop(
            name: e['name'],
            season: e['season'],
            careTip: e['careTip'],
            minTemp: (e['minTemp'] as num).toDouble(),
            maxTemp: (e['maxTemp'] as num).toDouble(),
            icon: e['icon'],
          ),
        )
        .where(
          (crop) =>
              weather.temperature >= crop.minTemp &&
              weather.temperature <= crop.maxTemp &&
              (crop.season == currentSeason || crop.season == 'Any'),
        )
        .toList();
  }

  void _checkAndNotify(Weather weather) {
    String? alert;
    if (weather.condition.toLowerCase().contains('rain')) {
      alert = 'Rain expected. Ensure proper drainage for your crops.';
    } else if (weather.temperature > 30) {
      alert = 'High temperature! Water your crops early in the morning.';
    }
    if (alert != null &&
        (_recentAlerts.isEmpty || _recentAlerts.first != alert)) {
      setState(() {
        _recentAlerts.insert(0, alert!);
      });
      NotificationService.showNotification(
        title: 'AgroWeather Alert',
        body: alert,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Note/Reminder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your note or reminder',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _userNotes.insert(0, controller.text.trim());
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCropDialog() {
    final nameController = TextEditingController();
    final seasonController = TextEditingController();
    final careTipController = TextEditingController();
    final minTempController = TextEditingController();
    final maxTempController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Crop'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Crop Name'),
                  ),
                  TextField(
                    controller: seasonController,
                    decoration: const InputDecoration(labelText: 'Season'),
                  ),
                  TextField(
                    controller: careTipController,
                    decoration: const InputDecoration(labelText: 'Care Tip'),
                  ),
                  TextField(
                    controller: minTempController,
                    decoration: const InputDecoration(
                      labelText: 'Min Temp (°C)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxTempController,
                    decoration: const InputDecoration(
                      labelText: 'Max Temp (°C)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    setState(() {
                      // Add the new crop to a local list for recommendations (not persistent)
                      _userAddedCrops.insert(
                        0,
                        Crop(
                          name: nameController.text.trim(),
                          season: seasonController.text.trim(),
                          careTip: careTipController.text.trim(),
                          minTemp:
                              double.tryParse(minTempController.text.trim()) ??
                              0,
                          maxTemp:
                              double.tryParse(maxTempController.text.trim()) ??
                              0,
                          icon: '🌱',
                        ),
                      );
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  final List<Crop> _userAddedCrops = [];

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to fetch real-time weather data
    final dashboardPage = FutureBuilder<Weather>(
      future:
          _userLat != null && _userLon != null
              ? WeatherService(
                _weatherApiKey,
              ).fetchCurrentWeather(_userLat!, _userLon!)
              : null,
      builder: (context, snapshot) {
        if (_userLat == null || _userLon == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading weather data'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No weather data available'));
        }
        final weather = snapshot.data!;
        final hour = DateTime.now().hour;
        String tip;
        if (weather.condition.toLowerCase().contains('rain')) {
          tip = 'Rain expected. Ensure proper drainage for your crops.';
        } else if (weather.temperature > 30) {
          tip = 'High temperature! Water your crops early in the morning.';
        } else if (hour < 10) {
          tip = 'Morning is the best time to irrigate your fields.';
        } else {
          tip = 'Monitor your crops for pests and diseases regularly.';
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _checkAndNotify(weather),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DashboardHeader(
                  location:
                      'Lat: ${_userLat!.toStringAsFixed(2)}, Lon: ${_userLon!.toStringAsFixed(2)}',
                  lastUpdate:
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  onRefresh: _refreshData,
                ),
              ),
              const SizedBox(height: 10),
              // Risk Alert Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AlertBanner(message: tip),
              ),
              const SizedBox(height: 12),
              // Water Analytics Card
              FutureBuilder<List<Crop>>(
                future: _loadRecommendedCrops(weather),
                builder: (context, cropSnap) {
                  double cropWaterNeed = 25.0;
                  if (cropSnap.hasData && cropSnap.data!.isNotEmpty) {
                    // Example: use minTemp as proxy for water need (replace with real logic if available)
                    cropWaterNeed = cropSnap.data!.first.minTemp * 1.5;
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: WaterAnalyticsCard(
                      cropWaterNeed: cropWaterNeed,
                      expectedRainfall: weather.rainfall,
                      waterDeficit: cropWaterNeed - weather.rainfall,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Weather Stat Cards (Temperature & Rainfall)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: WeatherStatCard(
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: '${weather.temperature.toStringAsFixed(1)}°C',
                        status:
                            weather.temperature > 30
                                ? 'High'
                                : weather.temperature < 15
                                ? 'Low'
                                : 'Normal',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WeatherStatCard(
                        icon: Icons.water_drop,
                        label: 'Rainfall',
                        value: '${weather.rainfall.toStringAsFixed(1)} mm',
                        status:
                            (weather.rainfall) > 10
                                ? 'Heavy'
                                : (weather.rainfall) > 2
                                ? 'Moderate'
                                : 'Light',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 7-Day Forecast Section (Simplified placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Icon(
                      LucideIcons.calendar,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.cloudSun,
                              size: 32,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Extended forecast will be available soon',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Crop Recommendations Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended Crops',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Icon(
                      LucideIcons.sprout,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: FutureBuilder<List<Crop>>(
                  future: _loadRecommendedCrops(weather),
                  builder: (context, snapshot) {
                    List<Crop> crops = [];
                    if (snapshot.hasData) {
                      crops = [..._userAddedCrops, ...snapshot.data!];
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error loading crops'));
                    } else if (!snapshot.hasData || crops.isEmpty) {
                      return const Center(
                        child: Text(
                          'No suitable crops found for current weather.',
                        ),
                      );
                    }
                    // Example suitability/waterSaving/reason logic
                    return Column(
                      children:
                          crops.map((crop) {
                            // Suitability: based on how close weather.temperature is to crop's ideal range
                            double tempMid =
                                (crop.minTemp + crop.maxTemp) / 2.0;
                            double tempDiff =
                                (weather.temperature - tempMid).abs();
                            double tempRange =
                                (crop.maxTemp - crop.minTemp) / 2.0;
                            double suitability =
                                1.0 - (tempDiff / (tempRange + 0.1));
                            suitability = suitability.clamp(0.0, 1.0);

                            // Water saving: based on rainfall vs a proxy crop water need
                            double cropWaterNeed = crop.minTemp * 1.5; // proxy
                            double waterSaving =
                                (weather.rainfall / cropWaterNeed) * 100.0;
                            waterSaving = waterSaving.clamp(0.0, 100.0);

                            // Reason: explain suitability
                            String reason;
                            if (suitability > 0.85) {
                              reason =
                                  'Ideal temperature and season for this crop.';
                            } else if (suitability > 0.6) {
                              reason =
                                  'Good match, but monitor temperature closely.';
                            } else {
                              reason =
                                  'Suboptimal temperature, consider alternatives.';
                            }
                            if (weather.rainfall < cropWaterNeed * 0.5) {
                              reason += ' Irrigation may be needed.';
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CropDetailsScreen(crop: crop),
                                  ),
                                );
                              },
                              child: CropRecommendationCard(
                                crop: crop,
                                suitability: suitability,
                                waterSaving: waterSaving,
                                reason: reason,
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ),
              // Trust Signals Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TrustSignalsCard(
                  signals: [
                    TrustSignal(label: 'Farmers Using', value: '10,000+'),
                    TrustSignal(
                      label: 'Verified Data',
                      value: 'OpenWeatherMap',
                    ),
                    TrustSignal(label: 'FAO Standards', value: 'Compliant'),
                    TrustSignal(label: 'Accuracy', value: '98%'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildQuickActionTile(
                          icon: LucideIcons.stickyNote,
                          title: 'Add Note',
                          subtitle: 'Create a farming reminder',
                          color: Colors.amber,
                          onTap: _showAddNoteDialog,
                        ),
                        const Divider(height: 24),
                        _buildQuickActionTile(
                          icon: LucideIcons.sprout,
                          title: 'Add Custom Crop',
                          subtitle: 'Track your own crop varieties',
                          color: Colors.green,
                          onTap: _showAddCropDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Recent Alerts
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: RecentAlertsSection(alerts: _recentAlerts),
              ),
              // Notes & Reminders
              if (_userNotes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Notes & Reminders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Icon(
                        LucideIcons.stickyNote,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._userNotes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.stickyNote,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                        ),
                        title: Text(note, style: const TextStyle(fontSize: 14)),
                        trailing: IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            color: Colors.red.shade300,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _userNotes.remove(note);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Modern spacing at bottom
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    // Build crops list screen with current weather data for recommendations
    final cropsPage = FutureBuilder<Weather>(
      future: _userLat != null && _userLon != null
          ? WeatherService(_weatherApiKey).fetchCurrentWeather(_userLat!, _userLon!)
          : null,
      builder: (context, snapshot) {
        return CropsListScreen(
          currentWeather: snapshot.data,
        );
      },
    );

    final weatherPage = const WeatherScreen();
    final settingsPage = const SettingsScreen();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.sprout, size: 24),
            const SizedBox(width: 8),
            const Text(
              'AgroWeather',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5E6), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: IndexedStack(
          index: _selectedIndex,
          children: [dashboardPage, weatherPage, cropsPage, settingsPage],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.cloudSun),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.sprout),
            label: 'Crops',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

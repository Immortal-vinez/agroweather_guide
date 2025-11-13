import 'dart:convert';
import 'package:agroweather_guide/models/weather.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../config/env.dart';
import 'crop_details_screen.dart';
import 'crops_list_screen.dart';
import 'weather_screen.dart';
import 'settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../widgets/offline_banner.dart';
import 'crop_recommendation_screen.dart';
import '../services/season_service.dart';
import '../widgets/season_card.dart';
import '../services/seasonal_forecast_service.dart';
import '../services/forecast_service.dart';
import '../widgets/daily_forecast_strip.dart';
import '../services/geocoding_service.dart';
import '../services/locations_service.dart';
import 'add_crop_plan_screen.dart';
import '../widgets/gradient_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _recentAlerts = [];
  int _selectedIndex = 0;
  final List<String> _userNotes = [];

  // API key sourced from --dart-define to avoid hardcoding secrets
  final String _weatherApiKey = Env.openWeatherApiKey;
  bool get _demoMode => !Env.hasApiKey;
  bool _isOffline = false;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<Position>? _posSub;
  DateTime _lastGeocodeAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastCity;

  double? _userLat;
  double? _userLon;
  Future<SeasonalOutlook?>? _outlookFuture;
  Future<List<DailyForecast>>? _dailyForecastFuture;
  // Track location fetch state and issues
  bool _triedLocation = false;
  String? _locationIssue;
  String? _locationLabel; // human-readable place, e.g., Ndola, Zambia
  SavedLocation? _activeSaved;
  List<SavedLocation> _savedLocations = [];

  // Settings cache
  bool _enableAnimations = true;
  bool _followLocation = true;
  bool _useCelsius = true;

  double? get _effLat => _activeSaved?.lat ?? _userLat;
  double? get _effLon => _activeSaved?.lon ?? _userLon;

  Future<void> _getUserLocation() async {
    try {
      setState(() {
        _triedLocation = true;
        _locationIssue = null;
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationIssue = 'Location services are turned off.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationIssue = 'Location permission denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationIssue =
              'Location permission permanently denied. Enable it in Settings or use a default location.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLat = position.latitude;
        _userLon = position.longitude;
        _locationIssue = null;
      });
      _refreshLocationLabel();
      _computeOutlook();
      _computeDailyForecast();
    } catch (e) {
      setState(() {
        _locationIssue = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  Future<void> _useDefaultLocation() async {
    // Default to Nairobi, Kenya (you can change these coords)
    const double defaultLat = -1.286389;
    const double defaultLon = 36.817223;
    setState(() {
      _userLat = defaultLat;
      _userLon = defaultLon;
      _locationIssue = null;
    });
    _refreshLocationLabel();
    _computeOutlook();
    _computeDailyForecast();
  }

  Future<void> _autoUseDefaultLocation() async {
    // Auto-fallback to default location after a delay if location fetch fails
    await Future.delayed(const Duration(seconds: 5));
    if (_userLat == null || _userLon == null) {
      await _useDefaultLocation();
    }
  }

  @override
  void initState() {
    super.initState();

    NotificationService.initialize();
    _loadSettings();
    _loadSavedLocations();
    _getUserLocation();
    _autoUseDefaultLocation(); // Auto-fallback to default location
    _initConnectivityWatcher();
    // Start streaming now; it will be stopped if a saved location becomes active.
    _startLocationStream();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anim = prefs.getBool('settings_enable_weather_animations');
      final follow = prefs.getBool('settings_location_follow');
      final cel = prefs.getBool('settings_use_celsius');
      final prevFollow = _followLocation;
      setState(() {
        _enableAnimations = anim ?? true;
        _followLocation = follow ?? true;
        _useCelsius = cel ?? true;
      });
      if (prevFollow != _followLocation) {
        if (_followLocation) {
          _startLocationStream();
        } else {
          _stopLocationStream();
        }
      }
    } catch (_) {}
  }

  void _initConnectivityWatcher() async {
    // Initial state
    final initial = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = initial.contains(ConnectivityResult.none);
    });
    // Listen for changes
    _connSub = Connectivity().onConnectivityChanged.listen((list) {
      if (!mounted) return;
      setState(() {
        _isOffline = list.contains(ConnectivityResult.none);
      });
      if (!_isOffline) {
        _computeOutlook();
        _computeDailyForecast();
      }
    });
  }

  // Start following GPS if no active saved location is selected.
  void _startLocationStream() {
    if (_activeSaved != null) return; // pinned to saved; don't follow GPS
    if (!_followLocation) return; // disabled via settings

    _posSub?.cancel();
    // Use a modest distance filter to catch town changes without draining battery.
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 1200, // ~1.2 km; adjust as needed
    );
    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) async {
      await _handlePosition(pos);
    }, onError: (_) {});
  }

  void _stopLocationStream() {
    _posSub?.cancel();
    _posSub = null;
  }

  Future<void> _handlePosition(Position p) async {
    // If pinned to saved, ignore stream updates.
    if (_activeSaved != null) return;

    final prevLat = _userLat;
    final prevLon = _userLon;

    // Always update coords; we’ll gate geocoding and heavy work below.
    setState(() {
      _userLat = p.latitude;
      _userLon = p.longitude;
    });

    // If we didn’t have a previous point, do an initial geocode.
    if (prevLat == null || prevLon == null) {
      await _maybeReverseGeocode(p.latitude, p.longitude, force: true);
      _computeOutlook();
      _computeDailyForecast();
      return;
    }

    // Only react if moved far enough (~1.2 km) or time since last geocode is large.
    final dist =
        Geolocator.distanceBetween(prevLat, prevLon, p.latitude, p.longitude);
    final movedFar = dist >= 1200;
    await _maybeReverseGeocode(p.latitude, p.longitude, force: movedFar);
  }

  Future<void> _maybeReverseGeocode(double lat, double lon,
      {bool force = false}) async {
    if (!mounted || _isOffline) return;
    final now = DateTime.now();
    // Debounce reverse geocoding to max ~1 call per 12s unless forced.
    if (!force &&
        now.difference(_lastGeocodeAt) < const Duration(seconds: 12)) {
      return;
    }

    _lastGeocodeAt = now;
    final label = await GeocodingService().placeNameFrom(lat, lon);
    if (!mounted) return;

    // Extract city from "City, Country" if possible.
    String? newCity;
    if (label != null && label.contains(',')) {
      newCity = label.split(',').first.trim();
    } else if (label != null) {
      newCity = label.trim();
    }

    final cityChanged = (newCity != null && newCity != _lastCity);
    setState(() {
      _locationLabel = label ??
          'Lat: ${lat.toStringAsFixed(2)}, Lon: ${lon.toStringAsFixed(2)}';
      if (newCity != null) _lastCity = newCity;
    });

    // If the city changed, refresh outlook/forecast (header weather FutureBuilder will also refresh via setState).
    if (cityChanged) {
      _computeOutlook();
      _computeDailyForecast();
    }
  }

  void _computeOutlook() {
    final lat = _effLat ?? _userLat;
    final lon = _effLon ?? _userLon;
    if (lat != null && lon != null && !_isOffline) {
      setState(() {
        _outlookFuture = SeasonalForecastService().fetchOutlook(
          latitude: lat,
          longitude: lon,
        );
      });
    }
  }

  void _computeDailyForecast() {
    final lat = _effLat ?? _userLat;
    final lon = _effLon ?? _userLon;
    if (lat != null && lon != null && !_isOffline) {
      final key =
          _weatherApiKey; // can be empty; ForecastService handles fallback
      setState(() {
        _dailyForecastFuture = ForecastService(
          key,
        ).fetchDailyForecast(lat: lat, lon: lon, days: 7);
      });
    }
  }

  Future<void> _loadSavedLocations() async {
    final svc = LocationsService();
    final saved = await svc.getSaved();
    final active = await svc.getActive();
    if (!mounted) return;
    setState(() {
      _savedLocations = saved;
      _activeSaved = active;
    });
    // Start/stop GPS streaming based on active saved location.
    if (_activeSaved == null) {
      _startLocationStream();
    } else {
      _stopLocationStream();
    }
    _refreshLocationLabel();
  }

  Future<void> _setActiveSaved(SavedLocation? loc) async {
    final svc = LocationsService();
    await svc.setActive(loc);
    if (!mounted) return;
    setState(() {
      _activeSaved = loc;
    });
    if (loc == null) {
      // Follow GPS again
      _startLocationStream();
    } else {
      // Pin to saved spot
      _stopLocationStream();
      setState(() {
        _userLat = loc.lat;
        _userLon = loc.lon;
      });
    }
    await _refreshLocationLabel();
    _computeOutlook();
    _computeDailyForecast();
  }

  Future<void> _refreshLocationLabel() async {
    if (_activeSaved != null) {
      setState(() {
        _locationLabel = _activeSaved!.name;
      });
      return;
    }
    if (_userLat != null && _userLon != null) {
      final label = await GeocodingService().placeNameFrom(
        _userLat!,
        _userLon!,
      );
      if (!mounted) return;
      setState(() {
        _locationLabel = label ??
            'Lat: ${_userLat!.toStringAsFixed(2)}, Lon: ${_userLon!.toStringAsFixed(2)}';
      });
    }
  }

  Future<void> _openLocationManager() async {
    final svc = LocationsService();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              Future<void> refreshSaved() async {
                final s = await svc.getSaved();
                final a = await svc.getActive();
                setLocal(() {
                  _savedLocations = s;
                  _activeSaved = a;
                });
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.target),
                        title: Text(_locationLabel ?? 'Current location'),
                        subtitle: (_userLat != null && _userLon != null)
                            ? Text(
                                'Lat ${_userLat!.toStringAsFixed(2)}, Lon ${_userLon!.toStringAsFixed(2)}')
                            : const Text('Fetching location...'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await _setActiveSaved(null); // Follow GPS
                            // ignore: use_build_context_synchronously
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Use'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saved locations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._savedLocations.map(
                      (loc) => Card(
                        child: ListTile(
                          leading: const Icon(LucideIcons.mapPin),
                          title: Text(loc.name),
                          subtitle: Text(
                            'Lat ${loc.lat.toStringAsFixed(2)}, Lon ${loc.lon.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_activeSaved?.name == loc.name)
                                const Icon(LucideIcons.check,
                                    color: Colors.green),
                              TextButton(
                                onPressed: () async {
                                  await _setActiveSaved(loc); // Pin to saved
                                  // ignore: use_build_context_synchronously
                                  if (mounted) Navigator.pop(context);
                                },
                                child: const Text('Use'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2),
                                onPressed: () async {
                                  await svc.removeByName(loc.name);
                                  await refreshSaved();
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Form(
                      key: formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Search place (e.g., Ndola, Zambia)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter a place'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final q = controller.text.trim();
                              final result =
                                  await GeocodingService().searchPlace(q);
                              if (result == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Place not found'),
                                    ),
                                  );
                                }
                                return;
                              }
                              final loc = SavedLocation(
                                name: result.label,
                                lat: result.lat,
                                lon: result.lon,
                              );
                              await svc.add(loc);
                              await refreshSaved();
                              controller.clear();
                            },
                            icon: const Icon(LucideIcons.search),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    await _loadSavedLocations();
    _computeOutlook();
    _computeDailyForecast();
  }

  Future<List<Crop>> _loadRecommendedCrops(Weather weather) async {
    final String data = await rootBundle.loadString('lib/data/crops.json');
    final List<dynamic> jsonResult = json.decode(data);
    final seasonInfo = SeasonService().getSeasonInfo(DateTime.now());
    final allowedTags = seasonInfo.datasetTags.toSet();

    bool seasonMatches(String s) {
      final norm = (s == 'Wet') ? 'Rainy' : s;
      return allowedTags.contains(norm);
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
              seasonMatches(crop.season),
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

  Widget _buildLocationPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPin, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Location Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _locationIssue ??
                'Please enable location to view local weather and recommendations.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _getUserLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Enable Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _useDefaultLocation,
                icon: const Icon(Icons.place),
                label: const Text('Use Default'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      builder: (context) => AlertDialog(
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
                          double.tryParse(minTempController.text.trim()) ?? 0,
                      maxTemp:
                          double.tryParse(maxTempController.text.trim()) ?? 0,
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

  void _refreshData() {
    setState(() {
      // Trigger a rebuild to refresh weather data and other content
    });
  }

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
                // ignore: deprecated_member_use
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
      future: (_effLat ?? _userLat) != null &&
              (_effLon ?? _userLon) != null &&
              !_isOffline
          ? WeatherService(
              _weatherApiKey,
              demoMode: _demoMode,
            ).fetchCurrentWeather(
              (_effLat ?? _userLat)!,
              (_effLon ?? _userLon)!,
            )
          : null,
      builder: (context, snapshot) {
        if (_isOffline) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OfflineBanner(onRetry: _refreshData),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You are offline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reconnect to load live weather and recommendations.',
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        if ((_effLat ?? _userLat) == null || (_effLon ?? _userLon) == null) {
          // If we tried and have an issue, show prompt instead of endless spinner
          if (_locationIssue != null || _triedLocation) {
            return _buildLocationPrompt();
          }
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
              if (_isOffline) OfflineBanner(onRetry: _refreshData),
              if (_demoMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    color: const Color(0xFFFFF3E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Demo data shown. Set OPENWEATHER_API_KEY via --dart-define to enable live data.',
                        style: TextStyle(color: Color(0xFFEF6C00)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DashboardHeader(
                  location: _locationLabel ??
                      ((_effLat ?? _userLat) != null &&
                              (_effLon ?? _userLon) != null
                          ? 'Lat: ${(_effLat ?? _userLat)!.toStringAsFixed(2)}, Lon: ${(_effLon ?? _userLon)!.toStringAsFixed(2)}'
                          : 'Locating...'),
                  lastUpdate:
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  onRefresh: _refreshData,
                  onLocationTap: _openLocationManager,
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
                        status: weather.temperature > 30
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
                        status: (weather.rainfall) > 10
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
              FutureBuilder<List<DailyForecast>>(
                future: _dailyForecastFuture,
                builder: (context, fSnap) {
                  if (_isOffline) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, color: Colors.red.shade300),
                              const SizedBox(width: 8),
                              const Text('Offline: forecast unavailable'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (fSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final days = fSnap.data ?? const <DailyForecast>[];
                  return DailyForecastStrip(
                    days: days,
                    enableAnimations: _enableAnimations,
                    useCelsius: _useCelsius,
                  );
                },
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
              // Zambia Season Card to inform recommendations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (_) {
                    final seasonInfo = SeasonService().getSeasonInfo(
                      DateTime.now(),
                    );
                    return FutureBuilder<SeasonalOutlook?>(
                      future: _outlookFuture,
                      builder: (context, outSnap) {
                        return SeasonCard(
                          season: seasonInfo,
                          outlook: outSnap.data,
                          onShowSeasonCrops: seasonInfo.name == 'Rainy'
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CropsListScreen(
                                        currentWeather: weather,
                                        initialSeasonFilter: 'Rainy',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    );
                  },
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
                      children: crops.map((crop) {
                        // Suitability: based on how close weather.temperature is to crop's ideal range
                        double tempMid = (crop.minTemp + crop.maxTemp) / 2.0;
                        double tempDiff = (weather.temperature - tempMid).abs();
                        double tempRange = (crop.maxTemp - crop.minTemp) / 2.0;
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
                                builder: (context) =>
                                    CropDetailsScreen(crop: crop),
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
              // Trust Signals section removed per request
              const SizedBox(height: 8),
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
                          icon: LucideIcons.calendarDays,
                          title: 'Plan',
                          subtitle: 'Open your crop planning calendar',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CropRecommendationScreen(
                                  currentWeather: weather,
                                  startInPlan: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        _buildQuickActionTile(
                          icon: LucideIcons.plus,
                          title: 'Add Crop Plan',
                          subtitle: 'Create a plan with schedule and reminders',
                          color: Colors.indigo,
                          onTap: () async {
                            final String data = await rootBundle.loadString(
                              'lib/data/crops.json',
                            );
                            final List<dynamic> jsonResult = json.decode(data);
                            final crops = jsonResult
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
                                .toList();
                            await Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddCropPlanScreen(
                                  knownCrops: crops,
                                  currentWeather: weather,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
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
          ? WeatherService(
              _weatherApiKey,
            ).fetchCurrentWeather(_userLat!, _userLon!)
          : null,
      builder: (context, snapshot) {
        return CropsListScreen(currentWeather: snapshot.data);
      },
    );

    final weatherPage = const WeatherScreen();
    final settingsPage = const SettingsScreen();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GradientAppBar(
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
      ),
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
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

  @override
  void dispose() {
    _connSub?.cancel();
    _stopLocationStream();
    super.dispose();
  }
}

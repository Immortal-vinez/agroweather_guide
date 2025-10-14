import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String _weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  double? _userLat;
  double? _userLon;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _getUserLocation();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLat = position.latitude;
      _userLon = position.longitude;
    });
  }

  Future<void> _refreshWeather() async {
    setState(() {
      _isLoading = true;
    });
    await _getUserLocation();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.cloudSun, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Weather Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw),
            onPressed: _refreshWeather,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userLat == null || _userLon == null
              ? _buildLocationError()
              : FutureBuilder<Weather>(
                future: WeatherService(
                  _weatherApiKey,
                ).fetchCurrentWeather(_userLat!, _userLon!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  if (!snapshot.hasData) {
                    return _buildNoDataState();
                  }
                  return _buildWeatherContent(snapshot.data!);
                },
              ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable location services to view weather data',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshWeather,
              icon: Icon(LucideIcons.mapPin),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Weather',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshWeather,
              icon: Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Text(
        'No weather data available',
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildWeatherContent(Weather weather) {
    return RefreshIndicator(
      onRefresh: _refreshWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Weather Card
            _buildHeroWeatherCard(weather),
            const SizedBox(height: 16),
            // Weather Details Grid
            _buildWeatherDetailsGrid(weather),
            const SizedBox(height: 16),
            // Farming Insights
            _buildFarmingInsights(weather),
            const SizedBox(height: 16),
            // Hourly Forecast Placeholder
            _buildHourlyForecast(),
            const SizedBox(height: 16),
            // Additional Weather Info
            _buildAdditionalInfo(weather),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroWeatherCard(Weather weather) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getWeatherGradient(weather.condition),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_userLat!.toStringAsFixed(2)}, Lon: ${_userLon!.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            // Weather Icon
            Icon(
              _getWeatherIcon(weather.condition),
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            // Temperature
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            // Condition
            Text(
              weather.condition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Feels like ${weather.temperature.toStringAsFixed(0)}°C',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Last updated
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsGrid(Weather weather) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildWeatherDetailCard(
                icon: LucideIcons.droplets,
                label: 'Humidity',
                value: '${weather.humidity}%',
                color: Colors.blue,
              ),
              _buildWeatherDetailCard(
                icon: LucideIcons.wind,
                label: 'Wind Speed',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                color: Colors.teal,
              ),
              _buildWeatherDetailCard(
                icon: Icons.water_drop,
                label: 'Rainfall',
                value: '${weather.rainfall.toStringAsFixed(1)} mm',
                color: Colors.indigo,
              ),
              _buildWeatherDetailCard(
                icon: LucideIcons.gauge,
                label: 'Pressure',
                value: '${weather.pressure} hPa',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmingInsights(Weather weather) {
    List<Map<String, dynamic>> insights = [];

    // Temperature insights
    if (weather.temperature > 30) {
      insights.add({
        'icon': LucideIcons.thermometer,
        'color': Colors.red,
        'title': 'High Temperature Alert',
        'message':
            'Water crops early morning or late evening to reduce evaporation.',
      });
    } else if (weather.temperature < 15) {
      insights.add({
        'icon': LucideIcons.thermometer,
        'color': Colors.blue,
        'title': 'Cool Temperature',
        'message': 'Consider frost protection for sensitive crops.',
      });
    }

    // Rainfall insights
    if (weather.rainfall > 10) {
      insights.add({
        'icon': LucideIcons.cloudRain,
        'color': Colors.blue,
        'title': 'Heavy Rainfall Expected',
        'message': 'Ensure proper drainage to prevent waterlogging.',
      });
    } else if (weather.rainfall < 2) {
      insights.add({
        'icon': LucideIcons.droplet,
        'color': Colors.orange,
        'title': 'Low Rainfall',
        'message': 'Plan irrigation schedule for your crops.',
      });
    }

    // Wind insights
    if (weather.windSpeed > 10) {
      insights.add({
        'icon': LucideIcons.wind,
        'color': Colors.teal,
        'title': 'High Wind Speed',
        'message': 'Secure tall crops and check support structures.',
      });
    }

    // Humidity insights
    if (weather.humidity > 80) {
      insights.add({
        'icon': LucideIcons.droplets,
        'color': Colors.indigo,
        'title': 'High Humidity',
        'message': 'Monitor for fungal diseases and pests.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'title': 'Ideal Conditions',
        'message': 'Weather conditions are favorable for farming activities.',
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farming Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: (insight['color'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (insight['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          insight['icon'],
                          color: insight['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['title'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight['message'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hourly Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hourly forecast coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get hour-by-hour weather updates',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(Weather weather) {
    final sunrise = DateTime.now().copyWith(hour: 6, minute: 30);
    final sunset = DateTime.now().copyWith(hour: 18, minute: 45);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sun & Moon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSunMoonInfo(
                      icon: LucideIcons.sunrise,
                      label: 'Sunrise',
                      time:
                          '${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')}',
                      color: Colors.orange,
                    ),
                  ),
                  Container(width: 1, height: 60, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildSunMoonInfo(
                      icon: LucideIcons.sunset,
                      label: 'Sunset',
                      time:
                          '${sunset.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')}',
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonInfo({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  List<Color> _getWeatherGradient(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)];
    } else if (lowerCondition.contains('rain')) {
      return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    } else if (lowerCondition.contains('cloud')) {
      return [const Color(0xFF757F9A), const Color(0xFFD7DDE8)];
    } else if (lowerCondition.contains('storm')) {
      return [const Color(0xFF373B44), const Color(0xFF4286f4)];
    } else if (lowerCondition.contains('snow')) {
      return [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)];
    } else {
      return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
    }
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return LucideIcons.sun;
    } else if (lowerCondition.contains('rain')) {
      return LucideIcons.cloudRain;
    } else if (lowerCondition.contains('cloud')) {
      return LucideIcons.cloud;
    } else if (lowerCondition.contains('storm')) {
      return LucideIcons.cloudLightning;
    } else if (lowerCondition.contains('snow')) {
      return LucideIcons.cloudSnow;
    } else {
      return LucideIcons.cloudSun;
    }
  }
}

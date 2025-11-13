import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:weather_animation/weather_animation.dart';
import '../services/forecast_service.dart';

// Helpers to map conditions to visuals
Color _bgFor(String condition) {
  final c = condition.toLowerCase();
  if (c.contains('thunder')) return const Color(0xFFFFF3CD); // soft amber
  if (c.contains('rain') || c.contains('drizzle')) {
    return const Color(0xFFE3F2FD); // light blue
  }
  if (c.contains('snow')) return const Color(0xFFECEFF1); // blue grey 50
  if (c.contains('cloud')) {
    return const Color(0xFFF1F8E9); // light greenish for overcast
  }
  return const Color(0xFFFFFDE7); // clear: pale yellow
}

IconData _iconFor(String condition) {
  final c = condition.toLowerCase();
  if (c.contains('thunder')) return LucideIcons.cloudLightning;
  if (c.contains('rain') || c.contains('drizzle')) return LucideIcons.cloudRain;
  if (c.contains('snow')) return LucideIcons.cloudSnow;
  if (c.contains('cloud')) return LucideIcons.cloud;
  return LucideIcons.sun; // clear
}

String _weekdayShort(DateTime date) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[(date.weekday - 1) % 7];
}

class DailyForecastStrip extends StatelessWidget {
  final List<DailyForecast> days;
  final bool enableAnimations;
  final bool useCelsius;
  const DailyForecastStrip(
      {super.key,
      required this.days,
      this.enableAnimations = true,
      this.useCelsius = true});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(LucideIcons.calendarX, color: Colors.grey.shade500, size: 32),
            const SizedBox(height: 8),
            Text(
              'No forecast data available',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, i) => MiniWeatherTile(
          day: days[i],
          bgColor: _bgFor(days[i].condition),
          icon: _iconFor(days[i].condition),
          label: _weekdayShort(days[i].date),
          enableAnimations: enableAnimations,
          useCelsius: useCelsius,
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: days.length,
      ),
    );
  }
}

class MiniWeatherTile extends StatefulWidget {
  final DailyForecast day;
  final Color bgColor;
  final IconData icon;
  final String label;
  final bool enableAnimations;
  final bool useCelsius;
  const MiniWeatherTile({
    super.key,
    required this.day,
    required this.bgColor,
    required this.icon,
    required this.label,
    this.enableAnimations = true,
    this.useCelsius = true,
  });

  @override
  State<MiniWeatherTile> createState() => _MiniWeatherTileState();
}

class _MiniWeatherTileState extends State<MiniWeatherTile> {
  bool get _isRain =>
      widget.day.condition.toLowerCase().contains('rain') ||
      widget.day.condition.toLowerCase().contains('drizzle');
  bool get _isSnow => widget.day.condition.toLowerCase().contains('snow');
  bool get _isThunder => widget.day.condition.toLowerCase().contains('thunder');
  bool get _isCloud => widget.day.condition.toLowerCase().contains('cloud');

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: 100,
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 38,
              child: Stack(
                children: [
                  // Third-party weather animation backdrop
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.85,
                      child: _buildWeatherFx(),
                    ),
                  ),
                  // Icon overlay
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(
                          widget.icon.codePoint ^ widget.day.condition.hashCode,
                        ),
                        color: Colors.grey.shade800,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${_fmtTemp(widget.day.maxTemp)}°/${_fmtTemp(widget.day.minTemp)}°',
                key: ValueKey('${widget.day.maxTemp}-${widget.day.minTemp}'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.umbrella,
                  size: 12,
                  color: Colors.blueGrey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(widget.day.pop * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on _MiniWeatherTileState {
  Widget _buildWeatherFx() {
    if (!widget.enableAnimations) return const SizedBox.shrink();
    if (_isThunder) return const ThunderWidget();
    if (_isRain) return const RainWidget();
    if (_isSnow) return const SnowWidget();
    if (_isCloud) return const CloudWidget();
    return const SunWidget();
  }

  String _fmtTemp(double c) {
    if (widget.useCelsius) return c.toStringAsFixed(0);
    final f = (c * 9 / 5) + 32;
    return f.toStringAsFixed(0);
  }
}

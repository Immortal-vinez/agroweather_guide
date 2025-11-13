import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/season_service.dart';
import '../services/seasonal_forecast_service.dart';

class SeasonCard extends StatelessWidget {
  final SeasonInfo season;
  final SeasonalOutlook? outlook;
  final VoidCallback? onShowSeasonCrops;
  const SeasonCard(
      {super.key, required this.season, this.outlook, this.onShowSeasonCrops});

  @override
  Widget build(BuildContext context) {
    final pct = (season.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final daysLeft = season.end.difference(DateTime.now()).inDays;
    final nextStartStr = DateFormat('MMM d').format(season.nextStart);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForSeason(season.name),
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Season: ${season.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        season.dateRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: season.progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$pct% through • ${daysLeft >= 0 ? '$daysLeft days left' : 'ends today'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Next: ${season.nextName} starts $nextStartStr',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (outlook != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    'Rainfall: ${outlook!.rainfallCategory}',
                    Icons.water_drop,
                  ),
                  _chip('Temp: ${outlook!.tempCategory}', Icons.thermostat),
                  _chip(outlook!.periodLabel, Icons.calendar_month),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                outlook!.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (season.name == 'Rainy' && onShowSeasonCrops != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onShowSeasonCrops,
                  icon: const Icon(LucideIcons.cloudRain),
                  label: const Text('Show Rainy Season Crops'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForSeason(String name) {
    switch (name) {
      case 'Rainy':
        return LucideIcons.cloudRain;
      case 'Cool Dry':
        return LucideIcons.snowflake;
      case 'Hot Dry':
      default:
        return LucideIcons.sun;
    }
  }
}

Widget _chip(String text, IconData icon) {
  return Chip(
    avatar: Icon(icon, size: 16),
    label: Text(text),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}

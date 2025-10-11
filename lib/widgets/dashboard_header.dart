import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardHeader extends StatelessWidget {
  final String location;
  final String lastUpdate;
  const DashboardHeader({
    required this.location,
    required this.lastUpdate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  color: const Color(0xFF43A047),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(LucideIcons.clock, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(
                  lastUpdate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'AgroWeather Guide',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF388E3C),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your farming companion for smart decisions',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

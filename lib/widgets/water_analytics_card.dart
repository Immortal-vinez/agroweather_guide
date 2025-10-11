import 'package:flutter/material.dart';

class WaterAnalyticsCard extends StatelessWidget {
  final double cropWaterNeed; // mm
  final double expectedRainfall; // mm
  final double waterDeficit; // mm

  const WaterAnalyticsCard({
    required this.cropWaterNeed,
    required this.expectedRainfall,
    required this.waterDeficit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final deficit = waterDeficit > 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: deficit ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            _buildBar(
              'Crop Water Need',
              cropWaterNeed,
              cropWaterNeed,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildBar(
              'Expected Rainfall',
              expectedRainfall,
              cropWaterNeed,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildBar('Water Deficit', waterDeficit, cropWaterNeed, Colors.red),
            const SizedBox(height: 12),
            if (deficit)
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: Water deficit detected! Consider irrigation.',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, double max, Color color) {
    final percent = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          minHeight: 7,
          // ignore: deprecated_member_use
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(1)} mm',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

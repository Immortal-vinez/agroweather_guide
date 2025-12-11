// ignore_for_file: deprecated_member_use

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
    final bool needsIrrigation = waterDeficit > 0;
    final double rainPercentage = cropWaterNeed > 0
        ? (expectedRainfall / cropWaterNeed * 100).clamp(0, 100)
        : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: needsIrrigation
                ? [Colors.orange.shade50, Colors.orange.shade100]
                : [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Water for Your Crops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Text(
                        needsIrrigation ? 'Action Needed' : 'Looks Good',
                        style: TextStyle(
                          fontSize: 13,
                          color: needsIrrigation
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Water Need Section
            _buildSimpleWaterBar(
              icon: Icons.agriculture,
              label: 'Crops Need',
              value: cropWaterNeed,
              color: Colors.blue.shade700,
              maxValue: cropWaterNeed,
            ),

            const SizedBox(height: 16),

            // Expected Rainfall Section
            _buildSimpleWaterBar(
              icon: Icons.cloud,
              label: 'Expected Rain',
              value: expectedRainfall,
              color: Colors.green.shade600,
              maxValue: cropWaterNeed,
            ),

            const SizedBox(height: 20),

            // Rain Coverage Indicator
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: needsIrrigation
                      ? Colors.orange.shade300
                      : Colors.green.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    needsIrrigation ? Icons.warning_amber : Icons.check_circle,
                    color: needsIrrigation
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rain covers ${rainPercentage.toInt()}% of water needed',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (needsIrrigation)
                          Text(
                            'You need ${waterDeficit.toStringAsFixed(0)}mm more water',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Rain is enough! No irrigation needed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (needsIrrigation) ...[
              const SizedBox(height: 16),
              // Irrigation Advice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb,
                        color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider watering your crops soon',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleWaterBar({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required double maxValue,
  }) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)} mm',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Filled bar
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/crop.dart';

class CropRecommendationCard extends StatelessWidget {
  final Crop crop;
  final double suitability;
  final double waterSaving;
  final String reason;
  const CropRecommendationCard({
    super.key,
    required this.crop,
    required this.suitability,
    required this.waterSaving,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(crop.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Suitability: ',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      Text(
                        '${(suitability * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Water Saving: ',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      Text(
                        '${waterSaving.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 13, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

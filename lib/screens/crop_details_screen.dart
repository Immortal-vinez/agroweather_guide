import 'package:flutter/material.dart';
import '../models/crop.dart';

class CropDetailsScreen extends StatelessWidget {
  final Crop crop;
  const CropDetailsScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(crop.name),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Season: ${crop.season}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Care Tip: ${crop.careTip}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text('Temperature Range: ${crop.minTemp}°C - ${crop.maxTemp}°C'),
          ],
        ),
      ),
    );
  }
}

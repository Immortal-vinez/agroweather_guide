import 'package:flutter/material.dart';

class RecentAlertsSection extends StatelessWidget {
  final List<String> alerts;
  const RecentAlertsSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container();
    }
    return Card(
      color: const Color(0xFFFFF9C4), // Sunshine Yellow (light)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50), // Leaf Green
              ),
            ),
            const SizedBox(height: 8),
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Color(0xFFFFA000),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: const TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

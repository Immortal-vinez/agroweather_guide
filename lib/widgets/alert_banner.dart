import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  const AlertBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF9C4), // Sunshine Yellow (light)
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.warning, color: Color(0xFFFFEB3B)), // Sunshine Yellow
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Color(0xFF333333), // Charcoal
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

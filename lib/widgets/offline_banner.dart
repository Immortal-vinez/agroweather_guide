import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0E0), // light red background
        border: Border(
          bottom: BorderSide(color: Colors.red.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red.shade600),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You are offline. Check your connection to fetch live data.',
              style: TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

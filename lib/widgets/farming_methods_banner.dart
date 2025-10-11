import 'package:flutter/material.dart';

class FarmingMethodsBanner extends StatefulWidget {
  const FarmingMethodsBanner({super.key});

  @override
  State<FarmingMethodsBanner> createState() => _FarmingMethodsBannerState();
}

class _FarmingMethodsBannerState extends State<FarmingMethodsBanner> {
  final List<_FarmingMethod> _methods = [
    _FarmingMethod(
      icon: Icons.grass,
      title: 'Conservation Tillage',
      description: 'Reduce soil erosion and improve water retention.',
    ),
    _FarmingMethod(
      icon: Icons.water_drop,
      title: 'Drip Irrigation',
      description: 'Save water and deliver nutrients directly to roots.',
    ),
    _FarmingMethod(
      icon: Icons.eco,
      title: 'Agroforestry',
      description: 'Integrate trees and crops for better yields.',
    ),
    _FarmingMethod(
      icon: Icons.bug_report,
      title: 'Integrated Pest Management',
      description: 'Use natural predators and reduce chemical use.',
    ),
  ];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 0), _autoSlide);
  }

  void _autoSlide() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      setState(() {
        _current = (_current + 1) % _methods.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = _methods[_current];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(method.icon, size: 48, color: Color(0xFF90A4AE)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF607D8B), // Ash gray
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF607D8B), // Ash gray
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmingMethod {
  final IconData icon;
  final String title;
  final String description;
  _FarmingMethod({
    required this.icon,
    required this.title,
    required this.description,
  });
}

import 'package:flutter/material.dart';

class RiskAlertBanner extends StatelessWidget {
  final String riskLevel; // e.g. 'High', 'Moderate', 'Low'
  final String alertMessage;
  final double riskPercent; // 0.0 - 1.0
  final String recommendedAction;

  const RiskAlertBanner({
    required this.riskLevel,
    required this.alertMessage,
    required this.riskPercent,
    required this.recommendedAction,
    super.key,
  });

  Color getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'moderate':
        return Colors.orangeAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = getRiskColor();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: riskColor, width: 6)),
          // ignore: deprecated_member_use
          color: riskColor.withOpacity(0.07),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning, color: riskColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              riskLevel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alertMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: riskPercent,
                        minHeight: 6,
                        // ignore: deprecated_member_use
                        backgroundColor: riskColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendedAction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF388E3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

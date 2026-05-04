import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Compact severity pill used in hazard report rows.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(severity.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  (Color, String) _styleFor(String s) {
    switch (s) {
      case 'critical':
        return (AppTheme.severityCritical, 'CRITICAL');
      case 'high':
        return (AppTheme.severityHigh, 'HIGH');
      case 'medium':
        return (AppTheme.severityMedium, 'MEDIUM');
      default:
        return (AppTheme.severityLow, 'LOW');
    }
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pill / chip showing a risk level (LOW / MEDIUM / HIGH).
///
/// Two visual sizes:
///  - `large = false` (default): 28-px height, used in worker list rows.
///  - `large = true`: 48-px height, used as the hero on Worker Dashboard.
///
/// The level string is normalised to lowercase so it's tolerant of upstream
/// case (Firestore docs may carry "low" or "Low").
class RiskLevelBadge extends StatelessWidget {
  const RiskLevelBadge({
    super.key,
    required this.level,
    this.large = false,
  });

  final String level;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final lvl = level.toLowerCase();
    final (color, label, icon) = _styleFor(lvl);
    final padV = large ? 12.0 : 4.0;
    final padH = large ? 18.0 : 10.0;
    final iconSize = large ? 20.0 : 14.0;
    final fontSize = large ? 20.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(large ? 24 : 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: large ? 8 : 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _styleFor(String lvl) {
    switch (lvl) {
      case 'high':
        return (AppTheme.riskHigh, 'HIGH', Icons.warning_amber_rounded);
      case 'medium':
        return (AppTheme.riskMedium, 'MEDIUM', Icons.error_outline_rounded);
      default:
        return (AppTheme.riskLow, 'LOW', Icons.shield_outlined);
    }
  }
}

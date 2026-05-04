import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pill showing the lifecycle status of a hazard report.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _styleFor(String s) {
    switch (s) {
      case 'acknowledged':
        return (AppTheme.statusAcknowledged, 'ACKNOWLEDGED');
      case 'in_progress':
        return (AppTheme.statusInProgress, 'IN PROGRESS');
      case 'resolved':
        return (AppTheme.statusResolved, 'RESOLVED');
      default:
        return (AppTheme.statusPending, 'PENDING');
    }
  }
}

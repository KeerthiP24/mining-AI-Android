import 'package:flutter/material.dart';

import '../models/hazard_report_model.dart';

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label,
        style: TextStyle(
          color: _foreground(status),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: _background(status),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _background(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:
        return Colors.orange.shade100;
      case ReportStatus.acknowledged:
        return Colors.blue.shade100;
      case ReportStatus.inProgress:
        return Colors.purple.shade100;
      case ReportStatus.resolved:
        return Colors.green.shade100;
    }
  }

  Color _foreground(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:
        return Colors.orange.shade900;
      case ReportStatus.acknowledged:
        return Colors.blue.shade900;
      case ReportStatus.inProgress:
        return Colors.purple.shade900;
      case ReportStatus.resolved:
        return Colors.green.shade900;
    }
  }
}

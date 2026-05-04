import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'risk_level_badge.dart';

/// A row in the supervisor's worker list. Tap navigates to that worker's
/// detail screen. Background tint matches the risk level so the list reads
/// as a heatmap when scrolled.
class WorkerListTile extends StatelessWidget {
  const WorkerListTile({
    super.key,
    required this.name,
    required this.riskLevel,
    required this.riskScore,
    required this.checklistDone,
    required this.pendingReports,
    required this.onTap,
    this.subtitle,
  });

  final String name;
  final String riskLevel;
  final int riskScore;
  final bool checklistDone;
  final int pendingReports;
  final VoidCallback onTap;

  /// Optional extra context (e.g. "Section B · Morning shift").
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _tintFor(riskLevel.toLowerCase());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: tint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                foregroundColor: theme.colorScheme.primary,
                child: Text(
                  _initials(name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RiskLevelBadge(level: riskLevel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          checklistDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: checklistDone
                              ? AppTheme.riskLow
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          checklistDone
                              ? 'Checklist done'
                              : 'Checklist pending',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 16,
                          color: pendingReports > 0
                              ? AppTheme.severityHigh
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pendingReports == 0
                              ? 'No reports'
                              : '$pendingReports report${pendingReports == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          'Score $riskScore',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Color _tintFor(String level) {
    switch (level) {
      case 'high':
        return AppTheme.riskHigh.withValues(alpha: 0.05);
      case 'medium':
        return AppTheme.riskMedium.withValues(alpha: 0.05);
      default:
        return AppTheme.riskLow.withValues(alpha: 0.04);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

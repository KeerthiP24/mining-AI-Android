import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// AppBar trailing chip showing "completed / total" item counts.
class ComplianceProgressChip extends StatelessWidget {
  const ComplianceProgressChip({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allDone = completed == total && total > 0;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: allDone
            ? Colors.green.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Text(
        l10n.checklist_progress_chip(completed, total),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: allDone
              ? Colors.green
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

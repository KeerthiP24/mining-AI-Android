import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// A single checklist row — glove-friendly 56dp+ tap target.
class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.itemId,
    required this.label,
    required this.mandatory,
    required this.completed,
    required this.isSubmitted,
    required this.onTap,
  });

  final String itemId;
  final String label;
  final bool mandatory;
  final bool completed;
  final bool isSubmitted;  // read-only mode after submission
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isSubmitted ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AnimatedCheckCircle(
              completed: completed,
              mandatory: mandatory,
              disabled: isSubmitted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: completed
                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                      : colorScheme.onSurface,
                  decoration:
                      completed ? TextDecoration.lineThrough : null,
                  decorationColor: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (mandatory && !completed)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.checklist_mandatory_badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCheckCircle extends StatelessWidget {
  const _AnimatedCheckCircle({
    required this.completed,
    required this.mandatory,
    required this.disabled,
  });

  final bool completed;
  final bool mandatory;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed
            ? Colors.green
            : (mandatory
                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest),
        border: Border.all(
          color: completed
              ? Colors.green
              : (mandatory ? colorScheme.error : colorScheme.outline),
          width: 2,
        ),
      ),
      child: completed
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }
}

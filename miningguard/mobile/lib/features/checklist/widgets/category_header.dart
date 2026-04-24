import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Maps a category ID to a display label using localisation.
String categoryLabel(BuildContext context, String category) {
  final l10n = AppLocalizations.of(context)!;
  switch (category) {
    case 'ppe':
      return l10n.checklist_category_ppe;
    case 'machinery':
      return l10n.checklist_category_machinery;
    case 'environment':
      return l10n.checklist_category_environment;
    case 'emergency':
      return l10n.checklist_category_emergency;
    case 'supervisor':
      return l10n.checklist_category_supervisor;
    default:
      return category;
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'ppe':
      return Icons.security;
    case 'machinery':
      return Icons.precision_manufacturing;
    case 'environment':
      return Icons.air;
    case 'emergency':
      return Icons.emergency;
    case 'supervisor':
      return Icons.supervisor_account;
    default:
      return Icons.checklist;
  }
}

/// Collapsible category section header.
/// Starts expanded; shows completed/total count in collapsed state.
class CategoryHeader extends StatefulWidget {
  const CategoryHeader({
    super.key,
    required this.category,
    required this.completedCount,
    required this.totalCount,
    required this.children,
  });

  final String category;
  final int completedCount;
  final int totalCount;
  final List<Widget> children;

  @override
  State<CategoryHeader> createState() => _CategoryHeaderState();
}

class _CategoryHeaderState extends State<CategoryHeader> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allDone = widget.completedCount == widget.totalCount;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        leading: Icon(
          _categoryIcon(widget.category),
          color: allDone ? Colors.green : colorScheme.primary,
        ),
        title: Text(
          categoryLabel(context, widget.category),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: allDone
                ? Colors.green
                : colorScheme.onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: allDone
                    ? Colors.green.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.completedCount} / ${widget.totalCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: allDone ? Colors.green : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        children: widget.children,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hazard_report_model.dart';
import '../providers/hazard_report_provider.dart';

class CategorySeverityPicker extends ConsumerWidget {
  const CategorySeverityPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportSubmissionProvider).value ?? const ReportDraft();
    final notifier = ref.read(reportSubmissionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<HazardCategory>(
          initialValue: draft.category,
          decoration: const InputDecoration(
            labelText: 'Hazard Category *',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select category'),
          items: HazardCategory.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
          onChanged: (val) {
            if (val != null) notifier.setCategory(val);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HazardSeverity>(
          initialValue: draft.severity,
          decoration: const InputDecoration(
            labelText: 'Severity',
            border: OutlineInputBorder(),
          ),
          items: HazardSeverity.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(_severityIcon(s), color: _severityColor(s), size: 18),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) notifier.setSeverity(val);
          },
        ),
      ],
    );
  }

  IconData _severityIcon(HazardSeverity s) {
    switch (s) {
      case HazardSeverity.low:
        return Icons.info_outline;
      case HazardSeverity.medium:
        return Icons.warning_amber_outlined;
      case HazardSeverity.high:
        return Icons.warning_rounded;
      case HazardSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _severityColor(HazardSeverity s) {
    switch (s) {
      case HazardSeverity.low:
        return Colors.green;
      case HazardSeverity.medium:
        return Colors.orange;
      case HazardSeverity.high:
        return Colors.deepOrange;
      case HazardSeverity.critical:
        return Colors.red;
    }
  }
}

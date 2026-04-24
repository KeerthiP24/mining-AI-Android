import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hazard_report_model.dart';
import '../providers/hazard_report_provider.dart';

class InputModeSelector extends ConsumerWidget {
  const InputModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportSubmissionProvider).value ?? const ReportDraft();
    final notifier = ref.read(reportSubmissionProvider.notifier);

    return Row(
      children: [
        for (final mode in InputMode.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(mode), size: 16),
                    const SizedBox(width: 4),
                    Text(mode.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                selected: draft.inputMode == mode,
                onSelected: (_) => notifier.setInputMode(mode),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(InputMode mode) {
    switch (mode) {
      case InputMode.photo:
        return Icons.camera_alt_outlined;
      case InputMode.voice:
        return Icons.mic_outlined;
      case InputMode.text:
        return Icons.edit_outlined;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_analysis_result_model.dart';
import '../providers/hazard_report_provider.dart';

class AiAnalysisCard extends ConsumerWidget {
  const AiAnalysisCard({super.key, required this.result});

  final AiAnalysisResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(reportSubmissionProvider.notifier);

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.secondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${result.confidencePercent}% confidence',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: result.confidence,
              backgroundColor: colorScheme.onSecondaryContainer.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                result.isHighConfidence ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            _Row(label: 'Detected', value: result.hazardDetected),
            _Row(label: 'Suggested severity', value: result.suggestedSeverity.label),
            if (result.recommendedAction.isNotEmpty)
              _Row(label: 'Recommended action', value: result.recommendedAction),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => notifier.applyAiSuggestion(result),
                child: const Text('Apply suggestions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

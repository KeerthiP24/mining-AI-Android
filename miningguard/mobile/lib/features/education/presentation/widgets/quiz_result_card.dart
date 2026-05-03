import 'package:flutter/material.dart';

/// Result panel shown after the last quiz question. Distinct strings/colors
/// for pass vs fail so the worker immediately knows the outcome.
class QuizResultCard extends StatelessWidget {
  const QuizResultCard({
    super.key,
    required this.passed,
    required this.score,
    required this.totalQuestions,
    required this.passHeading,
    required this.failHeading,
    required this.pointsAwardedLabel,
    required this.continueLabel,
    required this.onContinue,
  });

  final bool passed;
  final int score;
  final int totalQuestions;
  final String passHeading;
  final String failHeading;

  /// e.g. "+5 compliance points" — already localized & interpolated.
  final String pointsAwardedLabel;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        passed ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.emoji_events : Icons.school,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            passed ? passHeading : failHeading,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $totalQuestions',
            style: theme.textTheme.titleLarge,
          ),
          if (passed) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pointsAwardedLabel,
                style: const TextStyle(
                  color: Color(0xFFF5A623),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: Text(continueLabel),
            ),
          ),
        ],
      ),
    );
  }
}

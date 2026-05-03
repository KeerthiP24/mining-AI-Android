import 'package:flutter/material.dart';

import '../../domain/quiz_question.dart';
import '../../domain/safety_video.dart';
import 'quiz_result_card.dart';

/// Modal bottom-sheet quiz UI shown when the player crosses 90% completion.
///
/// Holds local state for the selected answer and the cumulative score, then
/// emits the final score via [onComplete]. The parent is responsible for
/// persisting the result (so this widget stays free of Firebase deps).
class QuizOverlay extends StatefulWidget {
  const QuizOverlay({
    super.key,
    required this.questions,
    required this.languageCode,
    required this.videoTitle,
    required this.headingLabel,
    required this.questionOfTotal,
    required this.submitLabel,
    required this.passHeading,
    required this.failHeading,
    required this.pointsAwardedLabel,
    required this.continueLabel,
    required this.onComplete,
  });

  final List<QuizQuestion> questions;
  final String languageCode;
  final String videoTitle;
  final String headingLabel;

  /// Renders e.g. "Question 2 of 3". Caller supplies a builder so it can use
  /// the gen-l10n placeholder helper.
  final String Function(int current, int total) questionOfTotal;
  final String submitLabel;
  final String passHeading;
  final String failHeading;

  /// Builds e.g. "+5 compliance points".
  final String Function(int points) pointsAwardedLabel;
  final String continueLabel;

  /// Called when the user taps Continue on the result card. [score] is the
  /// number of correct answers; the parent persists pass/fail and points.
  final void Function(int score) onComplete;

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> {
  int _currentIndex = 0;
  int? _selectedOption;
  int? _revealedAnswer; // non-null after Submit, until we advance
  int _correctCount = 0;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      // Defensive: we should not have opened the overlay without questions.
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No quiz questions available.'),
      );
    }

    if (_showResult) {
      return QuizResultCard(
        passed: _correctCount >= 2,
        score: _correctCount,
        totalQuestions: widget.questions.length,
        passHeading: widget.passHeading,
        failHeading: widget.failHeading,
        pointsAwardedLabel: widget.pointsAwardedLabel(5),
        continueLabel: widget.continueLabel,
        onContinue: () => widget.onComplete(_correctCount),
      );
    }

    final q = widget.questions[_currentIndex];
    final theme = Theme.of(context);
    final correctIndex = q.correctOptionIndex;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.headingLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.videoTitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          Text(
            widget.questionOfTotal(_currentIndex + 1, widget.questions.length),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            localizeMap(q.question, widget.languageCode),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ...List.generate(q.options.length, (i) {
            final isSelected = _selectedOption == i;
            final revealed = _revealedAnswer != null;
            Color? bg;
            Color? fg;
            if (revealed) {
              if (i == correctIndex) {
                bg = Colors.green.withValues(alpha: 0.18);
                fg = Colors.green.shade900;
              } else if (i == _revealedAnswer) {
                bg = Colors.red.withValues(alpha: 0.18);
                fg = Colors.red.shade900;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    side: BorderSide(
                      color: isSelected && !revealed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected && !revealed ? 2 : 1,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: revealed
                      ? null
                      : () => setState(() => _selectedOption = i),
                  child: Text(
                    localizeMap(q.options[i], widget.languageCode),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            );
          }),
          if (_revealedAnswer != null && _revealedAnswer != correctIndex) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizeMap(q.explanation, widget.languageCode),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedOption == null || _revealedAnswer != null
                      ? null
                      : _onSubmit,
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    final q = widget.questions[_currentIndex];
    final picked = _selectedOption!;
    final correct = picked == q.correctOptionIndex;
    setState(() {
      _revealedAnswer = picked;
      if (correct) _correctCount++;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex + 1 >= widget.questions.length) {
        setState(() => _showResult = true);
      } else {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _revealedAnswer = null;
        });
      }
    });
  }
}

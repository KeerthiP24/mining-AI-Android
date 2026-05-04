import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Animated horizontal score bar (0–100) used next to a [RiskLevelBadge].
///
/// Color graduates: green ≤33, amber 34–66, red ≥67. The bar animates from
/// 0 to the supplied score over 300 ms on first build so the worker sees it
/// move into place.
class RiskScoreBar extends StatelessWidget {
  const RiskScoreBar({super.key, required this.score});

  /// 0–100. Values outside the range are clamped.
  final int score;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100).toDouble();
    final color = _colorFor(clamped);
    final value = clamped / 100.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      builder: (_, t, __) {
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 10,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${clamped.toInt()} / 100',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _colorFor(double s) {
    if (s >= 67) return AppTheme.riskHigh;
    if (s >= 34) return AppTheme.riskMedium;
    return AppTheme.riskLow;
  }
}

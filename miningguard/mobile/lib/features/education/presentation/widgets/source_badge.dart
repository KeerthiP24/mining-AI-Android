import 'package:flutter/material.dart';

import '../../domain/safety_video.dart';

/// Small colored pill rendering a video [VideoSource]. Each source has a
/// distinct color so workers learn to associate them at a glance.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, String) _styleFor(String source) {
    switch (source) {
      case VideoSource.dgms:
        return (const Color(0xFFD32F2F), 'DGMS');
      case VideoSource.msha:
        return (const Color(0xFF1976D2), 'MSHA');
      case VideoSource.hse:
        return (const Color(0xFF388E3C), 'HSE');
      case VideoSource.workSafe:
        return (const Color(0xFF7B1FA2), 'WorkSafe');
      default:
        return (const Color(0xFF616161), 'Custom');
    }
  }
}

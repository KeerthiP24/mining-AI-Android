import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../providers/firebase_providers.dart';

/// Live-updating risk badge for the worker dashboard.
///
/// Subscribes to `users/{uid}` so when the FastAPI `/risk/predict` endpoint
/// (or its Cloud Function trigger) writes `riskLevel`/`riskScore`/
/// `riskFactors`, the card animates to the new state without a manual
/// refresh. Falls back to a "Low" placeholder while the document loads.
class RiskLevelCard extends ConsumerWidget {
  const RiskLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    if (auth == null) return const SizedBox.shrink();

    final firestore = ref.watch(firestoreProvider);
    return StreamBuilder(
      stream: firestore.collection('users').doc(auth.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final level = (data['riskLevel'] as String? ?? 'low').toLowerCase();
        final score = (data['riskScore'] as num?)?.toInt();
        final factors = ((data['riskFactors'] as List?) ?? const [])
            .whereType<String>()
            .toList();
        return _RiskCard(level: level, score: score, factors: factors);
      },
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.level,
    required this.score,
    required this.factors,
  });

  final String level;
  final int? score;
  final List<String> factors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label, icon) = _styleFor(level);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your safety risk',
                          style: theme.textTheme.bodySmall),
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score / 100',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (factors.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Why', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              ...factors.take(3).map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: Icon(Icons.circle, size: 6),
                          ),
                          Expanded(
                            child: Text(f, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, String, IconData) _styleFor(String level) {
    switch (level) {
      case 'high':
        return (const Color(0xFFC62828), 'HIGH', Icons.warning);
      case 'medium':
        return (const Color(0xFFEF6C00), 'MEDIUM', Icons.error_outline);
      default:
        return (const Color(0xFF2E7D32), 'LOW', Icons.shield_outlined);
    }
  }
}

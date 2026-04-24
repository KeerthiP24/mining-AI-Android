import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';

class ChecklistSuccessScreen extends StatefulWidget {
  const ChecklistSuccessScreen({super.key, required this.complianceScore});

  final double complianceScore;

  @override
  State<ChecklistSuccessScreen> createState() => _ChecklistSuccessScreenState();
}

class _ChecklistSuccessScreenState extends State<ChecklistSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _feedbackMessage(AppLocalizations l10n) {
    final pct = widget.complianceScore;
    if (pct >= 0.90) return l10n.checklist_success_excellent;
    if (pct >= 0.70) return l10n.checklist_success_good;
    if (pct >= 0.50) return l10n.checklist_success_fair;
    return l10n.checklist_success_poor;
  }

  Color _scoreColor() {
    final pct = widget.complianceScore;
    if (pct >= 0.90) return Colors.green;
    if (pct >= 0.70) return Colors.lightGreen;
    if (pct >= 0.50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scorePercent =
        (widget.complianceScore * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Green check animation
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      l10n.checklist_success_title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    // Score display
                    Text(
                      '$scorePercent%',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                        color: _scoreColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _feedbackMessage(l10n),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () =>
                            context.go(AppRoutes.workerHome),
                        child: Text(l10n.checklist_success_back_home),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

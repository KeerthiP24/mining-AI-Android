import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders that match the worker / supervisor dashboard
/// silhouettes. Shown while live providers are still resolving.
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({
    super.key,
    this.variant = SkeletonVariant.worker,
  });

  final SkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: variant == SkeletonVariant.supervisor
          ? const _SupervisorSkeleton()
          : const _WorkerSkeleton(),
    );
  }
}

enum SkeletonVariant { worker, supervisor }

class _Block extends StatelessWidget {
  const _Block({this.height = 80, this.width = double.infinity});
  final double height;
  final double width;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _WorkerSkeleton extends StatelessWidget {
  const _WorkerSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _Block(height: 140), // risk hero card
        _Block(height: 100), // checklist
        _Block(height: 110), // video of day
        _Block(height: 90),  // recent reports
        _Block(height: 80),  // alerts
        _Block(height: 180), // chart
      ],
    );
  }
}

class _SupervisorSkeleton extends StatelessWidget {
  const _SupervisorSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: const [
              Expanded(child: _Block(height: 90, width: 100)),
              Expanded(child: _Block(height: 90, width: 100)),
              Expanded(child: _Block(height: 90, width: 100)),
            ],
          ),
        ),
        const _Block(height: 60), // filter chips
        const _Block(height: 90),
        const _Block(height: 90),
        const _Block(height: 90),
        const _Block(height: 90),
        const _Block(height: 200), // chart
      ],
    );
  }
}

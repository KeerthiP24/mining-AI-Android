import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../models/hazard_report_model.dart';
import '../providers/hazard_report_provider.dart';
import '../providers/report_list_provider.dart';
import '../widgets/report_status_badge.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('My Reports')),
        body: Center(child: Text(e.toString())),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Reports')),
            body: const Center(child: Text('Not signed in')),
          );
        }
        return _ReportList(uid: user.uid);
      },
    );
  }
}

class _ReportList extends ConsumerWidget {
  const _ReportList({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(workerReportsProvider(uid));
    final queueService = ref.watch(reportQueueServiceProvider);
    final pendingCount = queueService.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('$pendingCount syncing'),
                backgroundColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade900,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.toString()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(workerReportsProvider(uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reports) {
          if (reports.isEmpty && pendingCount == 0) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ReportCard(
              report: reports[i],
              onTap: () => context.push(
                AppRoutes.reportDetail,
                extra: reports[i],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final HazardReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _severityColor(report.severity).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _categoryIcon(report.category),
                  color: _severityColor(report.severity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.category.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (report.isOfflineCreated && report.syncedAt == null) ...[
                          const SizedBox(width: 6),
                          _SyncingBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(report.submittedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (report.mineSection.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        report.mineSection,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ReportStatusBadge(status: report.status),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      report.severity.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: _severityColor(report.severity),
                      ),
                    ),
                    backgroundColor: _severityColor(report.severity).withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  IconData _categoryIcon(HazardCategory c) {
    switch (c) {
      case HazardCategory.roofFall:
        return Icons.foundation;
      case HazardCategory.gasLeak:
        return Icons.air;
      case HazardCategory.fire:
        return Icons.local_fire_department;
      case HazardCategory.machinery:
        return Icons.settings;
      case HazardCategory.electrical:
        return Icons.bolt;
      case HazardCategory.other:
        return Icons.warning_amber;
    }
  }
}

class _SyncingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '⏳ Syncing…',
            style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to report a hazard',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

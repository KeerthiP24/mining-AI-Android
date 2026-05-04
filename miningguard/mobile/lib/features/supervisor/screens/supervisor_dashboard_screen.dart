import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/widgets/dashboard/compliance_trend_chart.dart';
import '../../../shared/widgets/dashboard/dashboard_skeleton_loader.dart';
import '../../../shared/widgets/dashboard/report_status_badge.dart';
import '../../../shared/widgets/dashboard/severity_badge.dart';
import '../../../shared/widgets/dashboard/stat_card.dart';
import '../../../shared/widgets/dashboard/worker_list_tile.dart';
import '../providers/supervisor_dashboard_provider.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supervisorAsync = ref.watch(currentUserModelProvider);

    return supervisorAsync.when(
      loading: () => const Scaffold(
        body: DashboardSkeletonLoader(variant: SkeletonVariant.supervisor),
      ),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (supervisor) {
        if (supervisor == null) {
          return const Scaffold(body: Center(child: Text('Not signed in')));
        }
        final summary = ref.watch(mineSummaryProvider);
        final workers = ref.watch(filteredWorkersProvider);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shift Dashboard',
                    style: TextStyle(fontSize: 16)),
                Text(
                  '${supervisor.mineName ?? supervisor.mineId} · '
                  '${_titleCase(supervisor.shift)} shift',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Export shift report',
                icon: const Icon(Icons.ios_share),
                onPressed: () => _exportShiftReport(summary, workers),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.go(AppRoutes.workerProfile),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const _SectionTitle('Mine at a glance'),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    StatCard(
                      label: 'Workers',
                      value: '${summary.totalWorkers}',
                      icon: Icons.groups_outlined,
                    ),
                    StatCard(
                      label: 'High risk',
                      value: '${summary.highRiskCount}',
                      icon: Icons.warning_amber_outlined,
                      color: AppTheme.riskHigh,
                    ),
                    StatCard(
                      label: 'Checklists today',
                      value:
                          '${summary.checklistCompletedCount}/${summary.totalWorkers}',
                      icon: Icons.checklist_rounded,
                    ),
                    StatCard(
                      label: 'Pending reports',
                      value: '${summary.pendingReportsCount}',
                      icon: Icons.report_gmailerrorred_outlined,
                      color: AppTheme.severityHigh,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const _SectionTitle('Workers'),
              const _FilterChipRow(),
              if (workers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(child: Text('No workers match this filter.')),
                )
              else
                ...workers.map(
                  (w) => WorkerListTile(
                    name: w.fullName,
                    riskLevel: w.riskLevel,
                    riskScore: w.riskScore.toInt(),
                    checklistDone: w.todayChecklistDone,
                    pendingReports: w.pendingReportCount,
                    onTap: () => GoRouter.of(context).push(
                      '${AppRoutes.supervisorDashboard}/worker/${w.uid}',
                    ),
                    subtitle: w.department.isNotEmpty
                        ? '${w.department} · ${_titleCase(w.shift)}'
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              const _PendingReportsSection(),
              const SizedBox(height: 16),
              const _ComplianceTrendSection(),
            ],
          ),
        );
      },
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _exportShiftReport(
    MineSummary summary,
    List<UserModel> workers,
  ) async {
    final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());
    final buf = StringBuffer()
      ..writeln('MiningGuard — Shift Safety Report')
      ..writeln('Generated: $now')
      ..writeln('-' * 40)
      ..writeln('Total workers on shift: ${summary.totalWorkers}')
      ..writeln(
          'Checklists completed: ${summary.checklistCompletedCount}/${summary.totalWorkers}')
      ..writeln(
          'Completion rate: ${(summary.checklistCompletionRate * 100).toStringAsFixed(1)}%')
      ..writeln('')
      ..writeln('RISK DISTRIBUTION:')
      ..writeln('  High:   ${summary.highRiskCount}')
      ..writeln('  Medium: ${summary.mediumRiskCount}')
      ..writeln('  Low:    ${summary.lowRiskCount}')
      ..writeln('')
      ..writeln('PENDING REPORTS: ${summary.pendingReportsCount}')
      ..writeln('')
      ..writeln('HIGH RISK WORKERS:');
    for (final w in workers.where((w) => w.riskLevel == 'high')) {
      buf.writeln('  - ${w.fullName} (score ${w.riskScore.toInt()})');
    }
    await SharePlus.instance.share(
      ShareParams(text: buf.toString(), subject: 'MiningGuard Shift Report — $now'),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

// ── Filter chip row ──────────────────────────────────────────────────────────

class _FilterChipRow extends ConsumerWidget {
  const _FilterChipRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(workerFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final f in WorkerFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(f)),
                selected: selected == f,
                onSelected: (_) =>
                    ref.read(workerFilterProvider.notifier).state = f,
              ),
            ),
        ],
      ),
    );
  }

  String _label(WorkerFilter f) {
    switch (f) {
      case WorkerFilter.all:
        return 'All';
      case WorkerFilter.highRisk:
        return 'High risk';
      case WorkerFilter.pendingReports:
        return 'Has reports';
      case WorkerFilter.checklistIncomplete:
        return 'No checklist';
    }
  }
}

// ── Pending reports section ──────────────────────────────────────────────────

class _PendingReportsSection extends ConsumerWidget {
  const _PendingReportsSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingReportsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              const Text(
                'PENDING REPORTS',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
              const Spacer(),
              async.when(
                data: (r) => Text('(${r.length})'),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('No pending reports.'),
              );
            }
            return Column(
              children: reports.map((r) => _ReportCard(report: r)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});
  final HazardReportModel report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SeverityBadge(severity: report.severity.firestoreValue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.category.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                ReportStatusBadge(status: report.status.firestoreValue),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${report.mineSection.isEmpty ? "Mine" : report.mineSection} · '
              '${DateFormat('d MMM · HH:mm').format(report.submittedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (report.status == ReportStatus.pending)
                  TextButton.icon(
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                    label: const Text('Acknowledge'),
                    onPressed: () => _ack(context, ref),
                  ),
                if (report.status == ReportStatus.acknowledged ||
                    report.status == ReportStatus.inProgress)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Resolve'),
                    onPressed: () => _resolve(context, ref),
                  ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.open_in_full, size: 18),
                  label: const Text('Details'),
                  onPressed: () => GoRouter.of(context).push(
                    AppRoutes.supervisorReportDetail,
                    extra: report,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ack(BuildContext context, WidgetRef ref) async {
    final firestore = ref.read(firestoreProvider);
    await updateReportStatus(
      firestore: firestore,
      reportId: report.reportId,
      newStatus: 'acknowledged',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report acknowledged')),
      );
    }
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Resolve report'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Resolution note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
    if (note == null) return;
    final firestore = ref.read(firestoreProvider);
    await updateReportStatus(
      firestore: firestore,
      reportId: report.reportId,
      newStatus: 'resolved',
      supervisorNote: note,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report resolved')),
      );
    }
  }
}

// ── Compliance trend ─────────────────────────────────────────────────────────

class _ComplianceTrendSection extends ConsumerWidget {
  const _ComplianceTrendSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mineComplianceTrendProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
          data: (data) =>
              ComplianceTrendChart(title: 'Compliance trend (30 days)', data: data, height: 200),
        ),
      ),
    );
  }
}

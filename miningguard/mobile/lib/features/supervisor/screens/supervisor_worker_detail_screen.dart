import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/checklist/models/checklist.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/widgets/dashboard/compliance_trend_chart.dart';
import '../../../shared/widgets/dashboard/report_status_badge.dart';
import '../../../shared/widgets/dashboard/risk_level_badge.dart';
import '../../../shared/widgets/dashboard/risk_score_bar.dart';
import '../../../shared/widgets/dashboard/severity_badge.dart';
import '../providers/supervisor_dashboard_provider.dart';

/// Drill-down view for a single worker. Reached by tapping a tile on the
/// supervisor dashboard. Displays the AI risk profile, 30-day compliance,
/// recent hazard reports, and the last two weeks of checklist outcomes.
/// Includes a "send custom alert" affordance in the AppBar.
class SupervisorWorkerDetailScreen extends ConsumerWidget {
  const SupervisorWorkerDetailScreen({super.key, required this.workerUid});

  final String workerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerByUidProvider(workerUid));

    return workerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (worker) {
        if (worker == null) {
          return const Scaffold(body: Center(child: Text('Worker not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(worker.fullName),
            actions: [
              IconButton(
                tooltip: 'Send alert',
                icon: const Icon(Icons.notifications_active_outlined),
                onPressed: () => _sendAlertDialog(context, ref, worker.uid),
              ),
            ],
          ),
          body: ListView(
            children: [
              _RiskProfileCard(
                level: worker.riskLevel,
                score: worker.riskScore.toInt(),
                factors: worker.riskFactors,
                lastUpdated: worker.lastActiveAt,
              ),
              _ComplianceCard(uid: workerUid),
              _ReportsCard(uid: workerUid),
              _ChecklistHistoryCard(uid: workerUid),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendAlertDialog(
      BuildContext context, WidgetRef ref, String uid) async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send alert to worker'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (res == null || res.isEmpty || !context.mounted) return;
    final firestore = ref.read(firestoreProvider);
    await sendCustomAlert(
      firestore: firestore,
      workerUid: uid,
      title: 'Message from supervisor',
      message: res,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert sent')),
      );
    }
  }
}

// ── Risk profile ─────────────────────────────────────────────────────────────

class _RiskProfileCard extends StatelessWidget {
  const _RiskProfileCard({
    required this.level,
    required this.score,
    required this.factors,
    required this.lastUpdated,
  });
  final String level;
  final int score;
  final List<String> factors;
  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RISK PROFILE',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                RiskLevelBadge(level: level, large: true),
                const Spacer(),
                Text('Score', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            RiskScoreBar(score: score),
            if (factors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Contributing factors:'),
              ...factors.take(5).map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: Icon(Icons.circle, size: 6),
                          ),
                          Expanded(child: Text(f)),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateFormat('d MMM HH:mm').format(lastUpdated)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compliance ───────────────────────────────────────────────────────────────

class _ComplianceCard extends ConsumerWidget {
  const _ComplianceCard({required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerComplianceTrendProvider(uid));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
          data: (data) {
            final avg = data.isEmpty
                ? 0.0
                : data.map((d) => d.rate).reduce((a, b) => a + b) / data.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ComplianceTrendChart(
                  title: 'Compliance history (30 days)',
                  data: data,
                  height: 180,
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall rate: ${(avg * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Recent hazard reports ────────────────────────────────────────────────────

class _ReportsCard extends ConsumerWidget {
  const _ReportsCard({required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerReportsProvider(uid));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HAZARD REPORTS',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            async.when(
              loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Could not load reports'),
              data: (reports) {
                if (reports.isEmpty) {
                  return const Text('No reports filed.');
                }
                return Column(
                  children: reports.map((r) => _ReportRow(report: r)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final HazardReportModel report;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.category.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  DateFormat('d MMM HH:mm').format(report.submittedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SeverityBadge(severity: report.severity.firestoreValue),
          const SizedBox(width: 6),
          ReportStatusBadge(status: report.status.firestoreValue),
        ],
      ),
    );
  }
}

// ── Checklist history (14 days) ──────────────────────────────────────────────

class _ChecklistHistoryCard extends ConsumerWidget {
  const _ChecklistHistoryCard({required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerChecklistHistoryProvider(uid));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHECKLIST HISTORY',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            async.when(
              loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Could not load history'),
              data: (lists) {
                if (lists.isEmpty) {
                  return const Text('No checklists in the last 14 days.');
                }
                return Column(
                  children: lists.map(_ChecklistRow.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow(this.checklist);
  final Checklist checklist;
  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(checklist.date);
    final label = DateFormat('EEE d MMM').format(dt);
    final isMissed = checklist.status == 'missed';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMissed
                ? Icons.cancel_outlined
                : (checklist.isSubmitted ? Icons.check_circle : Icons.timelapse),
            color: isMissed
                ? AppTheme.severityHigh
                : (checklist.isSubmitted ? AppTheme.riskLow : AppTheme.riskMedium),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            isMissed
                ? 'MISSED'
                : '${(checklist.complianceScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

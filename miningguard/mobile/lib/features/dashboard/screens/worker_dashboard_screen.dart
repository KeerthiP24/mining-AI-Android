import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/education/domain/safety_video.dart';
import '../../../features/education/providers/education_providers.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/widgets/dashboard/compliance_trend_chart.dart';
import '../../../shared/widgets/dashboard/dashboard_skeleton_loader.dart';
import '../../../shared/widgets/dashboard/report_status_badge.dart';
import '../../../shared/widgets/dashboard/risk_level_badge.dart';
import '../../../shared/widgets/dashboard/risk_score_bar.dart';
import '../../../shared/widgets/dashboard/severity_badge.dart';
import '../providers/worker_dashboard_provider.dart';

/// The default screen for `worker` users — risk level, today's checklist,
/// recommended video, recent reports, alerts, and a compliance chart, all
/// driven by live Firestore streams.
class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: DashboardSkeletonLoader(),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not signed in')),
          );
        }

        final greeting = _greeting();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, ${user.fullName.split(' ').first}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                  user.mineName ?? user.mineId,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.go(AppRoutes.workerProfile),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(workerComplianceHistoryProvider);
              ref.invalidate(workerRecentReportsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _RiskCard(
                  level: user.riskLevel,
                  score: user.riskScore.toInt(),
                  factors: user.riskFactors,
                ),
                const _ChecklistCard(),
                const _VideoOfDayCard(),
                const _RecentReportsCard(),
                const _AlertsCard(),
                const _ComplianceChartCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

// ── Risk hero card ───────────────────────────────────────────────────────────

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.level,
    required this.score,
    required this.factors,
  });
  final String level;
  final int score;
  final List<String> factors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Your safety risk'),
          Row(
            children: [
              RiskLevelBadge(level: level, large: true),
            ],
          ),
          const SizedBox(height: 14),
          RiskScoreBar(score: score),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Why',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
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
                        Expanded(child: Text(f)),
                      ],
                    ),
                  ),
                ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No risk factors detected — keep it up.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Today's checklist ────────────────────────────────────────────────────────

class _ChecklistCard extends ConsumerWidget {
  const _ChecklistCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayChecklistProvider);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Today's checklist"),
          async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                Text('Could not load checklist', style: TextStyle(color: AppTheme.severityHigh)),
            data: (checklist) {
              if (checklist == null) {
                return _ChecklistCta(
                  label: 'Start checklist',
                  progress: 0,
                  total: 0,
                  done: 0,
                  isCompleted: false,
                );
              }
              final total = checklist.items.length;
              final done = checklist.items.values
                  .where((i) => i.completed)
                  .length;
              final isCompleted = checklist.isSubmitted;
              return _ChecklistCta(
                label: isCompleted
                    ? 'Completed · ${(checklist.complianceScore * 100).toStringAsFixed(0)}%'
                    : 'Continue checklist',
                progress: total == 0 ? 0 : done / total,
                total: total,
                done: done,
                isCompleted: isCompleted,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChecklistCta extends StatelessWidget {
  const _ChecklistCta({
    required this.label,
    required this.progress,
    required this.total,
    required this.done,
    required this.isCompleted,
  });
  final String label;
  final double progress;
  final int total, done;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 0) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppTheme.riskLow : AppTheme.primaryYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$done / $total',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                GoRouter.of(context).go(AppRoutes.checklist),
            icon: Icon(
                isCompleted ? Icons.check_circle : Icons.play_arrow_rounded),
            label: Text(label),
          ),
        ),
      ],
    );
  }
}

// ── Video of the Day ─────────────────────────────────────────────────────────

class _VideoOfDayCard extends ConsumerWidget {
  const _VideoOfDayCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(videoOfDayProvider);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Video of the day'),
          async.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Recommendations unavailable'),
            data: (video) {
              if (video == null) {
                return const Text('No video available right now.');
              }
              return _VideoTile(video: video);
            },
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends ConsumerWidget {
  const _VideoTile({required this.video});
  final SafetyVideo video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final lang = user?.preferredLanguage ?? 'en';
    final title = localizeMap(video.title, lang);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          GoRouter.of(context).push('${AppRoutes.education}/player', extra: video),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 120,
              height: 70,
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.play_circle_outline),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14),
                    const SizedBox(width: 4),
                    Text('${(video.durationSeconds / 60).round()} min'),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://www.youtube.com/watch?v=${video.youtubeId}');
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('YouTube'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent reports ───────────────────────────────────────────────────────────

class _RecentReportsCard extends ConsumerWidget {
  const _RecentReportsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerRecentReportsProvider);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Recent reports'),
          async.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Could not load reports'),
            data: (reports) => Column(
              children: [
                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No reports yet.'),
                  )
                else
                  ...reports.map((r) => _ReportRow(report: r)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        GoRouter.of(context).go(AppRoutes.reportHazard),
                    icon: const Icon(Icons.add),
                    label: const Text('File new report'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final HazardReportModel report;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          GoRouter.of(context).push(AppRoutes.reportDetail, extra: report),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM · HH:mm').format(report.submittedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SeverityBadge(severity: report.severity.firestoreValue),
            const SizedBox(width: 8),
            ReportStatusBadge(status: report.status.firestoreValue),
          ],
        ),
      ),
    );
  }
}

// ── Alerts ───────────────────────────────────────────────────────────────────

class _AlertsCard extends ConsumerWidget {
  const _AlertsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerAlertsProvider);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Active alerts'),
          async.when(
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Could not load alerts'),
            data: (alerts) => alerts.isEmpty
                ? const Text('No alerts. Stay safe.')
                : Column(
                    children:
                        alerts.map((a) => _AlertRow(alert: a)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({required this.alert});
  final AlertModel alert;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (alert.severity) {
      'critical' || 'high' => AppTheme.severityHigh,
      'medium' || 'warning' => AppTheme.severityMedium,
      _ => AppTheme.statusAcknowledged,
    };
    return InkWell(
      onTap: () => markAlertRead(ref, alert.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(alert.message,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (alert.createdAt != null)
              Text(
                DateFormat('HH:mm').format(alert.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Compliance chart ─────────────────────────────────────────────────────────

class _ComplianceChartCard extends ConsumerWidget {
  const _ComplianceChartCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workerComplianceHistoryProvider);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('My compliance (30 days)'),
          async.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 80,
              child: Center(child: Text('Could not load history')),
            ),
            data: (data) => ComplianceTrendChart(data: data, height: 160),
          ),
        ],
      ),
    );
  }
}

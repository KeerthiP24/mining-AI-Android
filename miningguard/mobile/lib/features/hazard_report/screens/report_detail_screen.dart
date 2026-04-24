import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/models/user_model.dart';
import '../models/hazard_report_model.dart';
import '../providers/hazard_report_provider.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/report_status_badge.dart';
import '../models/ai_analysis_result_model.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.report});

  final HazardReportModel report;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportStatus? _selectedStatus;
  final _noteController = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final roleAsync = ref.watch(currentUserRoleProvider);
    final isSupervisor = roleAsync == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(
        title: Text(report.category.label),
        actions: [ReportStatusBadge(status: report.status)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header row
          Row(
            children: [
              _InfoChip(Icons.access_time, timeago.format(report.submittedAt)),
              const SizedBox(width: 8),
              _InfoChip(Icons.place_outlined, report.mineSection.isNotEmpty ? report.mineSection : '—'),
            ],
          ),
          const SizedBox(height: 16),

          // Severity
          const _SectionLabel('Severity'),
          const SizedBox(height: 4),
          Text(report.severity.label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),

          // Input mode
          const _SectionLabel('Reported via'),
          const SizedBox(height: 4),
          Text(report.inputMode.label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),

          // Description / transcription
          if (report.description.isNotEmpty) ...[
            const _SectionLabel('Description'),
            const SizedBox(height: 4),
            Text(report.description),
            const SizedBox(height: 16),
          ],
          if (report.voiceTranscription.isNotEmpty) ...[
            const _SectionLabel('Voice Transcription'),
            const SizedBox(height: 4),
            Text(report.voiceTranscription),
            const SizedBox(height: 16),
          ],

          // Media thumbnails
          if (report.mediaUrls.isNotEmpty) ...[
            const _SectionLabel('Media'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report.mediaUrls[i],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI analysis
          if (report.aiAnalysis != null) ...[
            AiAnalysisCard(
              result: AiAnalysisResult(
                hazardDetected: report.aiAnalysis!.hazardDetected,
                confidence: report.aiAnalysis!.confidence,
                suggestedSeverity: HazardSeverity.fromString(report.aiAnalysis!.suggestedSeverity),
                recommendedAction: report.aiAnalysis!.recommendedAction,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Status timeline
          const _SectionLabel('Status Timeline'),
          const SizedBox(height: 8),
          _StatusTimeline(report: report),
          const SizedBox(height: 16),

          // Supervisor note
          if (report.supervisorNote != null && report.supervisorNote!.isNotEmpty) ...[
            const _SectionLabel('Supervisor Note'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(report.supervisorNote!),
            ),
            const SizedBox(height: 16),
          ],

          // Supervisor update controls
          if (isSupervisor && report.status != ReportStatus.resolved) ...[
            const Divider(),
            const SizedBox(height: 16),
            const _SectionLabel('Update Status'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ReportStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _updating ? null : _updateStatus,
                child: _updating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update Status'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _updating = true);

    try {
      final repo = ref.read(hazardReportRepositoryProvider);
      await repo.updateStatus(
        widget.report.reportId,
        _selectedStatus!,
        supervisorNote: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.report});
  final HazardReportModel report;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep('Submitted', report.submittedAt, done: true),
      _TimelineStep('Acknowledged', report.acknowledgedAt,
          done: report.acknowledgedAt != null),
      _TimelineStep('In Progress', null,
          done: report.status == ReportStatus.inProgress ||
              report.status == ReportStatus.resolved),
      _TimelineStep('Resolved', report.resolvedAt, done: report.resolvedAt != null),
    ];

    return Column(
      children: steps.map((step) {
        return Row(
          children: [
            Icon(
              step.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: step.done ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                step.label +
                    (step.time != null
                        ? ' — ${timeago.format(step.time!)}'
                        : ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: step.done ? null : Colors.grey,
                    ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TimelineStep {
  const _TimelineStep(this.label, this.time, {required this.done});
  final String label;
  final DateTime? time;
  final bool done;
}

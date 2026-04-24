import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/checklist/providers/checklist_provider.dart';

/// Summary of a mine's checklist completion for a given date.
class SupervisorChecklistStatus {
  const SupervisorChecklistStatus({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.missed,
    required this.pendingUids,
  });

  final int total;
  final int submitted;
  final int inProgress;
  final int missed;
  final List<String> pendingUids;  // uids that have NOT submitted

  int get notSubmitted => total - submitted;
}

/// Streams all checklists for a mine on a given date and aggregates status counts.
final supervisorChecklistStatusProvider = StreamProvider.family<
    SupervisorChecklistStatus,
    ({String mineId, String date})>((ref, args) {
  return ref
      .watch(checklistRepositoryProvider)
      .watchMineChecklists(args.mineId, args.date)
      .map((checklists) {
    final submitted = checklists.where((c) => c.status == 'submitted').length;
    final inProgress =
        checklists.where((c) => c.status == 'in_progress').length;
    final missed = checklists.where((c) => c.status == 'missed').length;
    final pendingUids = checklists
        .where((c) => c.status != 'submitted')
        .map((c) => c.uid)
        .toList();

    return SupervisorChecklistStatus(
      total: checklists.length,
      submitted: submitted,
      inProgress: inProgress,
      missed: missed,
      pendingUids: pendingUids,
    );
  });
});

/// Stub widget rendered by the Supervisor Dashboard in Phase 7.
/// The provider above is fully functional in Phase 3.
class SupervisorChecklistOverviewWidget extends ConsumerWidget {
  const SupervisorChecklistOverviewWidget({
    super.key,
    required this.mineId,
    required this.date,
  });

  final String mineId;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(
      supervisorChecklistStatusProvider((mineId: mineId, date: date)),
    );

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading checklist status: $e'),
      data: (status) => _StatusCard(status: status),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final SupervisorChecklistStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklist Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Row(label: 'Submitted', value: status.submitted, color: Colors.green),
            _Row(label: 'In Progress', value: status.inProgress, color: Colors.orange),
            _Row(label: 'Missed / Not Started', value: status.missed, color: Colors.red),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

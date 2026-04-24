import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../models/checklist.dart';
import '../providers/checklist_history_provider.dart';
import '../providers/checklist_provider.dart';
import '../widgets/category_header.dart';

class ChecklistHistoryScreen extends ConsumerStatefulWidget {
  const ChecklistHistoryScreen({super.key});

  @override
  ConsumerState<ChecklistHistoryScreen> createState() =>
      _ChecklistHistoryScreenState();
}

class _ChecklistHistoryScreenState
    extends ConsumerState<ChecklistHistoryScreen> {
  int _limit = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(checklistHistoryProvider(_limit));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklist_history_title)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error loading history: $e')),
        data: (checklists) {
          if (checklists.isEmpty) {
            return Center(
              child: Text(
                'No checklist history yet.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView(
            children: [
              ...checklists.map((c) => _HistoryRow(checklist: c)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => setState(() => _limit += 14),
                  child: Text(l10n.checklist_history_load_more),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.checklist});
  final Checklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isMissed = checklist.isMissed;
    final scorePercent = (checklist.complianceScore * 100).round();
    final dateFormatted = _formatDate(checklist.date);

    return GestureDetector(
      onTap: () => _showDetail(context, ref, checklist, l10n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMissed ? Colors.red : Colors.transparent,
              width: 4,
            ),
          ),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatted,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    _ShiftBadge(shift: checklist.shift),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: checklist.status, l10n: l10n),
                  const SizedBox(height: 4),
                  if (!isMissed)
                    Text(
                      '$scorePercent%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _scoreColor(checklist.complianceScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEE, d MMM yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }

  Color _scoreColor(double score) {
    if (score >= 0.90) return Colors.green;
    if (score >= 0.70) return Colors.lightGreen;
    if (score >= 0.50) return Colors.orange;
    return Colors.red;
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    Checklist checklist,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChecklistDetailSheet(checklist: checklist),
    );
  }
}

class _ChecklistDetailSheet extends ConsumerWidget {
  const _ChecklistDetailSheet({required this.checklist});
  final Checklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final roleKey =
        user?.role.name == 'supervisor' ? 'supervisor' : 'worker';
    final mineId = user?.mineId ?? checklist.mineId;

    final templateAsync = ref.watch(
      checklistTemplateProvider((mineId: mineId, role: roleKey)),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  checklist.date,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${(checklist.complianceScore * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: templateAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (template) {
                if (template == null) {
                  return const Center(child: Text('Template not available'));
                }
                return ListView(
                  controller: scrollController,
                  children: [
                    for (final category in template.categories)
                      Builder(builder: (context) {
                        final items = template.itemsForCategory(category);
                        final completed = items
                            .where((i) =>
                                checklist.items[i.itemId]?.completed == true)
                            .length;

                        return CategoryHeader(
                          category: category,
                          completedCount: completed,
                          totalCount: items.length,
                          children: [
                            for (final ti in items)
                              ListTile(
                                leading: Icon(
                                  checklist.items[ti.itemId]?.completed == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      checklist.items[ti.itemId]?.completed == true
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                title: Text(
                                  ti.labelKey,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                dense: true,
                              ),
                          ],
                        );
                      }),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'submitted':
        color = Colors.green;
        label = l10n.checklist_status_submitted;
        break;
      case 'missed':
        color = Colors.red;
        label = l10n.checklist_status_missed;
        break;
      default:
        color = Colors.orange;
        label = l10n.checklist_status_in_progress;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.shift});
  final String shift;

  @override
  Widget build(BuildContext context) {
    return Text(
      shift[0].toUpperCase() + shift.substring(1),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../models/checklist.dart';
import '../models/checklist_template.dart';
import '../providers/checklist_provider.dart';
import '../widgets/category_header.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/compliance_progress_chip.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(currentChecklistStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return checklistAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.checklist_title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.checklist_title)),
        body: _ErrorBody(error: e),
      ),
      data: (checklist) {
        if (checklist == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.checklist_title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _ChecklistBody(checklist: checklist);
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTemplate = error.toString().contains('template');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              isTemplate
                  ? l10n.checklist_error_template_not_found
                  : error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistBody extends ConsumerStatefulWidget {
  const _ChecklistBody({required this.checklist});
  final Checklist checklist;

  @override
  ConsumerState<_ChecklistBody> createState() => _ChecklistBodyState();
}

class _ChecklistBodyState extends ConsumerState<_ChecklistBody> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final checklist = widget.checklist;
    final l10n = AppLocalizations.of(context)!;
    final isSubmitted = checklist.isSubmitted;

    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.valueOrNull;
    final roleKey =
        user?.role.name == 'supervisor' ? 'supervisor' : 'worker';
    final mineId = user?.mineId ?? '';

    final templateAsync = ref.watch(
      checklistTemplateProvider((mineId: mineId, role: roleKey)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checklist_title),
        actions: [
          ComplianceProgressChip(
            completed: checklist.totalCompleted,
            total: checklist.totalItems,
          ),
        ],
      ),
      body: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (template) {
          if (template == null) {
            return _ErrorBody(
              error: Exception(l10n.checklist_error_template_not_found),
            );
          }
          return _ChecklistContent(
            checklist: checklist,
            template: template,
            isSubmitted: isSubmitted,
            l10n: l10n,
          );
        },
      ),
      bottomNavigationBar: isSubmitted
          ? _SubmittedBanner(l10n: l10n)
          : _SubmitBar(
              checklist: checklist,
              submitting: _submitting,
              l10n: l10n,
              onSubmit: () => _confirmAndSubmit(context, checklist, user?.uid ?? '', l10n),
            ),
    );
  }

  Future<void> _confirmAndSubmit(
    BuildContext context,
    Checklist checklist,
    String uid,
    AppLocalizations l10n,
  ) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.checklist_submit_confirm_title),
        content: Text(l10n.checklist_submit_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.checklist_submit_confirm_no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.checklist_submit_confirm_yes),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final today = checklist.date;
      await ref
          .read(checklistNotifierProvider.notifier)
          .submitChecklist(checklist.checklistId, uid, today);

      if (mounted) {
        final scores = checklist.calculateScores();
        router.go(AppRoutes.checklistSuccess, extra: scores.complianceScore);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ChecklistContent extends ConsumerWidget {
  const _ChecklistContent({
    required this.checklist,
    required this.template,
    required this.isSubmitted,
    required this.l10n,
  });

  final Checklist checklist;
  final ChecklistTemplate template;
  final bool isSubmitted;
  final AppLocalizations l10n;

  String _labelForKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'checklist_ppe_helmet': return l10n.checklist_ppe_helmet;
      case 'checklist_ppe_boots': return l10n.checklist_ppe_boots;
      case 'checklist_ppe_vest': return l10n.checklist_ppe_vest;
      case 'checklist_ppe_gloves': return l10n.checklist_ppe_gloves;
      case 'checklist_ppe_lamp_charged': return l10n.checklist_ppe_lamp_charged;
      case 'checklist_ppe_scsr_present': return l10n.checklist_ppe_scsr_present;
      case 'checklist_mach_preshift_done': return l10n.checklist_mach_preshift_done;
      case 'checklist_mach_guards_in_place': return l10n.checklist_mach_guards_in_place;
      case 'checklist_mach_no_leaks': return l10n.checklist_mach_no_leaks;
      case 'checklist_env_gas_detector_ok': return l10n.checklist_env_gas_detector_ok;
      case 'checklist_env_roof_inspected': return l10n.checklist_env_roof_inspected;
      case 'checklist_env_ventilation_ok': return l10n.checklist_env_ventilation_ok;
      case 'checklist_env_walkways_clear': return l10n.checklist_env_walkways_clear;
      case 'checklist_emg_exit_known': return l10n.checklist_emg_exit_known;
      case 'checklist_emg_comms_working': return l10n.checklist_emg_comms_working;
      case 'checklist_emg_first_aid_located': return l10n.checklist_emg_first_aid_located;
      case 'checklist_sup_attendance_confirmed': return l10n.checklist_sup_attendance_confirmed;
      case 'checklist_sup_toolbox_talk_done': return l10n.checklist_sup_toolbox_talk_done;
      case 'checklist_sup_dgms_permits_reviewed': return l10n.checklist_sup_dgms_permits_reviewed;
      case 'checklist_sup_high_risk_permits_checked': return l10n.checklist_sup_high_risk_permits_checked;
      case 'checklist_sup_muster_point_communicated': return l10n.checklist_sup_muster_point_communicated;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = checklist.totalItems > 0
        ? checklist.totalCompleted / checklist.totalItems
        : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final category in template.categories)
                Builder(builder: (context) {
                  final items = template.itemsForCategory(category);
                  final completedInCat = items
                      .where((i) =>
                          checklist.items[i.itemId]?.completed == true)
                      .length;

                  return CategoryHeader(
                    category: category,
                    completedCount: completedInCat,
                    totalCount: items.length,
                    children: [
                      for (final templateItem in items)
                        Builder(builder: (context) {
                          final itemData =
                              checklist.items[templateItem.itemId];
                          if (itemData == null) return const SizedBox.shrink();

                          return ChecklistItemTile(
                            itemId: templateItem.itemId,
                            label: _labelForKey(l10n, templateItem.labelKey),
                            mandatory: itemData.mandatory,
                            completed: itemData.completed,
                            isSubmitted: isSubmitted,
                            onTap: () {
                              ref
                                  .read(checklistNotifierProvider.notifier)
                                  .markItem(
                                    checklist.checklistId,
                                    templateItem.itemId,
                                    !itemData.completed,
                                    context,
                                  );
                            },
                          );
                        }),
                    ],
                  );
                }),
              const SizedBox(height: 80), // space for bottom bar
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.checklist,
    required this.submitting,
    required this.l10n,
    required this.onSubmit,
  });

  final Checklist checklist;
  final bool submitting;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSubmit = checklist.allMandatoryComplete && !submitting;
    final optRemaining = checklist.optionalUnchecked;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!checklist.allMandatoryComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.checklist_mandatory_incomplete_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (optRemaining > 0 && checklist.allMandatoryComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.checklist_optional_remaining(optRemaining),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: canSubmit ? onSubmit : null,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.checklist_submit_button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.green.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              l10n.checklist_already_submitted,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

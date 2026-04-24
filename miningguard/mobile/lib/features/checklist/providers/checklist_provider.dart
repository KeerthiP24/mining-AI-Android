import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_service.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/checklist_template.dart';
import '../services/checklist_generation_service.dart';
import '../services/checklist_repository.dart';

// ── Service / Repository providers ───────────────────────────────────────────

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.watch(firestoreProvider));
});

final checklistGenerationServiceProvider =
    Provider<ChecklistGenerationService>((ref) {
  return ChecklistGenerationService(
    ref.watch(checklistRepositoryProvider),
    ref.watch(firestoreProvider),
  );
});

final aiServiceProvider = Provider<AiService>((ref) => AiService());

// ── Current checklist stream ──────────────────────────────────────────────────

/// Generates (or retrieves) today's checklist then streams it live.
final currentChecklistIdProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(currentUserModelProvider.future);
  if (user == null) throw Exception('User not signed in');
  final service = ref.watch(checklistGenerationServiceProvider);
  final checklist = await service.getOrCreateChecklist(user);
  return checklist.checklistId;
});

final currentChecklistStreamProvider = StreamProvider<Checklist?>((ref) {
  final idAsync = ref.watch(currentChecklistIdProvider);
  return idAsync.when(
    data: (id) => ref.watch(checklistRepositoryProvider).watchChecklist(id),
    error: (e, _) => Stream.error(e),
    loading: () => const Stream.empty(),
  );
});

// ── Template provider (family, cached) ───────────────────────────────────────

final checklistTemplateProvider = FutureProvider.family<ChecklistTemplate?,
    ({String mineId, String role})>((ref, args) {
  return ref
      .watch(checklistRepositoryProvider)
      .getTemplate(args.mineId, args.role);
});

// ── ChecklistNotifier — markItem / submitChecklist ────────────────────────────

class ChecklistNotifier extends AsyncNotifier<Checklist?> {
  @override
  Future<Checklist?> build() async {
    final id = await ref.watch(currentChecklistIdProvider.future);
    final snap = await ref.watch(checklistRepositoryProvider).getChecklist(id);

    // Keep state live via stream subscription
    ref.listen(currentChecklistStreamProvider, (_, next) {
      next.whenData((checklist) {
        if (checklist != null) state = AsyncData(checklist);
      });
    });

    return snap;
  }

  /// Marks a single item completed/uncompleted with optimistic UI.
  Future<void> markItem(
    String checklistId,
    String itemId,
    bool completed,
    BuildContext context,
  ) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    final prevItemData = previous.items[itemId];
    if (prevItemData == null) return;

    // Optimistic update — modify only the changed item
    final updatedItems = Map<String, ChecklistItemData>.from(previous.items)
      ..[itemId] = prevItemData.copyWith(
        completed: completed,
        completedAt: completed ? DateTime.now() : null,
      );

    state = AsyncData(previous.copyWith(items: updatedItems));

    try {
      await ref
          .read(checklistRepositoryProvider)
          .updateItemCompleted(checklistId, itemId, completed);
    } catch (e) {
      // Revert on failure
      state = AsyncData(previous);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save — please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Submits the checklist: calculates scores, writes to Firestore,
  /// triggers risk recalculation stub.
  Future<void> submitChecklist(
    String checklistId,
    String uid,
    String today,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final scores = current.calculateScores();

    await ref.read(checklistRepositoryProvider).submitChecklist(
          checklistId,
          uid,
          today,
          scores.complianceScore,
          scores.mandatoryScore,
        );

    state = AsyncData(
      current.copyWith(
        status: 'submitted',
        complianceScore: scores.complianceScore,
        mandatoryScore: scores.mandatoryScore,
      ),
    );

    // Phase 6 stub
    await ref.read(aiServiceProvider).triggerRiskRecalculation(uid);
  }
}

final checklistNotifierProvider =
    AsyncNotifierProvider<ChecklistNotifier, Checklist?>(
  ChecklistNotifier.new,
);

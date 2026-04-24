import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../models/ai_analysis_result_model.dart';
import '../models/hazard_report_model.dart';
import '../services/hazard_report_repository.dart';
import '../services/media_upload_service.dart';
import '../services/report_queue_service.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final hazardReportRepositoryProvider = Provider<HazardReportRepository>((ref) {
  return HazardReportRepository(FirebaseFirestore.instance);
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(FirebaseStorage.instance);
});

final reportQueueServiceProvider = Provider<ReportQueueService>((ref) {
  final repo = ref.watch(hazardReportRepositoryProvider);
  final service = ReportQueueService(repo);
  service.startConnectivityListener();
  ref.onDispose(service.dispose);
  return service;
});

// ── Report draft ──────────────────────────────────────────────────────────────

class ReportDraft {
  const ReportDraft({
    this.inputMode = InputMode.text,
    this.mediaFiles = const [],
    this.voiceNoteFile,
    this.description = '',
    this.voiceTranscription = '',
    this.category,
    this.severity = HazardSeverity.low,
    this.mineSection = '',
    this.aiAnalysis,
  });

  final InputMode inputMode;
  final List<File> mediaFiles;
  final File? voiceNoteFile;
  final String description;
  final String voiceTranscription;
  final HazardCategory? category;
  final HazardSeverity severity;
  final String mineSection;
  final AiAnalysisResult? aiAnalysis;

  ReportDraft copyWith({
    InputMode? inputMode,
    List<File>? mediaFiles,
    File? voiceNoteFile,
    bool clearVoiceNote = false,
    String? description,
    String? voiceTranscription,
    HazardCategory? category,
    HazardSeverity? severity,
    String? mineSection,
    AiAnalysisResult? aiAnalysis,
    bool clearAiAnalysis = false,
  }) {
    return ReportDraft(
      inputMode: inputMode ?? this.inputMode,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      voiceNoteFile: clearVoiceNote ? null : (voiceNoteFile ?? this.voiceNoteFile),
      description: description ?? this.description,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      mineSection: mineSection ?? this.mineSection,
      aiAnalysis: clearAiAnalysis ? null : (aiAnalysis ?? this.aiAnalysis),
    );
  }
}

// ── Submission notifier ───────────────────────────────────────────────────────

class ReportSubmissionNotifier extends StateNotifier<AsyncValue<ReportDraft>> {
  ReportSubmissionNotifier(this._ref) : super(const AsyncValue.data(ReportDraft()));

  final Ref _ref;

  ReportDraft get _draft => state.value ?? const ReportDraft();

  void setInputMode(InputMode mode) {
    state = AsyncValue.data(_draft.copyWith(
      inputMode: mode,
      mediaFiles: [],
      clearVoiceNote: true,
      description: '',
      clearAiAnalysis: true,
    ));
  }

  void attachMedia(List<File> files) {
    state = AsyncValue.data(_draft.copyWith(mediaFiles: [..._draft.mediaFiles, ...files]));
  }

  void removeMedia(int index) {
    final updated = List<File>.from(_draft.mediaFiles)..removeAt(index);
    state = AsyncValue.data(_draft.copyWith(mediaFiles: updated));
  }

  void attachVoiceNote(File file) {
    state = AsyncValue.data(_draft.copyWith(voiceNoteFile: file));
  }

  void setDescription(String text) {
    state = AsyncValue.data(_draft.copyWith(description: text));
  }

  void setVoiceTranscription(String text) {
    state = AsyncValue.data(_draft.copyWith(voiceTranscription: text));
  }

  void setCategory(HazardCategory category) {
    state = AsyncValue.data(_draft.copyWith(category: category));
  }

  void setSeverity(HazardSeverity severity) {
    state = AsyncValue.data(_draft.copyWith(severity: severity));
  }

  void setMineSection(String section) {
    state = AsyncValue.data(_draft.copyWith(mineSection: section));
  }

  void applyAiSuggestion(AiAnalysisResult result) {
    state = AsyncValue.data(_draft.copyWith(
      aiAnalysis: result,
      severity: result.suggestedSeverity,
    ));
  }

  void reset() {
    state = const AsyncValue.data(ReportDraft());
  }

  Future<String> submit(UserModel user) async {
    if (_draft.category == null) {
      throw const ReportException('Category is required');
    }

    state = const AsyncValue.loading();

    try {
      final uploadService = _ref.read(mediaUploadServiceProvider);
      final repository = _ref.read(hazardReportRepositoryProvider);
      final queue = _ref.read(reportQueueServiceProvider);

      final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';

      // Upload media files
      final mediaUrls = <String>[];
      for (final file in _draft.mediaFiles) {
        final url = await uploadService.uploadImage(file, tempId);
        mediaUrls.add(url);
      }

      // Upload voice note
      String? voiceNoteUrl;
      if (_draft.voiceNoteFile != null) {
        voiceNoteUrl = await uploadService.uploadVoiceNote(_draft.voiceNoteFile!, tempId);
      }

      // Build AI analysis data if present
      AiAnalysisData? aiData;
      if (_draft.aiAnalysis != null) {
        final ai = _draft.aiAnalysis!;
        aiData = AiAnalysisData(
          hazardDetected: ai.hazardDetected,
          confidence: ai.confidence,
          suggestedSeverity: ai.suggestedSeverity.firestoreValue,
          recommendedAction: ai.recommendedAction,
        );
      }

      final report = HazardReportModel(
        reportId: '',
        uid: user.uid,
        mineId: user.mineId,
        supervisorId: '',
        mineSection: _draft.mineSection,
        inputMode: _draft.inputMode,
        description: _draft.description,
        voiceTranscription: _draft.voiceTranscription,
        category: _draft.category!,
        severity: _draft.severity,
        mediaUrls: mediaUrls,
        voiceNoteUrl: voiceNoteUrl,
        aiAnalysis: aiData,
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
      );

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.every((r) => r == ConnectivityResult.none);

      String reportId;
      if (isOffline) {
        await queue.enqueue(report);
        reportId = '';
      } else {
        reportId = await repository.submitReport(report);
      }

      state = const AsyncValue.data(ReportDraft());
      return reportId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reportSubmissionProvider =
    StateNotifierProvider<ReportSubmissionNotifier, AsyncValue<ReportDraft>>((ref) {
  return ReportSubmissionNotifier(ref);
});

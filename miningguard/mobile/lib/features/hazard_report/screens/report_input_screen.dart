import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../models/ai_analysis_result_model.dart';
import '../models/hazard_report_model.dart';
import '../providers/ai_analysis_provider.dart';
import '../providers/hazard_report_provider.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/category_severity_picker.dart';
import '../widgets/input_mode_selector.dart';
import '../widgets/photo_capture_widget.dart';
import '../widgets/voice_input_widget.dart';

class ReportInputScreen extends ConsumerStatefulWidget {
  const ReportInputScreen({super.key});

  @override
  ConsumerState<ReportInputScreen> createState() => _ReportInputScreenState();
}

class _ReportInputScreenState extends ConsumerState<ReportInputScreen> {
  final _mineSectionController = TextEditingController();
  static const _maxDescriptionLength = 500;

  @override
  void dispose() {
    _mineSectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(reportSubmissionProvider);
    final draft = submissionAsync.value ?? const ReportDraft();
    final notifier = ref.read(reportSubmissionProvider.notifier);

    // Watch AI analysis state when photo mode has files
    AsyncValue<AiAnalysisResult>? aiAsync;
    if (draft.inputMode == InputMode.photo && draft.mediaFiles.isNotEmpty) {
      aiAsync = ref.watch(imageAnalysisProvider(File(draft.mediaFiles.first.path)));
    }

    final isLoading = submissionAsync.isLoading;
    final canSubmit = draft.category != null && !isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Hazard'),
        actions: [
          if (draft.mediaFiles.isNotEmpty ||
              draft.voiceNoteFile != null ||
              draft.description.isNotEmpty)
            TextButton(
              onPressed: () {
                notifier.reset();
                _mineSectionController.clear();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Input Method', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const InputModeSelector(),
          const SizedBox(height: 20),

          // Mode-specific input
          if (draft.inputMode == InputMode.photo) ...[
            Text('Photos / Videos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const PhotoCaptureWidget(),
            const SizedBox(height: 20),
          ],

          if (draft.inputMode == InputMode.voice) ...[
            Text('Voice Recording', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const VoiceInputWidget(),
            const SizedBox(height: 20),
          ],

          if (draft.inputMode == InputMode.text) ...[
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: draft.description,
              decoration: InputDecoration(
                hintText: 'Describe the hazard you observed…',
                border: const OutlineInputBorder(),
                counterText: '${draft.description.length} / $_maxDescriptionLength',
              ),
              maxLines: 4,
              maxLength: _maxDescriptionLength,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  Text(
                    '$currentLength / $maxLength',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              onChanged: notifier.setDescription,
            ),
            const SizedBox(height: 20),
          ],

          // AI Analysis shimmer / card (photo mode only)
          if (draft.inputMode == InputMode.photo && draft.mediaFiles.isNotEmpty) ...[
            if (aiAsync != null && aiAsync.isLoading)
              _AiShimmer()
            else if (aiAsync?.valueOrNull != null) ...[
              AiAnalysisCard(result: aiAsync!.value!),
              const SizedBox(height: 20),
            ],
          ],

          Text('Category & Severity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const CategorySeverityPicker(),
          const SizedBox(height: 20),

          Text('Mine Section', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _mineSectionController,
            decoration: const InputDecoration(
              hintText: 'e.g. Level 3, Shaft B',
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.setMineSection,
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (submissionAsync.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    submissionAsync.error.toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canSubmit ? () => _submit(context) : null,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final user = ref.read(currentUserModelProvider).value;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final reportId = await ref.read(reportSubmissionProvider.notifier).submit(user);

      if (!mounted) return;

      final msg = reportId.isEmpty
          ? 'Report queued (offline) — will sync when connected'
          : 'Report submitted successfully';

      messenger.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
      ));
      navigator.pop();
    } catch (_) {
      // Error shown in body via submissionAsync.hasError
    }
  }
}

class _AiShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

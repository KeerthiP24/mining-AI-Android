import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/ai_analysis_provider.dart';
import '../providers/hazard_report_provider.dart';

class PhotoCaptureWidget extends ConsumerWidget {
  const PhotoCaptureWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportSubmissionProvider).value ?? const ReportDraft();
    final notifier = ref.read(reportSubmissionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PickButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: () => _pick(context, ref, notifier, ImageSource.camera),
            ),
            const SizedBox(width: 8),
            _PickButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: () => _pick(context, ref, notifier, ImageSource.gallery),
            ),
          ],
        ),
        if (draft.mediaFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: draft.mediaFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        draft.mediaFiles[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => notifier.removeMedia(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ReportSubmissionNotifier notifier,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);
    // Check if this is the first image BEFORE attaching
    final existingCount = (ref.read(reportSubmissionProvider).value ?? const ReportDraft()).mediaFiles.length;
    notifier.attachMedia([file]);

    // Trigger AI analysis only on the first image
    if (existingCount == 0) {
      ref.read(imageAnalysisProvider(file).future).then((result) {
        notifier.applyAiSuggestion(result);
      }).catchError((_) {});
    }
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/hazard_report_provider.dart';

class VoiceInputWidget extends ConsumerStatefulWidget {
  const VoiceInputWidget({super.key});

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget> {
  final _recorder = AudioRecorder();
  final _stt = SpeechToText();

  bool _isRecording = false;
  bool _sttAvailable = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize();
    if (mounted) setState(() => _sttAvailable = available);
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordingPath = path;
    });

    if (_sttAvailable) {
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            ref.read(reportSubmissionProvider.notifier)
                .setVoiceTranscription(result.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    await _stt.stop();
    setState(() => _isRecording = false);

    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        ref.read(reportSubmissionProvider.notifier).attachVoiceNote(file);
      }
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportSubmissionProvider).value ?? const ReportDraft();
    final transcription = draft.voiceTranscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        if (_isRecording)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Recording…', style: TextStyle(color: Colors.red)),
            ),
          ),
        if (draft.voiceNoteFile != null && !_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Voice note recorded',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (transcription.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Transcription', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(transcription),
          ),
        ],
      ],
    );
  }
}

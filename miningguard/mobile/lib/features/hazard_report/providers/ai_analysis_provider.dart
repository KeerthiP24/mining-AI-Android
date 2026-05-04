import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_service.dart';
import '../models/ai_analysis_result_model.dart';

/// Sends [imageFile] to the FastAPI backend's `/image/detect` endpoint and
/// returns the parsed [AiAnalysisResult].
///
/// Falls back to [AiAnalysisResult.safe] when the backend is unreachable or
/// returns malformed data so the worker can still submit a hazard report.
final imageAnalysisProvider =
    FutureProvider.family<AiAnalysisResult, File>((ref, imageFile) async {
  final ai = ref.watch(aiServiceProvider);
  try {
    final data = await ai.detectImageHazard(imageFile);
    if (data == null) return AiAnalysisResult.safe();
    return AiAnalysisResult.fromJson(data);
  } catch (_) {
    // Network / 5xx / parsing errors should not block report submission.
    return AiAnalysisResult.safe();
  }
});

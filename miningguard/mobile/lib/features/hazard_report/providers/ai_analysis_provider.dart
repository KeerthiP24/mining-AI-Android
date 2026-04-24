import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_analysis_result_model.dart';

const _aiEndpoint = 'http://localhost:8000/api/v1/image/detect';

final imageAnalysisProvider =
    FutureProvider.family<AiAnalysisResult, File>((ref, imageFile) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'hazard.jpg',
      ),
    });

    final response = await dio.post<Map<String, dynamic>>(
      _aiEndpoint,
      data: formData,
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.data == null) return AiAnalysisResult.safe();
    return AiAnalysisResult.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AiAnalysisResult.safe();
    }
    rethrow;
  }
});

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Single client for the FastAPI AI backend (Phase 6).
///
/// Resolves the base URL from compile-time `AI_BACKEND_URL`, falling back to
/// the development emulator URL in [AppConstants]. Every request attaches
/// the current Firebase ID token; if the user is signed out (or the token
/// fetch fails) the request still goes through unauthenticated, which the
/// backend rejects with 401 unless `SKIP_AUTH=true` is set in dev.
class AiService {
  AiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveBaseUrl(),
                connectTimeout: AppConstants.apiTimeout,
                receiveTimeout: AppConstants.apiTimeout,
                sendTimeout: AppConstants.apiTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  /// Backend base URL. Order:
  ///  1. `--dart-define=AI_BACKEND_URL=https://...` for release builds
  ///  2. [AppConstants.apiBaseUrlDev] for everything else
  static String _resolveBaseUrl() {
    const compileTime = String.fromEnvironment('AI_BACKEND_URL');
    if (compileTime.isNotEmpty) return compileTime;
    return AppConstants.apiBaseUrlDev;
  }

  Future<Map<String, String>> _authHeaders() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      return token == null ? {} : {'Authorization': 'Bearer $token'};
    } catch (e) {
      debugPrint('[AiService] Failed to fetch ID token: $e');
      return {};
    }
  }

  // ── Risk prediction ────────────────────────────────────────────────────────

  /// Triggers a backend risk recalculation for [uid].
  ///
  /// The backend pulls fresh features from Firestore, runs the GBC model,
  /// and writes the result back to `users/{uid}`. The mobile dashboard
  /// reads that document via a Firestore listener, so this call is
  /// fire-and-forget. Silently swallows network/server errors so the
  /// caller's primary flow (e.g. checklist submission) never breaks.
  Future<Map<String, dynamic>?> triggerRiskRecalculation(String uid) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.riskPredictEndpoint,
        data: {'uid': uid},
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        '[AiService] /risk/predict failed: ${e.response?.statusCode ?? e.type}',
      );
      return null;
    } catch (e) {
      debugPrint('[AiService] /risk/predict error: $e');
      return null;
    }
  }

  // ── Image hazard detection ─────────────────────────────────────────────────

  /// Uploads [imageFile] to `/image/detect` and parses the JSON response.
  /// Throws [DioException] on transport failure so the hazard-report flow
  /// can fall back to a "safe" default (allowing the worker to still submit).
  Future<Map<String, dynamic>?> detectImageHazard(
    File imageFile, {
    String filename = 'hazard.jpg',
  }) async {
    final headers = await _authHeaders();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: filename),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.imageDetectEndpoint,
      data: formData,
      options: Options(
        headers: {...headers, 'Content-Type': 'multipart/form-data'},
      ),
    );
    return response.data;
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  /// Returns the worker's "Video of the Day" + 4 also-recommended videos.
  /// Endpoint: `GET /recommendations/{uid}`.
  Future<Map<String, dynamic>?> getRecommendations(String uid) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.recommendationsEndpoint}/$uid',
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        '[AiService] /recommendations failed: ${e.response?.statusCode ?? e.type}',
      );
      return null;
    }
  }

  // ── Behavior analysis (supervisor / admin tools) ───────────────────────────

  Future<Map<String, dynamic>?> analyzeBehavior(String uid) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.behaviorAnalyzeEndpoint,
        data: {'uid': uid},
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        '[AiService] /behavior/analyze failed: ${e.response?.statusCode ?? e.type}',
      );
      return null;
    }
  }
}

/// Singleton Riverpod provider for the AI client.
///
/// Re-exported under the same name as the Phase 3 stub so existing callers
/// (e.g. `checklist_provider.dart`) get the upgrade automatically.
final aiServiceProvider = Provider<AiService>((ref) => AiService());

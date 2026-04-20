/// Unified exception type for MiningGuard.
/// All service layers throw AppException; UI layers catch AppException.
/// Never let Firebase exceptions, Dio exceptions, or Dart exceptions
/// propagate into widget code — always wrap them here.
class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  final String code;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  // ── Named constructors for common error types ────────────────────────────

  factory AppException.network(String message, {Object? originalError}) =>
      AppException(
        code: 'NETWORK_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.auth(String message, {Object? originalError}) =>
      AppException(
        code: 'AUTH_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.firestore(String message, {Object? originalError}) =>
      AppException(
        code: 'FIRESTORE_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.storage(String message, {Object? originalError}) =>
      AppException(
        code: 'STORAGE_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.ai(String message, {Object? originalError}) =>
      AppException(
        code: 'AI_BACKEND_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.unknown(Object error) =>
      AppException(
        code: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred.',
        originalError: error,
      );

  @override
  String toString() => 'AppException[$code]: $message';
}

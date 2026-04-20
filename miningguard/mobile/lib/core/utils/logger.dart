import 'package:logger/logger.dart';

/// Singleton logger. Use this everywhere instead of print() or debugPrint().
///
/// Usage:
///   import 'package:miningguard/core/utils/logger.dart';
///   AppLogger.d('checklist loaded'); // debug
///   AppLogger.i('user logged in');   // info
///   AppLogger.w('low connectivity'); // warning
///   AppLogger.e('upload failed', error: e, stackTrace: st); // error
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

// core/error_handler.dart
import 'dart:async';
import 'logger.dart';

/// Utility to handle retryable operations and centralized error handling.
class ErrorHandler {
  /// Executes [operation], retrying up to [attempts] times on failure.
  /// If all attempts fail the last error is rethrown.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int attempts = 2,
    Duration delayBetweenAttempts = const Duration(milliseconds: 200),
  }) async {
    if (attempts < 1) attempts = 1;
    int tried = 0;
    while (true) {
      tried++;
      try {
        return await operation();
      } catch (e, s) {
        Logger.instance.error('ErrorHandler.retry failed (attempt $tried): $e', s);
        if (tried >= attempts) rethrow;
        await Future.delayed(delayBetweenAttempts);
      }
    }
  }
}

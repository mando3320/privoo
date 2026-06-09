// core/logger.dart
/// نظام تسجيل موحد للتطبيق
class Logger {
  static final Logger instance = Logger();
  

  void i(String message) {
    _log('ℹ️', message);
  }

  void w(String message) {
    _log('⚠️', message);
  }

  void e(String message, [dynamic error]) {
    _log('❌', message + (error != null ? '\nError: $error' : ''));
  }

  void warning(String message) {
    _log('⚠️', message);
  }

  void error(String message, [dynamic error]) {
    _log('❌', message + (error != null ? '\nError: $error' : ''));
  }

  void debug(String message) {
    _log('🔍', message);
  }

  void _log(String prefix, String message) {
    final timestamp = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('$timestamp $prefix $message');
  }
}

// ✅ للحفاظ على التوافق مع الكود القديم
final logger = Logger();
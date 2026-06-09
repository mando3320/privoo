// lib/services/performance_monitor.dart
import 'package:firebase_performance/firebase_performance.dart';
import '../main.dart';

class PerformanceMonitor {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  static Future<Trace?> startTrace(String name) async {
    try {
      final trace = _performance.newTrace(name);
      await trace.start();
      return trace;
    } catch (e) {
      logger.e('خطأ في بدء Trace: $e');
      return null;
    }
  }
  
  static Future<void> endTrace(Trace trace) async {
    try {
      await trace.stop();
    } catch (e) {
      logger.e('خطأ في إنهاء Trace: $e');
    }
  }
}

// lib/services/performance_monitor.dart
import 'dart:developer' as dev;
import 'package:logger/logger.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Logger _logger = Logger();

  void startTrace(String name) {
    dev.debugTimelineSync(name, () {});
    _logger.d('🔍 Trace started: $name');
  }

  void stopTrace(String name) {
    dev.debugTimelineSync('$name:end', () {});
    _logger.d('🔍 Trace stopped: $name');
  }

  void logPerformance(String name, Duration duration) {
    _logger.d('⏱️ $name: ${duration.inMilliseconds}ms');
  }

  void logMetric(String name, num value, {String? unit}) {
    _logger.d('📊 $name: $value${unit ?? ''}');
  }

  void logCustomEvent(String name, Map<String, dynamic> attributes) {
    _logger.d('📊 Event: $name, Attributes: $attributes');
  }
}
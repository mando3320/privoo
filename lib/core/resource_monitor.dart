// core/resource_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logger.dart';

/// مراقب موارد التطبيق للتأكد من عدم حدوث مشاكل في الذاكرة أو الأداء
class ResourceMonitor {
  static final _logger = Logger.instance;
  static const platform = MethodChannel('privoo/resources');
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;

  static void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkResources(),
    );
    
    _logger.i('🔍 تم بدء مراقبة موارد التطبيق');
  }

  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    _logger.i('⏹️ تم إيقاف مراقبة موارد التطبيق');
  }

  static Future<void> _checkResources() async {
    try {
      final memoryInfo = await platform.invokeMethod('getMemoryInfo');
      if (memoryInfo != null) {
        final availableMemory = memoryInfo['availableMemory'] as int?;
        final totalMemory = memoryInfo['totalMemory'] as int?;
        
        if (availableMemory != null && totalMemory != null) {
          final usedPercentage = ((totalMemory - availableMemory) / totalMemory) * 100;
          
          if (usedPercentage > 85) {
            _logger.w('⚠️ استخدام الذاكرة مرتفع: ${usedPercentage.toStringAsFixed(1)}%');
            await _cleanupResources();
          }
        }
      }
    } catch (e) {
      _logger.e('خطأ في فحص موارد النظام', e);
    }
  }

  static Future<void> _cleanupResources() async {
    try {
      imageCache.clear();
      imageCache.clearLiveImages();
      
      await platform.invokeMethod('gc');
      
      _logger.i('🧹 تم تنظيف موارد النظام');
    } catch (e) {
      _logger.e('خطأ في تنظيف موارد النظام', e);
    }
  }

  static Future<void> dispose() async {
    stopMonitoring();
    await _cleanupResources();
  }
}
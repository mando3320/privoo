// core/app_state_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../core/error_handler.dart';

enum AppState {
  initializing,
  ready,
  error,
  maintenance,
  lowMemory,
  offline,
}

class AppStateManager extends ChangeNotifier {
  AppState _state = AppState.initializing;
  String? _errorMessage;
  bool _isPerformanceModeEnabled = false;
  
  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isPerformanceModeEnabled => _isPerformanceModeEnabled;
  
  void setState(AppState newState, {String? errorMessage}) {
    _state = newState;
    _errorMessage = errorMessage;
    Logger.instance.i('🔄 تغيرت حالة التطبيق إلى: $newState');
    notifyListeners();
  }
  
  void enablePerformanceMode() {
    _isPerformanceModeEnabled = true;
    Logger.instance.i('⚡ تم تفعيل وضع الأداء المنخفض');
    notifyListeners();
  }
  
  void disablePerformanceMode() {
    _isPerformanceModeEnabled = false;
    Logger.instance.i('⚡ تم تعطيل وضع الأداء المنخفض');
    notifyListeners();
  }
  
  Future<void> handleError(dynamic error, {bool fatal = false}) async {
    Logger.instance.error('خطأ في التطبيق', error);
    
    if (fatal) {
      setState(AppState.error, errorMessage: 'حدث خطأ غير متوقع');
    } else {
      try {
        await ErrorHandler.retry(
          operation: () async {
            await _reinitializeServices();
            return true;
          },
        );
      } catch (e) {
        setState(AppState.error, errorMessage: 'فشلت محاولة التعافي');
      }
    }
  }
  
  Future<void> _reinitializeServices() async {
    setState(AppState.initializing);
    
    try {
      setState(AppState.ready);
    } catch (e) {
      throw Exception('فشل في إعادة تهيئة الخدمات: $e');
    }
  }
}

final appStateProvider = ChangeNotifierProvider<AppStateManager>((ref) {
  return AppStateManager();
});
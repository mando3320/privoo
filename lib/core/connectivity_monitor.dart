// core/connectivity_monitor.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'logger.dart';

class ConnectivityMonitor {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<dynamic>? _subscription;
  static bool _isMonitoring = false;
  static ConnectivityResult _lastResult = ConnectivityResult.none;
  
  static Future<void> startMonitoring(BuildContext context) async {
    if (_isMonitoring) return;
    
    try {
      final rawResult = await _connectivity.checkConnectivity();
      _lastResult = rawResult.firstOrNull ?? ConnectivityResult.none;
      _isMonitoring = true;

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        _handleConnectivityChange(result, messenger);
      });
      
      Logger.instance.i('🌐 بدء مراقبة الاتصال بالإنترنت');
    } catch (e) {
      Logger.instance.error('خطأ في بدء مراقبة الاتصال', e);
    }
  }
  
  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
    Logger.instance.i('⏹️ إيقاف مراقبة الاتصال');
  }
  
  static void _handleConnectivityChange(
    dynamic rawResult,
    ScaffoldMessengerState messenger,
  ) {
    final result = rawResult is List<ConnectivityResult>
        ? rawResult.firstOrNull ?? ConnectivityResult.none
        : rawResult is ConnectivityResult
            ? rawResult
            : ConnectivityResult.none;
    
    if (result == _lastResult) return;

    _lastResult = result;
    String message = '';
    
    switch (result) {
      case ConnectivityResult.none:
        message = 'لا يوجد اتصال بالإنترنت';
        Logger.instance.warning('⚠️ انقطع الاتصال بالإنترنت');
        break;
      case ConnectivityResult.mobile:
        message = 'تم الاتصال عبر شبكة المحمول';
        Logger.instance.i('📱 تم الاتصال عبر شبكة المحمول');
        break;
      case ConnectivityResult.wifi:
        message = 'تم الاتصال عبر WiFi';
        Logger.instance.i('📶 تم الاتصال عبر WiFi');
        break;
      default:
        message = 'تغيرت حالة الاتصال';
        Logger.instance.i('🔄 تغيرت حالة الاتصال: $result');
    }
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static Future<bool> checkConnectivity() async {
    try {
      final rawResult = await _connectivity.checkConnectivity();
      final result = rawResult.firstOrNull ?? ConnectivityResult.none;
      return result != ConnectivityResult.none;
    } catch (e) {
      Logger.instance.error('خطأ في فحص الاتصال', e);
      return false;
    }
  }
  
  static Future<bool> retryConnection() async {
    for (int i = 0; i < 3; i++) {
      final isConnected = await checkConnectivity();
      if (isConnected) return true;
      await Future.delayed(const Duration(seconds: 2));
    }
    return false;
  }
  
  static void dispose() {
    stopMonitoring();
  }
}
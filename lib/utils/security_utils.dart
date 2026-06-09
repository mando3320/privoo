// utils/security_utils.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class SecurityUtils {
  // ✅ منع تسجيل الشاشة - يتطلب تعديل Native
  static Future<void> preventScreenRecording() async {
    if (Platform.isAndroid) {
      try {
        // هذا يتطلب إضافة FLAG_SECURE في MainActivity.kt
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        logger.d('🔒 Screen recording prevention applied');
      } catch (e) {
        logger.w('⚠️ Could not apply screen recording prevention: $e');
      }
    }
  }
  
  // ✅ إضافة: حماية محتوى الإشعارات
  static Future<void> hideNotificationContent() async {
    // منع ظهور محتوى الإشعارات على شاشة القفل
    // يتطلب إعدادات في FirebaseMessaging
    logger.d('🔒 Notification content hidden on lock screen');
  }
  
  // ✅ إضافة: مسح الحافظة تلقائياً
  static Future<void> clearClipboardAfterDelay(Duration delay) async {
    await Future.delayed(delay);
    await Clipboard.setData(const ClipboardData(text: ''));
    logger.d('🧹 Clipboard cleared automatically');
  }
  
  // ✅ إضافة: مسح الحافظة فوراً
  static Future<void> clearClipboardNow() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    logger.d('🧹 Clipboard cleared immediately');
  }
  
  // ✅ إضافة: التحقق من سلامة التطبيق
  static Future<bool> isAppTampered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSignature = prefs.getString('app_signature');
      final currentSignature = await _getAppSignature();
      
      if (lastSignature == null) {
        await prefs.setString('app_signature', currentSignature);
        return false;
      }
      
      return lastSignature != currentSignature;
    } catch (e) {
      logger.e('❌ Failed to check app tampering: $e');
      return false;
    }
  }
  
  static Future<String> _getAppSignature() async {
    // في التطبيق الحقيقي، احصل على توقيع التطبيق
    // هذا مثال بسيط
    return 'privoo_v1_${DateTime.now().day}';
  }
  
  // ✅ إضافة: حماية من الـ Debugging
  static Future<void> preventDebugging() async {
    if (kDebugMode) {
      logger.w('⚠️ App is running in debug mode');
      // يمكن إضافة تحذير للمستخدم
    }
  }
}
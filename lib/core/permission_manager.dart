// utils/permission_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';

import 'device_helper.dart';

/// إدارة الأذونات في التطبيق
class PermissionManager {
  static final _logger = Logger();
  /// قائمة الأذونات المطلوبة للتطبيق
  static final Map<Permission, String> _requiredPermissions = {
    Permission.camera: 'الكاميرا',
    Permission.microphone: 'الميكروفون',
    Permission.storage: 'الملفات',
    Permission.notification: 'الإشعارات',
    Permission.bluetooth: 'البلوتوث',
    if (Platform.isAndroid) ..._androidPermissions,
    if (Platform.isIOS) ..._iosPermissions,
  };

  /// أذونات خاصة بنظام Android
  static final Map<Permission, String> _androidPermissions = {
    Permission.phone: 'الهاتف',
    Permission.accessNotificationPolicy: 'سياسة الإشعارات',
    Permission.bluetooth: 'البلوتوث',
    Permission.bluetoothAdvertise: 'البث عبر البلوتوث',
    Permission.bluetoothConnect: 'الاتصال عبر البلوتوث',
    Permission.bluetoothScan: 'البحث عن أجهزة البلوتوث',
    Permission.systemAlertWindow: 'النوافذ المنبثقة',
  };

  /// أذونات خاصة بنظام iOS
  static final Map<Permission, String> _iosPermissions = {
    Permission.photos: 'الصور',
    Permission.mediaLibrary: 'مكتبة الوسائط',
  };

  /// فحص حالة جميع الأذونات المطلوبة
  static Future<Map<Permission, bool>> checkAllPermissions() async {
    final results = <Permission, bool>{};
    
    try {
      final isProblematic = await DeviceHelper.isProblematicDevice();
      final isLowVersion = await DeviceHelper.isLowAndroidVersion();

      for (final entry in _requiredPermissions.entries) {
        final permission = entry.key;
        
        // تخطي بعض الأذونات للأجهزة القديمة
        if (isLowVersion && _shouldSkipForLowVersion(permission)) {
          continue;
        }

        // معالجة خاصة للأجهزة المشكلة
        if (isProblematic && _shouldSkipForProblematicDevice(permission)) {
          results[permission] = true;
          continue;
        }

        try {
          final status = await permission.status;
          results[permission] = status.isGranted;
          
          _logger.i(
            '📱 حالة إذن ${entry.value}: ${status.isGranted ? "✅" : "❌"}'
          );
        } catch (e) {
          _logger.error('خطأ في فحص إذن ${entry.value}', e);
          results[permission] = false;
        }
      }
    } catch (e) {
      _logger.error('خطأ في فحص الأذونات', e);
    }

    return results;
  }

  /// طلب جميع الأذونات المطلوبة
  static Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      final currentPermissions = await checkAllPermissions();
      final missingPermissions = currentPermissions.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toList();

      if (missingPermissions.isEmpty) {
        _logger.i('✅ جميع الأذونات ممنوحة');
        return true;
      }

      // طلب الأذونات المفقودة
      for (final permission in missingPermissions) {
        final status = await permission.request();
        
        if (!status.isGranted) {
          _logger.warning(
            '⚠️ تم رفض إذن ${_requiredPermissions[permission]}'
          );
          
          // عرض شرح للمستخدم
          if (context.mounted) {
            await _showPermissionExplanationDialog(
              context,
              permission,
              _requiredPermissions[permission] ?? 'غير معروف'
            );
          }
        }
      }

      // إعادة فحص بعد الطلب
      final finalCheck = await checkAllPermissions();
      return !finalCheck.containsValue(false);

    } catch (e) {
      _logger.error('خطأ في طلب الأذونات', e);
      return false;
    }
  }

  /// عرض شرح للمستخدم عن سبب طلب الإذن
  static Future<void> _showPermissionExplanationDialog(
    BuildContext context,
    Permission permission,
    String permissionName,
  ) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('إذن $permissionName مطلوب'),
        content: Text(
          'يحتاج التطبيق إلى إذن $permissionName للعمل بشكل صحيح. '
          'هل تريد فتح إعدادات التطبيق لمنح الإذن؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// فحص إذا كان يجب تخطي الإذن للأجهزة القديمة
  static bool _shouldSkipForLowVersion(Permission permission) {
    return [
      Permission.notification,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].contains(permission);
  }

  /// فحص إذا كان يجب تخطي الإذن للأجهزة المشكلة
  static bool _shouldSkipForProblematicDevice(Permission permission) {
    return [
      Permission.systemAlertWindow,
      Permission.accessNotificationPolicy,
    ].contains(permission);
  }

  /// التحقق من إذن محدد
  static Future<bool> checkPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      _logger.error('خطأ في فحص الإذن', e);
      return false;
    }
  }

  /// طلب إذن محدد
  static Future<bool> requestPermission(
    Permission permission,
    BuildContext context
  ) async {
    try {
      final status = await permission.request();
      
      if (!status.isGranted && context.mounted) {
        await _showPermissionExplanationDialog(
          context,
          permission,
          _requiredPermissions[permission] ?? 'غير معروف'
        );
      }
      
      return status.isGranted;
    } catch (e) {
      _logger.error('خطأ في طلب الإذن', e);
      return false;
    }
  }

  /// فحص إذا كان يجب إعادة تشغيل التطبيق بعد تغيير الأذونات
  static Future<bool> needsRestart() async {
    if (!Platform.isAndroid) return false;

    try {
      final isProblematic = await DeviceHelper.isProblematicDevice();
      if (!isProblematic) return false;

      // فحص الأذونات الحرجة التي قد تتطلب إعادة تشغيل
      final criticalPermissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.bluetooth,
      ];

      for (final permission in criticalPermissions) {
        if (!await checkPermission(permission)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      _logger.error('خطأ في فحص حاجة إعادة التشغيل', e);
      return true; // للأمان
    }
  }
}
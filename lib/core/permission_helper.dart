// core/permission_helper.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'logger.dart';
import 'device_helper.dart';  // ✅ تم تصحيح المسار

class PermissionHelper {
  static final _logger = Logger();
  static final Map<Permission, String> _permissions = {
    Permission.camera: 'الكاميرا',
    Permission.microphone: 'الميكروفون',
    Permission.storage: 'التخزين',
    Permission.photos: 'الصور والوسائط',
    Permission.notification: 'الإشعارات',
  };

  static Future<bool> checkPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      _logger.error('خطأ في فحص الصلاحية ${_permissions[permission]}', e);
      return false;
    }
  }

  static Future<bool> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      _logger.error('خطأ في طلب الصلاحية ${_permissions[permission]}', e);
      return false;
    }
  }

  static Future<Map<Permission, bool>> checkAndRequestAllPermissions() async {
    final results = <Permission, bool>{};
    
    try {
      final isProblematic = await DeviceHelper.isProblematicDevice();
      final isLowVersion = await DeviceHelper.isLowAndroidVersion();

      for (final permission in _permissions.keys) {
        if (isLowVersion && 
            (permission == Permission.notification || 
             permission == Permission.photos)) {
          continue;
        }

        if (isProblematic && permission == Permission.storage) {
          results[permission] = true;
          continue;
        }

        bool hasPermission = await checkPermission(permission);
        if (!hasPermission) {
          hasPermission = await requestPermission(permission);
        }
        results[permission] = hasPermission;

        _logger.i(
          '📱 صلاحية ${_permissions[permission]}: ${hasPermission ? "✅" : "❌"}'
        );
      }
    } catch (e) {
      _logger.error('خطأ في فحص الصلاحيات', e);
    }

    return results;
  }

  static Future<bool> needsRestart() async {
    if (!Platform.isAndroid) return false;

    try {
      final isProblematic = await DeviceHelper.isProblematicDevice();
      if (!isProblematic) return false;

      final permissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
      ];

      for (final permission in permissions) {
        if (!await checkPermission(permission)) {
          return true;
        }
      }
    } catch (e) {
      _logger.error('خطأ في فحص حاجة إعادة التشغيل', e);
    }

    return false;
  }
}
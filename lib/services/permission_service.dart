// lib/services/permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../main.dart';
import '../config/app_theme.dart';

/// خدمة إدارة الأذونات - طلب الأذونات تلقائياً عند أول فتح
class PermissionService {
  /// طلب جميع الأذونات مرة واحدة
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.contacts,
      Permission.notification,
    ];
    
    return await permissions.request();
  }

  /// طلب الأذونات مع واجهة مستخدم (بدون توجيه للإعدادات)
  static Future<bool> requestPermissionsWithUI(BuildContext context) async {
    try {
      final statuses = await requestAllPermissions();
      
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      // طلب خاص لجهات الاتصال
      final hasContactPermission = await FlutterContacts.requestPermission();
      allGranted = allGranted && hasContactPermission;
      
      // ✅ إذا لم يتم منح جميع الأذونات، نعرض رسالة فقط (بدون توجيه للإعدادات)
      if (!allGranted && context.mounted) {
        // ✅ مجرد رسالة تنبيه بدون زر "فتح الإعدادات"
        await showDialog(
          context: context,
          barrierDismissible: true, // ✅ يسمح بإغلاق الحوار بالضغط خارجاً
          builder: (ctx) => AlertDialog(
            title: const Text('تنبيه'),
            content: const Text(
              'بعض الأذونات غير مفعلة. يمكنك تفعيلها لاحقاً من إعدادات الجهاز.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
        return false;
      }
      
      return allGranted;
    } catch (e) {
      logger.e('❌ خطأ في طلب الأذونات: $e');
      return false;
    }
  }

  /// التحقق من حالة الأذونات
  static Future<bool> checkPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.contacts,
      Permission.notification,
    ].request();
    
    return statuses.values.every((status) => status.isGranted);
  }
}
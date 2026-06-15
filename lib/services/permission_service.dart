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

  /// طلب الأذونات مع واجهة مستخدم
  static Future<bool> requestPermissionsWithUI(BuildContext context) async {
    try {
      final statuses = await requestAllPermissions();
      
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      // ✅ تصحيح: استخدام الطريقة الصحيحة للتحقق من إذن جهات الاتصال
      final hasContactPermission = await FlutterContacts.requestPermission();
      allGranted = allGranted && hasContactPermission;
      
      if (!allGranted && context.mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('الأذونات مطلوبة'),
            content: const Text(
              'يرجى منح الأذونات المطلوبة لضمان عمل التطبيق بشكل صحيح:\n\n'
              '• الكاميرا - لإجراء مكالمات الفيديو\n'
              '• الميكروفون - لإجراء المكالمات\n'
              '• التخزين - لحفظ الملفات والصور\n'
              '• جهات الاتصال - للعثور على أصدقائك\n'
              '• الإشعارات - لتلقي التنبيهات',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ليس الآن'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.privooDeepPurple,
                ),
                child: const Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          await openAppSettings();
        }
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

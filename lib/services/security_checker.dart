// lib/services/security_checker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../main.dart';

class SecurityChecker {
  static final SecurityChecker _instance = SecurityChecker._internal();
  factory SecurityChecker() => _instance;
  SecurityChecker._internal();
  
  bool _isCompromised = false;
  String? _compromiseReason;
  
  Future<bool> isDeviceSecure() async {
    _isCompromised = false;
    _compromiseReason = null;
    
    if (Platform.isAndroid) {
      await _checkAndroidRoot();
    } else if (Platform.isIOS) await _checkIOSJailbreak();
    
    await _checkDebugTools();
    return !_isCompromised;
  }
  
  Future<void> _checkAndroidRoot() async {
    try {
      final rootFiles = [
        '/system/app/Superuser.apk', '/sbin/su', '/system/bin/su',
        '/system/xbin/su', '/data/local/xbin/su', '/data/local/bin/su',
        '/system/sd/xbin/su', '/system/bin/failsafe/su', '/data/local/su',
        '/su/bin/su', '/system/bin/.ext/.su', '/system/usr/we-need-root/su-backup',
        '/system/xbin/daemonsu', '/data/adb/magisk', '/sbin/.magisk',
      ];
      
      for (final file in rootFiles) {
        if (await File(file).exists()) {
          _isCompromised = true;
          _compromiseReason = 'Root detected: $file exists';
          logger.w('⚠️ $_compromiseReason');
          return;
        }
      }
      
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.tags.contains('test-keys') == true) {
        _isCompromised = true;
        _compromiseReason = 'Test keys detected in build';
        logger.w('⚠️ $_compromiseReason');
      }
    } catch (e) {
      logger.e('Error checking Android root: $e');
    }
  }
  
  Future<void> _checkIOSJailbreak() async {
    try {
      final jailbreakFiles = [
        '/Applications/Cydia.app', '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash', '/usr/sbin/sshd', '/etc/apt', '/private/var/lib/apt',
        '/private/var/stash', '/private/var/tmp/cydia.log', '/usr/bin/ssh',
        '/usr/libexec/cydia',
      ];
      
      for (final file in jailbreakFiles) {
        if (await File(file).exists()) {
          _isCompromised = true;
          _compromiseReason = 'Jailbreak detected: $file exists';
          logger.w('⚠️ $_compromiseReason');
          return;
        }
      }
      
      final testFile = File('/private/test_write.txt');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        _isCompromised = true;
        _compromiseReason = 'Can write outside sandbox';
        logger.w('⚠️ $_compromiseReason');
      } catch (_) {}
    } catch (e) {
      logger.e('Error checking iOS jailbreak: $e');
    }
  }
  
  Future<void> _checkDebugTools() async {
    if (kDebugMode) {
      logger.d('ℹ️ Debug mode is active (normal for development)');
    }
  }
  
  String? getCompromiseReason() => _compromiseReason;
  
  Future<void> showSecurityAlert(BuildContext context) async {
    if (!_isCompromised) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ جهاز غير آمن', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم اكتشاف أن جهازك مخترق (Rooted / Jailbroken).'),
            const SizedBox(height: 12),
            Text('السبب: $_compromiseReason', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('الأجهزة المخترقة أقل أماناً وقد يتم تسريب بياناتك.\nنوصي باستخدام Privoo على جهاز آمن.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('فهمت')),
          if (!kDebugMode)
            TextButton(
              onPressed: () => exit(0),
              child: const Text('إغلاق التطبيق', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

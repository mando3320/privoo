// utils/device_identifier.dart
import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/logger.dart';

/// مساعد للتعامل مع هوية الجهاز
class DeviceIdentifier {
  static final _logger = Logger();
  static String? _cachedDeviceId;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// توليد معرف آمن للجهاز
  static Future<String> _generateSecureDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final deviceData = {
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'id': androidInfo.id,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'host': androidInfo.host,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'product': androidInfo.product,
        };
        
        final jsonStr = json.encode(deviceData);
        final bytes = utf8.encode(jsonStr);
        final digest = sha256.convert(bytes);
        return digest.toString();
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final deviceData = {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
        };
        
        final jsonStr = json.encode(deviceData);
        final bytes = utf8.encode(jsonStr);
        final digest = sha256.convert(bytes);
        return digest.toString();
      }
      return '';
    } catch (e) {
      _logger.error('خطأ في توليد معرف الجهاز الآمن', e);
      return '';
    }
  }

  /// الحصول على معرف الجهاز الفريد
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return (_cachedDeviceId ?? (throw Exception("Null value for _cachedDeviceId")));

    try {
      String deviceId = await _generateSecureDeviceId();
      if (deviceId.isEmpty) {
        deviceId = await _generateFallbackId();
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      _logger.error('خطأ في الحصول على معرف الجهاز', e);
      // استخدام معرف بديل في حالة الخطأ
      return await _generateFallbackId();
    }
  }

  /// إنشاء معرف بديل للجهاز
  static Future<String> _generateFallbackId() async {
    try {
      final StringBuffer idBuilder = StringBuffer();

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        idBuilder.writeAll([
          androidInfo.brand,
          androidInfo.device,
          androidInfo.id,
          androidInfo.fingerprint.substring(0, 8),
        ], '_');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        idBuilder.writeAll([
          iosInfo.model,
          iosInfo.systemVersion,
          iosInfo.identifierForVendor ?? '',
        ], '_');
      }

      // إضافة معلومات النظام
      final systemTemp = await getTemporaryDirectory();
      idBuilder.write('_${systemTemp.path.hashCode}');

      return idBuilder.toString();
    } catch (e) {
      _logger.error('خطأ في إنشاء معرف بديل', e);
      // إرجاع معرف عشوائي كحل أخير
      return DateTime.now().microsecondsSinceEpoch.toString();
    }
  }

  /// مسح المعرف المخزن مؤقتاً
  static void clearCache() {
    _cachedDeviceId = null;
  }

  /// التحقق من صحة المعرف
  static bool isValidDeviceId(String deviceId) {
    return deviceId.isNotEmpty && deviceId.length >= 8;
  }

  /// الحصول على معلومات إضافية عن الجهاز
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'bootloader': androidInfo.bootloader,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': iosInfo.utsname.sysname,
        };
      }
      return {'error': 'نظام تشغيل غير مدعوم'};
    } catch (e) {
      _logger.error('خطأ في الحصول على معلومات الجهاز', e);
      return {'error': e.toString()};
    }
  }
}
// utils/device_helper.dart (النسخة النهائية والمعدلة)

import "dart:io";
import "package:device_info_plus/device_info_plus.dart";

/// مُساعد للتحقق من معلومات الجهاز والسلوكيات الخاصة به
class DeviceHelper {
  
  /// قائمة بالعلامات التجارية المعروفة بسياستها العدوانية لإدارة الطاقة/الخلفية
  static const _problematicBrands = [
    "oppo", 
    "realme", 
    "oneplus", 
    "vivo", 
    // 💡 إضافات لأجهزة أخرى معروفة بالمشكلات
    "xiaomi", 
    "huawei",
    "honor",
  ];

  /// 📥 جلب اسم ماركة الجهاز (Brand)
  static Future<String> getBrand() async {
    if (!Platform.isAndroid) return "unknown";
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      // 💡 تحويل الاسم إلى حروف صغيرة لضمان المقارنة الصحيحة
      return info.brand.toLowerCase(); 
    } catch (e) {
      // في حال فشل جلب المعلومات
      return "unknown"; 
    }
  }

  /// ⚠️ التحقق مما إذا كان الجهاز من الماركات المعروفة بمشاكل الخلفية
  static Future<bool> isProblematicDevice() async {
    final brand = await getBrand();
    return _problematicBrands.contains(brand);
  }

  /// 🔻 التحقق مما إذا كان الجهاز يعمل بإصدار Android قديم
  /// (مهم لدعم الميزات القديمة أو تنبيه المستخدم)
  static Future<bool> isLowAndroidVersion() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    // API Level 23 = Android 6.0 (Marshmallow)
    return info.version.sdkInt < 23; 
  }
}

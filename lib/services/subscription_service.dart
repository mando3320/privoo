// lib/services/subscription_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SubscriptionService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> checkUserStatus() async {
    final user = _auth.currentUser;
    
    if (user == null || user.phoneNumber == null) {
      return {
        'isPro': false,
        'isLifetime': false,
        'isAdmin': false,
        'message': 'الرجاء تسجيل الدخول أولاً',
      };
    }

    try {
      final snapshot = await _database.child('lifetime_phons').get();
      
      if (snapshot.exists) {
        final value = snapshot.value;
        bool isLifetime = false;
        
        if (value is String) {
          isLifetime = (value == user.phoneNumber);
        } else if (value is Map) {
          isLifetime = value.values.map((e) => e.toString()).contains(user.phoneNumber);
        } else if (value is List) {
          isLifetime = value.map((e) => e.toString()).contains(user.phoneNumber);
        }
        
        await _saveToLocal(isLifetime: isLifetime);
        
        logger.i("✅ المستخدم: ${user.phoneNumber}, Lifetime=$isLifetime");
        
        return {
          'isPro': isLifetime,
          'isLifetime': isLifetime,
          'isAdmin': isLifetime,
          'phoneNumber': user.phoneNumber,
          'message': isLifetime ? '✅ اشتراك مدى الحياة مفعل' : '❌ اشتراك غير موجود',
        };
      }
      
      return {
        'isPro': false,
        'isLifetime': false,
        'isAdmin': false,
        'phoneNumber': user.phoneNumber,
        'message': 'لا يوجد اشتراك',
      };
    } catch (e) {
      logger.e("❌ فشل الاتصال بقاعدة البيانات: $e");
      return _getFromLocal(user.phoneNumber!);
    }
  }

  static Future<void> _saveToLocal({required bool isLifetime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLifetime', isLifetime);
      await prefs.setString('lifetime_updated', DateTime.now().toIso8601String());
    } catch (e) {
      logger.e("❌ فشل حفظ الحالة محلياً: $e");
    }
  }

  static Future<Map<String, dynamic>> _getFromLocal(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLifetime = prefs.getBool('isLifetime') ?? false;
      
      return {
        'isPro': isLifetime,
        'isLifetime': isLifetime,
        'isAdmin': false,
        'phoneNumber': phoneNumber,
        'message': isLifetime ? 'اشتراك مدى الحياة (من التخزين المحلي)' : 'لا يوجد اشتراك',
      };
    } catch (e) {
      return {
        'isPro': false,
        'isLifetime': false,
        'isAdmin': false,
        'phoneNumber': phoneNumber,
        'message': 'خطأ في جلب الحالة',
      };
    }
  }

  static Future<bool> isLifetimeUser() async {
    final status = await checkUserStatus();
    return status['isLifetime'] == true;
  }

  static Future<bool> isProUser() async {
    final status = await checkUserStatus();
    return status['isPro'] == true;
  }

  static Future<void> refreshUserStatus() async {
    await checkUserStatus();
    logger.i("🔄 تم تحديث حالة المستخدم");
  }

  // ✅ دوال التفعيل المطلوبة
  static Future<bool> activateDailySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 1));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك اليومي Pro (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateMonthlySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك الشهري Pro (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateYearlySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 365));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك السنوي Pro (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateFamilySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الخطة العائلية (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateStudentSubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الخطة الطلابية (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateFreeTrial() async {
    final expiry = DateTime.now().add(const Duration(days: 7));
    await _updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل العرض التجريبي المجاني (ينتهي: $expiry)");
    return true;
  }

  static Future<bool> activateLifetimeSubscription() async {
    await _updateSubscriptionStatus(isPro: true, isLifetime: true);
    logger.i("✅ تم تفعيل اشتراك مدى الحياة (Lifetime)");
    return true;
  }

  static Future<void> cancelSubscription() async {
    await _updateSubscriptionStatus(isPro: false, isLifetime: false);
    logger.i("✅ تم إلغاء الاشتراك");
  }

  static Future<void> _updateSubscriptionStatus({
    required bool isPro,
    required bool isLifetime,
    DateTime? expiryDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPro_cached', isPro);
      await prefs.setBool('isLifetime_cached', isLifetime);
      if (expiryDate != null) {
        await prefs.setString('pro_expiry', expiryDate.toIso8601String());
      } else if (!isPro) {
        await prefs.remove('pro_expiry');
      }
      logger.i("✅ تم تحديث حالة الاشتراك: Pro=$isPro, Lifetime=$isLifetime");
    } catch (e) {
      logger.e("❌ فشل تحديث حالة الاشتراك: $e");
    }
  }
}

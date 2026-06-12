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
}
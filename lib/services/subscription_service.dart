// lib/services/subscription_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ التحقق من حالة المستخدم من Firestore
  static Future<Map<String, dynamic>> checkUserStatus() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      return {
        'isPro': false,
        'isLifetime': false,
        'isAdmin': false,
        'message': 'الرجاء تسجيل الدخول أولاً',
      };
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final isPro = data['isPro'] ?? false;
        final isLifetime = data['isLifetime'] ?? false;
        final isAdmin = data['isAdmin'] ?? false;
        final expiryTimestamp = data['subscriptionExpiry'] as Timestamp?;
        
        bool isValid = isPro || isLifetime;
        
        // ✅ التحقق من انتهاء الصلاحية
        if (expiryTimestamp != null) {
          if (expiryTimestamp.toDate().isAfter(DateTime.now())) {
            isValid = true;
          } else if (expiryTimestamp.toDate().isBefore(DateTime.now())) {
            // الاشتراك منتهي - تحديث الحالة
            await _firestore.collection('users').doc(user.uid).update({
              'isPro': false,
            });
            isValid = false;
          }
        }
        
        await _saveToLocal(isPro: isValid, isLifetime: isLifetime);
        
        logger.i("✅ المستخدم: ${user.uid}, Pro=$isValid, Lifetime=$isLifetime");
        
        return {
          'isPro': isValid,
          'isLifetime': isLifetime,
          'isAdmin': isAdmin,
          'uid': user.uid,
          'message': isValid ? '✅ اشتراك مفعل' : '❌ اشتراك غير موجود',
        };
      } else {
        // ✅ إنشاء مستخدم جديد إذا لم يكن موجوداً
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.phoneNumber ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'avatarUrl': '',
          'about': 'مرحباً، أنا أستخدم Privoo',
          'isActive': true,
          'isPro': false,
          'isLifetime': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        
        return {
          'isPro': false,
          'isLifetime': false,
          'isAdmin': false,
          'uid': user.uid,
          'message': 'تم إنشاء مستخدم جديد',
        };
      }
    } catch (e) {
      logger.e("❌ فشل الاتصال بقاعدة البيانات: $e");
      return _getFromLocal();
    }
  }

  static Future<void> _saveToLocal({required bool isPro, required bool isLifetime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPro_cached', isPro);
      await prefs.setBool('isLifetime_cached', isLifetime);
      await prefs.setString('subscription_updated', DateTime.now().toIso8601String());
    } catch (e) {
      logger.e("❌ فشل حفظ الحالة محلياً: $e");
    }
  }

  static Future<Map<String, dynamic>> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPro = prefs.getBool('isPro_cached') ?? false;
      final isLifetime = prefs.getBool('isLifetime_cached') ?? false;
      
      return {
        'isPro': isPro,
        'isLifetime': isLifetime,
        'isAdmin': false,
        'message': isPro ? 'اشتراك (من التخزين المحلي)' : 'لا يوجد اشتراك',
      };
    } catch (e) {
      return {
        'isPro': false,
        'isLifetime': false,
        'isAdmin': false,
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

  // ✅ دوال التفعيل
  static Future<bool> activateDailySubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final expiry = DateTime.now().add(const Duration(days: 1));
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: false);
    logger.i("✅ تم تفعيل الاشتراك اليومي Pro");
    return true;
  }

  static Future<bool> activateMonthlySubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: false);
    logger.i("✅ تم تفعيل الاشتراك الشهري Pro");
    return true;
  }

  static Future<bool> activateYearlySubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final expiry = DateTime.now().add(const Duration(days: 365));
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: false);
    logger.i("✅ تم تفعيل الاشتراك السنوي Pro");
    return true;
  }

  static Future<bool> activateFamilySubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'isFamily': true,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: false);
    logger.i("✅ تم تفعيل الخطة العائلية");
    return true;
  }

  static Future<bool> activateStudentSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'isStudent': true,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: false);
    logger.i("✅ تم تفعيل الخطة الطلابية");
    return true;
  }

  static Future<bool> activateLifetimeSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': true,
      'isLifetime': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: true, isLifetime: true);
    logger.i("✅ تم تفعيل اشتراك مدى الحياة");
    return true;
  }

  static Future<void> cancelSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'isPro': false,
      'subscriptionExpiry': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _saveToLocal(isPro: false, isLifetime: false);
    logger.i("✅ تم إلغاء الاشتراك");
  }
}
// lib/services/subscription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SubscriptionService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // ✅ الحصول على المستخدم الحالي
  static User? get _currentUser => _supabase.auth.currentUser;

  /// ✅ التحقق من حالة المستخدم من Supabase
  static Future<Map<String, dynamic>> checkUserStatus({bool forceRefresh = false}) async {
    final user = _currentUser;
    
    if (user == null) {
      return _getGuestStatus();
    }

    // إذا كان التحديث القسري، نتجاوز التخزين المحلي
    if (!forceRefresh) {
      final localStatus = await _getFromLocal();
      if (localStatus['isValid'] == true) {
        return localStatus;
      }
    }

    try {
      // ✅ جلب بيانات المستخدم من جدول users
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle();

      if (response == null) {
        // ✅ إنشاء مستخدم جديد إذا لم يكن موجوداً
        await _createNewUser(user);
        return {
          'isPro': false,
          'isLifetime': false,
          'isAdmin': false,
          'isFamily': false,
          'isStudent': false,
          'uid': user.id,
          'message': 'تم إنشاء مستخدم جديد',
        };
      }

      // ✅ استخراج البيانات
      final isPro = response['isPro'] ?? false;
      final isLifetime = response['isLifetime'] ?? false;
      final isAdmin = response['isAdmin'] ?? false;
      final isFamily = response['isFamily'] ?? false;
      final isStudent = response['isStudent'] ?? false;
      final expiryTimestamp = response['subscriptionExpiry'] as String?;

      bool isValid = false;

      if (isLifetime) {
        isValid = true; // ✅ مدى الحياة لا ينتهي أبداً
      } else if (isPro && expiryTimestamp != null) {
        final expiryDate = DateTime.parse(expiryTimestamp);
        if (expiryDate.isAfter(DateTime.now())) {
          isValid = true;
        } else {
          // ✅ انتهت الصلاحية - تحديث تلقائي
          await _supabase
              .from('users')
              .update({
                'isPro': false,
                'subscriptionExpiry': null,
                'updatedAt': DateTime.now().toIso8601String(),
              })
              .eq('uid', user.id);
          isValid = false;
        }
      }

      await _saveToLocal(
        isPro: isValid,
        isLifetime: isLifetime,
        isAdmin: isAdmin,
        isFamily: isFamily,
        isStudent: isStudent,
      );

      logger.i("✅ المستخدم: ${user.id}, Pro=$isValid, Lifetime=$isLifetime");

      return {
        'isPro': isValid,
        'isLifetime': isLifetime,
        'isAdmin': isAdmin,
        'isFamily': isFamily,
        'isStudent': isStudent,
        'uid': user.id,
        'message': isValid ? '✅ اشتراك مفعل' : '❌ اشتراك غير موجود',
      };
    } catch (e) {
      logger.e("❌ فشل الاتصال بقاعدة البيانات: $e");
      return await _getFromLocal();
    }
  }

  /// ✅ إنشاء مستخدم جديد في Supabase
  static Future<void> _createNewUser(User user) async {
    await _supabase.from('users').insert({
      'uid': user.id,
      'name': user.userMetadata?['name'] ?? user.phone ?? '',
      'phoneNumber': user.phone ?? '',
      'email': user.email ?? '',
      'avatarUrl': user.userMetadata?['avatar_url'] ?? '',
      'about': 'مرحباً، أنا أستخدم Privoo',
      'isActive': true,
      'isPro': false,
      'isLifetime': false,
      'isAdmin': false,
      'isFamily': false,
      'isStudent': false,
      'createdAt': DateTime.now().toIso8601String(),
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  /// ✅ حفظ الحالة محلياً مع كافة البيانات
  static Future<void> _saveToLocal({
    required bool isPro,
    required bool isLifetime,
    required bool isAdmin,
    required bool isFamily,
    required bool isStudent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPro_cached', isPro);
      await prefs.setBool('isLifetime_cached', isLifetime);
      await prefs.setBool('isAdmin_cached', isAdmin);
      await prefs.setBool('isFamily_cached', isFamily);
      await prefs.setBool('isStudent_cached', isStudent);
      await prefs.setString('subscription_updated', DateTime.now().toIso8601String());
    } catch (e) {
      logger.e("❌ فشل حفظ الحالة محلياً: $e");
    }
  }

  /// ✅ جلب الحالة من التخزين المحلي
  static Future<Map<String, dynamic>> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPro = prefs.getBool('isPro_cached') ?? false;
      return {
        'isPro': isPro,
        'isLifetime': prefs.getBool('isLifetime_cached') ?? false,
        'isAdmin': prefs.getBool('isAdmin_cached') ?? false,
        'isFamily': prefs.getBool('isFamily_cached') ?? false,
        'isStudent': prefs.getBool('isStudent_cached') ?? false,
        'isValid': isPro,
        'message': 'من التخزين المحلي',
      };
    } catch (e) {
      return _getGuestStatus();
    }
  }

  /// ✅ حالة الضيف (غير مسجل)
  static Map<String, dynamic> _getGuestStatus() {
    return {
      'isPro': false,
      'isLifetime': false,
      'isAdmin': false,
      'isFamily': false,
      'isStudent': false,
      'isValid': false,
      'message': 'الرجاء تسجيل الدخول أولاً',
    };
  }

  /// ✅ دوال الاستعلام
  static Future<bool> isLifetimeUser() async {
    final status = await checkUserStatus();
    return status['isLifetime'] == true;
  }

  static Future<bool> isProUser() async {
    final status = await checkUserStatus();
    return status['isPro'] == true;
  }

  static Future<bool> isAdminUser() async {
    final status = await checkUserStatus();
    return status['isAdmin'] == true;
  }

  static Future<void> refreshUserStatus() async {
    await checkUserStatus(forceRefresh: true);
    logger.i("🔄 تم تحديث حالة المستخدم من السيرفر");
  }

  // ================================
  // 🔒 دوال التفعيل (يجب نقلها إلى Edge Functions)
  // ================================

  /// ⚠️ يجب استدعاء هذه الدوال من خلال Edge Function فقط!
  static Future<bool> _updateSubscription({
    required String uid,
    required bool isPro,
    bool isLifetime = false,
    bool isFamily = false,
    bool isStudent = false,
    int? daysToAdd,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'isPro': isPro,
        'isLifetime': isLifetime,
        'isFamily': isFamily,
        'isStudent': isStudent,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (daysToAdd != null && daysToAdd > 0) {
        final expiry = DateTime.now().add(Duration(days: daysToAdd));
        updates['subscriptionExpiry'] = expiry.toIso8601String();
      } else {
        updates['subscriptionExpiry'] = null;
      }

      await _supabase
          .from('users')
          .update(updates)
          .eq('uid', uid);

      // ✅ تحديث التخزين المحلي
      final currentStatus = await checkUserStatus(forceRefresh: true);
      await _saveToLocal(
        isPro: isPro,
        isLifetime: isLifetime,
        isAdmin: currentStatus['isAdmin'] ?? false,
        isFamily: isFamily,
        isStudent: isStudent,
      );

      logger.i("✅ تم تحديث الاشتراك للمستخدم $uid");
      return true;
    } catch (e) {
      logger.e("❌ فشل تحديث الاشتراك: $e");
      return false;
    }
  }

  /// ✅ دوال التفعيل (للإستخدام الداخلي فقط، يجب حمايتها)
  static Future<bool> activateDailySubscription() async {
    final user = _currentUser;
    if (user == null) return false;
    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      daysToAdd: 1,
    );
  }

  static Future<bool> activateMonthlySubscription() async {
    final user = _currentUser;
    if (user == null) return false;
    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      daysToAdd: 30,
    );
  }

  static Future<bool> activateYearlySubscription() async {
    final user = _currentUser;
    if (user == null) return false;
    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      daysToAdd: 365,
    );
  }

  static Future<bool> activateFamilySubscription() async {
    final user = _currentUser;
    if (user == null) return false;
    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      isFamily: true,
      daysToAdd: 30,
    );
  }

  static Future<bool> activateStudentSubscription() async {
    final user = _currentUser;
    if (user == null) return false;
    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      isStudent: true,
      daysToAdd: 30,
    );
  }

  static Future<bool> activateLifetimeSubscription() async {
    final user = _currentUser;
    if (user == null) return false;

    // ⚠️ تحقق أمني: فقط Admin يمكنه تفعيل Lifetime يدوياً
    final isAdmin = await isAdminUser();
    if (!isAdmin) {
      logger.w("⚠️ محاولة غير مصرح بها لتفعيل Lifetime من قبل مستخدم عادي");
      return false;
    }

    return await _updateSubscription(
      uid: user.id,
      isPro: true,
      isLifetime: true,
      daysToAdd: null,
    );
  }

  static Future<bool> cancelSubscription() async {
    final user = _currentUser;
    if (user == null) return false;

    return await _updateSubscription(
      uid: user.id,
      isPro: false,
      isLifetime: false,
      isFamily: false,
      isStudent: false,
      daysToAdd: null,
    );
  }

  /// ✅ التحقق من صلاحية الاشتراك في الوقت الفعلي (مباشر)
  static Stream<Map<String, dynamic>> streamUserStatus() {
    final user = _currentUser;
    if (user == null) {
      return Stream.value(_getGuestStatus());
    }

    return _supabase
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', user.id)
        .map((data) {
          if (data.isEmpty) return _getGuestStatus();
          final record = data.first;
          final isPro = record['isPro'] ?? false;
          final isLifetime = record['isLifetime'] ?? false;
          final expiry = record['subscriptionExpiry'] as String?;
          
          bool isValid = isLifetime || 
              (isPro && expiry != null && DateTime.parse(expiry).isAfter(DateTime.now()));

          return {
            'isPro': isValid,
            'isLifetime': isLifetime,
            'isAdmin': record['isAdmin'] ?? false,
            'isFamily': record['isFamily'] ?? false,
            'isStudent': record['isStudent'] ?? false,
            'uid': user.id,
            'message': isValid ? '✅ اشتراك مفعل' : '❌ اشتراك غير موجود',
          };
        });
  }
}
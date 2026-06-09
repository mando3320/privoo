// lib/services/subscription_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SubscriptionService {
  final String userAuthToken;

  SubscriptionService({required this.userAuthToken});

  // ✅ التحقق من حالة الاشتراك (خادم أولاً ثم محلياً)
  Future<Map<String, bool>> checkUserSubscriptionStatus() async {
    // 1️⃣ التحقق من الخادم أولاً
    if (userAuthToken.isNotEmpty && userAuthToken != 'UNINITIALIZED_AUTH_TOKEN') {
      try {
        final response = await http.post(
          Uri.parse('https://your-cloud-function.com/verify-subscription'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userAuthToken',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final isPro = data['isPro'] ?? false;
          final isLifetime = data['isLifetime'] ?? false;
          
          // تحديث التخزين المحلي
          await updateSubscriptionStatus(isPro: isPro, isLifetime: isLifetime);
          
          logger.i("✅ تم التحقق من الخادم: Pro=$isPro, Lifetime=$isLifetime");
          return {'isPro': isPro, 'isLifetime': isLifetime};
        }
      } catch (e) {
        logger.w("⚠️ فشل الاتصال بالخادم: $e، سيتم استخدام التخزين المحلي");
      }
    }
    
    // 2️⃣ Fallback: التحقق من التخزين المحلي
    return _getLocalSubscriptionStatus();
  }
  
  // ✅ التحقق من التخزين المحلي مع صلاحية
  Future<Map<String, bool>> _getLocalSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق من صلاحية الاشتراك المؤقت
      final expiryStr = prefs.getString('pro_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          await updateSubscriptionStatus(isPro: false, isLifetime: false);
          logger.i("⏰ انتهت صلاحية الاشتراك المؤقت");
          return {'isPro': false, 'isLifetime': false};
        }
      }

      final isPro = prefs.getBool('isPro_cached') ?? false;
      final isLifetime = prefs.getBool('isLifetime_cached') ?? false;

      logger.d("✅ تم جلب حالة الاشتراك محلياً: Pro=$isPro, Lifetime=$isLifetime");
      return {'isPro': isPro, 'isLifetime': isLifetime};
    } catch (e) {
      logger.e("❌ فشل جلب حالة الاشتراك: $e");
      return {'isPro': false, 'isLifetime': false};
    }
  }

  Future<void> updateSubscriptionStatus({
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

  Future<bool> activateDailySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 1));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك اليومي Pro (ينتهي: $expiry)");
    return true;
  }

  Future<bool> activateMonthlySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك الشهري Pro (ينتهي: $expiry)");
    return true;
  }

  Future<bool> activateYearlySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 365));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الاشتراك السنوي Pro (ينتهي: $expiry)");
    return true;
  }

  Future<bool> activateLifetimeSubscription() async {
    await updateSubscriptionStatus(isPro: true, isLifetime: true);
    logger.i("✅ تم تفعيل اشتراك مدى الحياة (Lifetime)");
    return true;
  }

  Future<bool> activateFamilySubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الخطة العائلية (ينتهي: $expiry)");
    return true;
  }

  Future<bool> activateStudentSubscription() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل الخطة الطلابية (ينتهي: $expiry)");
    return true;
  }

  Future<bool> activateFreeTrial() async {
    final expiry = DateTime.now().add(const Duration(days: 7));
    await updateSubscriptionStatus(isPro: true, isLifetime: false, expiryDate: expiry);
    logger.i("✅ تم تفعيل العرض التجريبي المجاني (ينتهي: $expiry)");
    return true;
  }

  Future<void> cancelSubscription() async {
    await updateSubscriptionStatus(isPro: false, isLifetime: false);
    logger.i("✅ تم إلغاء الاشتراك");
  }
}
// lib/services/api/auth_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'package:privoo/services/key_exchange_service.dart';
import 'package:privoo/services/supabase_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final SupabaseService _supabase = SupabaseService();
  final Logger _logger = Logger();
  final KeyExchangeService _kx = KeyExchangeService();

  int _failedAttempts = 0;
  final Lock _otpLock = Lock();

  // ⭐⭐⭐ دالة تنسيق رقم الهاتف تلقائياً ⭐⭐⭐
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.trim();
    cleaned = cleaned.replaceAll(' ', '');
    
    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('0020')) {
      return '+20${cleaned.substring(4)}';
    }
    if (cleaned.startsWith('+20')) {
      return cleaned;
    }
    if (!cleaned.startsWith('+')) {
      return '+20$cleaned';
    }
    return cleaned;
  }

  // ---------------- Email/Password ----------------
  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.signInWithEmail(email, password);
      final user = response.user;
      if (user != null) {
        _failedAttempts = 0;
        _logger.i('تم تسجيل الدخول: ${user.id}');
        await _kx.ensureIdentityAndSignatureKeys(user.id);
      }
      return user;
    } catch (e) {
      _failedAttempts++;
      _logger.e('خطأ في تسجيل الدخول: $e');
      return null;
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      final response = await _supabase.signUpWithEmail(email, password);
      final user = response.user;
      if (user != null) {
        _logger.i('تم إنشاء حساب جديد: ${user.id}');
        await _kx.ensureIdentityAndSignatureKeys(user.id);
        
        // ✅ إنشاء مستخدم في Supabase
        await _supabase.createUser(UserModel(
          id: user.id,
          authId: user.id,
          name: email.split('@').first,
          email: email,
          isActive: true,
          createdAt: DateTime.now(),
        ));
      }
      return user;
    } catch (e) {
      _logger.e('خطأ في إنشاء الحساب: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _supabase.currentUser;
      if (user != null) {
        await _supabase.setUserOffline(user.id);
      }
      await _supabase.signOut();
      _logger.i('تم تسجيل الخروج');
    } catch (e) {
      _logger.e('خطأ في تسجيل الخروج: $e');
    }
  }
  
  Future<void> signOutFromAllDevices() async {
    try {
      await _supabase.signOut();
      _logger.i('✅ تم تسجيل الخروج من جميع الأجهزة');
    } catch (e) {
      _logger.e('❌ خطأ في تسجيل الخروج من جميع الأجهزة: $e');
    }
  }

  User? get currentUser => _supabase.currentUser;

  // ---------------- Phone OTP support ----------------
  
  Future<bool> sendOTP(String phoneE164) async {
    final formattedNumber = _formatPhoneNumber(phoneE164);
    _logger.i('📱 محاولة إرسال OTP إلى الرقم: $formattedNumber');
    
    return await _otpLock.synchronized(() async {
      final regex = RegExp(r'^\+[1-9]\d{7,14}$');
      if (!regex.hasMatch(formattedNumber)) {
        _logger.w('رقم هاتف غير صالح: $formattedNumber');
        return false;
      }

      try {
        await _supabase.signInWithOTP(formattedNumber);
        _logger.i('✅ تم إرسال رمز التحقق بنجاح إلى $formattedNumber');
        return true;
      } catch (e) {
        _logger.e('❌ فشل إرسال OTP: $e');
        return false;
      }
    });
  }

  Future<bool> verifyOTP(String phoneNumber, String smsCode) async {
    return await _otpLock.synchronized(() async {
      if (smsCode.length != 6) {
        _logger.w('❌ رمز غير صالح: يجب أن يكون 6 أرقام');
        return false;
      }

      try {
        final response = await _supabase.verifyOTP(phoneNumber, smsCode);
        final user = response.user;
        if (user != null) {
          _failedAttempts = 0;
          _logger.i('✅ تم التحقق من الرمز وتسجيل الدخول بنجاح');
          await _kx.ensureIdentityAndSignatureKeys(user.id);
          return true;
        }
        return false;
      } catch (e) {
        _failedAttempts++;
        _logger.e('❌ رمز تحقق غير صحيح أو منتهي: $e');
        return false;
      }
    });
  }

  Future<String?> signInWithKeys(String userId) async {
    try {
      await _kx.ensureIdentityAndSignatureKeys(userId);
      _logger.i('✅ تسجيل دخول باستخدام هوية المفاتيح فقط: $userId');
      return userId;
    } catch (e) {
      _logger.e('❌ فشل تسجيل الدخول باستخدام المفاتيح: $e');
      return null;
    }
  }

  Future<String?> getMyFingerprint() async {
    final user = currentUser;
    if (user == null) return null;
    final pair = await _kx.getIdentityKeyPair(user.id);
    final pub = await pair.extractPublicKey();
    return await KeyExchangeService.pubFingerprint(pub.bytes, bytes: 16);
  }

  Future<bool> verifyPeerFingerprint(String peerId, String expectedFingerprint) async {
    try {
      final pub = await _kx.fetchPeerIdentityPublicKey(peerId);
      final fp = await KeyExchangeService.pubFingerprint(pub.bytes, bytes: 16);
      final match = (fp == expectedFingerprint);
      _logger.i(match
          ? '✅ بصمة الطرف الآخر متطابقة.'
          : '⚠️ بصمة الطرف الآخر غير متطابقة!');
      return match;
    } catch (e) {
      _logger.e('❌ فشل التحقق من بصمة الطرف الآخر: $e');
      return false;
    }
  }
  
  void resetFailedAttempts() {
    _failedAttempts = 0;
    _logger.d('🔄 تم إعادة تعيين عدد المحاولات الفاشلة');
  }
  
  int getFailedAttempts() {
    return _failedAttempts;
  }
  
  bool isRateLimited() {
    return _failedAttempts >= 10;
  }
}
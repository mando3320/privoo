// lib/services/api/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'package:privoo/services/key_exchange_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final KeyExchangeService _kx = KeyExchangeService();

  int _failedAttempts = 0;
  final Lock _otpLock = Lock();
  String? _verificationId;

  // ⭐⭐⭐ دالة تنسيق رقم الهاتف تلقائياً ⭐⭐⭐
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.trim();
    // إزالة أي مسافات
    cleaned = cleaned.replaceAll(' ', '');
    
    // لو الرقم بيبدأ بـ 0، استبدله بـ +20
    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }
    // لو الرقم بيبدأ بـ 0020، استبدله بـ +20
    if (cleaned.startsWith('0020')) {
      return '+20${cleaned.substring(4)}';
    }
    // لو الرقم بيبدأ بـ +20، خلاص تمام
    if (cleaned.startsWith('+20')) {
      return cleaned;
    }
    // لو الرقم بيبدأ برقم تاني غير الصيغ المصرية، أضف +20
    if (!cleaned.startsWith('+')) {
      return '+20$cleaned';
    }
    return cleaned;
  }

  // ---------------- Email/Password ----------------
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _failedAttempts = 0;
      _logger.i('تم تسجيل الدخول: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      _failedAttempts++;
      _logger.e('خطأ في تسجيل الدخول: $e');
      return null;
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('تم إنشاء حساب جديد: ${result.user?.uid}');
      await _kx.ensureIdentityAndSignatureKeys(result.user!.uid);
      return result.user;
    } catch (e) {
      _logger.e('خطأ في إنشاء الحساب: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('تم تسجيل الخروج');
    } catch (e) {
      _logger.e('خطأ في تسجيل الخروج: $e');
    }
  }
  
  Future<void> signOutFromAllDevices() async {
    try {
      await _auth.signOut();
      await _auth.currentUser?.reload();
      _logger.i('✅ تم تسجيل الخروج من جميع الأجهزة');
    } catch (e) {
      _logger.e('❌ خطأ في تسجيل الخروج من جميع الأجهزة: $e');
    }
  }

  User? get currentUser => _auth.currentUser;

  // ---------------- Phone OTP support (مع Lock وتنسيق تلقائي) ----------------
  
  Future<bool> sendOTP(String phoneE164) async {
    // ⭐⭐⭐ تنسيق الرقم تلقائياً ⭐⭐⭐
    final formattedNumber = _formatPhoneNumber(phoneE164);
    
    _logger.i('📱 محاولة إرسال OTP إلى الرقم: $formattedNumber');
    
    return await _otpLock.synchronized(() async {
      final regex = RegExp(r'^\+[1-9]\d{7,14}$');
      if (!regex.hasMatch(formattedNumber)) {
        _logger.w('رقم هاتف غير صالح: $formattedNumber');
        return false;
      }

      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: formattedNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            _logger.i('✅ تم التحقق التلقائي عبر SMS');
            try {
              await _auth.signInWithCredential(credential);
              _logger.i('✅ تم تسجيل الدخول تلقائياً');
            } catch (e) {
              _logger.e('❌ فشل تسجيل الدخول التلقائي: $e');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            _logger.e('❌ فشل إرسال الرمز: ${e.code} - ${e.message}');
            if (e.code == 'invalid-phone-number') {
              _logger.e('⚠️ رقم الهاتف غير صالح للتنسيق الدولي');
            } else if (e.code == 'too-many-requests') {
              _logger.e('⚠️ تم تجاوز عدد المحاولات، حاول لاحقاً');
            }
          },
          codeSent: (verificationId, forceResendingToken) {
            _verificationId = verificationId;
            _logger.i('✅ تم إرسال رمز التحقق بنجاح إلى $formattedNumber');
            _logger.i('📱 Verification ID: ${verificationId.substring(0, 8)}...');
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationId = verificationId;
            _logger.w('⏰ انتهى وقت الاسترجاع التلقائي للرمز');
          },
        );
        return true;
      } catch (e) {
        _logger.e('❌ تعذر إرسال OTP: $e');
        return false;
      }
    });
  }

  Future<bool> verifyOTP(String smsCode) async {
    return await _otpLock.synchronized(() async {
      if (_verificationId == null) {
        _logger.e('❌ لا يوجد verificationId. أرسل OTP أولاً.');
        return false;
      }
      if (smsCode.length != 6) {
        _logger.w('❌ رمز غير صالح: يجب أن يكون 6 أرقام');
        return false;
      }

      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        await _auth.signInWithCredential(credential);
        _failedAttempts = 0;
        _logger.i('✅ تم التحقق من الرمز وتسجيل الدخول بنجاح');
        return true;
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
    final pair = await _kx.getIdentityKeyPair(user.uid);
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
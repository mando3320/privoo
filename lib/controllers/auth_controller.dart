// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'app_controller.dart';
import '../services/supabase_service.dart';
import '../services/quantum_resistant_service.dart';
import '../services/key_exchange_service.dart';
import 'lifetime_users.dart';
import '../models/admin_model.dart';
import '../core/permissions.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref: ref);
});

class AuthController extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final Ref _ref;
  final Logger _logger = logger;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthController({required Ref ref}) : _ref = ref;

  bool isLoading = false;
  
  AdminModel? _currentAdmin;
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isAdmin => _currentAdmin != null && _currentAdmin!.isActive;
  bool get isSuperAdmin => _currentAdmin?.role == AdminRole.superAdmin;

  AppController get _appController => _ref.read(appControllerProvider);

  User? get currentUser => _supabase.client.auth.currentUser;

  Future<void> sendOTP(String phoneNumber) async {
    isLoading = true;
    notifyListeners();
    try {
      await _supabase.signInWithOTP(phoneNumber);
      _logger.i("✅ تم إرسال OTP إلى $phoneNumber");
    } catch (e) {
      _logger.w("❌ فشل إرسال OTP: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> verifyOTP(String phoneNumber, String smsCode) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.verifyOTP(phoneNumber, smsCode);
      final user = response.user;
      
      if (user != null) {
        _logger.i("✅ تم تسجيل الدخول: ${user.id}");
        await _generateQuantumKeys(user.id);
        await _checkLifetimeStatus(user.id);
        await _checkAdminStatus(user.id);
      } else {
        _logger.w("❌ فشل التحقق من OTP");
      }
    } catch (e) {
      _logger.e("❌ خطأ في التحقق: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _generateQuantumKeys(String userId) async {
    try {
      await QuantumResistantService.generateKyberKeyPair(userId);
      await QuantumResistantService.generateDilithiumKeyPair(userId);
      _logger.i('🔐 تم توليد المفاتيح الكمومية للمستخدم $userId');
    } catch (e) {
      _logger.w('⚠️ فشل توليد المفاتيح الكمومية: $e');
    }
  }

  Future<void> saveProfile(String name, String status, {String avatarUrl = ""}) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      await _supabase.updateUser(user.id, {
        'name': name,
        'avatar_url': avatarUrl,
        'about': status,
        'is_active': true,
        'last_seen': DateTime.now().toIso8601String(),
      });
      _logger.d('✅ تم حفظ الملف الشخصي للمستخدم: ${user.id}');
    } catch (e) {
      _logger.e('❌ خطأ أثناء حفظ الملف الشخصي: $e');
    }
  }

  Future<void> logout() async {
    try {
      final user = currentUser;
      if (user != null) {
        await QuantumResistantService.deleteQuantumKeys(user.id);
        await _supabase.updateUser(user.id, {
          'is_active': false,
          'last_seen': DateTime.now().toIso8601String(),
        });
      }
      await _supabase.signOut();
      await _appController.updateSubscriptionStatus(isPro: false, isLifetime: false);
      _logger.d('✅ تم تسجيل الخروج');
    } catch (e) {
      _logger.e('❌ خطأ أثناء تسجيل الخروج: $e');
    }
  }

  Future<bool> checkIfAdminLocal(String phoneNumber) async {
    return adminPhones.contains(phoneNumber) || adminEmails.contains(phoneNumber);
  }

  Future<bool> checkIfLifetimeUserLocal(String phoneNumber) async {
    return lifetimePhones.contains(phoneNumber) || lifetimeEmails.contains(phoneNumber);
  }

  Future<void> _checkLifetimeStatus(String userId) async {
    try {
      final userData = await _supabase.getUser(userId);
      if (userData == null) return;
      
      final phoneNumber = userData.phoneNumber;
      final email = userData.email;
      
      final isLifetimeByPhone = phoneNumber != null && lifetimePhones.contains(phoneNumber);
      final isLifetimeByEmail = email != null && lifetimeEmails.contains(email);
      
      if (isLifetimeByPhone || isLifetimeByEmail || userData.isLifetime) {
        await _appController.updateSubscriptionStatus(isPro: true, isLifetime: true);
        _logger.i("✅ تم تفعيل اشتراك مدى الحياة للمستخدم $phoneNumber");
        return;
      }
    } catch (e) {
      _logger.e('❌ خطأ أثناء التحقق من الاشتراك: $e');
    }
  }

  Future<void> _checkAdminStatus(String userId) async {
    try {
      final userData = await _supabase.getUser(userId);
      if (userData == null) {
        _logger.w('❌ userData is null');
        return;
      }
      
      final phoneNumber = userData.phoneNumber;
      final email = userData.email;
      
      _logger.i('📱 phoneNumber: $phoneNumber');
      _logger.i('📧 email: $email');
      
      final isAdminByPhone = phoneNumber != null && adminPhones.contains(phoneNumber);
      final isAdminByEmail = email != null && adminEmails.contains(email);
      
      if (isAdminByPhone || isAdminByEmail) {
        _logger.i("✅ المستخدم لديه صلاحيات مشرف (Super Admin)");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdmin', true);
        await prefs.setString('adminRole', 'super_admin');
        
        _currentAdmin = AdminModel(
          phoneNumber: phoneNumber ?? '',
          role: AdminRole.superAdmin,
          name: userData.name ?? 'المدير العام',
          assignedAt: DateTime.now(),
          permissions: RolePermissions.getPermissionsForRole(AdminRole.superAdmin),
          isActive: true,
        );
        notifyListeners();
        return;
      }

      _currentAdmin = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdmin');
      await prefs.remove('adminRole');
      
    } catch (e) {
      _logger.e('❌ خطأ أثناء التحقق من صلاحية المشرف: $e');
      _currentAdmin = null;
    }
  }

  bool hasPermission(String permission) {
    if (_currentAdmin == null) return false;
    return RolePermissions.hasPermission(_currentAdmin!.role, permission);
  }

  Future<void> loadAdminFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdminCached = prefs.getBool('isAdmin') ?? false;
    if (isAdminCached) {
      final roleString = prefs.getString('adminRole') ?? 'viewer_admin';
      final role = AdminRoleExtension.fromApiValue(roleString);
      _currentAdmin = AdminModel(
        phoneNumber: '',
        role: role,
        name: '',
        assignedAt: DateTime.now(),
        permissions: RolePermissions.getPermissionsForRole(role),
        isActive: true,
      );
      notifyListeners();
    }
  }

  Future<bool> checkIfAdmin(String phoneNumber) async {
    final user = await _supabase.getUserByPhone(phoneNumber);
    if (user != null) {
      await _checkAdminStatus(user.authId);
    }
    return isAdmin;
  }

  Future<bool> authenticateWithBiometrics() async {
    final isPro = _appController.isPro;
    if (!isPro) {
      _logger.w('⚠️ مصادقة البصمة متاحة فقط للمستخدمين Pro');
      return false;
    }

    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        _logger.w('⚠️ الجهاز لا يدعم المصادقة البيومترية');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'تحقق من هويتك لفتح التطبيق',
      );

      return isAuthenticated;
    } catch (e) {
      _logger.e('❌ فشل المصادقة البيومترية: $e');
      return false;
    }
  }

  Future<String?> getMyFingerprint() async {
    final user = currentUser;
    if (user == null) return null;
    final keyService = KeyExchangeService();
    final pair = await keyService.getIdentityKeyPair(user.id);
    final pub = await pair.extractPublicKey();
    return await KeyExchangeService.pubFingerprint(pub.bytes, bytes: 16);
  }
}
// controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../main.dart';
import 'app_controller.dart';
import '../services/api/auth_service.dart';
import '../services/quantum_resistant_service.dart';
import 'lifetime_users.dart';
import '../models/admin_model.dart';
import '../core/permissions.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref: ref);
});

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;
  final Logger _logger = logger;
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthController({required Ref ref}) : _ref = ref;

  // Verification id for phone auth (not referenced directly)
  bool isLoading = false;
  
  // ✅ متغيرات المشرف
  AdminModel? _currentAdmin;
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isAdmin => _currentAdmin != null && _currentAdmin!.isActive;
  bool get isSuperAdmin => _currentAdmin?.role == AdminRole.superAdmin;

  AppController get _appController => _ref.read(appControllerProvider);

  Future<void> sendOTP(String phoneNumber) async {
    isLoading = true;
    notifyListeners();
    final ok = await _authService.sendOTP(phoneNumber);
    isLoading = false;
    notifyListeners();
    if (!ok) _logger.w("❌ فشل إرسال OTP");
  }

  Future<void> verifyOTP(String smsCode) async {
    isLoading = true;
    notifyListeners();
    final ok = await _authService.verifyOTP(smsCode);
    if (ok) {
      final user = _auth.currentUser;
      final phoneNumber = user?.phoneNumber;
      await _generateQuantumKeys(user!.uid);
      await _checkLifetimeStatus(phoneNumber);
      await _checkAdminStatus(phoneNumber);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _generateQuantumKeys(String userId) async {
    try {
      await QuantumResistantService.generateKyberKeyPair(userId);
      await QuantumResistantService.generateDilithiumKeyPair(userId);
      logger.i('🔐 تم توليد المفاتيح الكمومية للمستخدم $userId');
    } catch (e) {
      logger.w('⚠️ فشل توليد المفاتيح الكمومية: $e');
    }
  }

  Future<void> signInWithKeys(String userId) async {
    isLoading = true;
    notifyListeners();
    final uid = await _authService.signInWithKeys(userId);
    if (uid != null) {
      await _generateQuantumKeys(uid);
      await _checkLifetimeStatus(uid);
      _logger.i("✅ تسجيل دخول بالمفاتيح فقط: $uid");
    } else {
      _logger.e("❌ فشل تسجيل الدخول بالمفاتيح");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<String?> getMyFingerprint() async {
    return await _authService.getMyFingerprint();
  }

  Future<bool> verifyPeerFingerprint(String peerId, String expectedFingerprint) async {
    return await _authService.verifyPeerFingerprint(peerId, expectedFingerprint);
  }

  Future<void> saveProfile(String name, String status, {String avatarUrl = ""}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'phone': user.phoneNumber,
        'avatarUrl': avatarUrl,
        'isOnline': true,
        'status': status,
        'lastSeen': DateTime.now(),
      }, SetOptions(merge: true));
      _logger.d('✅ تم حفظ الملف الشخصي للمستخدم: ${user.uid}');
    } catch (e) {
      _logger.e('❌ خطأ أثناء حفظ الملف الشخصي: $e');
    }
  }

  Future<void> logout() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await QuantumResistantService.deleteQuantumKeys(userId);
      }
      await _auth.signOut();
      await _appController.updateSubscriptionStatus(isPro: false, isLifetime: false);
      _logger.d('✅ تم تسجيل الخروج');
    } catch (e) {
      _logger.e('❌ خطأ أثناء تسجيل الخروج: $e');
    }
  }

  Future<bool> checkIfAdminLocal(String phoneNumber) async {
    return adminPhones.contains(phoneNumber);
  }

  Future<bool> checkIfLifetimeUserLocal(String phoneNumber) async {
    return lifetimePhones.contains(phoneNumber);
  }

  Future<void> _checkLifetimeStatus(String? phoneNumber) async {
    if (phoneNumber == null) return;

    if (lifetimePhones.contains(phoneNumber)) {
      await _appController.updateSubscriptionStatus(isPro: true, isLifetime: true);
      _logger.i("✅ تم تفعيل اشتراك مدى الحياة للمستخدم $phoneNumber");
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('licenses')
          .doc('mando_lifetime')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final owner = data['owner'];
        final family = List<String>.from(data['family'] ?? []);
        final bool isFirestoreLifetime = phoneNumber == owner || family.contains(phoneNumber);
        
        if (isFirestoreLifetime) {
          await _appController.updateSubscriptionStatus(isPro: true, isLifetime: true);
          _logger.i("✅ تم تفعيل اشتراك مدى الحياة للمستخدم $phoneNumber (من Firestore)");
          return;
        }
      }
    } catch (e) {
      _logger.e('❌ خطأ أثناء التحقق من Firestore: $e');
    }

    final token = await _auth.currentUser?.getIdToken() ?? '';
    if (token.isNotEmpty) {
      await _appController.fetchAndVerifyUserStatus(token);
    }
  }

  // ✅ دالة التحقق من صلاحية المشرف (معدلة لدعم الأدوار)
  Future<void> _checkAdminStatus(String? phoneNumber) async {
    if (phoneNumber == null) return;

    // التحقق من القائمة الثابتة أولاً
    if (adminPhones.contains(phoneNumber)) {
      _logger.i("✅ المستخدم $phoneNumber لديه صلاحيات مشرف (Super Admin)");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', true);
      await prefs.setString('adminRole', 'super_admin');
      
      // إنشاء كائن المشرف
      _currentAdmin = AdminModel(
        phoneNumber: phoneNumber,
        role: AdminRole.superAdmin,
        name: 'المدير العام',
        assignedAt: DateTime.now(),
        permissions: RolePermissions.getPermissionsForRole(AdminRole.superAdmin),
        isActive: true,
      );
      notifyListeners();
      return;
    }

    // التحقق من Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(phoneNumber)
          .get();
          
      if (doc.exists) {
        _currentAdmin = AdminModel.fromMap(doc.data()!);
        _logger.i("✅ المستخدم $phoneNumber لديه صلاحيات مشرف: ${_currentAdmin!.role.displayName}");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdmin', true);
        await prefs.setString('adminRole', _currentAdmin!.role.apiValue);
        notifyListeners();
      } else {
        _currentAdmin = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isAdmin');
        await prefs.remove('adminRole');
      }
    } catch (e) {
      _logger.e('❌ خطأ أثناء التحقق من صلاحية المشرف: $e');
      _currentAdmin = null;
    }
  }

  // ✅ دالة التحقق من الصلاحية (للاستخدام في الشاشات)
  bool hasPermission(String permission) {
    if (_currentAdmin == null) return false;
    return RolePermissions.hasPermission(_currentAdmin!.role, permission);
  }

  // ✅ دالة الحصول على بيانات المشرف من التخزين المحلي (للسرعة)
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

  // ✅ دالة التحقق من المشرف (للاستخدام في FutureBuilder)
  Future<bool> checkIfAdmin(String phoneNumber) async {
    await _checkAdminStatus(phoneNumber);
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

  User? get currentUser => _auth.currentUser;
}
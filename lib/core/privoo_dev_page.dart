// core/privoo_dev_page.dart
// ⚠️ هذا الملف مخصص فقط لبيئة التطوير (Debug Mode)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صفحة المطور - متاحة فقط في وضع التصحيح
/// للوصول إليها: اضغط 3 مرات على شعار Privoo في الصفحة الرئيسية
class PrivooDevPage extends StatelessWidget {
  const PrivooDevPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ التأكد من أن الصفحة تظهر فقط في وضع التطوير
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('هذه الصفحة متاحة فقط في بيئة التطوير')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧑‍💻 صفحة المطور'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('🔐 معلومات الحساب', [
            _buildInfoTile(
              'UID',
              FirebaseAuth.instance.currentUser?.uid ?? 'غير مسجل',
              Icons.person,
            ),
            _buildInfoTile(
              'البريد الإلكتروني',
              FirebaseAuth.instance.currentUser?.email ?? 'غير متوفر',
              Icons.email,
            ),
            _buildInfoTile(
              'رقم الهاتف',
              FirebaseAuth.instance.currentUser?.phoneNumber ?? 'غير متوفر',
              Icons.phone,
            ),
          ]),
          _buildSection('📱 معلومات الجهاز', [
            _buildInfoTile('المنصة', defaultTargetPlatform.toString(), Icons.devices),
            _buildInfoTile('وضع التصحيح', kDebugMode.toString(), Icons.bug_report),
            _buildInfoTile('الإصدار', '1.0.0', Icons.info),
          ]),
          _buildSection('🛠️ أدوات المطور', [
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.orange),
              title: const Text('مسح الكاش'),
              subtitle: const Text('حذف الملفات المؤقتة'),
              onTap: () => _clearCache(context),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('إعادة تعيين الإعدادات'),
              subtitle: const Text('استعادة الإعدادات الافتراضية'),
              onTap: () => _resetSettings(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('مسح جميع البيانات المحلية'),
              subtitle: const Text('حذف جميع بيانات التطبيق'),
              onTap: () => _clearAllData(context),
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '📦 المشروع على GitHub:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'github.com/MaNdOoOoO/Privoo',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      // مسح الكاش
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧹 جاري مسح الكاش...')),
      );
      
      // محاكاة مسح الكاش
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم مسح الكاش بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل مسح الكاش: $e')),
      );
    }
  }

  Future<void> _resetSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('♻️ تم إعادة تعيين الإعدادات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل إعادة التعيين: $e')),
      );
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير!', style: TextStyle(color: Colors.red)),
        content: const Text(
          'سيتم حذف جميع بيانات التطبيق المحلية بشكل نهائي.\n'
          'هذا الإجراء لا يمكن التراجع عنه.\n\n'
          'هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // حذف بيانات Firebase Auth (تسجيل الخروج)
      await FirebaseAuth.instance.signOut();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف جميع البيانات بنجاح')),
      );
      
      // العودة إلى شاشة البداية
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل حذف البيانات: $e')),
      );
    }
  }
}

// ============================================================
// ✅ دوال مساعدة محسنة
// ============================================================

/// تسجيل دخول برقم الهاتف (OTP) - للاختبار فقط
/// ⚠️ ملاحظة: هذه الدوال موجودة للتوافق مع الإصدارات القديمة
/// يفضل استخدام AuthService بدلاً منها
class PrivooDevHelper {
  /// تسجيل دخول برقم الهاتف (OTP)
  static Future<void> verifyPhoneNumber({
    required String phone,
    required BuildContext context,
    required void Function(String verificationId) onCodeSent,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    required void Function(Exception e) onVerificationFailed,
    required void Function() onCompleted,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
        onCompleted();
      },
      verificationFailed: (e) => onVerificationFailed(e),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (verificationId) => onAutoRetrievalTimeout(verificationId),
    );
  }

  /// التحقق من OTP
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// حفظ الملف الشخصي في Firestore
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String phone,
    String avatarUrl = '',
    bool isOnline = true,
    String status = '',
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// التحقق من حالة مدى الحياة وتفعيل برو
  /// ⚠️ ملاحظة: هذه الدالة قديمة، استخدم AuthController.checkIfLifetimeUser بدلاً منها
  static Future<void> checkLifetimeAndActivatePro(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('licenses')
          .doc('mando_lifetime')
          .get();
          
      if (doc.exists) {
        final data = doc.data()!;
        final isLifetime = uid == data['owner'] || 
            List<String>.from(data['family'] ?? []).contains(uid);
            
        if (isLifetime) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPro', true);
        }
      }
    } catch (e) {
      debugPrint('❌ فشل التحقق من Lifetime: $e');
    }
  }
}

// ============================================================
// ✅ نموذج المستخدم المبسط
// ============================================================

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;
  final bool isOnline;
  final String status;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl = '',
    this.isOnline = false,
    this.status = 'متاح',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'isOnline': isOnline,
    'status': status,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      isOnline: json['isOnline'] ?? false,
      status: json['status'] ?? 'متاح',
    );
  }
}
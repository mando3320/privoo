// lib/views/auth/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../config/app_theme.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _cachedPhoneNumber;
  String? _cachedEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // ✅ جلب رقم الهاتف
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['phoneNumber'] != null) {
          _cachedPhoneNumber = doc.data()!['phoneNumber'];
        } else if (user.phoneNumber != null) {
          _cachedPhoneNumber = user.phoneNumber;
        }

        // ✅ جلب الإيميل
        if (user.email != null && user.email!.isNotEmpty) {
          _cachedEmail = user.email;
        } else if (doc.exists && doc.data()?['email'] != null) {
          _cachedEmail = doc.data()!['email'];
        }

        // ✅ جلب الاسم (لو موجود)
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _nameController.text = user.displayName!;
        } else if (doc.exists && doc.data()?['name'] != null) {
          _nameController.text = doc.data()!['name'];
        }

      } catch (e) {
        logger.e('❌ فشل جلب بيانات المستخدم: $e');
        if (user.phoneNumber != null) {
          _cachedPhoneNumber = user.phoneNumber;
        }
        if (user.email != null) {
          _cachedEmail = user.email;
        }
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.privooError : AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackbar("خطأ: يرجى تسجيل الدخول أولاً.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ✅ حفظ في Firestore (مع رقم الهاتف والإيميل)
      final Map<String, dynamic> data = {
        'name': name,
        'avatarUrl': '',
        'lastSeen': FieldValue.serverTimestamp(),
      };

      // ✅ أضف رقم الهاتف لو موجود
      if (_cachedPhoneNumber != null && _cachedPhoneNumber!.isNotEmpty) {
        data['phoneNumber'] = _cachedPhoneNumber;
      }

      // ✅ أضف الإيميل لو موجود
      if (_cachedEmail != null && _cachedEmail!.isNotEmpty) {
        data['email'] = _cachedEmail;
      } else if (user.email != null && user.email!.isNotEmpty) {
        data['email'] = user.email;
      }

      await _db.collection('users').doc(user.uid).set(data, SetOptions(merge: true));

      logger.i("✅ تم حفظ الملف الشخصي بنجاح: ${user.uid}");
      
      // ✅ التحقق من نجاح الحفظ
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        print('✅ تأكيد: المستند موجود في Firestore');
        print('📄 البيانات: ${doc.data()}');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      logger.e("❌ فشل حفظ الملف الشخصي: $e");
      _showSnackbar("فشل حفظ الملف الشخصي", isError: true);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إعداد الملف الشخصي"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.privooDeepPurple,
                    boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_add, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Privoo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.privooDeepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.privooLightPurple,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "أدخل اسمك لعرضه لأصدقائك في Privoo.", 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.privooDeepPurple,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    hintText: "ادخل اسمك كاملاً",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return "الاسم يجب أن يكون ثلاث أحرف على الأقل.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "حفظ ومتابعة",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

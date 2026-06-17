// lib/views/auth/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

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

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    
    final user = _auth.currentUser;
    if (user == null) {
      logger.e("❌ لا يوجد مستخدم مصادق حاليًا.");
      _showSnackbar("خطأ: يرجى تسجيل الدخول أولاً.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ✅ استخدم uid و phoneNumber عشان يتوافق مع القواعد
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'phoneNumber': user.phoneNumber ?? '',
        'avatarUrl': '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logger.i("✅ تم حفظ ملف المستخدم: ${user.uid}");

      if (mounted) {
        // ✅ استخدم /home بدلاً من /chat
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      logger.e("❌ فشل حفظ ملف المستخدم: $e");
      _showSnackbar("فشل حفظ الملف الشخصي. يرجى المحاولة مرة أخرى.", isError: true);
    } finally {
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
      appBar: AppBar(title: const Text("إعداد الملف الشخصي")),
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "أدخل اسمك لعرضه لأصدقائك في Privoo.", 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "الاسم",
                    hintText: "الاسم الكامل",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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

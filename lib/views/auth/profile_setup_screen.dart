// lib/views/auth/profile_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  File? _selectedImage;
  String? _cachedPhoneNumber;
  String? _cachedEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseService().currentUser;
    if (user != null) {
      try {
        final userData = await SupabaseService().getUser(user.id);
        if (userData != null) {
          if (userData.phoneNumber != null) {
            _cachedPhoneNumber = userData.phoneNumber;
          }
          if (userData.email != null) {
            _cachedEmail = userData.email;
          }
          if (userData.name != null && userData.name!.isNotEmpty) {
            _nameController.text = userData.name!;
          }
        }
      } catch (e) {
        logger.e('❌ فشل جلب بيانات المستخدم: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      print('❌ فشل اختيار الصورة: $e');
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
    
    final user = SupabaseService().currentUser;
    if (user == null) {
      _showSnackbar("خطأ: يرجى تسجيل الدخول أولاً.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = _selectedImage!.path;
      }

      await SupabaseService().updateUser(user.id, {
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'last_seen': DateTime.now().toIso8601String(),
      });

      logger.i("✅ تم حفظ الملف الشخصي بنجاح: ${user.id}");

      if (mounted) {
        setState(() => _isLoading = false);
        // ✅ استخدام pop بدلاً من pushReplacementNamed عشان مايروحش للـ Login
        Navigator.pop(context, true);
      }
    } catch (e) {
      logger.e("❌ فشل حفظ الملف الشخصي: $e");
      _showSnackbar("فشل حفظ الملف الشخصي: ${e.toString()}", isError: true);
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.privooLightPurple,
                      backgroundImage: _selectedImage != null 
                          ? FileImage(_selectedImage!) 
                          : null,
                      child: _selectedImage == null
                          ? Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "اضغط لتغيير الصورة",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
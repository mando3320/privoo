// lib/views/settings/change_name_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';

class ChangeNameScreen extends ConsumerStatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  ConsumerState<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends ConsumerState<ChangeNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _originalName;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  Future<void> _loadCurrentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final name = doc.data()?['name'] ?? user.displayName ?? '';
          setState(() {
            _originalName = name;
            _nameController.text = name;
          });
        } else {
          setState(() {
            _originalName = user.displayName ?? '';
            _nameController.text = user.displayName ?? '';
          });
        }
      } catch (e) {
        setState(() {
          _originalName = user.displayName ?? '';
          _nameController.text = user.displayName ?? '';
        });
      }
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      _showSnackbar('الرجاء إدخال الاسم', isError: true);
      return;
    }
    
    if (newName.length < 3) {
      _showSnackbar('الاسم يجب أن يكون 3 أحرف على الأقل', isError: true);
      return;
    }
    
    if (newName == _originalName) {
      _showSnackbar('الاسم لم يتغير', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      // تحديث في Firebase Auth
      await user.updateDisplayName(newName);
      
      // تحديث في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackbar('✅ تم تغيير الاسم بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.privooError : AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
        title: const Text('تغيير الاسم'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // شعار
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(Icons.badge, size: 40, color: AppTheme.privooDeepPurple),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'تغيير الاسم الشخصي',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.privooDeepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا الاسم سيراه جميع جهات اتصالك',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            
            // حقل إدخال الاسم
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الجديد',
                hintText: 'أدخل اسمك الكامل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _nameController.clear(),
                      )
                    : null,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updateName(),
            ),
            
            const SizedBox(height: 32),
            
            // زر الحفظ
            ElevatedButton(
              onPressed: _isLoading ? null : _updateName,
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التغييرات', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 16),
            
            // زر إلغاء
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}
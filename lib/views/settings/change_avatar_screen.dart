// lib/views/settings/change_avatar_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class ChangeAvatarScreen extends ConsumerStatefulWidget {
  const ChangeAvatarScreen({super.key});

  @override
  ConsumerState<ChangeAvatarScreen> createState() => _ChangeAvatarScreenState();
}

class _ChangeAvatarScreenState extends ConsumerState<ChangeAvatarScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _currentAvatarUrl;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCurrentAvatar();
  }

  Future<void> _loadCurrentAvatar() async {
    final user = SupabaseService().currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle();
      
      if (response != null) {
        setState(() {
          _currentAvatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      // ✅ رفع الصورة إلى Supabase Storage
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';
      
      final response = await _supabase.storage
          .from('avatars')
          .upload(filePath, _selectedImage!);
      
      final downloadUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      // ✅ تحديث في Supabase
      await _supabase
          .from('users')
          .update({
            'avatar_url': downloadUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);
      
      if (mounted) {
        _showSnackbar('✅ تم تغيير الصورة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة الشخصية'),
        content: const Text('هل أنت متأكد من حذف صورتك الشخصية؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      await _supabase
          .from('users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.id);

      if (mounted) {
        _showSnackbar('✅ تم حذف الصورة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.privooDeepPurple),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.privooDeepPurple),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentAvatarUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.privooError),
                title: const Text('حذف الصورة'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تغيير الصورة الشخصية'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // صورة البروفايل
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                  ),
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                            ? NetworkImage(_currentAvatarUrl!)
                            : null),
                    child: (_selectedImage == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                        ? Icon(Icons.person, size: 70, color: AppTheme.privooDeepPurple)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.privooDeepPurple,
                      shape: BoxShape.circle,
                      boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                      onPressed: _isLoading ? null : _showImageSourceDialog,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'اضغط على أيقونة الكاميرا لتغيير صورتك',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'يُفضل استخدام صورة مربعة واضحة',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            
            const SizedBox(height: 32),
            
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadAvatar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
                    : const Text('رفع الصورة', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
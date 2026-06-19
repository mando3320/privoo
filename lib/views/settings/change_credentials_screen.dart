// lib/views/settings/change_credentials_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class ChangeCredentialsScreen extends ConsumerStatefulWidget {
  const ChangeCredentialsScreen({super.key});

  @override
  ConsumerState<ChangeCredentialsScreen> createState() => _ChangeCredentialsScreenState();
}

class _ChangeCredentialsScreenState extends ConsumerState<ChangeCredentialsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _currentEmail;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final user = SupabaseService().currentUser;
    if (user != null) {
      setState(() {
        _currentEmail = user.email;
        _emailController.text = user.email ?? '';
      });
    }
  }

  Future<void> _updateCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      _showSnackbar('الرجاء إدخال بريد إلكتروني أو كلمة مرور جديدة', isError: true);
      return;
    }

    if (password.isNotEmpty && password != confirm) {
      _showSnackbar('كلمة المرور غير متطابقة', isError: true);
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      _showSnackbar('كلمة المرور يجب أن تكون 6 أحرف على الأقل', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      // تحديث البريد الإلكتروني
      if (email.isNotEmpty && email != _currentEmail) {
        await _supabase.auth.updateUser(UserAttributes(email: email));
        await _supabase
            .from('users')
            .update({'email': email})
            .eq('uid', user.id);
        _showSnackbar('✅ تم تحديث البريد الإلكتروني بنجاح');
      }

      // تحديث كلمة المرور
      if (password.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: password));
        _showSnackbar('✅ تم تغيير كلمة المرور بنجاح');
      }

      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تغيير بيانات الدخول'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                child: Icon(Icons.security, size: 40, color: AppTheme.privooDeepPurple),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'تغيير بيانات الدخول',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.privooDeepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تغيير بريدك الإلكتروني أو كلمة المرور',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // البريد الإلكتروني الحالي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 20, color: AppTheme.privooDeepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'البريد الحالي',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          _currentEmail ?? 'غير محدد',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // حقل البريد الإلكتروني الجديد
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني الجديد',
                hintText: 'example@domain.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // حقل كلمة المرور الجديدة
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                hintText: 'اختياري - اتركه فارغاً إذا لا تريد التغيير',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // حقل تأكيد كلمة المرور
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updateCredentials(),
            ),
            const SizedBox(height: 32),

            // زر الحفظ
            ElevatedButton(
              onPressed: _isLoading ? null : _updateCredentials,
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

            // ملاحظة أمنية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.privooGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.privooGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تغيير البريد الإلكتروني يتطلب تأكيد عبر رابط يُرسل إلى البريد الجديد',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
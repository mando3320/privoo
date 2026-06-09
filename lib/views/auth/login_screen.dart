// lib/views/auth/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool otpSent = false;
  bool isLoading = false;
  int attempts = 0;
  String? _errorMessage;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
  }

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldownSeconds <= 1) {
        t.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
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

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    
    // تحقق من رقم الهاتف
    if (phone.isEmpty) {
      _showSnackbar("📵 يرجى إدخال رقم الهاتف.", isError: true);
      return;
    }
    
    if (phone.length < 10) {
      _showSnackbar("📵 رقم الهاتف يجب أن يكون 10 أرقام على الأقل", isError: true);
      return;
    }
    
    if (_cooldownSeconds > 0) return;

    setState(() => isLoading = true);
    
    // عرض مؤشر تحميل مع رسالة
    final messenger = ScaffoldMessenger.of(context);
    final loadingSnack = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('جاري إرسال رمز التحقق إلى $phone...')),
        ],
      ),
      duration: const Duration(seconds: 10),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(loadingSnack);
    
    try {
      final auth = ref.read(authControllerProvider.notifier);
      await auth.sendOTP(phone);
      
      messenger.clearSnackBars();
      
      if (!mounted) return;
      setState(() => isLoading = false);
      
      // بعد إرسال الـ OTP، نعتبر أن العملية نجحت
      setState(() {
        otpSent = true;
      });
      _startCooldown(30);
      _showSnackbar("✅ تم إرسال رمز التحقق بنجاح.");
      
    } catch (e) {
      messenger.clearSnackBars();
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackbar("❌ خطأ في الاتصال: ${e.toString()}", isError: true);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (attempts >= 5) {
      _showSnackbar("⏳ تم تجاوز الحد. أعد إرسال الرمز بعد قليل.", isError: true);
      return;
    }

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackbar("🔑 رمز التحقق يجب أن يكون 6 أرقام.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final auth = ref.read(authControllerProvider.notifier);
      await auth.verifyOTP(otp);
      
      if (!mounted) return;
      setState(() => isLoading = false);

      // بعد التحقق، ننتقل إلى شاشة إعداد الملف الشخصي
      await _handleSuccessfulLogin();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          attempts += 1;
        });
        _showSnackbar("❌ رمز غير صحيح. المحاولات المتبقية: ${5 - attempts}", isError: true);
      }
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (mounted) {
      // مسح الـ navigation stack بالكامل
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/profile', 
        (route) => false
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار Privoo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.privooDeepPurple,
                  boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline, size: 50, color: Colors.white),
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
              ),
              const SizedBox(height: 40),
              
              if (!otpSent)
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: "مثال: 01208499976",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendOtp(),
                ),
              if (otpSent)
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'رمز التحقق',
                    hintText: "أدخل الرقم المكون من 6 أرقام",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verifyOtp(),
                ),
              const SizedBox(height: 30),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (!otpSent) {
                          _sendOtp();
                        } else {
                          _verifyOtp();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        otpSent
                          ? 'تحقق'
                          : (_cooldownSeconds > 0
                            ? 'إرسال ($_cooldownSeconds s)'
                            : 'إرسال'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
              if (otpSent)
                TextButton(
                  onPressed: () {
                    setState(() {
                      otpSent = false;
                      _otpController.clear();
                      attempts = 0;
                    });
                  },
                  child: const Text('تغيير الرقم'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
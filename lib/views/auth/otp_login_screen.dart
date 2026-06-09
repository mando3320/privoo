// lib/views/auth/otp_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'terms_acceptance_screen.dart';
import '../../config/app_theme.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  int _attempts = 0;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

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

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.trim();
    cleaned = cleaned.replaceAll(' ', '');
    cleaned = cleaned.replaceAll('-', '');
    cleaned = cleaned.replaceAll('(', '');
    cleaned = cleaned.replaceAll(')', '');
    
    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('0020')) {
      return '+20${cleaned.substring(4)}';
    }
    if (cleaned.startsWith('+20')) {
      return cleaned;
    }
    if (!cleaned.startsWith('+')) {
      return '+20$cleaned';
    }
    return cleaned;
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

  Future<void> _sendOTP() async {
    final rawPhone = _phoneController.text.trim();
    final phone = _formatPhoneNumber(rawPhone);
    
    if (phone.isEmpty) {
      _showSnackbar("📵 يرجى إدخال رقم الهاتف.", isError: true);
      return;
    }
    
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    if (!regex.hasMatch(phone)) {
      _showSnackbar("📵 رقم الهاتف غير صالح. مثال: 01234567890", isError: true);
      return;
    }
    
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
    
    final messenger = ScaffoldMessenger.of(context);
    final loadingSnack = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text('جاري إرسال رمز التحقق إلى $phone...')),
        ],
      ),
      duration: const Duration(seconds: 10),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(loadingSnack);
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            await _checkTermsAndNavigate();
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar("❌ فشل التحقق: ${e.message}", isError: true);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          _startCooldown(30);
          _showSnackbar("✅ تم إرسال رمز التحقق إلى $phone");
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showSnackbar("❌ تعذر إرسال الرمز. حاول لاحقًا.", isError: true);
    } finally {
      messenger.clearSnackBars();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_attempts >= 5) {
      _showSnackbar("⏳ تم تجاوز الحد. أعد إرسال الرمز بعد قليل.", isError: true);
      return;
    }
    
    if (_verificationId == null) {
      _showSnackbar("⚠️ أرسل رمز تحقق أولاً.", isError: true);
      return;
    }

    final code = _otpController.text.trim();
    if (code.length != 6) {
      _showSnackbar("🔑 رمز التحقق يجب أن يكون 6 أرقام.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _auth.signInWithCredential(credential);
      await _checkTermsAndNavigate();
    } catch (e) {
      setState(() {
        _attempts += 1;
      });
      _showSnackbar("❌ رمز غير صحيح. المحاولات المتبقية: ${5 - _attempts}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTermsAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final termsAccepted = prefs.getBool('terms_accepted') ?? false;
    
    if (!termsAccepted && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TermsAcceptanceScreen(
            onAccepted: () {
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
        ),
      );
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/profile');
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
    final resendTitle = _cooldownSeconds > 0 ? 'إرسال الرمز (${_cooldownSeconds}s)' : 'إرسال الرمز';

    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل الدخول برقم الهاتف"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
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
                child: Icon(Icons.phone_android, size: 50, color: Colors.white),
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
            
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "رقم الهاتف",
                hintText: "مثال: 01234567890",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOTP(),
            ),
            const SizedBox(height: 16),
            
            if (_codeSent)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: "رمز التحقق",
                  hintText: "أدخل الرقم المكون من 6 أرقام",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyOTP(),
              ),
              
            const SizedBox(height: 20),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _codeSent ? _verifyOTP : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _codeSent ? "تحقق" : resendTitle,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  
            if (_codeSent)
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
                          _verificationId = null;
                          _attempts = 0;
                        });
                      },
                child: const Text("تغيير الرقم"),
              ),
          ],
        ),
      ),
    );
  }
}
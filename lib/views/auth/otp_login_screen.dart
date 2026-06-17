// lib/views/auth/otp_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'terms_acceptance_screen.dart';

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

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    if (!regex.hasMatch(phone)) {
      _show("📵 رقم الهاتف غير صالح بصيغة E.164 (+20...)");
      return;
    }
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
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
          _show("❌ فشل التحقق: ${e.message}");
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          _startCooldown(30);
          _show("✅ تم إرسال رمز التحقق.");
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _show("❌ تعذر إرسال الرمز. حاول لاحقًا.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_attempts >= 5) {
      _show("⏳ تم تجاوز الحد. أعد إرسال الرمز بعد قليل.");
      return;
    }
    if (_verificationId == null) {
      _show("أرسل رمز تحقق أولًا.");
      return;
    }

    final code = _otpController.text.trim();
    if (code.length != 6) {
      _show("🔑 رمز التحقق يجب أن يكون 6 أرقام.");
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
      _attempts += 1;
      _show("❌ رمز غير صحيح. المحاولات المتبقية: ${5 - _attempts}");
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

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      appBar: AppBar(title: const Text("تسجيل الدخول برقم الهاتف")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "رقم الهاتف",
                hintText: "+20xxxxxxxxxx",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_codeSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: "رمز التحقق",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _codeSent ? _verifyOTP : _sendOTP,
                    child: Text(_codeSent ? "تحقق" : resendTitle),
                  ),
            if (_codeSent)
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
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

// lib/views/auth/otp_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'terms_acceptance_screen.dart';
import '../../config/app_theme.dart';
import '../../main.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  int _attempts = 0;
  int _loginMethod = 0; // 0 = Phone, 1 = Email

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

  String _formatEmail(String email) {
    return email.trim().toLowerCase();
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

  Future<void> _createUserInFirestore(User user, String identifier, String type) async {
    print('🔵🔵🔵 دالة _createUserInFirestore اتعملت 🔵🔵🔵');
    print('🆔 UID: ${user.uid}');
    print('$type: $identifier');
    
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'name': type == 'phone' ? identifier : identifier.split('@').first,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isActive': true,
        'avatarUrl': '',
        'about': 'مرحباً، أنا أستخدم Privoo',
      };
      
      if (type == 'phone') {
        userData['phoneNumber'] = identifier;
      } else {
        userData['email'] = identifier;
      }
      
      if (!doc.exists) {
        await userRef.set(userData);
        print('✅ تم إنشاء مستخدم جديد في Firestore: ${user.uid}');
      } else {
        // تحديث بيانات الدخول الجديدة
        await userRef.update(userData);
        print('✅ تم تحديث بيانات المستخدم: ${user.uid}');
      }
    } catch (e) {
      print('❌❌❌ فشل إنشاء المستخدم: $e ❌❌❌');
    }
  }

  // ==================== طرق تسجيل الدخول ====================
  
  // ✅ 1. تسجيل الدخول برقم الهاتف (SMS OTP)
  Future<void> _sendPhoneOTP() async {
    final rawPhone = _phoneController.text.trim();
    final phone = _formatPhoneNumber(rawPhone);
    
    if (phone.isEmpty) {
      _showSnackbar("📵 يرجى إدخال رقم الهاتف.", isError: true);
      return;
    }
    
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          await _createUserInFirestore(userCredential.user!, phone, 'phone');
          await _checkTermsAndNavigate();
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
      _showSnackbar("❌ تعذر إرسال الرمز.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPhoneOTP() async {
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
      final userCredential = await _auth.signInWithCredential(credential);
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      await _createUserInFirestore(userCredential.user!, phone, 'phone');
      await _checkTermsAndNavigate();
    } catch (e) {
      setState(() => _attempts += 1);
      _showSnackbar("❌ رمز غير صحيح.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ 2. تسجيل الدخول بالبريد الإلكتروني (Magic Link)
  Future<void> _sendMagicLink() async {
    final email = _formatEmail(_emailController.text.trim());
    
    if (email.isEmpty || !email.contains('@')) {
      _showSnackbar("📧 يرجى إدخال بريد إلكتروني صالح.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://privoo.page.link/login',
          handleCodeInApp: true,
          androidPackageName: 'com.mando.privoo',
          androidInstallApp: true,
          androidMinimumVersion: '1',
          iOSBundleId: 'com.mando.privoo',
        ),
      );
      
      _showSnackbar("✅ تم إرسال رابط سحري إلى $email!");
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_for_signin', email);
      
      setState(() {
        _codeSent = true;
        _loginMethod = 1;
      });
    } catch (e) {
      _showSnackbar("❌ فشل الإرسال: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMagicLink() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email_for_signin');
    
    if (email != null && _auth.isSignInWithEmailLink(_verificationId ?? '')) {
      try {
        final userCredential = await _auth.signInWithEmailLink(
          email: email,
          emailLink: _verificationId!,
        );
        await _createUserInFirestore(userCredential.user!, email, 'email');
        await _checkTermsAndNavigate();
      } catch (e) {
        print('❌ فشل التحقق من الرابط: $e');
      }
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
  void initState() {
    super.initState();
    _handleMagicLink();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneMethod = _loginMethod == 0;
    final resendTitle = _cooldownSeconds > 0 
        ? 'إرسال (${_cooldownSeconds}s)' 
        : (isPhoneMethod ? 'إرسال رمز التحقق' : 'إرسال رابط سحري');

    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل الدخول"),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildMethodButton(0, '📱 رقم الهاتف', Icons.phone),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMethodButton(1, '📧 البريد الإلكتروني', Icons.email),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.privooDeepPurple,
                boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
              ),
              child: Center(
                child: Icon(
                  _loginMethod == 0 ? Icons.phone_android : Icons.email,
                  size: 50,
                  color: Colors.white,
                ),
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
            
            // الحقل حسب الطريقة المختارة
            if (_loginMethod == 0 && !_codeSent)
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
              ),
              
            if (_loginMethod == 1 && !_codeSent)
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "البريد الإلكتروني",
                  hintText: "example@domain.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
            if (_codeSent)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: _loginMethod == 0 ? "رمز التحقق" : "رمز التحقق (اختياري)",
                  hintText: "أدخل الرمز المكون من 6 أرقام",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              
            const SizedBox(height: 20),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      if (!_codeSent) {
                        if (_loginMethod == 0) {
                          _sendPhoneOTP();
                        } else {
                          _sendMagicLink();
                        }
                      } else {
                        if (_loginMethod == 0) {
                          _verifyPhoneOTP();
                        } else {
                          // للبريد الإلكتروني، الرابط السحري لا يحتاج OTP
                          _showSnackbar("⚠️ اضغط على الرابط المرسل إلى بريدك");
                        }
                      }
                    },
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
                  
            if (_codeSent && _loginMethod == 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _otpController.clear();
                    _verificationId = null;
                    _attempts = 0;
                  });
                },
                child: const Text("تغيير رقم الهاتف"),
              ),
              
            if (_loginMethod == 1 && !_codeSent)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'سيتم إرسال رابط سحري إلى بريدك الإلكتروني',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMethodButton(int method, String label, IconData icon) {
    final isSelected = _loginMethod == method;
    return GestureDetector(
      onTap: () {
        if (!_isLoading) {
          setState(() {
            _loginMethod = method;
            _codeSent = false;
            _otpController.clear();
            _verificationId = null;
            _attempts = 0;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.privooLightPurple 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? AppTheme.privooLightPurple 
                : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

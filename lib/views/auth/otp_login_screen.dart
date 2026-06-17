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

class _OTPLoginScreenState extends State<OTPLoginScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // ✅ State
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  int _attempts = 0;
  int _selectedTab = 0; // 0 = هاتف, 1 = إيميل
  bool _isLogin = true; // true = تسجيل دخول, false = إنشاء حساب

  // ✅ Country
  String _selectedCountryCode = '+20';
  String _selectedCountryFlag = '🇪🇬';
  String _selectedCountryName = 'مصر';

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  // ✅ Countries list
  final List<Map<String, String>> _allCountries = [
    {'code': '+20', 'flag': '🇪🇬', 'name': 'مصر'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'السعودية'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'الإمارات'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'قطر'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'الكويت'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'البحرين'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'عمان'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'الأردن'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'لبنان'},
    {'code': '+963', 'flag': '🇸🇾', 'name': 'سوريا'},
    {'code': '+970', 'flag': '🇵🇸', 'name': 'فلسطين'},
    {'code': '+964', 'flag': '🇮🇶', 'name': 'العراق'},
    {'code': '+967', 'flag': '🇾🇪', 'name': 'اليمن'},
    {'code': '+93', 'flag': '🇦🇫', 'name': 'أفغانستان'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'الهند'},
    {'code': '+92', 'flag': '🇵🇰', 'name': 'باكستان'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'تركيا'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'الولايات المتحدة'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'بريطانيا'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'ألمانيا'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'فرنسا'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'إيطاليا'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'إسبانيا'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'روسيا'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'الصين'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'اليابان'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'البرازيل'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'أستراليا'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'جنوب أفريقيا'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'الجزائر'},
    {'code': '+212', 'flag': '🇲🇦', 'name': 'المغرب'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'تونس'},
    {'code': '+218', 'flag': '🇱🇾', 'name': 'ليبيا'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'السودان'},
  ];

  List<Map<String, String>> _filteredCountries = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = _allCountries;
    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = _allCountries.where((country) {
        return country['name']!.toLowerCase().contains(query) ||
            country['code']!.contains(query);
      }).toList();
    });
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

  String _getFullPhoneNumber() {
    String localNumber = _phoneController.text.trim();
    localNumber = localNumber.replaceAll(' ', '');
    localNumber = localNumber.replaceAll('-', '');
    localNumber = localNumber.replaceAll('(', '');
    localNumber = localNumber.replaceAll(')', '');
    
    while (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    
    return '$_selectedCountryCode$localNumber';
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

  // ============================================================
  // 📱 Phone Auth
  // ============================================================

  Future<bool> _saveUserToFirestore(User user, String phoneNumber) async {
    print('📝 حفظ المستخدم في Firestore: ${user.uid}');
    print('📞 الهاتف: $phoneNumber');
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': phoneNumber,
        'phoneNumber': phoneNumber,
        'avatarUrl': '',
        'about': 'مرحباً، أنا أستخدم Privoo',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم حفظ المستخدم بنجاح');
      return true;
      
    } on FirebaseException catch (e) {
      print('❌ FirebaseException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      return false;
    }
  }

  Future<void> _sendOTP() async {
    final localNumber = _phoneController.text.trim();
    
    if (localNumber.isEmpty) {
      _showSnackbar("📵 يرجى إدخال رقم الهاتف.", isError: true);
      return;
    }
    
    if (localNumber.length < 6) {
      _showSnackbar("📵 رقم الهاتف يجب أن يكون 6 أرقام على الأقل", isError: true);
      return;
    }
    
    if (_cooldownSeconds > 0) return;

    final fullPhoneNumber = _getFullPhoneNumber();
    setState(() => _isLoading = true);
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final success = await _saveUserToFirestore(userCredential.user!, fullPhoneNumber);
            if (success && mounted) {
              await _checkTermsAndNavigate();
            }
          } catch (e) {
            print('❌ verificationCompleted error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar("❌ فشل التحقق: ${e.message}", isError: true);
          setState(() => _isLoading = false);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
          _startCooldown(30);
          _showSnackbar("✅ تم إرسال رمز التحقق إلى $fullPhoneNumber");
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showSnackbar("❌ تعذر إرسال الرمز: $e", isError: true);
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
      print('⏳ جاري التحقق من الرمز...');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ تم تسجيل الدخول: ${userCredential.user?.uid}');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      print('👤 Current user: ${currentUser?.uid}');
      
      final fullPhoneNumber = _getFullPhoneNumber();
      
      final success = await _saveUserToFirestore(userCredential.user!, fullPhoneNumber);
      
      if (!success) {
        _showSnackbar("❌ فشل حفظ البيانات، حاول مرة أخرى.", isError: true);
        return;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      print('📄 المستند موجود؟ ${doc.exists}');
      if (doc.exists) {
        print('📄 البيانات: ${doc.data()}');
      } else {
        print('⚠️ المستند غير موجود بعد الحفظ!');
        _showSnackbar("⚠️ حدث خطأ في حفظ البيانات.", isError: true);
        return;
      }
      
      if (mounted) {
        await _checkTermsAndNavigate();
      }
      
    } catch (e) {
      print('❌ خطأ في التحقق: $e');
      setState(() => _attempts += 1);
      _showSnackbar("❌ رمز غير صحيح. المحاولات المتبقية: ${5 - _attempts}", isError: true);
      
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'البحث عن دولة...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        return ListTile(
                          leading: Text(country['flag']!, style: const TextStyle(fontSize: 28)),
                          title: Text(country['name']!),
                          trailing: Text(country['code']!, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          onTap: () {
                            setState(() {
                              _selectedCountryCode = country['code']!;
                              _selectedCountryFlag = country['flag']!;
                              _selectedCountryName = country['name']!;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ✉️ Email Auth
  // ============================================================

  Future<void> _emailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('يرجى ملء جميع الحقول', isError: true);
      return;
    }

    if (!_isLogin && password.length < 6) {
      _showSnackbar('كلمة المرور يجب أن تكون 6 أحرف على الأقل', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential;

      if (_isLogin) {
        // ✅ تسجيل دخول
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // ✅ إنشاء حساب جديد
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final name = _nameController.text.trim();
        if (name.isNotEmpty) {
          await userCredential.user!.updateDisplayName(name);
        }
      }

      // ✅ حفظ الجلسة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_uid', userCredential.user!.uid);

      _showSnackbar(_isLogin ? '✅ تم تسجيل الدخول' : '✅ تم إنشاء الحساب');

      if (mounted) {
        await _checkTermsAndNavigate();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ';
      if (e.code == 'user-not-found') message = '❌ المستخدم غير موجود';
      else if (e.code == 'wrong-password') message = '❌ كلمة المرور غير صحيحة';
      else if (e.code == 'email-already-in-use') message = '❌ الإيميل مستخدم بالفعل';
      else if (e.code == 'weak-password') message = '❌ كلمة المرور ضعيفة';
      else if (e.code == 'invalid-email') message = '❌ إيميل غير صالح';
      _showSnackbar(message, isError: true);
    } catch (e) {
      _showSnackbar('❌ حدث خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🚀 Navigation
  // ============================================================

  Future<void> _checkTermsAndNavigate() async {
    print('🔍 بدء التوجيه...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool('terms_accepted') ?? false;
      
      print('📝 termsAccepted: $termsAccepted');
      
      if (!termsAccepted && mounted) {
        print('🚀 التوجيه إلى TermsAcceptanceScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TermsAcceptanceScreen(
              onAccepted: () {
                print('✅ تم قبول الشروط، التوجيه إلى Profile');
                Navigator.pushReplacementNamed(context, '/profile');
              },
            ),
          ),
        );
      } else if (mounted) {
        print('🚀 التوجيه مباشرة إلى Profile');
        Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (e) {
      print('❌ خطأ في _checkTermsAndNavigate: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resendTitle = _cooldownSeconds > 0 
        ? 'إرسال الرمز (${_cooldownSeconds}s)' 
        : 'إرسال رمز التحقق';

    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل الدخول"),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          indicatorColor: AppTheme.privooGold,
          labelColor: AppTheme.privooGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.phone), text: 'رقم الهاتف'),
            Tab(icon: Icon(Icons.email), text: 'الإيميل'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _selectedTab == 0 
            ? _buildPhoneAuth(resendTitle)
            : _buildEmailAuth(),
      ),
    );
  }

  // ============================================================
  // 📱 Phone Auth Widget
  // ============================================================

  Widget _buildPhoneAuth(String resendTitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.privooDeepPurple,
            boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
          ),
          child: const Center(
            child: Icon(Icons.phone_android, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'رقم الهاتف',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.privooDeepPurple),
        ),
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(_selectedCountryFlag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 4),
                    Text(_selectedCountryCode, style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف",
                  hintText: "مثال: 123456789",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendOTP(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$_selectedCountryName • ${_selectedCountryFlag} $_selectedCountryCode',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          
        const SizedBox(height: 16),
        Text(
          'سيتم إرسال رمز تحقق عن طريق رسالة نصية إلى رقم هاتفك',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // ✉️ Email Auth Widget
  // ============================================================

  Widget _buildEmailAuth() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isLogin ? Icons.login : Icons.person_add,
          size: 60,
          color: AppTheme.privooDeepPurple,
        ),
        const SizedBox(height: 16),
        Text(
          _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.privooDeepPurple,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'example@email.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور',
            hintText: '********',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),

        if (!_isLogin)
          Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'أدخل اسمك',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _emailSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLogin
                  ? 'ليس لديك حساب؟'
                  : 'لديك حساب بالفعل؟',
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                style: TextStyle(color: AppTheme.privooGold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

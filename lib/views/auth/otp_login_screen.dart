// lib/views/auth/otp_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'terms_acceptance_screen.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../controllers/app_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OTPLoginScreen extends ConsumerStatefulWidget {
  const OTPLoginScreen({super.key});

  @override
  ConsumerState<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends ConsumerState<OTPLoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  int _attempts = 0;
  int _selectedTab = 0;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedCountryCode = '+20';
  String _selectedCountryFlag = '🇪🇬';
  String _selectedCountryName = 'مصر';

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  final List<Map<String, String>> _languages = [
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
  ];

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
  final TextEditingController _searchController = TextEditingController();

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
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: isError ? AppTheme.privooError : AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _changeLanguage(String code, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    
    final appController = ref.read(appControllerProvider.notifier);
    appController.updateLanguage(code);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OTPLoginScreen()),
      );
    }
    
    _showSnackbar('✅ تم تغيير اللغة إلى $name');
  }

  Future<void> _sendOTP() async {
    final phone = _getFullPhoneNumber();
    
    if (phone.isEmpty) {
      _showSnackbar("📵 يرجى إدخال رقم الهاتف.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await SupabaseService().signInWithOTP(phone);
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      _startCooldown(30);
      _showSnackbar("✅ تم إرسال رمز التحقق إلى $phone");
    } catch (e) {
      _showSnackbar("❌ فشل الإرسال: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_attempts >= 5) {
      _showSnackbar("⏳ تم تجاوز الحد. أعد إرسال الرمز بعد قليل.", isError: true);
      return;
    }

    final code = _otpController.text.trim();
    final phone = _getFullPhoneNumber();
    
    if (code.length != 6) {
      _showSnackbar("🔑 رمز التحقق يجب أن يكون 6 أرقام.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService().verifyOTP(phone, code);
      final user = response.user;
      
      if (user == null) {
        _showSnackbar("❌ فشل التحقق", isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      await SupabaseService().createUser(UserModel(
        id: user.id,
        authId: user.id,
        name: phone,
        phoneNumber: phone,
        isActive: true,
        createdAt: DateTime.now(),
      ));
      
      _showSnackbar("✅ تم تسجيل الدخول بنجاح");
      
      if (mounted) {
        await _checkTermsAndNavigate();
      }
    } catch (e) {
      _showSnackbar("❌ رمز غير صحيح: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _emailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('يرجى ملء جميع الحقول', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackbar('❌ البريد الإلكتروني غير صالح', isError: true);
      return;
    }

    if (!_isLogin && password.length < 6) {
      _showSnackbar('❌ كلمة المرور يجب أن تكون 6 أحرف على الأقل', isError: true);
      return;
    }

    if (!_isLogin && password != confirmPassword) {
      _showSnackbar('❌ كلمة المرور غير متطابقة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final response = await SupabaseService().signInWithEmail(email, password);
        final user = response.user;
        
        if (user != null) {
          _showSnackbar('✅ تم تسجيل الدخول بنجاح');
          if (mounted) {
            await _checkTermsAndNavigate();
          }
        } else {
          _showSnackbar('❌ فشل تسجيل الدخول', isError: true);
        }
      } else {
        final response = await SupabaseService().signUpWithEmail(email, password);
        final user = response.user;
        
        if (user != null) {
          final name = _nameController.text.trim();
          
          await SupabaseService().createUser(UserModel(
            id: user.id,
            authId: user.id,
            name: name.isNotEmpty ? name : email.split('@').first,
            phoneNumber: null,
            email: email,
            isActive: true,
            createdAt: DateTime.now(),
          ));
          
          _showSnackbar('✅ تم إنشاء الحساب بنجاح');
          if (mounted) {
            await _checkTermsAndNavigate();
          }
        } else {
          _showSnackbar('❌ فشل إنشاء الحساب', isError: true);
        }
      }
    } catch (e) {
      _showSnackbar('❌ حدث خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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

  void _showCountryPicker() {
    final theme = Theme.of(context);
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
                        fillColor: theme.colorScheme.surface.withValues(alpha: 0.05),
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
                          title: Text(country['name']!, style: TextStyle(color: theme.colorScheme.onSurface)),
                          trailing: Text(country['code']!, 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _searchController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ✅ ============================================================
  // ✅ BUILD - استخدام ألوان الثيم مباشرة
  // ✅ ============================================================
  
  @override
  Widget build(BuildContext context) {
    final resendTitle = _cooldownSeconds > 0 
        ? 'إرسال الرمز (${_cooldownSeconds}s)' 
        : 'إرسال رمز التحقق';
    
    final currentLocale = ref.watch(appControllerProvider).locale;
    final currentLanguage = _languages.firstWhere(
      (lang) => lang['code'] == currentLocale.languageCode,
      orElse: () => _languages.first,
    );

    // ✅ استخدام ألوان الثيم مباشرة
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final backgroundColor = colorScheme.surface;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "تسجيل الدخول",
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        actions: [
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currentLanguage['flag'] ?? '🌐', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: textColor),
              ],
            ),
            onSelected: (code) {
              final selected = _languages.firstWhere((lang) => lang['code'] == code);
              _changeLanguage(code, selected['name']!);
            },
            itemBuilder: (context) => _languages.map((lang) {
              return PopupMenuItem<String>(
                value: lang['code'],
                child: Row(
                  children: [
                    Text(lang['flag'] ?? '🌐', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(lang['name']!, style: TextStyle(color: colorScheme.onSurface)),
                    if (lang['code'] == currentLocale.languageCode)
                      const Spacer(),
                    if (lang['code'] == currentLocale.languageCode)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.phone), text: '📱 رقم الهاتف'),
            Tab(icon: Icon(Icons.email), text: '✉️ الإيميل'),
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

  // ✅ ============================================================
  // ✅ PHONE AUTH - استخدام ألوان آمنة متوافقة مع كل الثيمات
  // ✅ ============================================================
  
  Widget _buildPhoneAuth(String resendTitle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // ✅ ألوان آمنة متوافقة مع كل الثيمات
    final textColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final primaryColor = colorScheme.primary;
    final borderColor = colorScheme.outline ?? Colors.grey.withValues(alpha: 0.3);
    final fillColor = colorScheme.surface.withValues(alpha: 0.05);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
            boxShadow: [AppTheme.mainShadow(primaryColor)],
          ),
          child: Center(
            child: Icon(Icons.phone_android, size: 40, color: colorScheme.onPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '📱 تسجيل الدخول برقم الهاتف',
          style: textTheme.titleLarge?.copyWith(
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيتم إرسال رمز تحقق إلى رقم هاتفك',
          style: textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
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
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(_selectedCountryFlag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountryCode, 
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    Icon(Icons.arrow_drop_down, size: 20, color: textColor),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "رقم الهاتف",
                  hintText: "مثال: 123456789",
                  labelStyle: TextStyle(color: secondaryTextColor),
                  hintStyle: TextStyle(color: secondaryTextColor),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.phone, color: secondaryTextColor),
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
          style: TextStyle(
            fontSize: 12, 
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_codeSent)
          TextField(
            controller: _otpController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: "رمز التحقق",
              hintText: "أدخل الرقم المكون من 6 أرقام",
              labelStyle: TextStyle(color: secondaryTextColor),
              hintStyle: TextStyle(color: secondaryTextColor),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.lock, color: secondaryTextColor),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyOTP(),
          ),
          
        const SizedBox(height: 20),
        
        _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : ElevatedButton(
                onPressed: _codeSent ? _verifyOTP : _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _codeSent ? "🔑 تحقق" : resendTitle,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              
        if (_codeSent)
          TextButton(
            onPressed: () {
              setState(() {
                _codeSent = false;
                _otpController.clear();
                _attempts = 0;
              });
            },
            child: Text(
              "تغيير رقم الهاتف",
              style: TextStyle(color: primaryColor),
            ),
          ),
          
        const SizedBox(height: 16),
        Text(
          'سيتم إرسال رمز تحقق عن طريق رسالة نصية إلى رقم هاتفك',
          style: TextStyle(
            fontSize: 12, 
            color: secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ ============================================================
  // ✅ EMAIL AUTH - استخدام ألوان آمنة متوافقة مع كل الثيمات
  // ✅ ============================================================
  
  Widget _buildEmailAuth() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // ✅ ألوان آمنة متوافقة مع كل الثيمات
    final textColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final primaryColor = colorScheme.primary;
    final fillColor = colorScheme.surface.withValues(alpha: 0.05);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
            boxShadow: [AppTheme.mainShadow(primaryColor)],
          ),
          child: Center(
            child: Icon(Icons.email, size: 40, color: colorScheme.onPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isLogin ? '✉️ تسجيل الدخول بالإيميل' : '✉️ إنشاء حساب جديد',
          style: textTheme.titleLarge?.copyWith(
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'سجل الدخول باستخدام بريدك الإلكتروني' : 'أنشئ حساباً جديداً باستخدام بريدك الإلكتروني',
          style: textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 24),

        if (!_isLogin)
          Column(
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  hintText: 'أدخل اسمك الكامل',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  hintStyle: TextStyle(color: secondaryTextColor),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person, color: secondaryTextColor),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        TextField(
          controller: _emailController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'example@email.com',
            labelStyle: TextStyle(color: secondaryTextColor),
            hintStyle: TextStyle(color: secondaryTextColor),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email, color: secondaryTextColor),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            hintText: '********',
            labelStyle: TextStyle(color: secondaryTextColor),
            hintStyle: TextStyle(color: secondaryTextColor),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock, color: secondaryTextColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: secondaryTextColor,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: !_isLogin ? TextInputAction.next : TextInputAction.done,
        ),
        const SizedBox(height: 16),

        if (!_isLogin)
          TextField(
            controller: _confirmPasswordController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              hintText: 'أعد كتابة كلمة المرور',
              labelStyle: TextStyle(color: secondaryTextColor),
              hintStyle: TextStyle(color: secondaryTextColor),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.lock_outline, color: secondaryTextColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: secondaryTextColor,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _emailSubmit(),
          ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _emailSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
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
              _isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟',
              style: TextStyle(color: secondaryTextColor),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isLogin = !_isLogin;
                _passwordController.clear();
                _confirmPasswordController.clear();
              }),
              child: Text(
                _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

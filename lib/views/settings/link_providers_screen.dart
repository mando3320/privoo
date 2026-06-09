// lib/views/settings/link_providers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';  // ❌ معلق مؤقتاً
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';  // ❌ معلق مؤقتاً
import '../../config/app_theme.dart';

class LinkProvidersScreen extends ConsumerStatefulWidget {
  const LinkProvidersScreen({super.key});

  @override
  ConsumerState<LinkProvidersScreen> createState() => _LinkProvidersScreenState();
}

class _LinkProvidersScreenState extends ConsumerState<LinkProvidersScreen> {
  bool _isLinking = false;
  List<Map<String, dynamic>> _linkedProviders = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedProviders();
  }

  void _loadLinkedProviders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final providers = <Map<String, dynamic>>[];
    
    final providerIds = user.providerData.map((p) => p.providerId).toSet();
    
    // إضافة البريد الإلكتروني (Email/Password)
    providers.add({
      'providerId': 'password',
      'displayName': 'البريد الإلكتروني',
      'icon': Icons.email,
      'color': Colors.blue,
      'isLinked': providerIds.contains('password') || user.email != null,
      'email': user.email ?? '',
    });
    
    // ✅ إضافة Google (معطل مؤقتاً)
    providers.add({
      'providerId': 'google.com',
      'displayName': 'Google',
      'icon': Icons.g_mobiledata,
      'color': Colors.red,
      'isLinked': providerIds.contains('google.com'),
      'email': '',
    });
    
    // ✅ إضافة Apple (معطل مؤقتاً)
    providers.add({
      'providerId': 'apple.com',
      'displayName': 'Apple',
      'icon': Icons.apple,
      'color': Colors.black,
      'isLinked': providerIds.contains('apple.com'),
      'email': '',
    });
    
    // إضافة رقم الهاتف
    providers.add({
      'providerId': 'phone',
      'displayName': 'رقم الهاتف',
      'icon': Icons.phone,
      'color': Colors.green,
      'isLinked': user.phoneNumber != null,
      'email': user.phoneNumber ?? '',
    });
    
    setState(() {
      _linkedProviders = providers;
    });
  }

  // ✅ Google Sign-In معطل مؤقتاً
  Future<void> _linkWithGoogle() async {
    // مؤقتاً: إظهار رسالة أن الميزة غير متاحة
    _showSnackbar('⏳ ميزة ربط Google قيد التطوير حالياً', isError: false);
    return;
    
    /* الكود الأصلي معطل
    setState(() => _isLinking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);
      _loadLinkedProviders();
      _showSnackbar('✅ تم ربط حساب Google بنجاح');
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLinking = false);
    }
    */
  }

  // ✅ Apple Sign-In معطل مؤقتاً
  Future<void> _linkWithApple() async {
    // مؤقتاً: إظهار رسالة أن الميزة غير متاحة
    _showSnackbar('⏳ ميزة ربط Apple قيد التطوير حالياً', isError: false);
    return;
    
    /* الكود الأصلي معطل
    setState(() => _isLinking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await user.linkWithCredential(credential);
      _loadLinkedProviders();
      _showSnackbar('✅ تم ربط حساب Apple بنجاح');
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLinking = false);
    }
    */
  }

  Future<void> _unlinkProvider(String providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء ربط الحساب'),
        content: Text('هل أنت متأكد من إلغاء ربط حساب ${_getProviderDisplayName(providerId)}؟'),
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
            child: const Text('إلغاء الربط'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLinking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل');
      await user.unlink(providerId);
      _loadLinkedProviders();
      _showSnackbar('✅ تم إلغاء ربط حساب ${_getProviderDisplayName(providerId)}');
    } catch (e) {
      _showSnackbar('❌ خطأ: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLinking = false);
    }
  }

  String _getProviderDisplayName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'phone':
        return 'رقم الهاتف';
      case 'password':
        return 'البريد الإلكتروني';
      default:
        return providerId.split('.').first;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط حسابات أخرى'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.privooDeepPurple.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Icon(Icons.link, size: 40, color: AppTheme.privooDeepPurple),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ربط حسابات أخرى',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.privooDeepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اربط حساباتك لتتمكن من تسجيل الدخول بطرق متعددة',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                ..._linkedProviders.map((provider) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: provider['color'].withValues(alpha: 0.1),
                      child: Icon(provider['icon'], color: provider['color']),
                    ),
                    title: Text(
                      provider['displayName'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: provider['email'].toString().isNotEmpty
                        ? Text(provider['email'].toString(), style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: provider['isLinked']
                        ? IconButton(
                            icon: const Icon(Icons.link_off, color: AppTheme.privooError),
                            onPressed: _isLinking ? null : () => _unlinkProvider(provider['providerId']),
                          )
                        : ElevatedButton(
                            onPressed: _isLinking
                                ? null
                                : () {
                                    if (provider['providerId'] == 'google.com') {
                                      _linkWithGoogle();
                                    } else if (provider['providerId'] == 'apple.com') {
                                      _linkWithApple();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider['color'],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('ربط'),
                          ),
                  ),
                )),

                const SizedBox(height: 24),
                
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
                          'ستحتاج إلى حساب واحد على الأقل مرتبط للوصول إلى حسابك',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLinking)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
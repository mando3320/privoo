// lib/views/settings/link_providers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    
    providers.add({
      'providerId': 'password',
      'displayName': 'البريد الإلكتروني',
      'icon': Icons.email_outlined,
      'color': Colors.blue,
      'isLinked': providerIds.contains('password') || user.email != null,
      'email': user.email ?? '',
    });
    
    providers.add({
      'providerId': 'google.com',
      'displayName': 'Google',
      'icon': Icons.g_mobiledata,
      'color': Colors.red,
      'isLinked': providerIds.contains('google.com'),
      'email': '',
    });
    
    providers.add({
      'providerId': 'apple.com',
      'displayName': 'Apple',
      'icon': Icons.apple,
      'color': Colors.black,
      'isLinked': providerIds.contains('apple.com'),
      'email': '',
    });
    
    providers.add({
      'providerId': 'phone',
      'displayName': 'رقم الهاتف',
      'icon': Icons.phone_android_outlined,
      'color': Colors.green,
      'isLinked': user.phoneNumber != null,
      'email': user.phoneNumber ?? '',
    });
    
    setState(() {
      _linkedProviders = providers;
    });
  }

  Future<void> _linkWithGoogle() async {
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
  }

  Future<void> _linkWithApple() async {
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
                _buildHeader(),
                const SizedBox(height: 32),
                ..._linkedProviders.map((provider) => _buildProviderCard(provider)),
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ),
          ),
          if (_isLinking) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.privooLightPurple, AppTheme.privooDeepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.privooLightPurple.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.link_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ربط حسابات أخرى',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.privooGold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اربط حساباتك لتتمكن من تسجيل الدخول بطرق متعددة',
          style: TextStyle(color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final isLinked = provider['isLinked'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLinked 
              ? [AppTheme.privooSuccess.withValues(alpha: 0.1), Colors.transparent]
              : [Colors.transparent, Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLinked ? AppTheme.privooSuccess : Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: provider['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(provider['icon'], color: provider['color'], size: 28),
        ),
        title: Text(
          provider['displayName'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: provider['email'].toString().isNotEmpty
            ? Text(
                provider['email'].toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              )
            : null,
        trailing: isLinked
            ? IconButton(
                icon: const Icon(Icons.link_off, color: Colors.red),
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
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('ربط'),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.privooGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.privooGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.privooGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ستحتاج إلى حساب واحد على الأقل مرتبط للوصول إلى حسابك',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جاري الربط...',
                style: TextStyle(color: AppTheme.privooGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
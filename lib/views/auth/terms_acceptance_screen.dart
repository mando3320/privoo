// lib/views/auth/terms_acceptance_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../config/app_theme.dart';

final _logger = Logger();

class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAccepted;
  const TermsAcceptanceScreen({super.key, this.onAccepted});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _ageConfirmed = false;
  bool _isLoading = false;
  bool _navigated = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموافقة على الشروط'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                        child: Icon(Icons.security_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'مرحباً بك في Privoo',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.privooGold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تطبيق تواصل آمن وخاص',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildModernCheckCard(
                      title: 'شروط الاستخدام',
                      subtitle: 'اقرأ الشروط والأحكام',
                      icon: Icons.description_outlined,
                      iconColor: Colors.blue,
                      isChecked: _termsAccepted,
                      onChanged: (value) => setState(() => _termsAccepted = value),
                      content: _buildTermsContent(),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildModernCheckCard(
                      title: 'سياسة الخصوصية',
                      subtitle: 'كيف نحمي بياناتك',
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.green,
                      isChecked: _privacyAccepted,
                      onChanged: (value) => setState(() => _privacyAccepted = value),
                      content: _buildPrivacyContent(),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildModernCheckCard(
                      title: 'تأكيد العمر',
                      subtitle: 'يجب أن يكون عمرك 13 سنة أو أكثر',
                      icon: Icons.verified_outlined,
                      iconColor: Colors.orange,
                      isChecked: _ageConfirmed,
                      onChanged: (value) => setState(() => _ageConfirmed = value),
                      content: null,
                      simpleMode: true,
                    ),
                    const SizedBox(height: 32),
                    
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 30),
                      child: ElevatedButton(
                        onPressed: (_termsAccepted && _privacyAccepted && _ageConfirmed && !_isLoading)
                            ? _acceptTerms
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.privooLightPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('أوافق وأستمر', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernCheckCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isChecked,
    required Function(bool) onChanged,
    Widget? content,
    bool simpleMode = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: isChecked,
            onChanged: (value) => onChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: iconColor,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (!simpleMode && isChecked && content != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: content,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTermsContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.check_circle_outline, 'مبادئ الاستخدام', 'باستخدامك لتطبيق Privoo، فإنك توافق على الالتزام بمبادئ التواصل الآمن.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.people_outline, 'حقوق المستخدم', 'الخصوصية، التحكم الكامل بحسابك، تشفير E2EE لجميع الرسائل.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.workspace_premium_outlined, 'الاشتراكات المدفوعة', 'يومي، شهري، سنوي، عائلي، وطلابي.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.gavel_outlined, 'الامتثال القانوني', 'متوافق مع 13 قانوناً عالمياً للخصوصية.'),
        ],
      ),
    );
  }
  
  Widget _buildPrivacyContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.privacy_tip_outlined, 'فلسفة الخصوصية', 'لا نحلل سلوكك، ولا نبيع معلوماتك.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.data_usage_outlined, 'البيانات التي نجمعها', 'رقم الهاتف، الاسم (يمكن أن يكون مستعار)، الصورة الشخصية.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.security_outlined, 'الأمان', 'تشفير Double Ratchet، X3DH Key Exchange، AES-GCM 256-bit.'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.delete_outline, 'التحكم في البيانات', 'يمكنك حذف حسابك وجميع بياناتك نهائياً.'),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.privooGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _acceptTerms() async {
    if (_isLoading || _navigated) return;
    _navigated = true;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      _logger.i('✅ Terms saved to SharedPreferences');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        unawaited(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'termsAccepted': true,
                'privacyAccepted': true,
                'ageConfirmed': true,
                'termsAcceptedAt': FieldValue.serverTimestamp(),
                'termsVersion': '1.0',
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 5))
              .then((_) => _logger.i('✅ Terms saved to Firestore'))
              .catchError((e) => _logger.w('⚠️ Firestore save failed: $e'))
        );
      }
      
      if (mounted) {
        if (widget.onAccepted != null) {
          widget.onAccepted!();
        } else {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      }
    } catch (e) {
      _logger.e('❌ Failed to save terms acceptance: $e');
      
      if (mounted) {
        if (widget.onAccepted != null) {
          widget.onAccepted!();
        } else {
          try {
            Navigator.pushReplacementNamed(context, '/profile');
          } catch (navError) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
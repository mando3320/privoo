// lib/views/auth/terms_acceptance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

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
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموافقة على الشروط'), 
        centerTitle: true, 
        automaticallyImplyLeading: false
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'مرحباً بك في Privoo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'قبل أن نبدأ، يرجى قراءة والموافقة على الشروط التالية',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // ========== شروط الاستخدام ==========
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('شروط الاستخدام', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTermsContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // ========== سياسة الخصوصية ==========
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('سياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildPrivacyContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ========== خانات الموافقة ==========
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                    title: const Text('أوافق على شروط الاستخدام'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.blue,
                  ),
                  const Divider(),
                  CheckboxListTile(
                    value: _privacyAccepted,
                    onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                    title: const Text('أوافق على سياسة الخصوصية'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.blue,
                  ),
                  const Divider(),
                  CheckboxListTile(
                    value: _ageConfirmed,
                    onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                    title: const Text('أؤكد أن عمري 13 سنة أو أكثر'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: (_termsAccepted && _privacyAccepted && _ageConfirmed && !_isLoading) ? _acceptTerms : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('أوافق وأستمر', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. مبادئ الاستخدام
        _buildSectionTitle('1. مبادئ الاستخدام'),
        const SizedBox(height: 4),
        const Text('باستخدامك لتطبيق Privoo، فإنك توافق على الالتزام بمبادئ التواصل الآمن، واحترام خصوصية الآخرين، والامتناع عن أي استخدام غير قانوني.'),
        const SizedBox(height: 16),
        
        // 2. حقوق المستخدم
        _buildSectionTitle('2. حقوق المستخدم'),
        const SizedBox(height: 4),
        const Text('• الخصوصية: استخدام التطبيق دون تتبع'),
        const Text('• التحكم الكامل: حذف حسابك وبياناتك نهائياً'),
        const Text('• تشفير E2EE: جميع رسائلك مشفرة'),
        const SizedBox(height: 16),
        
        // 3. الاشتراكات المدفوعة
        _buildSectionTitle('3. الاشتراكات المدفوعة (Privoo Pro)'),
        const SizedBox(height: 4),
        const Text('• يومي: 25 ج.م'),
        const Text('• شهري: 199 ج.م'),
        const Text('• سنوي: 1,200 ج.م'),
        const Text('• عائلي: 399 ج.م/شهر'),
        const Text('• طلابي: 99 ج.م/شهر'),
        const SizedBox(height: 16),
        
        // 4. الامتثال القانوني
        _buildSectionTitle('4. الامتثال القانوني'),
        const SizedBox(height: 4),
        const Text('Privoo متوافق مع 13 قانوناً عالمياً: GDPR، CCPA، PDPL، PIPL، LGPD، POPIA، KVKK وغيرها.'),
        const SizedBox(height: 16),
        
        // 5. التراخيص
        _buildSectionTitle('5. التراخيص'),
        const SizedBox(height: 4),
        const Text('• Gemini AI من Google'),
        const Text('• Firebase من Google'),
        const Text('• Flutter Framework - BSD 3-Clause'),
      ],
    );
  }
  
  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. فلسفة الخصوصية
        _buildSectionTitle('1. فلسفة الخصوصية'),
        const SizedBox(height: 4),
        const Text('في Privoo، لا نعتبر الخصوصية مجرد بند قانوني، بل مبدأ وجودي. نحن لا نحلل سلوكك، ولا نبيع معلوماتك لأي جهة كانت. كل تواصل يتم عبر تشفير متقدم من طرف إلى طرف (Double Ratchet Protocol).'),
        const SizedBox(height: 16),
        
        // 2. البيانات التي نجمعها
        _buildSectionTitle('2. البيانات التي نجمعها'),
        const SizedBox(height: 4),
        const Text('• رقم الهاتف (للتسجيل فقط)'),
        const Text('• الاسم (يمكن أن يكون اسم مستعار)'),
        const Text('• الصورة الشخصية (اختياري)'),
        const Text('• مفاتيح التشفير (تخزن محلياً على جهازك فقط)'),
        const SizedBox(height: 16),
        
        // 3. الامتثال القانوني
        _buildSectionTitle('3. الامتثال القانوني'),
        const SizedBox(height: 4),
        const Text('Privoo متوافق مع 13 قانوناً عالمياً: GDPR (أوروبا)، CCPA (أمريكا)، PDPL (مصر، السعودية)، PIPL (الصين)، LGPD (البرازيل)، POPIA (جنوب أفريقيا)، KVKK (تركيا)، UK GDPR، Privacy Act (أستراليا)، APPI (اليابان)، PDPB (الهند)، PDPO (هونغ كونغ)، Law 25 (كيبيك، كندا).'),
        const SizedBox(height: 16),
        
        // 4. حقوقك
        _buildSectionTitle('4. حقوقك'),
        const SizedBox(height: 4),
        const Text('• الحق في الوصول: يمكنك طلب نسخة من بياناتك'),
        const Text('• الحق في التصحيح: يمكنك تصحيح بياناتك'),
        const Text('• الحق في الحذف: يمكنك حذف حسابك نهائياً'),
        const Text('• الحق في نقل البيانات: تصدير بياناتك بصيغة JSON'),
        const SizedBox(height: 16),
        
        // 5. الأمان
        _buildSectionTitle('5. الأمان'),
        const SizedBox(height: 4),
        const Text('• 🔐 تشفير Double Ratchet'),
        const Text('• 🔒 X3DH Key Exchange'),
        const Text('• 🛡️ تشفير AES-GCM 256-bit'),
        const Text('• 📱 كشف الأجهزة المخترقة'),
        const SizedBox(height: 16),
        
        // 6. التحكم في البيانات
        _buildSectionTitle('6. التحكم في البيانات'),
        const SizedBox(height: 4),
        const Text('يمكنك حذف حسابك وجميع بياناتك نهائياً في أي وقت من داخل التطبيق (الإعدادات → حذف الحساب).'),
        const SizedBox(height: 16),
        
        // ✅ Banner التوافق مع 13 قانوناً
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ متوافق مع 13 قانوناً عالمياً: GDPR • CCPA • PDPL • PIPL • LGPD • POPIA • KVKK • UK GDPR • Privacy Act • APPI • PDPB • PDPO • Law 25',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
  
  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'termsAccepted': true,
        'privacyAccepted': true,
        'ageConfirmed': true,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'termsVersion': '1.0',
      }, SetOptions(merge: true));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ. يرجى المحاولة مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
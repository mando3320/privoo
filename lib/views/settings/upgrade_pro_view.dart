// lib/views/settings/upgrade_pro_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/subscription_service.dart';
import '../../services/offer_service.dart';
import '../../models/offer_model.dart';
import '../../main.dart';

class UpgradeProView extends ConsumerStatefulWidget {
  const UpgradeProView({super.key});

  @override
  ConsumerState<UpgradeProView> createState() => _UpgradeProViewState();
}

class _UpgradeProViewState extends ConsumerState<UpgradeProView> {
  bool _isProcessing = false;
  
  final TextEditingController _couponController = TextEditingController();
  String _couponMessage = '';
  double _discount = 0;
  OfferModel? _appliedOffer;

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponMessage = '⚠️ الرجاء إدخال الكود');
      return;
    }

    setState(() => _couponMessage = '⏳ جاري التحقق...');
    
    try {
      final offerService = ref.read(offerServiceProvider);
      final offer = await offerService.validateCoupon(code);
      
      if (offer != null) {
        setState(() {
          _appliedOffer = offer;
          _discount = offer.value;
          _couponMessage = '✅ تم تطبيق خصم ${offer.value}${offer.type == OfferType.percentage ? '%' : ' ج.م'}';
        });
      } else {
        setState(() {
          _appliedOffer = null;
          _discount = 0;
          _couponMessage = '❌ كود غير صالح أو منتهي';
        });
      }
    } catch (e) {
      setState(() => _couponMessage = '❌ حدث خطأ، حاول مرة أخرى');
    }
  }

  Future<void> _handleUpgrade(String type) async {
    setState(() => _isProcessing = true);

    try {
      final user = ref.read(authControllerProvider).currentUser;
      if (user == null) {
        _showSnackbar('يرجى تسجيل الدخول أولاً', isError: true);
        return;
      }

      if (_appliedOffer != null) {
        await ref.read(offerServiceProvider).redeemCoupon(user.id, _appliedOffer!.code);
      }

      bool success = false;
      switch (type) {
        case 'daily':
          success = await SubscriptionService.activateDailySubscription();
          break;
        case 'monthly':
          success = await SubscriptionService.activateMonthlySubscription();
          break;
        case 'yearly':
          success = await SubscriptionService.activateYearlySubscription();
          break;
        case 'family':
          success = await SubscriptionService.activateFamilySubscription();
          break;
        case 'student':
          success = await SubscriptionService.activateStudentSubscription();
          break;
        case 'lifetime':
          success = await SubscriptionService.activateLifetimeSubscription();
          break;
      }

      if (success) {
        await SubscriptionService.refreshUserStatus();
        // ✅ تم تعليق هذا السطر مؤقتاً
        // await ref.read(appControllerProvider.notifier).fetchAndVerifyUserStatus(await user.getIdToken() ?? '');
        
        final messageMap = {
          'daily': 'اليومي Pro',
          'monthly': 'الشهري Pro',
          'yearly': 'السنوي Pro',
          'family': 'العائلي Pro',
          'student': 'الطلابي Pro',
          'lifetime': 'مدى الحياة',
        };
        
        _showSnackbar('🎉 تم تفعيل اشتراك ${messageMap[type] ?? "Pro"} بنجاح!');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackbar('❌ فشل في تفعيل الاشتراك. حاول مرة أخرى.', isError: true);
      }
    } catch (e) {
      logger.e('خطأ في الترقية: $e');
      _showSnackbar('حدث خطأ. تأكد من اتصالك بالإنترنت.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showStudentVerificationDialog() async {
    final emailController = TextEditingController();
    
    final verified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التحقق من البريد الجامعي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل بريدك الجامعي (.edu) للتحقق'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'example@university.edu',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.contains('.edu') || email.contains('university')) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال بريد جامعي صالح')),
                );
              }
            },
            child: const Text('تحقق'),
          ),
        ],
      ),
    );
    
    if (verified == true) {
      await _handleUpgrade('student');
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.privooError : AppTheme.privooSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Privoo Pro'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.privooGold.withValues(alpha: 0.1),
                    ),
                    child: const Center(
                      child: Icon(Icons.workspace_premium, size: 32, color: AppTheme.privooGold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '✨ Privoo Pro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.privooDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'استمتع بميزات احترافية وتجربة دردشة غير مسبوقة',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.privooDeepPurple.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Table(
                      border: TableBorder.all(color: AppTheme.privooDeepPurple.withValues(alpha: 0.1)),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                          ),
                          children: [
                            const Padding(padding: EdgeInsets.all(12), child: Text('الميزة', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Padding(padding: EdgeInsets.all(12), child: Text('مجاني', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.all(12), child: Text('Pro', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.privooGold))),
                          ],
                        ),
                        _buildRow('مكالمات فيديو (1-1)', '✅', '✅'),
                        _buildRow('مكالمات صوتية (1-1)', '✅', '✅'),
                        _buildRow('تشفير طرف إلى طرف', '✅', '✅'),
                        _buildRow('مساعد ذكي 🤖', '10 رسائل/يوم', 'غير محدود'),
                        _buildRow('رفع الملفات', 'حتى 10 ميجابايت', 'غير محدود'),
                        _buildRow('النسخ الاحتياطي السحابي', '❌', '✅'),
                        _buildRow('استعادة المحادثات', '❌', '✅'),
                        _buildRow('دعم الأولوية', '❌', '✅'),
                        _buildRow('خلفيات مخصصة', 'أساسية', 'مكتبة كاملة'),
                        _buildRow('بدون إعلانات', '✅', '✅'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.privooGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer, color: AppTheme.privooGold),
                            const SizedBox(width: 8),
                            const Text('هل لديك كود خصم؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                decoration: InputDecoration(
                                  hintText: 'أدخل الكود هنا',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyCoupon,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.privooGold,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('تطبيق'),
                            ),
                          ],
                        ),
                        if (_couponMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _couponMessage,
                              style: TextStyle(
                                color: _couponMessage.contains('✅') ? AppTheme.privooSuccess : AppTheme.privooError,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (app.isPro || app.isLifetime)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.privooSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.privooSuccess),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              app.isLifetime
                                  ? '💎 أنت مشترك Privoo Pro مدى الحياة'
                                  : '✅ أنت مشترك بالفعل في Privoo Pro',
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildUpgradeButton(
                      icon: Icons.today,
                      title: 'يومي Pro',
                      price: '25 ج.م',
                      onPressed: () => _handleUpgrade('daily'),
                    ),
                    _buildUpgradeButton(
                      icon: Icons.calendar_view_month,
                      title: 'اشتراك شهري',
                      price: '199 ج.م',
                      onPressed: () => _handleUpgrade('monthly'),
                    ),
                    _buildUpgradeButton(
                      icon: Icons.calendar_today,
                      title: 'اشتراك سنوي',
                      price: '1,200 ج.م',
                      onPressed: () => _handleUpgrade('yearly'),
                    ),
                    _buildUpgradeButton(
                      icon: Icons.family_restroom,
                      title: 'خطة عائلية',
                      subtitle: '4 أفراد',
                      price: '399 ج.م/شهر',
                      color: AppTheme.privooLightPurple,
                      onPressed: () => _handleUpgrade('family'),
                    ),
                    _buildUpgradeButton(
                      icon: Icons.school,
                      title: 'خطة طلابية',
                      price: '99 ج.م/شهر',
                      color: AppTheme.privooTeal,
                      onPressed: _showStudentVerificationDialog,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required String price,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.privooDeepPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  TableRow _buildRow(String feature, String free, String pro) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(feature)),
        Padding(padding: const EdgeInsets.all(10), child: Text(free, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(pro, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.privooGold))),
      ],
    );
  }
}
// lib/views/settings/compliance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/region_compliance_service.dart';
import '../../config/app_theme.dart';
import '../../main.dart';
import '../../services/supabase_service.dart';
import 'export_data_screen.dart';
import 'delete_account_screen.dart';

class ComplianceScreen extends ConsumerStatefulWidget {
  const ComplianceScreen({super.key});

  @override
  ConsumerState<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends ConsumerState<ComplianceScreen> {
  ComplianceRegion _userRegion = ComplianceRegion.egypt;
  ComplianceRequirements? _requirements;
  bool _optOutSale = false;
  bool _isLoading = true;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _loadUserRegion();
  }
  
  Future<void> _loadUserRegion() async {
    setState(() => _isLoading = true);
    try {
      _userRegion = await RegionComplianceService.getUserRegion();
      _requirements = RegionComplianceService.getRequirements(_userRegion);
      
      final user = SupabaseService().currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('uid', user.id)
            .maybeSingle();
        _optOutSale = response?['opt_out_sale'] ?? false;
      }
    } catch (e) {
      logger.e('خطأ في تحميل المنطقة: $e');
    }
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final regionInfo = RegionInfo.allRegions
        .firstWhere((r) => r.region == _userRegion);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الامتثال القانوني'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة المنطقة
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.privooDeepPurple, AppTheme.privooLightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [AppTheme.mainShadow(AppTheme.privooDeepPurple)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(regionInfo.flagIcon, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            regionInfo.countryName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            regionInfo.lawName,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.privooGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'الحد الأدنى للعمر: ${regionInfo.minAge} سنة',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.privooGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // حقوقك القانونية
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel, color: AppTheme.privooDeepPurple),
                              const SizedBox(width: 8),
                              Text(
                                'حقوقك القانونية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.privooDeepPurple,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            RegionComplianceService.getRightsText(_userRegion),
                            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // أزرار الإجراءات
                  if (_requirements?.requiresExportData == true)
                    _buildActionButton(
                      icon: Icons.download,
                      title: 'تصدير بياناتي',
                      subtitle: 'احصل على نسخة من جميع بياناتك الشخصية',
                      color: AppTheme.privooSuccess,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportDataScreen())),
                    ),
                  if (_requirements?.requiresDeleteAccount == true)
                    _buildActionButton(
                      icon: Icons.delete_forever,
                      title: 'حذف حسابي وكل بياناتي',
                      subtitle: 'حذف نهائي للحساب وجميع البيانات (الحق في النسيان)',
                      color: AppTheme.privooError,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
                    ),
                  
                  if (_requirements?.optOutSale == true)
                    Container(
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
                      child: SwitchListTile(
                        title: const Text('لا تبيع بياناتي'),
                        subtitle: const Text('منع بيع بياناتي الشخصية لأطراف ثالثة (CCPA)'),
                        value: _optOutSale,
                        onChanged: (value) async {
                          setState(() => _optOutSale = value);
                          final service = RegionComplianceService();
                          final user = SupabaseService().currentUser;
                          if (user != null) await service.recordOptOutSale(user.id, value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? '✅ تم تفعيل "لا تبيع بياناتي"' : '❌ تم إلغاء "لا تبيع بياناتي"'),
                              backgroundColor: value ? AppTheme.privooSuccess : AppTheme.privooError,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        activeColor: AppTheme.privooDeepPurple,
                      ),
                    ),

                  if (_requirements?.requiresDataLocalization == true)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.privooGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storage, color: AppTheme.privooGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بياناتك تخزن محلياً وفقاً لقانون ${_requirements?.lawName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ملاحظة ختامية
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.privooDeepPurple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'نلتزم بقوانين الخصوصية في ${regionInfo.countryName}. لديك الحق في ممارسة حقوقك القانونية في أي وقت.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.privooDeepPurple),
        onTap: onTap,
      ),
    );
  }
}
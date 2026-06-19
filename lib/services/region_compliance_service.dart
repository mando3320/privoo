// lib/services/region_compliance_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_picker/country_picker.dart';
import 'supabase_service.dart';

enum ComplianceRegion {
  egypt,        // 🇪🇬 EG
  uae,          // 🇦🇪 UAE
  saudi,        // 🇸🇦 KSA
  europe,       // 🇪🇺 GDPR
  usa,          // 🇺🇸 CCPA
  china,        // 🇨🇳 PIPL
  india,        // 🇮🇳 DPDPA
  brazil,       // 🇧🇷 LGPD
  uk,           // 🇬🇧 UK GDPR
  turkey,       // 🇹🇷 KVKK
  russia,       // 🇷🇺 152-FZ
  japan,        // 🇯🇵 APPI
  australia,    // 🇦🇺 Privacy Act
}

class RegionInfo {
  final ComplianceRegion region;
  final String countryName;
  final String lawName;
  final String flagIcon;
  final int minAge;

  const RegionInfo({
    required this.region,
    required this.countryName,
    required this.lawName,
    required this.flagIcon,
    required this.minAge,
  });

  static const List<RegionInfo> allRegions = [
    RegionInfo(region: ComplianceRegion.egypt, countryName: 'مصر', lawName: 'قانون حماية البيانات الشخصية', flagIcon: '🇪🇬', minAge: 13),
    RegionInfo(region: ComplianceRegion.uae, countryName: 'الإمارات', lawName: 'UAE PDPL', flagIcon: '🇦🇪', minAge: 13),
    RegionInfo(region: ComplianceRegion.saudi, countryName: 'السعودية', lawName: 'PDPL', flagIcon: '🇸🇦', minAge: 13),
    RegionInfo(region: ComplianceRegion.europe, countryName: 'أوروبا', lawName: 'GDPR', flagIcon: '🇪🇺', minAge: 16),
    RegionInfo(region: ComplianceRegion.usa, countryName: 'الولايات المتحدة', lawName: 'CCPA/CPRA', flagIcon: '🇺🇸', minAge: 13),
    RegionInfo(region: ComplianceRegion.china, countryName: 'الصين', lawName: 'PIPL', flagIcon: '🇨🇳', minAge: 14),
    RegionInfo(region: ComplianceRegion.india, countryName: 'الهند', lawName: 'DPDPA', flagIcon: '🇮🇳', minAge: 13),
    RegionInfo(region: ComplianceRegion.brazil, countryName: 'البرازيل', lawName: 'LGPD', flagIcon: '🇧🇷', minAge: 13),
    RegionInfo(region: ComplianceRegion.uk, countryName: 'بريطانيا', lawName: 'UK GDPR', flagIcon: '🇬🇧', minAge: 16),
    RegionInfo(region: ComplianceRegion.turkey, countryName: 'تركيا', lawName: 'KVKK', flagIcon: '🇹🇷', minAge: 13),
    RegionInfo(region: ComplianceRegion.russia, countryName: 'روسيا', lawName: '152-FZ', flagIcon: '🇷🇺', minAge: 13),
    RegionInfo(region: ComplianceRegion.japan, countryName: 'اليابان', lawName: 'APPI', flagIcon: '🇯🇵', minAge: 13),
    RegionInfo(region: ComplianceRegion.australia, countryName: 'أستراليا', lawName: 'Privacy Act', flagIcon: '🇦🇺', minAge: 13),
  ];

  static RegionInfo getRegionInfo(ComplianceRegion region) {
    return allRegions.firstWhere((r) => r.region == region);
  }

  static ComplianceRegion? fromCountryCode(String countryCode) {
    final map = {
      'EG': ComplianceRegion.egypt,
      'AE': ComplianceRegion.uae,
      'SA': ComplianceRegion.saudi,
      'GB': ComplianceRegion.uk,
      'EU': ComplianceRegion.europe,
      'US': ComplianceRegion.usa,
      'CN': ComplianceRegion.china,
      'IN': ComplianceRegion.india,
      'BR': ComplianceRegion.brazil,
      'TR': ComplianceRegion.turkey,
      'RU': ComplianceRegion.russia,
      'JP': ComplianceRegion.japan,
      'AU': ComplianceRegion.australia,
    };
    return map[countryCode];
  }
}

class ComplianceRequirements {
  final String lawName;
  final int minAge;
  final bool requiresConsent;
  final bool requiresExportData;
  final bool requiresDeleteAccount;
  final bool optOutSale;
  final bool requiresDataLocalization;
  final bool requiresBreachNotification;

  const ComplianceRequirements({
    required this.lawName,
    required this.minAge,
    this.requiresConsent = true,
    this.requiresExportData = true,
    this.requiresDeleteAccount = true,
    this.optOutSale = false,
    this.requiresDataLocalization = false,
    this.requiresBreachNotification = true,
  });
}

class RegionComplianceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static Future<ComplianceRegion> getUserRegion() async {
    final user = SupabaseService().currentUser;
    if (user == null) return ComplianceRegion.egypt;

    try {
      final response = await _supabase
          .from('users')
          .select('region')
          .eq('uid', user.id)
          .maybeSingle();

      if (response != null && response['region'] != null) {
        final regionStr = response['region'] as String;
        return ComplianceRegion.values.firstWhere(
          (r) => r.name == regionStr,
          orElse: () => ComplianceRegion.egypt,
        );
      }
    } catch (e) {
      print('❌ Failed to get user region: $e');
    }

    return ComplianceRegion.egypt;
  }

  static ComplianceRequirements getRequirements(ComplianceRegion region) {
    switch (region) {
      case ComplianceRegion.europe:
        return const ComplianceRequirements(
          lawName: 'GDPR',
          minAge: 16,
          requiresConsent: true,
          requiresExportData: true,
          requiresDeleteAccount: true,
          optOutSale: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
        );
      case ComplianceRegion.usa:
        return const ComplianceRequirements(
          lawName: 'CCPA/CPRA',
          minAge: 13,
          requiresConsent: true,
          requiresExportData: true,
          requiresDeleteAccount: true,
          optOutSale: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
        );
      case ComplianceRegion.china:
        return const ComplianceRequirements(
          lawName: 'PIPL',
          minAge: 14,
          requiresConsent: true,
          requiresExportData: true,
          requiresDeleteAccount: true,
          optOutSale: true,
          requiresDataLocalization: true,
          requiresBreachNotification: true,
        );
      default:
        return const ComplianceRequirements(
          lawName: 'قانون الخصوصية المحلي',
          minAge: 13,
          requiresConsent: true,
          requiresExportData: true,
          requiresDeleteAccount: true,
          optOutSale: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
        );
    }
  }

  static String getRightsText(ComplianceRegion region) {
    switch (region) {
      case ComplianceRegion.europe:
        return '• الحق في الوصول إلى بياناتك\n'
               '• الحق في تصحيح بياناتك\n'
               '• الحق في حذف بياناتك (الحق في النسيان)\n'
               '• الحق في تقييد المعالجة\n'
               '• الحق في نقل البيانات\n'
               '• الحق في الاعتراض على المعالجة';
      case ComplianceRegion.usa:
        return '• الحق في معرفة البيانات التي تم جمعها\n'
               '• الحق في حذف البيانات\n'
               '• الحق في إلغاء الاشتراك من بيع البيانات\n'
               '• الحق في عدم التمييز عند ممارسة الحقوق';
      default:
        return '• الحق في الوصول إلى بياناتك\n'
               '• الحق في تصحيح بياناتك\n'
               '• الحق في حذف بياناتك\n'
               '• الحق في سحب الموافقة في أي وقت';
    }
  }

  Future<void> recordOptOutSale(String userId, bool optOut) async {
    await _supabase
        .from('users')
        .update({'opt_out_sale': optOut})
        .eq('uid', userId);
  }
}
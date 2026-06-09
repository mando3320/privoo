// lib/services/region_compliance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

// قائمة الدول الـ 13 المدعومة
enum ComplianceRegion {
  egypt,      // مصر - PDPL
  saudi,      // السعودية - PDPL
  uae,        // الإمارات - UAE Data Protection Law
  europe,     // أوروبا - GDPR
  usa,        // الولايات المتحدة - CCPA
  china,      // الصين - PIPL
  india,      // الهند - DPDP
  brazil,     // البرازيل - LGPD
  southAfrica, // جنوب أفريقيا - POPIA
  turkey,     // تركيا - KVKK
  uk,         // المملكة المتحدة - UK GDPR
  australia,  // أستراليا - Privacy Act
  japan,      // اليابان - APPI
}

class RegionComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<ComplianceRegion> getUserRegion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return ComplianceRegion.egypt;
    final phoneNumber = user.phoneNumber ?? '';
    if (phoneNumber.startsWith('+20')) return ComplianceRegion.egypt;
    if (phoneNumber.startsWith('+966')) return ComplianceRegion.saudi;
    if (phoneNumber.startsWith('+971')) return ComplianceRegion.uae;
    if (phoneNumber.startsWith('+44')) return ComplianceRegion.uk;
    if (phoneNumber.startsWith('+49') || phoneNumber.startsWith('+33') || 
        phoneNumber.startsWith('+34') || phoneNumber.startsWith('+39')) {
      return ComplianceRegion.europe;
    }
    if (phoneNumber.startsWith('+1')) return ComplianceRegion.usa;
    if (phoneNumber.startsWith('+86')) return ComplianceRegion.china;
    if (phoneNumber.startsWith('+91')) return ComplianceRegion.india;
    if (phoneNumber.startsWith('+55')) return ComplianceRegion.brazil;
    if (phoneNumber.startsWith('+27')) return ComplianceRegion.southAfrica;
    if (phoneNumber.startsWith('+90')) return ComplianceRegion.turkey;
    if (phoneNumber.startsWith('+61')) return ComplianceRegion.australia;
    if (phoneNumber.startsWith('+81')) return ComplianceRegion.japan;
    return ComplianceRegion.egypt;
  }
  
  static ComplianceRequirements getRequirements(ComplianceRegion region) {
    switch (region) {
      case ComplianceRegion.egypt:
        return ComplianceRequirements(
          lawName: 'PDPL - قانون حماية البيانات الشخصية المصري',
          lawNumber: 'رقم 151 لسنة 2020',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 16,
          requiresParentalConsent: true,
          requiresDataLocalization: true,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.saudi:
        return ComplianceRequirements(
          lawName: 'PDPL - نظام حماية البيانات الشخصية السعودي',
          lawNumber: 'المرسوم الملكي م/19',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 18,
          requiresParentalConsent: true,
          requiresDataLocalization: true,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.uae:
        return ComplianceRequirements(
          lawName: 'UAE Data Protection Law',
          lawNumber: 'Federal Law No. 45 of 2021',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 18,
          requiresParentalConsent: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.europe:
        return ComplianceRequirements(
          lawName: 'GDPR - General Data Protection Regulation',
          lawNumber: 'EU 2016/679',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 16,
          requiresParentalConsent: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.usa:
        return ComplianceRequirements(
          lawName: 'CCPA - California Consumer Privacy Act',
          lawNumber: 'Civil Code 1798.100-1798.199',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 13,
          requiresParentalConsent: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: false,
          optOutSale: true,
        );
      case ComplianceRegion.china:
        return ComplianceRequirements(
          lawName: 'PIPL - Personal Information Protection Law',
          lawNumber: '中华人民共和国个人信息保护法',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 14,
          requiresParentalConsent: true,
          requiresDataLocalization: true,
          requiresBreachNotification: true,
          breachNotificationHours: 24,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.india:
        return ComplianceRequirements(
          lawName: 'DPDP - Digital Personal Data Protection Act',
          lawNumber: 'Act No. 22 of 2023',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 18,
          requiresParentalConsent: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: false,
        );
      case ComplianceRegion.brazil:
        return ComplianceRequirements(
          lawName: 'LGPD - Lei Geral de Proteção de Dados',
          lawNumber: 'Lei 13.709/2018',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 13,
          requiresParentalConsent: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.southAfrica:
        return ComplianceRequirements(
          lawName: 'POPIA - Protection of Personal Information Act',
          lawNumber: 'Act No. 4 of 2013',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 18,
          requiresParentalConsent: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.turkey:
        return ComplianceRequirements(
          lawName: 'KVKK - Kişisel Verileri Koruma Kanunu',
          lawNumber: 'Kanun No. 6698',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 18,
          requiresParentalConsent: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.uk:
        return ComplianceRequirements(
          lawName: 'UK GDPR - Data Protection Act 2018',
          lawNumber: '2018 c. 12',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: true,
          minAge: 13,
          requiresParentalConsent: true,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
      case ComplianceRegion.australia:
        return ComplianceRequirements(
          lawName: 'Privacy Act 1988 (APP)',
          lawNumber: 'No. 119, 1988',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 18,
          requiresParentalConsent: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: false,
        );
      case ComplianceRegion.japan:
        return ComplianceRequirements(
          lawName: 'APPI - Act on the Protection of Personal Information',
          lawNumber: 'Act No. 57 of 2003',
          requiresExportData: true,
          requiresDeleteAccount: true,
          requiresAgeVerification: false,
          minAge: 16,
          requiresParentalConsent: false,
          requiresDataLocalization: false,
          requiresBreachNotification: true,
          breachNotificationHours: 72,
          requiresDataMinimization: true,
          requiresConsentForMarketing: true,
          requiresDataProtectionOfficer: true,
        );
    }
  }
  
  static String getRightsText(ComplianceRegion region) {
    final req = getRequirements(region);
    return '''
${req.lawName} (${req.lawNumber})

حقوقك بموجب هذا القانون:

1. الحق في الوصول: يمكنك طلب نسخة من بياناتك الشخصية.
2. الحق في التصحيح: يمكنك طلب تصحيح بياناتك غير الصحيحة.
3. الحق في الحذف: يمكنك طلب حذف بياناتك الشخصية (الحق في النسيان).
4. الحق في تقييد المعالجة: يمكنك طلب تقييد معالجة بياناتك.
5. الحق في نقل البيانات: يمكنك طلب نقل بياناتك إلى خدمة أخرى.
6. الحق في الاعتراض: يمكنك الاعتراض على معالجة بياناتك.
7. الحق في عدم الخضوع لقرار آلي: لا تتخذ قرارات آلية تؤثر عليك.

${req.optOutSale ? '8. الحق في إلغاء الاشتراك: يمكنك طلب عدم بيع بياناتك لأطراف ثالثة.\n' : ''}
${req.requiresDataLocalization ? 'ملاحظة: بياناتك تخزن محلياً وفقاً للقوانين المحلية.' : ''}
''';
  }
  
  Future<void> recordUserConsent(String userId, ComplianceRegion region) async {
    final req = getRequirements(region);
    await _firestore.collection('users').doc(userId).set({
      'region': region.name,
      'lawName': req.lawName,
      'consentGivenAt': FieldValue.serverTimestamp(),
      'consentVersion': '1.0',
      'ageVerified': req.requiresAgeVerification,
      'parentalConsent': false,
      'optOutSale': false,
    }, SetOptions(merge: true));
    logger.i('✅ تم تسجيل موافقة المستخدم $userId حسب قانون ${req.lawName}');
  }
  
  Future<void> recordBreachNotification({
    required String userId,
    required String description,
    required String affectedData,
  }) async {
    final region = await getUserRegion();
    final req = getRequirements(region);
    await _firestore.collection('breach_notifications').add({
      'userId': userId,
      'description': description,
      'affectedData': affectedData,
      'timestamp': FieldValue.serverTimestamp(),
      'notifiedWithinHours': req.breachNotificationHours,
      'region': region.name,
      'law': req.lawName,
    });
    logger.w('⚠️ تم تسجيل إشعار اختراق للمستخدم $userId - تم الإخطار خلال ${req.breachNotificationHours} ساعة');
  }
  
  static Future<bool> isUserAgeValid(int age, ComplianceRegion region) async {
    final req = getRequirements(region);
    return age >= req.minAge;
  }
  
  static bool requiresLocalStorage(ComplianceRegion region) {
    final req = getRequirements(region);
    return req.requiresDataLocalization;
  }
  
  Future<void> recordOptOutSale(String userId, bool optOut) async {
    final region = await getUserRegion();
    final req = getRequirements(region);
    if (!req.optOutSale) return;
    await _firestore.collection('users').doc(userId).set({
      'optOutSale': optOut,
      'optOutSaleUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    logger.i('✅ تم تسجيل خيار "لا تبيع بياناتي" للمستخدم $userId: $optOut');
  }
}

class ComplianceRequirements {
  final String lawName;
  final String lawNumber;
  final bool requiresExportData;
  final bool requiresDeleteAccount;
  final bool requiresAgeVerification;
  final int minAge;
  final bool requiresParentalConsent;
  final bool requiresDataLocalization;
  final bool requiresBreachNotification;
  final int breachNotificationHours;
  final bool requiresDataMinimization;
  final bool requiresConsentForMarketing;
  final bool requiresDataProtectionOfficer;
  final bool optOutSale;
  
  ComplianceRequirements({
    required this.lawName,
    required this.lawNumber,
    required this.requiresExportData,
    required this.requiresDeleteAccount,
    required this.requiresAgeVerification,
    required this.minAge,
    required this.requiresParentalConsent,
    required this.requiresDataLocalization,
    required this.requiresBreachNotification,
    required this.breachNotificationHours,
    required this.requiresDataMinimization,
    required this.requiresConsentForMarketing,
    required this.requiresDataProtectionOfficer,
    this.optOutSale = false,
  });
}

class RegionInfo {
  final ComplianceRegion region;
  final String countryName;
  final String countryCode;
  final String flagIcon;
  final String lawName;
  final int minAge;
  
  RegionInfo({
    required this.region,
    required this.countryName,
    required this.countryCode,
    required this.flagIcon,
    required this.lawName,
    required this.minAge,
  });
  
  static List<RegionInfo> getAllRegions() {
    return [
      RegionInfo(region: ComplianceRegion.egypt, countryName: 'مصر', countryCode: 'EG', flagIcon: '🇪🇬', lawName: 'PDPL', minAge: 16),
      RegionInfo(region: ComplianceRegion.saudi, countryName: 'السعودية', countryCode: 'SA', flagIcon: '🇸🇦', lawName: 'PDPL', minAge: 18),
      RegionInfo(region: ComplianceRegion.uae, countryName: 'الإمارات', countryCode: 'AE', flagIcon: '🇦🇪', lawName: 'UAE Data Protection', minAge: 18),
      RegionInfo(region: ComplianceRegion.europe, countryName: 'أوروبا', countryCode: 'EU', flagIcon: '🇪🇺', lawName: 'GDPR', minAge: 16),
      RegionInfo(region: ComplianceRegion.usa, countryName: 'الولايات المتحدة', countryCode: 'US', flagIcon: '🇺🇸', lawName: 'CCPA', minAge: 13),
      RegionInfo(region: ComplianceRegion.china, countryName: 'الصين', countryCode: 'CN', flagIcon: '🇨🇳', lawName: 'PIPL', minAge: 14),
      RegionInfo(region: ComplianceRegion.india, countryName: 'الهند', countryCode: 'IN', flagIcon: '🇮🇳', lawName: 'DPDP', minAge: 18),
      RegionInfo(region: ComplianceRegion.brazil, countryName: 'البرازيل', countryCode: 'BR', flagIcon: '🇧🇷', lawName: 'LGPD', minAge: 13),
      RegionInfo(region: ComplianceRegion.southAfrica, countryName: 'جنوب أفريقيا', countryCode: 'ZA', flagIcon: '🇿🇦', lawName: 'POPIA', minAge: 18),
      RegionInfo(region: ComplianceRegion.turkey, countryName: 'تركيا', countryCode: 'TR', flagIcon: '🇹🇷', lawName: 'KVKK', minAge: 18),
      RegionInfo(region: ComplianceRegion.uk, countryName: 'المملكة المتحدة', countryCode: 'GB', flagIcon: '🇬🇧', lawName: 'UK GDPR', minAge: 13),
      RegionInfo(region: ComplianceRegion.australia, countryName: 'أستراليا', countryCode: 'AU', flagIcon: '🇦🇺', lawName: 'Privacy Act', minAge: 18),
      RegionInfo(region: ComplianceRegion.japan, countryName: 'اليابان', countryCode: 'JP', flagIcon: '🇯🇵', lawName: 'APPI', minAge: 16),
    ];
  }
}

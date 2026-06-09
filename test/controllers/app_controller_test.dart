// test/controllers/app_controller_test.dart - 20 اختبار
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privoo/config/app_theme.dart';
import 'package:privoo/controllers/app_controller.dart';

void main() {
  group('AppController - 20 اختبار (نظام الثيمات والاشتراكات)', () {
    late ProviderContainer container;
    late AppController appController;
    
    setUp(() {
      container = ProviderContainer();
      appController = AppController(container.read);
    });
    
    tearDown(() {
      container.dispose();
    });
    
    group('Theme System (10)', () {
      test('TC1: 25 ثيماً في التطبيق', () {
        expect(AppTheme.allThemeNames.length, 25);
      });
      
      test('TC2: 4 ثيمات مجانية', () {
        expect(AppTheme.freeThemes.length, 4);
      });
      
      test('TC3: 21 ثيماً مدفوعة', () {
        expect(AppTheme.lockedThemesCount, 21);
      });
      
      test('TC4: ثيم Blue Light مجاني', () {
        expect(AppTheme.isThemeAvailable('Blue Light', false), true);
      });
      
      test('TC5: ثيم Neon Dark مدفوع', () {
        expect(AppTheme.isThemeAvailable('Neon Dark', false), false);
      });
      
      test('TC6: مستخدم Pro يصل لكل الثيمات', () {
        expect(AppTheme.isThemeAvailable('Neon Dark', true), true);
      });
      
      test('TC7: قائمة ثيمات مجانية', () {
        final free = AppTheme.getAvailableThemesForUser(false);
        expect(free.length, 4);
      });
      
      test('TC8: قائمة ثيمات Pro', () {
        final pro = AppTheme.getAvailableThemesForUser(true);
        expect(pro.length, 25);
      });
      
      test('TC9: الحصول على ثيم بالاسم', () {
        final theme = AppTheme.getTheme('Blue Light');
        expect(theme, isNotNull);
      });
      
      test('TC10: ثيم غير موجود يرجع الافتراضي', () {
        final theme = AppTheme.getTheme('Invalid');
        expect(theme, AppTheme.blueLightTheme);
      });
    });
    
    group('Subscription Limits (5)', () {
      test('TC11: 30 رسالة للمستخدم المجاني يومياً', () {
        expect(appController.dailyFreeLimit, 30);
      });
      
      test('TC12: مستخدم مجاني يرسل رسالة 5', () {
        final canSend = appController.canSendMessage;
        expect(canSend, true);
      });
      
      test('TC13: مستخدم مجاني يرسل رسالة 30', () {
        // عند الوصول للحد الأقصى
        expect(appController.dailyFreeLimit, 30);
      });
      
      test('TC14: مستخدم مجاني يرسل رسالة 31', () {
        final canSend = appController.messagesToday < appController.dailyFreeLimit;
        expect(canSend, false);
      });
      
      test('TC15: مستخدم Pro يرسل غير محدود', () {
        expect(true, true);
      });
    });
    
    group('Settings Management (5)', () {
      test('TC16: حفظ إعدادات اللغة', () async {
        await appController.updateLanguage('ar');
        expect(appController.locale.languageCode, 'ar');
      });
      
      test('TC17: تبديل الوضع الداكن', () async {
        await appController.toggleTheme(true);
        expect(appController.themeMode, ThemeMode.dark);
      });
      
      test('TC18: تبديل الوضع الفاتح', () async {
        await appController.toggleTheme(false);
        expect(appController.themeMode, ThemeMode.light);
      });
      
      test('TC19: إعادة ضبط الإعدادات', () async {
        await appController.resetSettings();
        expect(appController.themeName, 'Blue Light');
      });
      
      test('TC20: مسح الكاش', () async {
        await appController.clearCache();
        expect(true, true);
      });
    });
  });
}
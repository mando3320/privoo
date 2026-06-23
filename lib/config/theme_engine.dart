// lib/config/theme_engine.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// ✅ محرك الثيمات - يدير جميع الثيمات مع دعم Light/Dark
class ThemeEngine {
  // ✅ تحديد الثيمات التي تدعم الوضع الفاتح
  static const Map<String, bool> themeHasLightMode = {
    // ✅ الثيمات الجديدة
    'Privoo Premium': true,   // يدعم Light/Dark
    'Privoo Midnight': false, // Dark فقط
    'Privoo Royal': false,    // Dark فقط
    'Privoo Ocean': false,    // Dark فقط
    'Privoo Aurora': false,   // Dark فقط
    'Privoo Obsidian': false, // Dark فقط
    
    // ✅ الثيمات القديمة
    'Privoo Light': true,
    'Privoo Dark': false,
    'Blue Light': true,
    'Blue Dark': false,
    'Grey Light': true,
    'Grey Dark': false,
    'Purple Light': true,
    'Purple Dark': false,
    'Red Light': true,
    'Red Dark': false,
    'Green Light': true,
    'Green Dark': false,
    'Yellow Light': true,
    'Yellow Dark': false,
    'Orange Light': true,
    'Orange Dark': false,
    'Pink Light': true,
    'Pink Dark': false,
    'Teal Light': true,
    'Teal Dark': false,
    'Cyan Light': true,
    'Cyan Dark': false,
    'Indigo Light': true,
    'Indigo Dark': false,
    'Neon Dark': false,
  };

  /// ✅ الحصول على الثيم بناءً على الاسم والوضع
  static ThemeData getTheme({
    required String themeName,
    required ThemeMode themeMode,
  }) {
    final isDark = themeMode == ThemeMode.dark;
    
    // ✅ الثيمات الجديدة
    switch (themeName) {
      case 'Privoo Premium':
        return isDark 
            ? AppTheme.privooPremiumTheme 
            : AppTheme.privooLightPremiumTheme;
      
      case 'Privoo Midnight':
        return AppTheme.privooMidnightTheme;
      
      case 'Privoo Royal':
        return AppTheme.privooRoyalTheme;
      
      case 'Privoo Ocean':
        return AppTheme.privooOceanTheme;
      
      case 'Privoo Aurora':
        return AppTheme.privooAuroraTheme;
      
      case 'Privoo Obsidian':
        return AppTheme.privooObsidianTheme;
      
      default:
        // ✅ الثيمات القديمة من AppTheme
        return AppTheme.getTheme(themeName);
    }
  }

  /// ✅ التحقق من دعم الوضع الفاتح للثيم
  static bool supportsLightMode(String themeName) {
    return themeHasLightMode[themeName] ?? false;
  }

  /// ✅ قائمة الثيمات المتاحة للمستخدم
  static List<String> getAvailableThemes(bool isPro) {
    if (isPro) {
      return AppTheme.allThemeNames;
    } else {
      return AppTheme.freeThemes.toList();
    }
  }

  /// ✅ الحصول على الثيم الافتراضي
  static String get defaultTheme => 'Privoo Premium';
  static ThemeMode get defaultThemeMode => ThemeMode.dark;
}
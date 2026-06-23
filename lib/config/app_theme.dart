// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // 🎨 ألوان Privoo - الهوية الجديدة (بنفسجي داكن + ذهبي)
  // ============================================================
  
  // ✅ الألوان الأساسية للهوية الجديدة
  static const Color privooDeepPurple = Color(0xFF2D1B4E);  // Surface/Card
  static const Color privooLightPurple = Color(0xFF7B2F9D); // Primary
  static const Color privooGold = Color(0xFFFFD700);        // Secondary/Accent
  
  // ✅ خلفيات داكنة
  static const Color privooDarkBg = Color(0xFF1A1230);      // Background الرئيسي
  static const Color privooDarkerBg = Color(0xFF120C22);    // Dark Background
  static const Color privooLightBg = Color(0xFF2D1B4E);     // Surface (موحد مع البنفسجي)
  
  // ✅ ألوان الكروت
  static const Color privooCardDark = Color(0xFF2D1B4E);     // سطح البطاقات
  static const Color privooCardLight = Color(0xFF3D2B5E);    // سطح بطاقات أفتح قليلاً
  
  // ✅ ألوان الحالات (Status)
  static const Color privooSuccess = Color(0xFF4CAF50);
  static const Color privooError = Color(0xFFF44336);
  static const Color privooInfo = Color(0xFF2196F3);
  static const Color privooWarning = Color(0xFFFF9800);
  
  // ✅ ألوان النصوص (محسنة للخلفية الداكنة)
  static const Color privooTextPrimary = Color(0xFFFFFFFF);
  static const Color privooTextSecondary = Color(0xFFD0C8E6);
  static const Color privooTextHint = Color(0xFF9E95C6);
  
  // ✅ ألوان إضافية للميزات
  static const Color privooBlue = Color(0xFF0066FF);
  static const Color privooRed = Color(0xFFFF3B30);
  static const Color privooGreen = Color(0xFF4CAF50);
  static const Color privooYellow = Color(0xFFFFC107);
  static const Color privooOrange = Color(0xFFFF9800);
  static const Color privooPink = Color(0xFFE91E63);
  static const Color privooTeal = Color(0xFF009688);
  static const Color privooCyan = Color(0xFF00BCD4);
  static const Color privooIndigo = Color(0xFF3F51B5);
  static const Color privooLime = Color(0xFFCDDC39);
  static const Color privooBrown = Color(0xFF795548);
  static const Color privooGrey = Color(0xFF9E9E9E);
  static const Color privooDark = Color(0xFF121212);
  static const Color privooPurple = Color(0xFF9C27B0);

  // ============================================================
  // 🎨 تدرجات لونية احترافية (Gradients)
  // ============================================================
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [privooDarkerBg, privooDarkBg, privooDarkerBg],
  );
  
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [privooLightPurple, privooDeepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [privooLightPurple, privooDeepPurple, privooLightPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldButtonGradient = LinearGradient(
    colors: [privooGold, Color(0xFFFFA500), privooGold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [privooLightPurple, privooGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient cardGradient = LinearGradient(
    colors: [
      privooCardDark.withValues(alpha: 0.95),
      privooCardDark.withValues(alpha: 0.98),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient mainGradient = backgroundGradient;
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [privooGold, Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================
  // 🎨 Helper Shadows (ظلال محسنة)
  // ============================================================
  static BoxShadow mainShadow(Color color) => BoxShadow(
    color: color.withValues(alpha: 0.3),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow goldShadow = BoxShadow(
    color: privooGold.withValues(alpha: 0.25),
    blurRadius: 12,
    spreadRadius: 2,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow cardShadow = BoxShadow(
    color: privooDarkBg.withValues(alpha: 0.5),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );

  // ============================================================
  // ✅ تصنيف الثيمات حسب نوع الاشتراك
  // ============================================================
  
  // ✅ الثيمات المجانية
  static const Set<String> freeThemes = {
    'Privoo Premium',
    // ✅ الثيمات القديمة المجانية
    'Privoo Light',
    'Privoo Dark',
    'Blue Light',
    'Blue Dark',
    'Grey Light',
    'Grey Dark',
    'Purple Light',
    'Purple Dark',
  };
  
  // ✅ الثيمات المدفوعة (Pro)
  static const Set<String> proThemes = {
    'Privoo Midnight',
    'Privoo Royal',
    'Privoo Ocean',
    'Privoo Aurora',
    'Privoo Obsidian',
    // ✅ الثيمات القديمة المدفوعة
    'Red Light',
    'Red Dark',
    'Green Light',
    'Green Dark',
    'Yellow Light',
    'Yellow Dark',
    'Orange Light',
    'Orange Dark',
    'Pink Light',
    'Pink Dark',
    'Teal Light',
    'Teal Dark',
    'Cyan Light',
    'Cyan Dark',
    'Indigo Light',
    'Indigo Dark',
    'Neon Dark',
  };
  
  // ✅ جميع الثيمات
  static final Map<String, ThemeData> allThemes = {
    // ✅ ثيمات مجانية
    'Privoo Premium': privooPremiumTheme,
    'Privoo Light': privooLightTheme,
    'Privoo Dark': privooDarkTheme,
    'Blue Light': blueLightTheme,
    'Blue Dark': blueDarkTheme,
    'Grey Light': greyLightTheme,
    'Grey Dark': greyDarkTheme,
    'Purple Light': purpleLightTheme,
    'Purple Dark': purpleDarkTheme,
    
    // ✅ ثيمات Pro (جديدة وقديمة)
    'Privoo Midnight': privooMidnightTheme,
    'Privoo Royal': privooRoyalTheme,
    'Privoo Ocean': privooOceanTheme,
    'Privoo Aurora': privooAuroraTheme,
    'Privoo Obsidian': privooObsidianTheme,
    'Red Light': redLightTheme,
    'Red Dark': redDarkTheme,
    'Green Light': greenLightTheme,
    'Green Dark': greenDarkTheme,
    'Yellow Light': yellowLightTheme,
    'Yellow Dark': yellowDarkTheme,
    'Orange Light': orangeLightTheme,
    'Orange Dark': orangeDarkTheme,
    'Pink Light': pinkLightTheme,
    'Pink Dark': pinkDarkTheme,
    'Teal Light': tealLightTheme,
    'Teal Dark': tealDarkTheme,
    'Cyan Light': cyanLightTheme,
    'Cyan Dark': cyanDarkTheme,
    'Indigo Light': indigoLightTheme,
    'Indigo Dark': indigoDarkTheme,
    'Neon Dark': neonDarkTheme,
  };

  static List<String> get allThemeNames => allThemes.keys.toList();
  
  static bool isThemeAvailable(String themeName, bool isPro) {
    if (freeThemes.contains(themeName)) return true;
    if (isPro && proThemes.contains(themeName)) return true;
    return false;
  }
  
  static List<String> getAvailableThemesForUser(bool isPro) {
    if (isPro) {
      return allThemeNames;
    } else {
      return allThemeNames.where((theme) => freeThemes.contains(theme)).toList();
    }
  }
  
  static int get lockedThemesCount => proThemes.length;

  // ============================================================
  // 🎨 تعريف الثيمات
  // ============================================================
  
  // ✅ الثيم الرئيسي (مجاني)
  static final ThemeData privooPremiumTheme = _buildPremiumTheme();
  
  // ✅ ثيمات Pro الجديدة
  static final ThemeData privooMidnightTheme = _buildProTheme(
    name: 'Privoo Midnight',
    primaryColor: const Color(0xFF1A0A2E),
    secondaryColor: const Color(0xFFFFD700),
    backgroundColor: const Color(0xFF0F0720),
    scaffoldColor: const Color(0xFF0F0720),
    appBarColor: const Color(0xFF0F0720),
    cardColor: const Color(0xFF1A0A2E),
  );

  static final ThemeData privooRoyalTheme = _buildProTheme(
    name: 'Privoo Royal',
    primaryColor: const Color(0xFF4A148C),
    secondaryColor: const Color(0xFFFFD700),
    backgroundColor: const Color(0xFF1A0033),
    scaffoldColor: const Color(0xFF1A0033),
    appBarColor: const Color(0xFF0D001A),
    cardColor: const Color(0xFF2A0055),
  );

  static final ThemeData privooOceanTheme = _buildProTheme(
    name: 'Privoo Ocean',
    primaryColor: const Color(0xFF006994),
    secondaryColor: const Color(0xFF00D4FF),
    backgroundColor: const Color(0xFF0A192F),
    scaffoldColor: const Color(0xFF0A192F),
    appBarColor: const Color(0xFF0A192F),
    cardColor: const Color(0xFF112240),
  );

  static final ThemeData privooAuroraTheme = _buildProTheme(
    name: 'Privoo Aurora',
    primaryColor: const Color(0xFF00B4D8),
    secondaryColor: const Color(0xFF90E0EF),
    backgroundColor: const Color(0xFF0A1128),
    scaffoldColor: const Color(0xFF0A1128),
    appBarColor: const Color(0xFF0A1128),
    cardColor: const Color(0xFF1A2A4A),
  );

  static final ThemeData privooObsidianTheme = _buildProTheme(
    name: 'Privoo Obsidian',
    primaryColor: const Color(0xFF1A1A1A),
    secondaryColor: const Color(0xFFC0C0C0),
    backgroundColor: const Color(0xFF0D0D0D),
    scaffoldColor: const Color(0xFF0D0D0D),
    appBarColor: const Color(0xFF0D0D0D),
    cardColor: const Color(0xFF1A1A1A),
  );

  // ✅ الثيمات القديمة
  static final ThemeData privooLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooDeepPurple,
    secondaryColor: privooGold,
    backgroundColor: privooLightBg,
    scaffoldColor: privooLightBg,
    appBarColor: privooDeepPurple,
    cardColor: Colors.white,
    name: 'Privoo Light',
  );

  static final ThemeData privooDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooLightPurple,
    secondaryColor: privooGold,
    backgroundColor: privooDarkBg,
    scaffoldColor: privooDarkBg,
    appBarColor: privooDarkBg,
    cardColor: privooCardDark,
    name: 'Privoo Dark',
  );

  static final ThemeData blueLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooBlue,
    secondaryColor: privooPurple,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooBlue,
    cardColor: privooBlue.withValues(alpha: 0.05),
    name: 'Blue Light',
  );

  static final ThemeData blueDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooBlue,
    secondaryColor: privooPurple,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooBlue.withValues(alpha: 0.1),
    name: 'Blue Dark',
  );

  static final ThemeData greyLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooGrey,
    secondaryColor: privooBlue,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooGrey,
    cardColor: privooGrey.withValues(alpha: 0.05),
    name: 'Grey Light',
  );

  static final ThemeData greyDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooGrey,
    secondaryColor: privooBlue,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooGrey.withValues(alpha: 0.1),
    name: 'Grey Dark',
  );

  static final ThemeData purpleLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooPurple,
    secondaryColor: privooPink,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooPurple,
    cardColor: privooPurple.withValues(alpha: 0.05),
    name: 'Purple Light',
  );

  static final ThemeData purpleDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooPurple,
    secondaryColor: privooPink,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooPurple.withValues(alpha: 0.1),
    name: 'Purple Dark',
  );

  static final ThemeData redLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooRed,
    secondaryColor: privooOrange,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooRed,
    cardColor: privooRed.withValues(alpha: 0.05),
    name: 'Red Light',
  );

  static final ThemeData redDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooRed,
    secondaryColor: privooOrange,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooRed.withValues(alpha: 0.1),
    name: 'Red Dark',
  );

  static final ThemeData greenLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooGreen,
    secondaryColor: privooTeal,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooGreen,
    cardColor: privooGreen.withValues(alpha: 0.05),
    name: 'Green Light',
  );

  static final ThemeData greenDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooGreen,
    secondaryColor: privooTeal,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooGreen.withValues(alpha: 0.1),
    name: 'Green Dark',
  );

  static final ThemeData yellowLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooYellow,
    secondaryColor: privooOrange,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooYellow,
    cardColor: privooYellow.withValues(alpha: 0.05),
    name: 'Yellow Light',
  );

  static final ThemeData yellowDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooYellow,
    secondaryColor: privooOrange,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooYellow.withValues(alpha: 0.1),
    name: 'Yellow Dark',
  );

  static final ThemeData orangeLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooOrange,
    secondaryColor: privooRed,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooOrange,
    cardColor: privooOrange.withValues(alpha: 0.05),
    name: 'Orange Light',
  );

  static final ThemeData orangeDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooOrange,
    secondaryColor: privooRed,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooOrange.withValues(alpha: 0.1),
    name: 'Orange Dark',
  );

  static final ThemeData pinkLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooPink,
    secondaryColor: privooPurple,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooPink,
    cardColor: privooPink.withValues(alpha: 0.05),
    name: 'Pink Light',
  );

  static final ThemeData pinkDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooPink,
    secondaryColor: privooPurple,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooPink.withValues(alpha: 0.1),
    name: 'Pink Dark',
  );

  static final ThemeData tealLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooTeal,
    secondaryColor: privooCyan,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooTeal,
    cardColor: privooTeal.withValues(alpha: 0.05),
    name: 'Teal Light',
  );

  static final ThemeData tealDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooTeal,
    secondaryColor: privooCyan,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooTeal.withValues(alpha: 0.1),
    name: 'Teal Dark',
  );

  static final ThemeData cyanLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooCyan,
    secondaryColor: privooBlue,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooCyan,
    cardColor: privooCyan.withValues(alpha: 0.05),
    name: 'Cyan Light',
  );

  static final ThemeData cyanDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooCyan,
    secondaryColor: privooBlue,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooCyan.withValues(alpha: 0.1),
    name: 'Cyan Dark',
  );

  static final ThemeData indigoLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooIndigo,
    secondaryColor: privooPurple,
    backgroundColor: Colors.white,
    scaffoldColor: Colors.white,
    appBarColor: privooIndigo,
    cardColor: privooIndigo.withValues(alpha: 0.05),
    name: 'Indigo Light',
  );

  static final ThemeData indigoDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooIndigo,
    secondaryColor: privooPurple,
    backgroundColor: privooDark,
    scaffoldColor: privooDark,
    appBarColor: privooDark,
    cardColor: privooIndigo.withValues(alpha: 0.1),
    name: 'Indigo Dark',
  );

  static final ThemeData neonDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: Colors.cyanAccent,
    secondaryColor: Colors.pinkAccent,
    backgroundColor: Colors.black,
    scaffoldColor: Colors.black,
    appBarColor: Colors.black,
    cardColor: Colors.cyanAccent.withValues(alpha: 0.1),
    name: 'Neon Dark',
    customCardColor: Colors.cyanAccent.withValues(alpha: 0.15),
    customButtonGradient: const LinearGradient(
      colors: [Colors.cyanAccent, Colors.pinkAccent],
    ),
  );

  // ============================================================
  // ✅ ثيم Light Mode لـ Privoo Premium (جديد)
  // ============================================================

  static final ThemeData privooLightPremiumTheme = _buildLightPremiumTheme();

  static ThemeData _buildLightPremiumTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: privooDeepPurple,
        onPrimary: Colors.white,
        secondary: privooGold,
        onSecondary: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black87,
        error: privooError,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: privooDeepPurple),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooDeepPurple, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade600),
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: privooDeepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: privooDeepPurple,
        unselectedItemColor: Colors.grey,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: privooDeepPurple.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: privooDeepPurple);
          }
          return const TextStyle(fontSize: 12, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: privooDeepPurple);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.black54),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(color: Colors.black87),
        actionTextColor: privooDeepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: privooDeepPurple,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: privooDeepPurple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: privooDeepPurple,
        dividerColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: privooDeepPurple,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooDeepPurple;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooDeepPurple.withValues(alpha: 0.5);
          return Colors.grey.withValues(alpha: 0.5);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooDeepPurple;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.grey, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooDeepPurple;
          return Colors.grey;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: privooDeepPurple,
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: privooDeepPurple,
        overlayColor: privooDeepPurple.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: privooDeepPurple,
        textColor: Colors.black87,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // ============================================================
  // 🎨 دالة بناء الثيمات Pro (موحدة)
  // ============================================================
  static ThemeData _buildProTheme({
    required String name,
    required Color primaryColor,
    required Color secondaryColor,
    required Color backgroundColor,
    required Color scaffoldColor,
    required Color appBarColor,
    required Color cardColor,
  }) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      error: privooError,
      onError: Colors.white,
      surface: scaffoldColor,
      onSurface: Colors.white,
      surfaceContainerHighest: cardColor,
      onSurfaceVariant: Colors.grey,
      outline: secondaryColor,
      outlineVariant: Colors.grey.shade600,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: primaryColor,
      onInverseSurface: Colors.white,
      inversePrimary: secondaryColor,
      surfaceTint: primaryColor,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: scaffoldColor,
      cardColor: cardColor,
      primaryColor: primaryColor,
      primaryColorDark: primaryColor,
      primaryColorLight: primaryColor,
      secondaryHeaderColor: secondaryColor,
      
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: 56,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        iconTheme: IconThemeData(color: secondaryColor),
        actionsIconTheme: IconThemeData(color: secondaryColor),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: appBarColor,
        selectedItemColor: secondaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBarColor,
        indicatorColor: primaryColor,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor);
          }
          return const TextStyle(fontSize: 12, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: secondaryColor);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 4,
          shadowColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooError, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        floatingLabelStyle: TextStyle(color: secondaryColor),
        prefixIconColor: Colors.grey.shade500,
        suffixIconColor: Colors.grey.shade500,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
        surfaceTintColor: Colors.transparent,
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: scaffoldColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        elevation: 8,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      tabBarTheme: TabBarTheme(
        labelColor: secondaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: secondaryColor,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        textStyle: const TextStyle(color: Colors.white),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryColor;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryColor.withValues(alpha: 0.5);
          return Colors.grey.withValues(alpha: 0.5);
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: Colors.grey, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryColor;
          return Colors.grey;
        }),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: secondaryColor,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
        thumbColor: secondaryColor,
        overlayColor: secondaryColor.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey),
      ),
      
      dividerTheme: DividerThemeData(
        color: Colors.white24,
        thickness: 1,
        space: 1,
      ),
      
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: secondaryColor,
        textColor: Colors.white,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: secondaryColor,
        circularTrackColor: Colors.grey.withValues(alpha: 0.2),
        linearTrackColor: Colors.grey.withValues(alpha: 0.2),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: scaffoldColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.zero,
          ),
        ),
      ),
      
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(cardColor),
        hintStyle: WidgetStateProperty.all(TextStyle(color: Colors.grey.shade500)),
        textStyle: WidgetStateProperty.all(TextStyle(color: Colors.white)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: BorderSide(color: Colors.white24),
      ),
      
      applyElevationOverlayColor: true,
      
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // ============================================================
  // 🎨 الثيم الافتراضي (Privoo Premium)
  // ============================================================
  
  static ThemeData _buildPremiumTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: privooLightPurple,
      onPrimary: Colors.white,
      primaryContainer: privooDeepPurple,
      onPrimaryContainer: privooTextPrimary,
      secondary: privooGold,
      onSecondary: Colors.black,
      secondaryContainer: privooGold,
      onSecondaryContainer: Colors.black,
      tertiary: privooDeepPurple,
      onTertiary: Colors.white,
      error: privooError,
      onError: Colors.white,
      errorContainer: privooError,
      onErrorContainer: Colors.white,
      surface: privooDeepPurple,
      onSurface: privooTextPrimary,
      surfaceContainerHighest: privooCardLight,
      onSurfaceVariant: privooTextSecondary,
      outline: privooGold,
      outlineVariant: privooTextHint,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: privooLightPurple,
      onInverseSurface: Colors.white,
      inversePrimary: privooGold,
      surfaceTint: privooLightPurple,
    );
    
    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: privooTextPrimary),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: privooTextPrimary),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: privooTextPrimary),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: privooTextPrimary),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: privooTextPrimary),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: privooTextPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: privooTextPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: privooTextPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: privooTextSecondary),
      bodyLarge: TextStyle(fontSize: 16, color: privooTextPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: privooTextPrimary),
      bodySmall: TextStyle(fontSize: 12, color: privooTextSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: privooTextPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: privooTextSecondary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: privooTextHint),
    );
    
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      
      scaffoldBackgroundColor: privooDarkBg,
      canvasColor: privooDarkBg,
      cardColor: privooCardDark,
      primaryColor: privooLightPurple,
      primaryColorDark: privooDeepPurple,
      primaryColorLight: privooLightPurple,
      secondaryHeaderColor: privooGold,
      
      appBarTheme: AppBarTheme(
        backgroundColor: privooDarkBg,
        foregroundColor: privooTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: 56,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        iconTheme: const IconThemeData(color: privooGold),
        actionsIconTheme: const IconThemeData(color: privooGold),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: privooTextPrimary,
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: privooDarkerBg,
        selectedItemColor: privooGold,
        unselectedItemColor: privooTextSecondary,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: privooDarkerBg,
        indicatorColor: privooLightPurple,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: privooGold);
          }
          return const TextStyle(fontSize: 12, color: privooTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: privooGold);
          }
          return const IconThemeData(color: privooTextSecondary);
        }),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: privooLightPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: privooTextHint,
          disabledForegroundColor: privooTextSecondary,
          elevation: 4,
          shadowColor: privooLightPurple,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: privooGold,
          side: const BorderSide(color: privooGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: privooGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: privooLightPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: privooDeepPurple,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: privooTextHint.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: privooError, width: 2),
        ),
        hintStyle: TextStyle(color: privooTextHint, fontSize: 14),
        labelStyle: TextStyle(color: privooTextSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: privooGold),
        prefixIconColor: privooTextHint,
        suffixIconColor: privooTextHint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardThemeData(
        color: privooCardDark,
        elevation: 4,
        shadowColor: privooDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
        surfaceTintColor: Colors.transparent,
      ),
      
      dialogTheme: DialogTheme(
        backgroundColor: privooDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: privooTextPrimary),
        contentTextStyle: const TextStyle(fontSize: 14, color: privooTextSecondary),
        elevation: 8,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      tabBarTheme: TabBarTheme(
        labelColor: privooGold,
        unselectedLabelColor: privooTextSecondary,
        indicatorColor: privooGold,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: privooCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        textStyle: TextStyle(color: privooTextPrimary),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold;
          return privooTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold.withValues(alpha: 0.5);
          return privooTextHint.withValues(alpha: 0.5);
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: privooTextHint, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold;
          return privooTextHint;
        }),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: privooGold,
        inactiveTrackColor: privooTextHint.withValues(alpha: 0.3),
        thumbColor: privooGold,
        overlayColor: privooGold.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      
      iconTheme: const IconThemeData(color: privooTextPrimary, size: 24),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      
      dividerTheme: DividerThemeData(
        color: privooTextSecondary.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: privooGold,
        textColor: privooTextPrimary,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontSize: 13, color: privooTextSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: privooCardDark,
        contentTextStyle: const TextStyle(color: privooTextPrimary),
        actionTextColor: privooGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: privooGold,
        circularTrackColor: privooTextHint.withValues(alpha: 0.2),
        linearTrackColor: privooTextHint.withValues(alpha: 0.2),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: privooDarkBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.zero,
          ),
        ),
      ),
      
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(privooCardDark),
        hintStyle: WidgetStateProperty.all(TextStyle(color: privooTextHint)),
        textStyle: WidgetStateProperty.all(TextStyle(color: privooTextPrimary)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: privooCardDark,
        selectedColor: privooLightPurple,
        secondarySelectedColor: privooGold,
        labelStyle: TextStyle(color: privooTextPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: BorderSide(color: privooTextHint.withValues(alpha: 0.2)),
      ),
      
      applyElevationOverlayColor: true,
      
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: privooCardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: privooTextPrimary),
      ),
    );
  }

  // ============================================================
  // 🎨 دالة بناء الثيم (المساعدة للثيمات الأخرى)
  // ============================================================
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color backgroundColor,
    required Color scaffoldColor,
    required Color appBarColor,
    required Color cardColor,
    required String name,
    Color? customCardColor,
    LinearGradient? customButtonGradient,
  }) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Cairo',
      
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        error: privooError,
        onError: Colors.white,
        surface: scaffoldColor,
        onSurface: isDark ? Colors.white : Colors.black,
      ),
      
      scaffoldBackgroundColor: scaffoldColor,
      
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 6,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 10,
        shape: const CircleBorder(),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return secondaryColor.withValues(alpha: 0.9);
            }
            return primaryColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 14;
            return 8;
          }),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: customCardColor ?? cardColor,
        shadowColor: primaryColor.withValues(alpha: isDark ? 0.5 : 0.35),
        elevation: isDark ? 10 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? scaffoldColor.withValues(alpha: 0.8)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: TextStyle(color: isDark ? privooTextHint : Colors.grey.shade600),
        labelStyle: TextStyle(color: isDark ? privooTextSecondary : Colors.grey.shade700),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white24 : Colors.black12,
        thickness: 1,
      ),
    );
  }

  // ============================================================
  // 🎨 دوال المساعدة (Helper Functions)
  // ============================================================
  
  static ThemeData getTheme(String themeName) {
    // ✅ إذا كان الثيم Privoo Premium، استخدم الثيم المناسب
    if (themeName == 'Privoo Premium') {
      return privooPremiumTheme;
    }
    return allThemes[themeName] ?? privooPremiumTheme;
  }
  
  static String getThemeName(ThemeData theme) {
    final entry = allThemes.entries.firstWhere(
      (entry) => entry.value == theme,
      orElse: () => MapEntry('Privoo Premium', privooPremiumTheme),
    );
    return entry.key;
  }
  
  static final ThemeData lightTheme = privooLightTheme;
  static final ThemeData darkTheme = privooPremiumTheme;
}

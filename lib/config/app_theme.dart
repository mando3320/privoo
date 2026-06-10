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
  
  // ✅ تدرج الخلفية الرئيسية
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    bottomLeft: Alignment.bottomRight,
    colors: [privooDarkerBg, privooDarkBg, privooDarkerBg],
  );
  
  // ✅ تدرج AppBar
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [privooLightPurple, privooDeepPurple],
    begin: Alignment.topLeft,
    bottomLeft: Alignment.bottomRight,
  );

  // ✅ تدرج الأزرار الرئيسية
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [privooLightPurple, privooDeepPurple, privooLightPurple],
    begin: Alignment.centerLeft,
    bottomLeft: Alignment.centerRight,
  );

  // ✅ تدرج الأزرار الذهبية (Pro/Upgrade)
  static const LinearGradient goldButtonGradient = LinearGradient(
    colors: [privooGold, Color(0xFFFFA500), privooGold],
    begin: Alignment.centerLeft,
    bottomLeft: Alignment.centerRight,
  );

  // ✅ تدرج أزرار FAB
  static const LinearGradient fabGradient = LinearGradient(
    colors: [privooLightPurple, privooGold],
    begin: Alignment.topLeft,
    bottomLeft: Alignment.bottomRight,
  );

  // ✅ تدرج الكروت
  static final LinearGradient cardGradient = LinearGradient(
    colors: [
      privooCardDark.withValues(alpha: 0.95),
      privooCardDark.withValues(alpha: 0.98),
    ],
    begin: Alignment.topLeft,
    bottomLeft: Alignment.bottomRight,
  );
  
  // ✅ تدرج الخلفية الرئيسية (احتياطي)
  static const LinearGradient mainGradient = backgroundGradient;
  
  // ✅ تدرج ذهبي للزينة
  static const LinearGradient goldGradient = LinearGradient(
    colors: [privooGold, Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    bottomLeft: Alignment.bottomRight,
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
  
  static const Set<String> freeThemes = {
    'Privoo Premium',  // ✅ أصبح الاسم يعكس الهوية الجديدة
    'Privoo Light',    // احتياطي
    'Privoo Dark',
    'Blue Light',
    'Blue Dark',
    'Grey Light',
    'Grey Dark',
    'Purple Light',
    'Purple Dark',
  };
  
  static final Map<String, ThemeData> allThemes = {
    'Privoo Premium': privooPremiumTheme,   // ✅ الثيم الرئيسي الجديد
    'Privoo Light': privooLightTheme,
    'Privoo Dark': privooDarkTheme,
    'Blue Light': blueLightTheme,
    'Blue Dark': blueDarkTheme,
    'Grey Light': greyLightTheme,
    'Grey Dark': greyDarkTheme,
    'Purple Light': purpleLightTheme,
    'Purple Dark': purpleDarkTheme,
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
    if (isPro && allThemes.containsKey(themeName)) return true;
    return false;
  }
  
  static List<String> getAvailableThemesForUser(bool isPro) {
    if (isPro) {
      return allThemeNames;
    } else {
      return allThemeNames.where((theme) => freeThemes.contains(theme)).toList();
    }
  }
  
  static int get lockedThemesCount => allThemeNames.length - freeThemes.length;

  // ============================================================
  // 🎨 تعريف الثيمات
  // ============================================================
  
  // ✅ الثيم الرئيسي الجديد (Premium)
  static final ThemeData privooPremiumTheme = _buildPremiumTheme();

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

  // ✅ الثيمات الإضافية (سيتم تحديثها تدريجياً)
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
  // 🎨 دالة بناء الثيم الأساسية (Premium)
  // ============================================================
  
  static ThemeData _buildPremiumTheme() {
    // ✅ إنشاء ColorScheme متكامل
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: privooLightPurple,      // #7B2F9D
      onPrimary: Colors.white,
      primaryContainer: privooDeepPurple,
      onPrimaryContainer: privooTextPrimary,
      secondary: privooGold,            // #FFD700
      onSecondary: Colors.black,
      secondaryContainer: privooGold,
      onSecondaryContainer: Colors.black,
      tertiary: privooDeepPurple,
      onTertiary: Colors.white,
      error: privooError,               // #F44336
      onError: Colors.white,
      errorContainer: privooError,
      onErrorContainer: Colors.white,
      surface: privooDeepPurple,        // #2D1B4E
      onSurface: privooTextPrimary,     // #FFFFFF
      surfaceContainerHighest: privooCardLight,
      onSurfaceVariant: privooTextSecondary,  // #D0C8E6
      outline: privooGold,
      outlineVariant: privooTextHint,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: privooLightPurple,
      onInverseSurface: Colors.white,
      inversePrimary: privooGold,
      surfaceTint: privooLightPurple,
    );
    
    // ✅ نص ثيم محسن للوضع الداكن
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
      // ✅ الأساسيات
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      
      // ✅ الألوان الأساسية
      scaffoldBackgroundColor: privooDarkBg,      // #1A1230
      canvasColor: privooDarkBg,
      cardColor: privooCardDark,                  // #2D1B4E
      primaryColor: privooLightPurple,
      primaryColorDark: privooDeepPurple,
      primaryColorLight: privooLightPurple,
      secondaryHeaderColor: privooGold,
      
      // ✅ AppBar
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
      ),
      
      // ✅ Bottom Navigation Bar
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
      
      // ✅ Navigation Bar (Material 3)
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
      
      // ✅ الأزرار
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: privooGold,
          side: const BorderSide(color: privooGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: privooGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: privooLightPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      
      // ✅ الحقول النصية
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
      
      // ✅ الكروت
      cardTheme: CardThemeData(
        color: privooCardDark,
        elevation: 4,
        shadowColor: privooDarkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),
      
      // ✅ الحوارات
      dialogTheme: DialogTheme(
        backgroundColor: privooDarkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: privooTextPrimary),
        contentTextStyle: const TextStyle(fontSize: 14, color: privooTextSecondary),
        elevation: 8,
      ),
      
      // ✅ التبويبات (Tabs)
      tabBarTheme: TabBarTheme(
        labelColor: privooGold,
        unselectedLabelColor: privooTextSecondary,
        indicatorColor: privooGold,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
      ),
      
      // ✅ القوائم المنبثقة
      popupMenuTheme: PopupMenuThemeData(
        color: privooCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      
      // ✅ أزرار التبديل (Switch)
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
      
      // ✅ صناديق الاختيار (Checkbox)
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: privooTextHint, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // ✅ أزرار الراديو (Radio)
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return privooGold;
          return privooTextHint;
        }),
      ),
      
      // ✅ شريط التمرير (Slider)
      sliderTheme: SliderThemeData(
        activeTrackColor: privooGold,
        inactiveTrackColor: privooTextHint.withValues(alpha: 0.3),
        thumbColor: privooGold,
        overlayColor: privooGold.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      
      // ✅ الأيقونات
      iconTheme: const IconThemeData(color: privooTextPrimary, size: 24),
      
      // ✅ الخطوط (Typography)
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      
      // ✅ شريط التقسيم (Divider)
      dividerTheme: DividerThemeData(
        color: privooTextSecondary.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      
      // ✅ قوائم ListTile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: privooGold,
        textColor: privooTextPrimary,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontSize: 13, color: privooTextSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      // ✅ SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: privooCardDark,
        contentTextStyle: const TextStyle(color: privooTextPrimary),
        actionTextColor: privooGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ✅ مؤشر التحميل (Progress Indicator)
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: privooGold,
        circularTrackColor: privooTextHint.withValues(alpha: 0.2),
        linearTrackColor: privooTextHint.withValues(alpha: 0.2),
      ),
      
      // ✅ الشريط الجانبي (Drawer)
      drawerTheme: DrawerThemeData(
        backgroundColor: privooDarkBg,
        shape: const RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.zero,
          ),
        ),
      ),
      
      // ✅ شريط البحث (Search Bar)
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(privooCardDark),
        hintStyle: WidgetStateProperty.all(TextStyle(color: privooTextHint)),
        textStyle: WidgetStateProperty.all(TextStyle(color: privooTextPrimary)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      
      // ✅ أزرار المساعدة السريعة (Chips)
      chipTheme: ChipThemeData(
        backgroundColor: privooCardDark,
        selectedColor: privooLightPurple,
        secondarySelectedColor: privooGold,
        labelStyle: TextStyle(color: privooTextPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      
      // ✅ تأثيرات الظل
      applyElevationOverlayColor: true,
      
      // ✅ حجم التلميحات
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  static final ThemeData darkTheme = privooPremiumTheme;  // ✅ الثيم الرئيسي الجديد
}
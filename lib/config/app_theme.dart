// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // 🎨 ألوان Privoo - مطابقة للوجو (أرجواني داكن + ذهبي)
  // ============================================================
  
  // الألوان الأساسية من اللوجو
  static const Color privooDeepPurple = Color(0xFF2D1B4E);
  static const Color privooGold = Color(0xFFFFD700);
  static const Color privooLightPurple = Color(0xFF7B2F9D);
  static const Color privooDarkBg = Color(0xFF1A1A2E);
  static const Color privooLightBg = Color(0xFFF8F9FA);
  static const Color privooCardDark = Color(0xFF16213E);
  static const Color privooCardLight = Color(0xFFFFFFFF);
  
  // ✅ ألوان إضافية مطلوبة للشاشات
  static const Color privooSuccess = Color(0xFF4CAF50);
  static const Color privooError = Color(0xFFE53935);
  static const Color privooInfo = Color(0xFF2196F3);
  
  // ألوان إضافية للميزات (محتفظ بها من الكود الأصلي)
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
  // 🎨 تدرجات لونية (Gradients)
  // ============================================================
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [privooDeepPurple, privooLightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [privooDeepPurple, privooLightPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [privooLightPurple, privooGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.05)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mainGradient = LinearGradient(
    colors: [privooDeepPurple, privooLightPurple, privooGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [privooGold, Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================
  // 🎨 Helper Shadows
  // ============================================================
  static BoxShadow mainShadow(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: const Offset(0, 6),
      );
  
  static BoxShadow goldShadow = BoxShadow(
    color: privooGold.withValues(alpha: 0.3),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );

  // ============================================================
  // ✅ تصنيف الثيمات حسب نوع الاشتراك
  // ============================================================
  
  static const Set<String> freeThemes = {
    'Privoo Light',
    'Privoo Dark',
    'Blue Light',
    'Blue Dark',
    'Grey Light',
    'Grey Dark',
    'Purple Light',
    'Purple Dark',
  };
  
  static final Map<String, ThemeData> allThemes = {
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

  static final ThemeData privooLightTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: privooDeepPurple,
    secondaryColor: privooGold,
    backgroundColor: privooLightBg,
    scaffoldColor: privooLightBg,
    appBarColor: privooDeepPurple,
    cardColor: privooDeepPurple.withValues(alpha: 0.05),
    name: 'Privoo Light',
  );

  static final ThemeData privooDarkTheme = _buildTheme(
    brightness: Brightness.dark,
    primaryColor: privooLightPurple,
    secondaryColor: privooGold,
    backgroundColor: privooDarkBg,
    scaffoldColor: privooDarkBg,
    appBarColor: privooDarkBg,
    cardColor: privooLightPurple.withValues(alpha: 0.1),
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
  // 🎨 دالة بناء الثيم (المساعدة)
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
        error: privooRed,
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
    return allThemes[themeName] ?? privooLightTheme;
  }
  
  static String getThemeName(ThemeData theme) {
    final entry = allThemes.entries.firstWhere(
      (entry) => entry.value == theme,
      orElse: () => MapEntry('Privoo Light', privooLightTheme),
    );
    return entry.key;
  }
  
  static final ThemeData lightTheme = privooLightTheme;
  static final ThemeData darkTheme = privooDarkTheme;
}
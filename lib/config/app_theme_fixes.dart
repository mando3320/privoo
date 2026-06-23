// lib/config/app_theme_fixes.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppThemeFixes {
  static Color getPrimaryTextColor(BuildContext context) {
    // ✅ تم التحديث من onBackground لـ onSurface
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    // ✅ تم تصحيح الشفافية والمسميات لتطابق التحديث الجديد
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }
  
  static Color getPrimaryButtonColor(BuildContext context) {
    return AppTheme.privooBlue;
  }
  
  static Color getDangerButtonColor(BuildContext context) {
    return AppTheme.privooRed;
  }
  
  static Color getSuccessColor(BuildContext context) {
    return AppTheme.privooGreen;
  }

  // ============================================================
  // ✅ دوال جديدة لدعم Light Mode
  // ============================================================

  /// ✅ الحصول على لون الخلفية حسب الوضع (Light/Dark)
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.privooDarkBg : Colors.white;
  }

  /// ✅ الحصول على لون البطاقة حسب الوضع
  static Color getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.privooCardDark : Colors.white;
  }

  /// ✅ التحقق من الوضع الحالي (داكن أم فاتح)
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// ✅ الحصول على لون النص المناسب حسب الوضع
  static Color getTextColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  /// ✅ الحصول على لون النص الثانوي حسب الوضع
  static Color getSecondaryTextColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  /// ✅ الحصول على لون النص التلميحي حسب الوضع
  static Color getHintTextColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade500 : Colors.grey.shade400;
  }

  /// ✅ الحصول على لون الحدود حسب الوضع
  static Color getBorderColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  /// ✅ الحصول على لون الظل حسب الوضع
  static Color getShadowColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black54 : Colors.black12;
  }

  /// ✅ الحصول على لون الخلفية المميزة حسب الوضع
  static Color getHighlightColorForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.privooLightPurple.withValues(alpha: 0.2) : AppTheme.privooDeepPurple.withValues(alpha: 0.1);
  }

  /// ✅ الحصول على قيمة الـ Elevation المناسبة حسب الوضع
  static double getElevationForTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? 0 : 2;
  }
}

class ThemedScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool centerTitle;
  
  const ThemedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام دوال Light Mode الجديدة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.privooDarkBg : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        centerTitle: centerTitle,
        actions: actions,
        backgroundColor: isDark ? AppTheme.privooDarkBg : Colors.white,
        foregroundColor: textColor,
        elevation: isDark ? 0 : 2,
        flexibleSpace: isDark
            ? Container(
                decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
              )
            : null,
      ),
      body: body,
    );
  }
}
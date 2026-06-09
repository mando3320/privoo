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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
        ),
      ),
      body: body,
    );
  }
}

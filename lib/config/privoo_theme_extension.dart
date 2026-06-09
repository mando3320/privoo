// config/privoo_theme_extension.dart
import 'package:flutter/material.dart';

class PrivooThemeExtension extends ThemeExtension<PrivooThemeExtension> {
  final Color? privooBlue;
  final Color? privooRed;
  final Color? privooPurple;
  final LinearGradient? appBarGradient;
  final LinearGradient? buttonGradient;

  const PrivooThemeExtension({
    this.privooBlue,
    this.privooRed,
    this.privooPurple,
    this.appBarGradient,
    this.buttonGradient,
  });

  @override
  ThemeExtension<PrivooThemeExtension> copyWith({
    Color? privooBlue,
    Color? privooRed,
    Color? privooPurple,
    LinearGradient? appBarGradient,
    LinearGradient? buttonGradient,
  }) {
    return PrivooThemeExtension(
      privooBlue: privooBlue ?? this.privooBlue,
      privooRed: privooRed ?? this.privooRed,
      privooPurple: privooPurple ?? this.privooPurple,
      appBarGradient: appBarGradient ?? this.appBarGradient,
      buttonGradient: buttonGradient ?? this.buttonGradient,
    );
  }

  @override
  ThemeExtension<PrivooThemeExtension> lerp(
    covariant ThemeExtension<PrivooThemeExtension>? other,
    double t,
  ) {
    if (other is! PrivooThemeExtension) return this;
    return PrivooThemeExtension(
      privooBlue: Color.lerp(privooBlue, other.privooBlue, t),
      privooRed: Color.lerp(privooRed, other.privooRed, t),
      privooPurple: Color.lerp(privooPurple, other.privooPurple, t),
      appBarGradient: LinearGradient.lerp(appBarGradient, other.appBarGradient, t),
      buttonGradient: LinearGradient.lerp(buttonGradient, other.buttonGradient, t),
    );
  }
}
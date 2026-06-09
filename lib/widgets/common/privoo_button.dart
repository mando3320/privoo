// lib/widgets/common/privoo_button.dart
import 'package:flutter/material.dart';
import 'package:privoo/config/app_theme.dart'; // ✅ تم تصحيح المسار ليكون حزمياً ومضموناً

enum PrivooButtonType {
  primary,
  secondary,
  danger,
  success,
}

class PrivooButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final PrivooButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const PrivooButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = PrivooButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height = 50,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(context),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final colors = _getButtonColors();
    
    return ElevatedButton.styleFrom(
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      elevation: 4,
      shadowColor: AppTheme.privooPurple.withValues(alpha: 0.3), // ✅ تم التحديث إلى معايير فلاتر الجديدة
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: type == PrivooButtonType.secondary 
            ? const BorderSide(color: AppTheme.privooBlue, width: 1.5) 
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  ({Color background, Color foreground}) _getButtonColors() {
    switch (type) {
      case PrivooButtonType.primary:
        return (
          background: AppTheme.privooBlue,
          foreground: Colors.white,
        );
      case PrivooButtonType.secondary:
        return (
          background: Colors.transparent,
          foreground: AppTheme.privooBlue,
        );
      case PrivooButtonType.danger:
        return (
          background: AppTheme.privooRed,
          foreground: Colors.white,
        );
      case PrivooButtonType.success:
        return (
          background: AppTheme.privooGreen,
          foreground: Colors.white,
        );
    }
  }
}

class PrivooOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isFullWidth;

  const PrivooOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.privooBlue,
          side: const BorderSide(color: AppTheme.privooBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text),
      ),
    );
  }
}

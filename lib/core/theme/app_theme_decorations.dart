import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_theme.dart';

class AppThemeDecorations {
  AppThemeDecorations._();

  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.gold.withValues(alpha: 0.85), size: 20),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
    );
  }

  static BoxDecoration cardDecoration({bool isHovered = false}) {
    return BoxDecoration(
      color: AppColors.cardDark.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(
        color: isHovered
            ? AppColors.gold.withValues(alpha: 0.4)
            : AppColors.gold.withValues(alpha: 0.18),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.35 : 0.25),
          blurRadius: isHovered ? 24 : 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle({bool isLoading = false}) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      ),
      elevation: WidgetStateProperty.all(isLoading ? 0 : 4),
      shadowColor: WidgetStateProperty.all(
        isLoading ? Colors.transparent : AppColors.gold.withValues(alpha: 0.35),
      ),
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      ),
      side: WidgetStateProperty.all(
        BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      foregroundColor: WidgetStateProperty.all(AppColors.gold),
    );
  }
}

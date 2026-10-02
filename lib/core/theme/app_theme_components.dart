import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_theme.dart';

class AppThemeComponents {
  AppThemeComponents._();

  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      duration: const Duration(seconds: 5),
    );
  }

  static SnackBar infoSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.textMuted,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      duration: const Duration(seconds: 4),
    );
  }

  static Widget badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyLg,
          ),
        ],
      ),
    );
  }

  static Widget loadingState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.gold,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message, style: AppTheme.bodyLg),
          ],
        ],
      ),
    );
  }

  static Widget errorState(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: AppTheme.bodyLg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget glowCircle({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  static Widget fadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

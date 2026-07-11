import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Sistema de diseño compartido — LOCUSTAF.
///
/// Todos los widgets de la aplicación deben usar estos helpers
/// para mantener identidad visual consistente con el Login.
class AppTheme {
  AppTheme._();

  // ── ThemeData for MaterialApp ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDarkTop,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
      surface: AppColors.cardDark,
      error: AppColors.error,
      onPrimary: AppColors.bgDarkTop,
      onSecondary: AppColors.bgDarkTop,
      onSurface: AppColors.textWhite,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sidebar,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.gold),
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.gold,
      thickness: 0.3,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
    ),
  );

  // ── Breakpoints ──────────────────────────────────────────────────────────
  static const double mobile = 768;
  static const double tablet = 992;
  static const double laptop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < laptop;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= laptop;

  // ── Border Radius ────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 24.0;

  // ── Spacing ──────────────────────────────────────────────────────────────
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // ── Typography ───────────────────────────────────────────────────────────
  static const TextStyle headingLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ── Gradient principal ───────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgDarkTop, AppColors.bgDarkBottom],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [AppColors.gold, AppColors.goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientHorizontal = LinearGradient(
    colors: [AppColors.gold, AppColors.goldLight],
  );

  // ── InputDecoration ───────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
    );
  }

  // ── CardDecoration ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({bool isHovered = false}) {
    return BoxDecoration(
      color: AppColors.cardDark.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(radiusXl),
      border: Border.all(
        color: isHovered
            ? AppColors.gold.withValues(alpha: 0.4)
            : AppColors.gold.withValues(alpha: 0.18),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: isHovered ? 0.1 : 0.06),
          blurRadius: isHovered ? 50 : 40,
          spreadRadius: isHovered ? 6 : 4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 30,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  // ── Button Styles ────────────────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle({bool isLoading = false}) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      side: WidgetStateProperty.all(
        BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      foregroundColor: WidgetStateProperty.all(AppColors.gold),
    );
  }

  // ── SnackBar ─────────────────────────────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      duration: const Duration(seconds: 5),
    );
  }

  // ── Badge ────────────────────────────────────────────────────────────────
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

  // ── Empty State ──────────────────────────────────────────────────────────
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
            style: bodyLg,
          ),
        ],
      ),
    );
  }

  // ── Loading State ────────────────────────────────────────────────────────
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
            Text(message, style: bodyLg),
          ],
        ],
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  static Widget errorState(String message) {
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
          Text(message, style: bodyLg, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Glow Circle (decorativo) ────────────────────────────────────────────
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

  // ── Page Transition ──────────────────────────────────────────────────────
  static Widget fadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

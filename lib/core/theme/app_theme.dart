import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'app_theme_components.dart';
import 'app_theme_decorations.dart';

/// Sistema de diseño compartido — LOCUSTAF.
///
/// Todos los widgets de la aplicación deben usar estos helpers
/// para mantener identidad visual consistente con el Login.
class AppTheme {
  AppTheme._();

  /// Tipografía corporativa — IBM Plex (Sans para UI, Mono para datos).
  ///
  /// Se aplica al `textTheme` del material app; los estilos tipográficos
  /// específicos ([corpSans]/[corpMono]) se usan en pantallas rediseñadas.
  static TextStyle sans({TextStyle? base, double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.ibmPlexSans(
        textStyle: (base ?? const TextStyle()).copyWith(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      );

  // ── ThemeData for MaterialApp ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDarkTop,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.textMuted,
            displayColor: AppColors.textWhite,
          ),
    ),
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
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.sidebar,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.gold),
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
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
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 10.0;
  static const double radiusXl = 16.0;

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
  }) =>
      AppThemeDecorations.inputDecoration(label: label, icon: icon, hint: hint);

  // ── CardDecoration ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({bool isHovered = false}) =>
      AppThemeDecorations.cardDecoration(isHovered: isHovered);

  // ── Button Styles ────────────────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle({bool isLoading = false}) =>
      AppThemeDecorations.primaryButtonStyle(isLoading: isLoading);

  static ButtonStyle secondaryButtonStyle() =>
      AppThemeDecorations.secondaryButtonStyle();

  // ── SnackBar ─────────────────────────────────────────────────────────────
  static SnackBar successSnackBar(String message) =>
      AppThemeComponents.successSnackBar(message);

  static SnackBar errorSnackBar(String message) =>
      AppThemeComponents.errorSnackBar(message);

  static SnackBar infoSnackBar(String message) =>
      AppThemeComponents.infoSnackBar(message);

  // ── Badge ────────────────────────────────────────────────────────────────
  static Widget badge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) =>
      AppThemeComponents.badge(
          label: label, bgColor: bgColor, textColor: textColor);

  // ── Empty State ──────────────────────────────────────────────────────────
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      AppThemeComponents.emptyState(
          icon: icon, title: title, subtitle: subtitle);

  // ── Loading State ────────────────────────────────────────────────────────
  static Widget loadingState({String? message}) =>
      AppThemeComponents.loadingState(message: message);

  // ── Error State ──────────────────────────────────────────────────────────
  static Widget errorState(String message, {VoidCallback? onRetry}) =>
      AppThemeComponents.errorState(message, onRetry: onRetry);

  // ── Glow Circle (decorativo) ────────────────────────────────────────────
  static Widget glowCircle({required Color color, required double size}) =>
      AppThemeComponents.glowCircle(color: color, size: size);

  // ── Page Transition ──────────────────────────────────────────────────────
  static Widget fadeTransition(Animation<double> animation, Widget child) =>
      AppThemeComponents.fadeTransition(animation, child);
}

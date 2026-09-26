import 'package:flutter/material.dart';

/// Paleta oficial LOCUSTAF — Identidad visual unificada.
///
/// Estilo corporativo NAVY + VERDE (Restyle Corporativo, TASK-RESTYLE-001).
/// TODA la aplicación usa exclusivamente estos tokens: se redefinen los
/// valores (no los nombres) para que las pantallas existentes adopten la
/// nueva identidad sin migración archivo por archivo.
class AppColors {
  AppColors._();

  // ── Paleta principal (dark navy) ─────────────────────────────────────────
  /// Fondo navy profundo — superior de gradientes, sidebar.
  static const Color bgDarkTop = Color(0xFF081420);

  /// Fondo navy inferior — gradientes.
  static const Color bgDarkBottom = Color(0xFF0E2236);

  /// Acento verde corporativo — botones primarios, bordes activos, íconos.
  static const Color gold = Color(0xFF2FBF71);

  /// Verde claro — gradientes de botones, hover.
  static const Color goldLight = Color(0xFF77E0A3);

  /// Superficie de cards navy.
  static const Color cardDark = Color(0xFF0F2438);

  // ── Colores semánticos ───────────────────────────────────────────────────
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0EA5E9);

  // ── Texto ────────────────────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFFAFC3D4);
  static const Color textPrimary = Color(0xFF0B1B2A);
  static const Color textSecondary = Color(0xFF8FA8BB);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Bordes y divisores ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color borderGold = Color(0xFF2FBF71);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebar = Color(0xFF081420);
  static const Color sidebarText = Color(0xFFB9C9D8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarItemActive = Color(0xFF2FBF71);
  static const Color sidebarItemHover = Color(0xFF122B42);

  // ── Estados de badge ─────────────────────────────────────────────────────
  static const Color badgePendingBg = Color(0xFFFEF3C7);
  static const Color badgePendingText = Color(0xFF92400E);
  static const Color badgeApprovedBg = Color(0xFFD1FAE5);
  static const Color badgeApprovedText = Color(0xFF065F46);
  static const Color badgeRejectedBg = Color(0xFFFEE2E2);
  static const Color badgeRejectedText = Color(0xFF991B1B);
  static const Color badgeActiveBg = Color(0xFF2FBF71);
  static const Color badgeActiveText = Color(0xFF081420);
  static const Color badgeInactiveBg = Color(0xFF122B42);
  static const Color badgeInactiveText = Color(0xFFB9C9D8);
}

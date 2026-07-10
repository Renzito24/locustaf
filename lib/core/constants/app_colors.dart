import 'package:flutter/material.dart';

/// Paleta oficial LOCUSTAF según STD-001.
class AppColors {
  AppColors._();

  // ── Colores principales ──────────────────────────────────────────────────
  /// Color primario de la marca — botones, acentos, íconos activos.
  static const Color primary = Color(0xFF2563EB);

  /// Color del sidebar lateral.
  static const Color sidebar = Color(0xFF1E293B);

  /// Fondo general de la aplicación.
  static const Color background = Color(0xFFF5F7FA);

  /// Superficie de cards y paneles.
  static const Color surface = Color(0xFFFFFFFF);

  // ── Colores semánticos ───────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0EA5E9);

  // ── Texto ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Bordes y divisores ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebarText = Color(0xFFCBD5E1);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarItemActive = Color(0xFF2563EB);
  static const Color sidebarItemHover = Color(0xFF334155);

  // ── Estados de badge ─────────────────────────────────────────────────────
  static const Color badgePendingBg = Color(0xFFFEF3C7);
  static const Color badgePendingText = Color(0xFF92400E);
  static const Color badgeApprovedBg = Color(0xFFD1FAE5);
  static const Color badgeApprovedText = Color(0xFF065F46);
  static const Color badgeRejectedBg = Color(0xFFFEE2E2);
  static const Color badgeRejectedText = Color(0xFF991B1B);
  static const Color badgeActiveBg = Color(0xFFDBEAFE);
  static const Color badgeActiveText = Color(0xFF1D4ED8);
  static const Color badgeInactiveBg = Color(0xFFF1F5F9);
  static const Color badgeInactiveText = Color(0xFF64748B);
}

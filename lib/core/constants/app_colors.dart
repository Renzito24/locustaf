import 'package:flutter/material.dart';

/// Paleta oficial LOCUSTAF — Identidad visual unificada.
///
/// Basada en el Login como referencia absoluta.
/// TODA la aplicación debe usar exclusivamente estos tokens.
class AppColors {
  AppColors._();

  // ── Paleta principal (Login dark theme) ──────────────────────────────────
  /// Fondo oscuro superior — gradientes, sidebar.
  static const Color bgDarkTop = Color(0xFF0B0B0F);

  /// Fondo oscuro inferior — gradientes.
  static const Color bgDarkBottom = Color(0xFF1A1710);

  /// Acento dorado — botones primarios, bordes activos, íconos.
  static const Color gold = Color(0xFFD4AF37);

  /// Dorado claro — gradientes de botones, hover.
  static const Color goldLight = Color(0xFFF3D98B);

  /// Superficie de cards oscuras.
  static const Color cardDark = Color(0xFF17161C);

  // ── Colores semánticos ───────────────────────────────────────────────────
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0EA5E9);

  // ── Texto ────────────────────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFFCBCBD1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Bordes y divisores ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color borderGold = Color(0xFFD4AF37);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebar = Color(0xFF0B0B0F);
  static const Color sidebarText = Color(0xFFCBCBD1);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarItemActive = Color(0xFFD4AF37);
  static const Color sidebarItemHover = Color(0xFF1A1710);

  // ── Estados de badge ─────────────────────────────────────────────────────
  static const Color badgePendingBg = Color(0xFFFEF3C7);
  static const Color badgePendingText = Color(0xFF92400E);
  static const Color badgeApprovedBg = Color(0xFFD1FAE5);
  static const Color badgeApprovedText = Color(0xFF065F46);
  static const Color badgeRejectedBg = Color(0xFFFEE2E2);
  static const Color badgeRejectedText = Color(0xFF991B1B);
  static const Color badgeActiveBg = Color(0xFFD4AF37);
  static const Color badgeActiveText = Color(0xFF1A1710);
  static const Color badgeInactiveBg = Color(0xFF1A1710);
  static const Color badgeInactiveText = Color(0xFFCBCBD1);
}

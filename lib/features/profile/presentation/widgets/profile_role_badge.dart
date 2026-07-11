import 'package:flutter/material.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileRoleBadge extends StatelessWidget {
  final UserRole role;

  const ProfileRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (role) {
      UserRole.admin => (const Color(0xFFD4AF37).withValues(alpha: 0.2), const Color(0xFFD4AF37), 'Administrador'),
      UserRole.supervisor => (const Color(0xFF0EA5E9).withValues(alpha: 0.2), const Color(0xFF0EA5E9), 'Supervisor'),
      UserRole.employee => (const Color(0xFF059669).withValues(alpha: 0.2), const Color(0xFF059669), 'Empleado'),
    };
    return AppTheme.badge(label: label, bgColor: bg, textColor: fg);
  }
}

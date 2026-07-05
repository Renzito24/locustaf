import 'package:flutter/material.dart';

import '../../../authentication/data/models/user_model.dart';

class ProfileRoleBadge extends StatelessWidget {
  final UserRole role;

  const ProfileRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (role) {
      UserRole.admin => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Administrador'),
      UserRole.supervisor => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF), 'Supervisor'),
      UserRole.employee => (const Color(0xFFD1FAE5), const Color(0xFF065F46), 'Empleado'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

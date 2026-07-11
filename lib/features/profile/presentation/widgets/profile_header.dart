import 'package:flutter/material.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'profile_role_badge.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.goldGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials(user),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${user.nombre} ${user.apellido}',
          style: AppTheme.headingMd,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ProfileRoleBadge(role: user.rol),
      ],
    );
  }

  String _initials(UserModel user) {
    final first = user.nombre.isNotEmpty ? user.nombre[0] : '';
    final last = user.apellido.isNotEmpty ? user.apellido[0] : '';
    return '$first$last'.toUpperCase();
  }
}

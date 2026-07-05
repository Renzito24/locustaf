import 'package:flutter/material.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';
import 'profile_role_badge.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          child: Text(
            _initials(user),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
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

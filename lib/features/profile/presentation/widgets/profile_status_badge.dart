import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileStatusBadge extends StatelessWidget {
  final bool isActive;

  const ProfileStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return AppTheme.badge(
        label: 'Activo',
        bgColor: AppColors.success.withValues(alpha: 0.15),
        textColor: AppColors.success,
      );
    }
    return AppTheme.badge(
      label: 'Inactivo',
      bgColor: AppColors.error.withValues(alpha: 0.15),
      textColor: AppColors.error,
    );
  }
}

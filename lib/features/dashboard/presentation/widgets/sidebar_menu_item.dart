import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: AppColors.sidebarItemHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: isActive
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.gold : AppColors.sidebarText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? AppColors.sidebarTextActive : AppColors.sidebarText,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

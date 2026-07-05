import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<ProfileInfoRow> rows;

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows.fold<List<Widget>>([], (list, row) {
              if (list.isNotEmpty) {
                list.add(const Divider(height: 20));
              }
              if (row.child != null) {
                list.add(row.child!);
              } else {
                list.add(_infoRow(row.icon, row.label, row.value!));
              }
              return list;
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileInfoRow {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  const ProfileInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
  });
}

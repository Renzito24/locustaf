import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/users_provider.dart';

class EmployeeFilterBar extends ConsumerWidget {
  const EmployeeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(employeeFilterProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context: context,
          ref: ref,
          label: 'Todos',
          filter: EmployeeStatusFilter.all,
          isSelected: selectedFilter == EmployeeStatusFilter.all,
        ),
        _buildFilterChip(
          context: context,
          ref: ref,
          label: 'Activos',
          filter: EmployeeStatusFilter.active,
          isSelected: selectedFilter == EmployeeStatusFilter.active,
        ),
        _buildFilterChip(
          context: context,
          ref: ref,
          label: 'Inactivos',
          filter: EmployeeStatusFilter.inactive,
          isSelected: selectedFilter == EmployeeStatusFilter.inactive,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required EmployeeStatusFilter filter,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(employeeFilterProvider.notifier).setFilter(filter);
        }
      },
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
        width: 1,
      ),
    );
  }
}

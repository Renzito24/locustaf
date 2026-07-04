import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/users_provider.dart';

class EmployeeFilterBar extends ConsumerWidget {
  const EmployeeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(employeeFilterProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        const SizedBox(width: 8),
        _buildWorkplaceDropdown(ref, workplacesAsync),
      ],
    );
  }

  Widget _buildWorkplaceDropdown(WidgetRef ref, AsyncValue<List<WorkplaceModel>> workplacesAsync) {
    final selectedWorkplace = ref.watch(employeeWorkplaceFilterProvider);

    return workplacesAsync.when(
      data: (workplaces) {
        if (workplaces.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedWorkplace,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Lugar de trabajo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              ...workplaces.map(
                (w) => DropdownMenuItem<String?>(
                  value: w.id,
                  child: Text(w.nombre, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(employeeWorkplaceFilterProvider.notifier).setFilter(value);
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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

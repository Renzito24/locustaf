import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../providers/history_provider.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);
    final workplacesAsync = ref.watch(allWorkplacesStreamProvider);

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: AppTheme.inputDecoration(
                    label: 'Buscar nombre/apellido',
                    icon: Icons.search,
                    hint: 'Escribe para buscar...',
                  ),
                  style: AppTheme.bodyLg.copyWith(color: AppColors.textWhite),
                  controller: TextEditingController(
                      text: filter.searchQuery.isNotEmpty
                          ? filter.searchQuery
                          : '')
                    ..selection = TextSelection.collapsed(
                        offset: filter.searchQuery.length),
                  onChanged: (value) {
                    ref
                        .read(historyFilterProvider.notifier)
                        .setSearchQuery(value);
                  },
                ),
              ),
              _buildEmployeeDropdown(ref, usersAsync, filter.employeeId),
              _buildWorkplaceDropdown(
                  ref, workplacesAsync, filter.workplaceId),
              _buildStatusDropdown(ref, filter.status),
              _buildDateField(
                context: context,
                ref: ref,
                label: 'Fecha desde',
                value: filter.dateFrom,
                onChanged: (v) => ref
                    .read(historyFilterProvider.notifier)
                    .setDateFrom(v),
              ),
              _buildDateField(
                context: context,
                ref: ref,
                label: 'Fecha hasta',
                value: filter.dateTo,
                onChanged: (v) => ref
                    .read(historyFilterProvider.notifier)
                    .setDateTo(v),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(historyFilterProvider.notifier).clear(),
                icon: const Icon(Icons.clear, color: AppColors.gold),
                label: const Text('Limpiar',
                    style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTheme.bodyMd,
      isDense: true,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide:
            BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide:
            BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide:
            const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildEmployeeDropdown(
    WidgetRef ref,
    AsyncValue<List<UserModel>> usersAsync,
    String? selectedId,
  ) {
    return usersAsync.when(
      data: (users) {
        final employees = users
            .where((u) => u.rol == UserRole.employee && !u.isDeleted)
            .toList();
        return SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: _dropdownDecoration('Empleado'),
            dropdownColor: AppColors.cardDark,
            style: AppTheme.bodyMd.copyWith(color: AppColors.textWhite),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos',
                    style: TextStyle(color: AppColors.textWhite)),
              ),
              ...employees.map(
                (e) => DropdownMenuItem<String?>(
                  value: e.id,
                  child: Text(e.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppColors.textWhite)),
                ),
              ),
            ],
            onChanged: (value) {
              ref
                  .read(historyFilterProvider.notifier)
                  .setEmployeeId(value);
            },
          ),
        );
      },
      loading: () => SizedBox(
        width: 200,
        child: TextField(
          decoration: _dropdownDecoration('Empleado'),
          enabled: false,
        ),
      ),
      error: (_, _) => SizedBox(
        width: 200,
        child: TextField(
          decoration: _dropdownDecoration('Empleado'),
          enabled: false,
        ),
      ),
    );
  }

  Widget _buildWorkplaceDropdown(
    WidgetRef ref,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
    String? selectedId,
  ) {
    return workplacesAsync.when(
      data: (workplaces) {
        final active = workplaces.where((w) => w.isActive).toList();
        return SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: _dropdownDecoration('Lugar de trabajo'),
            dropdownColor: AppColors.cardDark,
            style: AppTheme.bodyMd.copyWith(color: AppColors.textWhite),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos',
                    style: TextStyle(color: AppColors.textWhite)),
              ),
              ...active.map(
                (w) => DropdownMenuItem<String?>(
                  value: w.id,
                  child: Text(w.nombre,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppColors.textWhite)),
                ),
              ),
            ],
            onChanged: (value) {
              ref
                  .read(historyFilterProvider.notifier)
                  .setWorkplaceId(value);
            },
          ),
        );
      },
      loading: () => SizedBox(
        width: 200,
        child: TextField(
          decoration: _dropdownDecoration('Lugar de trabajo'),
          enabled: false,
        ),
      ),
      error: (_, _) => SizedBox(
        width: 200,
        child: TextField(
          decoration: _dropdownDecoration('Lugar de trabajo'),
          enabled: false,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(WidgetRef ref, String? selectedStatus) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String?>(
        initialValue: selectedStatus,
        decoration: _dropdownDecoration('Estado'),
        dropdownColor: AppColors.cardDark,
        style: AppTheme.bodyMd.copyWith(color: AppColors.textWhite),
        items: const [
          DropdownMenuItem<String?>(
              value: null,
              child:
                  Text('Todos', style: TextStyle(color: AppColors.textWhite))),
          DropdownMenuItem<String?>(
              value: 'active',
              child:
                  Text('Activo', style: TextStyle(color: AppColors.textWhite))),
          DropdownMenuItem<String?>(
              value: 'completed',
              child: Text('Finalizada',
                  style: TextStyle(color: AppColors.textWhite))),
        ],
        onChanged: (value) {
          ref.read(historyFilterProvider.notifier).setStatus(value);
        },
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: TextField(
        decoration: AppTheme.inputDecoration(
          label: label,
          icon: Icons.date_range,
          hint: 'YYYY-MM-DD',
        ),
        style: AppTheme.bodyMd.copyWith(color: AppColors.textWhite),
        controller: TextEditingController(text: value ?? ''),
        onChanged: onChanged,
      ),
    );
  }
}

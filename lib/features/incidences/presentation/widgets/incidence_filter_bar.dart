import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';

class IncidenceFilterBar extends ConsumerWidget {
  const IncidenceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidencesFilterProvider);
    final usersAsync = ref.watch(usersStreamProvider);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas chicas (teléfonos) los campos se estiran a todo el
          // ancho disponible; en pantallas grandes conservan el ancho fijo.
          // Nunca dependen del ancho del dispositivo para no desbordar.
          final w = constraints.maxWidth;
          final searchWidth = w >= 900 ? 260.0 : w;
          final pairWidth = (w - 12) / 2;
          final fieldWidth = w >= 900 ? 200.0 : (w >= 640 ? pairWidth : w);
          final stateWidth = w >= 900 ? 180.0 : fieldWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  decoration: AppTheme.inputDecoration(
                    label: 'Buscar nombre/apellido/tipo',
                    icon: Icons.search,
                    hint: 'Escribe para buscar...',
                  ),
                  style: const TextStyle(color: AppColors.textWhite),
                  controller: TextEditingController(
                    text: filter.searchQuery.isNotEmpty ? filter.searchQuery : '',
                  )
                    ..selection = TextSelection.collapsed(offset: filter.searchQuery.length),
                  onChanged: (value) {
                    ref.read(incidencesFilterProvider.notifier).setSearchQuery(value);
                  },
                ),
              ),
              _buildEmployeeDropdown(ref, usersAsync, filter.employeeId, fieldWidth),
              _buildTypeDropdown(ref, filter.type, fieldWidth),
              _buildStateDropdown(ref, filter.state, stateWidth),
              TextButton.icon(
                onPressed: () => ref.read(incidencesFilterProvider.notifier).clear(),
                icon: const Icon(Icons.clear, color: AppColors.textMuted),
                label: const Text('Limpiar', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmployeeDropdown(
    WidgetRef ref,
    AsyncValue<List<UserModel>> usersAsync,
    String? selectedId,
    double width,
  ) {
    return usersAsync.when(
      data: (users) {
        final employees =
            users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
        return SizedBox(
          width: width,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: AppColors.textWhite),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...employees.map(
                (e) => DropdownMenuItem<String?>(
                  value: e.id,
                  child: Text(e.nombreCompleto, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(incidencesFilterProvider.notifier).setEmployeeId(value);
            },
          ),
        );
      },
      loading: () => SizedBox(width: width),
      error: (_, _) => SizedBox(width: width),
    );
  }

  Widget _buildTypeDropdown(WidgetRef ref, IncidenceType? selectedType, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<IncidenceType?>(
        initialValue: selectedType,
        decoration: AppTheme.inputDecoration(label: 'Tipo', icon: Icons.category),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(color: AppColors.textWhite),
        isExpanded: true,
        items: [
          const DropdownMenuItem<IncidenceType?>(value: null, child: Text('Todos')),
          ...IncidenceType.values.map(
            (t) => DropdownMenuItem<IncidenceType?>(
              value: t,
              child: Text(t.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(incidencesFilterProvider.notifier).setType(value);
        },
      ),
    );
  }

  Widget _buildStateDropdown(WidgetRef ref, IncidenceEstado? selectedState, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<IncidenceEstado?>(
        initialValue: selectedState,
        decoration: AppTheme.inputDecoration(label: 'Estado', icon: Icons.flag),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(color: AppColors.textWhite),
        isExpanded: true,
        items: [
          const DropdownMenuItem<IncidenceEstado?>(value: null, child: Text('Todos')),
          ...IncidenceEstado.values.map(
            (s) => DropdownMenuItem<IncidenceEstado?>(
              value: s,
              child: Text(s.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(incidencesFilterProvider.notifier).setState(value);
        },
      ),
    );
  }
}

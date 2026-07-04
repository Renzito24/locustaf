import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';

class IncidenceFilterBar extends ConsumerWidget {
  const IncidenceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidencesFilterProvider);
    final usersAsync = ref.watch(usersStreamProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar nombre/apellido/tipo',
                  hintText: 'Escribe para buscar...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                controller: TextEditingController(
                  text: filter.searchQuery.isNotEmpty ? filter.searchQuery : '',
                )
                  ..selection = TextSelection.collapsed(offset: filter.searchQuery.length),
                onChanged: (value) {
                  ref.read(incidencesFilterProvider.notifier).setSearchQuery(value);
                },
              ),
            ),
            _buildEmployeeDropdown(ref, usersAsync, filter.employeeId),
            _buildTypeDropdown(ref, filter.type),
            _buildStateDropdown(ref, filter.state),
            TextButton.icon(
              onPressed: () => ref.read(incidencesFilterProvider.notifier).clear(),
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown(
    WidgetRef ref,
    AsyncValue<List<UserModel>> usersAsync,
    String? selectedId,
  ) {
    return usersAsync.when(
      data: (users) {
        final employees =
            users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
        return SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: const InputDecoration(
              labelText: 'Empleado',
              border: OutlineInputBorder(),
              isDense: true,
            ),
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
      loading: () => const SizedBox(width: 200),
      error: (_, _) => const SizedBox(width: 200),
    );
  }

  Widget _buildTypeDropdown(WidgetRef ref, IncidenceType? selectedType) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<IncidenceType?>(
        initialValue: selectedType,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<IncidenceType?>(value: null, child: Text('Todos')),
          ...IncidenceType.values.map(
            (t) => DropdownMenuItem<IncidenceType?>(
              value: t,
              child: Text(t.label),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(incidencesFilterProvider.notifier).setType(value);
        },
      ),
    );
  }

  Widget _buildStateDropdown(WidgetRef ref, IncidenceState? selectedState) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<IncidenceState?>(
        initialValue: selectedState,
        decoration: const InputDecoration(
          labelText: 'Estado',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<IncidenceState?>(value: null, child: Text('Todos')),
          ...IncidenceState.values.map(
            (s) => DropdownMenuItem<IncidenceState?>(
              value: s,
              child: Text(s.label),
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

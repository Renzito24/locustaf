import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/history_provider.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final workplacesAsync = ref.watch(workplacesStreamProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
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
                    decoration: const InputDecoration(
                      labelText: 'Buscar nombre/apellido',
                      hintText: 'Escribe para buscar...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    controller: TextEditingController(text: filter.searchQuery.isNotEmpty ? filter.searchQuery : '')
                      ..selection = TextSelection.collapsed(offset: filter.searchQuery.length),
                    onChanged: (value) {
                      ref.read(historyFilterProvider.notifier).setSearchQuery(value);
                    },
                  ),
                ),
                _buildEmployeeDropdown(ref, usersAsync, filter.employeeId),
                _buildWorkplaceDropdown(ref, workplacesAsync, filter.workplaceId),
                _buildStatusDropdown(ref, filter.status),
                _buildDateField(
                  context: context,
                  ref: ref,
                  label: 'Fecha desde',
                  value: filter.dateFrom,
                  onChanged: (v) => ref.read(historyFilterProvider.notifier).setDateFrom(v),
                ),
                _buildDateField(
                  context: context,
                  ref: ref,
                  label: 'Fecha hasta',
                  value: filter.dateTo,
                  onChanged: (v) => ref.read(historyFilterProvider.notifier).setDateTo(v),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(historyFilterProvider.notifier).clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                ),
              ],
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
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              ...employees.map(
                (e) => DropdownMenuItem<String?>(
                  value: e.id,
                  child: Text(e.nombreCompleto, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(historyFilterProvider.notifier).setEmployeeId(value);
            },
          ),
        );
      },
      loading: () => const SizedBox(width: 200, child: TextField(decoration: InputDecoration(labelText: 'Empleado', border: OutlineInputBorder(), isDense: true), enabled: false)),
      error: (_, _) => const SizedBox(width: 200, child: TextField(decoration: InputDecoration(labelText: 'Empleado', border: OutlineInputBorder(), isDense: true), enabled: false)),
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
            decoration: const InputDecoration(
              labelText: 'Workplace',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              ...active.map(
                (w) => DropdownMenuItem<String?>(
                  value: w.id,
                  child: Text(w.nombre, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(historyFilterProvider.notifier).setWorkplaceId(value);
            },
          ),
        );
      },
      loading: () => const SizedBox(width: 200, child: TextField(decoration: InputDecoration(labelText: 'Workplace', border: OutlineInputBorder(), isDense: true), enabled: false)),
      error: (_, _) => const SizedBox(width: 200, child: TextField(decoration: InputDecoration(labelText: 'Workplace', border: OutlineInputBorder(), isDense: true), enabled: false)),
    );
  }

  Widget _buildStatusDropdown(WidgetRef ref, String? selectedStatus) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String?>(
        initialValue: selectedStatus,
        decoration: const InputDecoration(
          labelText: 'Estado',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem<String?>(value: null, child: Text('Todos')),
          DropdownMenuItem<String?>(value: 'active', child: Text('Activo')),
          DropdownMenuItem<String?>(value: 'completed', child: Text('Finalizada')),
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
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.date_range, size: 18),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final formatted =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                onChanged(formatted);
              }
            },
          ),
        ),
        controller: TextEditingController(text: value ?? ''),
        onChanged: onChanged,
      ),
    );
  }
}

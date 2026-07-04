import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../../medical_documents/data/models/medical_document_model.dart';
import '../providers/medical_documents_provider.dart';

class MedicalDocumentFilterBar extends ConsumerWidget {
  const MedicalDocumentFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(medicalDocumentsFilterProvider);
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
                controller: TextEditingController(text: filter.searchQuery.isNotEmpty ? filter.searchQuery : '')
                  ..selection = TextSelection.collapsed(offset: filter.searchQuery.length),
                onChanged: (value) {
                  ref.read(medicalDocumentsFilterProvider.notifier).setSearchQuery(value);
                },
              ),
            ),
            _buildEmployeeDropdown(ref, usersAsync, filter.employeeId),
            _buildTipoDropdown(ref, filter.tipo),
            _buildVigenciaDropdown(ref, filter.vigencia),
            TextButton.icon(
              onPressed: () => ref.read(medicalDocumentsFilterProvider.notifier).clear(),
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
              ref.read(medicalDocumentsFilterProvider.notifier).setEmployeeId(value);
            },
          ),
        );
      },
      loading: () => const SizedBox(width: 200),
      error: (_, _) => const SizedBox(width: 200),
    );
  }

  Widget _buildTipoDropdown(WidgetRef ref, MedicalDocumentTipo? selectedTipo) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<MedicalDocumentTipo?>(
        initialValue: selectedTipo,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<MedicalDocumentTipo?>(
            value: null,
            child: Text('Todos'),
          ),
          ...MedicalDocumentTipo.values.map(
            (t) => DropdownMenuItem<MedicalDocumentTipo?>(
              value: t,
              child: Text(t.label),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(medicalDocumentsFilterProvider.notifier).setTipo(value);
        },
      ),
    );
  }

  Widget _buildVigenciaDropdown(WidgetRef ref, VigenciaEstado? selectedVigencia) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<VigenciaEstado?>(
        initialValue: selectedVigencia,
        decoration: const InputDecoration(
          labelText: 'Estado',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<VigenciaEstado?>(
            value: null,
            child: Text('Todos'),
          ),
          ...VigenciaEstado.values.map(
            (v) => DropdownMenuItem<VigenciaEstado?>(
              value: v,
              child: Text(v.label),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(medicalDocumentsFilterProvider.notifier).setVigencia(value);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../../medical_documents/data/models/medical_document_model.dart';
import '../providers/medical_documents_provider.dart';

class MedicalDocumentFilterBar extends ConsumerWidget {
  const MedicalDocumentFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(medicalDocumentsFilterProvider);
    final usersAsync = ref.watch(usersStreamProvider);

    return Container(
      decoration: AppTheme.cardDecoration(),
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
                  controller: TextEditingController(text: filter.searchQuery.isNotEmpty ? filter.searchQuery : '')
                    ..selection = TextSelection.collapsed(offset: filter.searchQuery.length),
                  onChanged: (value) {
                    ref.read(medicalDocumentsFilterProvider.notifier).setSearchQuery(value);
                  },
                ),
              ),
              _buildEmployeeDropdown(ref, usersAsync, filter.employeeId, fieldWidth),
              _buildTipoDropdown(ref, filter.tipo, fieldWidth),
              _buildVigenciaDropdown(ref, filter.vigencia, fieldWidth),
              TextButton.icon(
                onPressed: () => ref.read(medicalDocumentsFilterProvider.notifier).clear(),
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
      loading: () => SizedBox(width: width),
      error: (_, _) => SizedBox(width: width),
    );
  }

  Widget _buildTipoDropdown(WidgetRef ref, MedicalDocumentTipo? selectedTipo, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<MedicalDocumentTipo?>(
        initialValue: selectedTipo,
        decoration: AppTheme.inputDecoration(label: 'Tipo', icon: Icons.category),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(color: AppColors.textWhite),
        isExpanded: true,
        items: [
          const DropdownMenuItem<MedicalDocumentTipo?>(
            value: null,
            child: Text('Todos'),
          ),
          ...MedicalDocumentTipo.values.map(
            (t) => DropdownMenuItem<MedicalDocumentTipo?>(
              value: t,
              child: Text(t.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          ref.read(medicalDocumentsFilterProvider.notifier).setTipo(value);
        },
      ),
    );
  }

  Widget _buildVigenciaDropdown(WidgetRef ref, VigenciaEstado? selectedVigencia, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<VigenciaEstado?>(
        initialValue: selectedVigencia,
        decoration: AppTheme.inputDecoration(label: 'Estado', icon: Icons.flag),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(color: AppColors.textWhite),
        isExpanded: true,
        items: [
          const DropdownMenuItem<VigenciaEstado?>(
            value: null,
            child: Text('Todos'),
          ),
          ...VigenciaEstado.values.map(
            (v) => DropdownMenuItem<VigenciaEstado?>(
              value: v,
              child: Text(v.label, overflow: TextOverflow.ellipsis),
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

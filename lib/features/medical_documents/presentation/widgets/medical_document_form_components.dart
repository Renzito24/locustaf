import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../data/models/medical_document_model.dart';

class MedicalDocumentEmployeeDropdown extends StatelessWidget {
  final String? fixedUserId;
  final String userId;
  final List<UserModel> employees;
  final bool isEditing;
  final ValueChanged<String?> onChanged;

  const MedicalDocumentEmployeeDropdown({
    super.key,
    this.fixedUserId,
    required this.userId,
    required this.employees,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (fixedUserId != null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: userId.isEmpty ? null : userId,
          decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
          dropdownColor: AppColors.cardDark,
          style: const TextStyle(color: AppColors.textWhite),
          items: employees
              .map((e) => DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(e.nombreCompleto),
                  ))
              .toList(),
          onChanged: isEditing ? null : onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Seleccione un empleado';
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class MedicalDocumentTypeDropdown extends StatelessWidget {
  final MedicalDocumentTipo tipo;
  final ValueChanged<MedicalDocumentTipo?> onChanged;

  const MedicalDocumentTypeDropdown({
    super.key,
    required this.tipo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MedicalDocumentTipo>(
      initialValue: tipo,
      decoration: AppTheme.inputDecoration(label: 'Tipo de documento', icon: Icons.description),
      dropdownColor: AppColors.cardDark,
      style: const TextStyle(color: AppColors.textWhite),
      items: MedicalDocumentTipo.values
          .map((t) => DropdownMenuItem<MedicalDocumentTipo>(
                value: t,
                child: Text(t.label),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) return 'Seleccione un tipo';
        return null;
      },
    );
  }
}

class MedicalDocumentDatePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(String?)? validator;

  const MedicalDocumentDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: AppTheme.inputDecoration(
        label: label,
        icon: Icons.calendar_today,
      ).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, size: 18, color: AppColors.gold),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.gold,
                      onPrimary: Colors.white,
                      surface: AppColors.cardDark,
                      onSurface: AppColors.textWhite,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) onChanged(date);
          },
        ),
      ),
      style: const TextStyle(color: AppColors.textWhite),
      controller: TextEditingController(
        text:
            '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      ),
      readOnly: true,
      validator: validator,
    );
  }
}

class MedicalDocumentFilePicker extends StatelessWidget {
  final bool isLoading;
  final PlatformFile? archivoFile;
  final String? archivoUrl;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const MedicalDocumentFilePicker({
    super.key,
    required this.isLoading,
    this.archivoFile,
    this.archivoUrl,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (archivoFile != null || archivoUrl != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    archivoFile?.name ?? archivoUrl!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textWhite),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (archivoFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    onPressed: onClearFile,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onPickFile,
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(archivoFile != null ? 'Cambiar archivo' : 'Seleccionar archivo (opcional)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        ),
      ],
    );
  }
}

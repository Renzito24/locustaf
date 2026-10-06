import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../data/models/incidence_model.dart';

class IncidenceErrorMessage extends StatelessWidget {
  final String errorMessage;

  const IncidenceErrorMessage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        errorMessage,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}

class IncidenceEmployeeDropdown extends StatelessWidget {
  final AsyncValue<List<UserModel>> usersAsync;
  final String userId;
  final bool isEditing;
  final ValueChanged<String?> onChanged;

  const IncidenceEmployeeDropdown({
    super.key,
    required this.usersAsync,
    required this.userId,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        usersAsync.when(
          data: (users) {
            final employees =
                users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
            return DropdownButtonFormField<String>(
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
              validator: (v) => (v == null || v.isEmpty) ? 'Seleccione un empleado' : null,
            );
          },
          loading: () => TextField(
            decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
            enabled: false,
          ),
          error: (_, _) => TextField(
            decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
            enabled: false,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class IncidenceTypeDropdown extends StatelessWidget {
  final IncidenceType type;
  final ValueChanged<IncidenceType?> onChanged;

  const IncidenceTypeDropdown({
    super.key,
    required this.type,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<IncidenceType>(
      initialValue: type,
      decoration: AppTheme.inputDecoration(label: 'Tipo de incidencia', icon: Icons.category),
      dropdownColor: AppColors.cardDark,
      style: const TextStyle(color: AppColors.textWhite),
      items: IncidenceType.values
          .map((t) => DropdownMenuItem<IncidenceType>(
                value: t,
                child: Text(t.label),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Seleccione un tipo' : null,
    );
  }
}

class IncidenceDatePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(String?)? validator;

  const IncidenceDatePicker({
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
        text: '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      ),
      readOnly: true,
      validator: validator,
    );
  }
}

class IncidenceTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const IncidenceTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
      ),
      style: const TextStyle(color: AppColors.textWhite),
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class IncidenceSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final VoidCallback? onSubmit;

  const IncidenceSubmitButton({
    super.key,
    required this.isLoading,
    required this.isEditing,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Guardar cambios' : 'Crear incidencia'),
        ),
      ),
    );
  }
}

class IncidenceFilePicker extends StatelessWidget {
  final bool isLoading;
  final PlatformFile? archivoFile;
  final String? archivoUrl;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const IncidenceFilePicker({
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

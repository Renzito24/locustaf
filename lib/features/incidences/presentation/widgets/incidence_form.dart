import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/incidence_model.dart';

class IncidenceFormData {
  final String userId;
  final IncidenceType type;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String observaciones;
  final String? documentoRelacionado;

  const IncidenceFormData({
    required this.userId,
    required this.type,
    required this.fechaInicio,
    required this.fechaFin,
    this.observaciones = '',
    this.documentoRelacionado,
  });
}

class IncidenceForm extends ConsumerStatefulWidget {
  final IncidenceModel? existingIncidence;
  final bool isLoading;
  final String? errorMessage;
  final void Function(IncidenceFormData data) onSubmit;

  const IncidenceForm({
    super.key,
    this.existingIncidence,
    this.isLoading = false,
    this.errorMessage,
    required this.onSubmit,
  });

  @override
  ConsumerState<IncidenceForm> createState() => _IncidenceFormState();
}

class _IncidenceFormState extends ConsumerState<IncidenceForm> {
  final _formKey = GlobalKey<FormState>();
  late String _userId;
  late IncidenceType _type;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late String _observaciones;
  final _observacionesController = TextEditingController();
  final _documentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final inc = widget.existingIncidence;
    _userId = inc?.userId ?? '';
    _type = inc?.type ?? IncidenceType.vacaciones;
    _fechaInicio = inc?.fechaInicio ?? DateTime.now();
    _fechaFin = inc?.fechaFin ?? DateTime.now().add(const Duration(days: 1));
    _observaciones = inc?.observaciones ?? '';
    _observacionesController.text = _observaciones;
    _documentoController.text = inc?.documentoRelacionado ?? '';
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.existingIncidence != null;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          usersAsync.when(
            data: (users) {
              final employees =
                  users.where((u) => u.rol == UserRole.employee && !u.isDeleted).toList();
              return DropdownButtonFormField<String>(
                initialValue: _userId.isEmpty ? null : _userId,
                decoration: AppTheme.inputDecoration(label: 'Empleado', icon: Icons.person),
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textWhite),
                items: employees
                    .map((e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(e.nombreCompleto),
                        ))
                    .toList(),
                onChanged: isEditing ? null : (v) => setState(() => _userId = v ?? ''),
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
          DropdownButtonFormField<IncidenceType>(
            initialValue: _type,
            decoration: AppTheme.inputDecoration(label: 'Tipo de incidencia', icon: Icons.category),
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: AppColors.textWhite),
            items: IncidenceType.values
                .map((t) => DropdownMenuItem<IncidenceType>(
                      value: t,
                      child: Text(t.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
            validator: (v) => v == null ? 'Seleccione un tipo' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Fecha inicio',
                  value: _fechaInicio,
                  onChanged: (d) => setState(() => _fechaInicio = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Fecha fin',
                  value: _fechaFin,
                  onChanged: (d) => setState(() => _fechaFin = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacionesController,
            decoration: AppTheme.inputDecoration(label: 'Observaciones', icon: Icons.notes),
            style: const TextStyle(color: AppColors.textWhite),
            maxLines: 3,
            onChanged: (v) => _observaciones = v,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese las observaciones' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _documentoController,
            decoration: AppTheme.inputDecoration(
              label: 'Documento relacionado (opcional)',
              icon: Icons.link,
              hint: 'https://...',
            ),
            style: const TextStyle(color: AppColors.textWhite),
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Guardar cambios' : 'Crear incidencia'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required void Function(DateTime) onChanged,
  }) {
    return TextField(
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Seleccione un empleado'),
      );
      return;
    }
    widget.onSubmit(IncidenceFormData(
      userId: _userId,
      type: _type,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      observaciones: _observaciones.trim(),
      documentoRelacionado: _documentoController.text.trim().isEmpty
          ? null
          : _documentoController.text.trim(),
    ));
  }
}

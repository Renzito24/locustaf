import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/workplace_model.dart';
import 'workplace_map_picker.dart';

class WorkplaceBasicInfoSection extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController descriptionController;

  const WorkplaceBasicInfoSection({
    super.key,
    required this.nombreController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nombreController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Nombre *',
            icon: Icons.business_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Descripción',
            icon: Icons.description_outlined,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es obligatoria';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class WorkplaceLocationSection extends StatelessWidget {
  final TextEditingController latitudController;
  final TextEditingController longitudController;
  final TextEditingController direccionController;
  final TextEditingController radioController;
  final TextEditingController codigoController;
  final WorkplaceModel? initialData;

  const WorkplaceLocationSection({
    super.key,
    required this.latitudController,
    required this.longitudController,
    required this.direccionController,
    required this.radioController,
    required this.codigoController,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkplaceMapPicker(
          initialLatitude: initialData?.latitud,
          initialLongitude: initialData?.longitud,
          initialAddress: initialData?.direccion,
          onLatitudeChanged: (lat) {
            latitudController.text = lat.toStringAsFixed(6);
          },
          onLongitudeChanged: (lng) {
            longitudController.text = lng.toStringAsFixed(6);
          },
          onAddressChanged: (address) {
            if (address != null) {
              direccionController.text = address;
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latitudController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Latitud *',
                  icon: Icons.map_outlined,
                  hint: '-34.6037',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Obligatorio';
                  }
                  final v = double.tryParse(value.trim());
                  if (v == null) return 'Número inválido';
                  return Validators.latitud(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: longitudController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Longitud *',
                  icon: Icons.map_outlined,
                  hint: '-58.3816',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Obligatorio';
                  }
                  final v = double.tryParse(value.trim());
                  if (v == null) return 'Número inválido';
                  return Validators.longitud(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: radioController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Radio (metros)',
                  icon: Icons.radar_outlined,
                  hint: '100',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value.trim()) == null) {
                      return 'Número inválido';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: codigoController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Código',
                  icon: Icons.qr_code_outlined,
                  hint: 'OF-A',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WorkplaceScheduleSection extends StatelessWidget {
  final TextEditingController horaInicioController;
  final TextEditingController horaFinController;
  final TextEditingController toleranciaController;
  final bool Function(String) isValidHhmm;

  const WorkplaceScheduleSection({
    super.key,
    required this.horaInicioController,
    required this.horaFinController,
    required this.toleranciaController,
    required this.isValidHhmm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de jornada',
          style: AppTheme.headingMd,
        ),
        const SizedBox(height: 4),
        Text(
          'Opcional. Si se define, se detectan llegadas tarde y jornadas huérfanas.',
          style: AppTheme.bodyMd,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: horaInicioController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Hora de inicio',
                  icon: Icons.schedule_outlined,
                  hint: '08:00',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!isValidHhmm(value.trim())) {
                      return 'Formato HH:mm';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: horaFinController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Hora de fin',
                  icon: Icons.schedule_outlined,
                  hint: '16:00',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!isValidHhmm(value.trim())) {
                      return 'Formato HH:mm';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: toleranciaController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Tolerancia (minutos)',
            icon: Icons.timer_outlined,
            hint: '15',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final v = int.tryParse(value.trim());
              if (v == null || v < 0) {
                return 'Número válido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

class WorkplaceSubmitButton extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onSubmit;

  const WorkplaceSubmitButton({
    super.key,
    required this.isSaving,
    required this.isEditing,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isSaving ? null : AppTheme.goldGradient,
          color: isSaving ? AppColors.gold.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            if (!isSaving)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSaving ? null : onSubmit,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0B0B0F),
                      ),
                    )
                  : Text(
                      isEditing
                          ? 'Guardar cambios'
                          : 'Crear lugar de trabajo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B0B0F),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';

class CompanyFormBasicFields extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController razonSocialController;
  final TextEditingController cuitController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController direccionController;
  final bool isLoading;

  const CompanyFormBasicFields({
    super.key,
    required this.nombreController,
    required this.razonSocialController,
    required this.cuitController,
    required this.emailController,
    required this.telefonoController,
    required this.direccionController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nombreController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Nombre comercial *',
            icon: Icons.business_outlined,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: razonSocialController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Razón social *',
            icon: Icons.business_outlined,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cuitController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'CUIT *',
            icon: Icons.numbers_outlined,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: Validators.cuit,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return Validators.email(v);
          },
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: telefonoController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Teléfono',
            icon: Icons.phone_outlined,
          ),
          keyboardType: TextInputType.phone,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: direccionController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Dirección',
            icon: Icons.home_outlined,
          ),
          enabled: !isLoading,
        ),
      ],
    );
  }
}

class CompanyFormConfigFields extends StatelessWidget {
  final CompanyEstado estado;
  final ValueChanged<CompanyEstado> onEstadoChanged;
  final TextEditingController toleranciaController;
  final Set<int> diasLaborables;
  final ValueChanged<Set<int>> onDiasChanged;
  final bool isLoading;

  const CompanyFormConfigFields({
    super.key,
    required this.estado,
    required this.onEstadoChanged,
    required this.toleranciaController,
    required this.diasLaborables,
    required this.onDiasChanged,
    required this.isLoading,
  });

  String _dayLabel(int day) {
    switch (day) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mié';
      case 4:
        return 'Jue';
      case 5:
        return 'Vie';
      case 6:
        return 'Sáb';
      default:
        return 'Dom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<CompanyEstado>(
          initialValue: estado,
          decoration: AppTheme.inputDecoration(
            label: 'Estado',
            icon: Icons.toggle_on_outlined,
          ),
          dropdownColor: AppColors.cardDark,
          style: const TextStyle(color: AppColors.textWhite),
          items: CompanyEstado.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.label),
                  ))
              .toList(),
          onChanged: isLoading ? null : (v) => onEstadoChanged(v ?? CompanyEstado.activa),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: toleranciaController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Tolerancia de check-in (minutos)',
            hint: 'Minutos permitidos para marcar entrada (default 15)',
            icon: Icons.timer_outlined,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 0) {
              return 'Debe ser un número mayor o igual a 0';
            }
            return null;
          },
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        Text(
          'Días laborables',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (i) {
            final day = i + 1;
            final selected = diasLaborables.contains(day);
            return FilterChip(
              label: Text(_dayLabel(day)),
              selected: selected,
              selectedColor: AppColors.gold,
              checkmarkColor: AppColors.textWhite,
              backgroundColor: AppColors.cardDark,
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.textWhite
                    : AppColors.textSecondary,
              ),
              side: selected
                  ? const BorderSide(color: AppColors.gold, width: 1)
                  : BorderSide.none,
              onSelected: isLoading
                  ? null
                  : (v) {
                      final updated = Set<int>.of(diasLaborables);
                      if (v) {
                        updated.add(day);
                      } else {
                        updated.remove(day);
                      }
                      onDiasChanged(updated);
                    },
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Los reportes de "Ausentes" solo aplican en días laborables.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class CompanyFormSubmitButton extends StatelessWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onSubmit;

  const CompanyFormSubmitButton({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: isLoading ? null : onSubmit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Guardar cambios' : 'Crear empresa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

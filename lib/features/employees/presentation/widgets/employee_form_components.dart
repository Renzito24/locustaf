import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';

InputDecoration buildEmployeeInputDeco(String label, {IconData? icon, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    hintStyle: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 14),
    prefixIcon: icon != null
        ? Icon(icon, color: AppColors.gold.withValues(alpha: 0.85), size: 20)
        : null,
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.25),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
  );
}

class EmployeePasswordFields extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const EmployeePasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<EmployeePasswordFields> createState() => _EmployeePasswordFieldsState();
}

class _EmployeePasswordFieldsState extends State<EmployeePasswordFields> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
            decoration: buildEmployeeInputDeco('Contraseña *').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) => Validators.password(value),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: TextFormField(
            controller: widget.confirmPasswordController,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
            decoration: buildEmployeeInputDeco('Confirmar contraseña *').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme la contraseña';
              }
              if (value != widget.passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class EmployeeRoleDropdown extends ConsumerWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole?> onChanged;

  const EmployeeRoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<UserRole>(
      initialValue: selectedRole,
      decoration: buildEmployeeInputDeco('Rol *',
          icon: Icons.admin_panel_settings_outlined),
      items: [
        if (ref.watch(userRoleProvider) == UserRole.superadmin)
          const DropdownMenuItem(
            value: UserRole.superadmin,
            child: Text('Super Administrador',
                style: TextStyle(color: AppColors.textWhite)),
          ),
        if (ref.watch(userRoleProvider) == UserRole.superadmin)
          const DropdownMenuItem(
            value: UserRole.admin,
            child: Text('Administrador',
                style: TextStyle(color: AppColors.textWhite)),
          ),
        const DropdownMenuItem(
          value: UserRole.employee,
          child: Text('Empleado',
              style: TextStyle(color: AppColors.textWhite)),
        ),
        const DropdownMenuItem(
          value: UserRole.supervisor,
          child: Text('Supervisor',
              style: TextStyle(color: AppColors.textWhite)),
        ),
      ],
      onChanged: onChanged,
      validator: (value) {
        if (value == null) return 'Seleccione un rol';
        return null;
      },
    );
  }
}

class EmployeeWorkplaceDropdown extends ConsumerWidget {
  final String? selectedWorkplaceId;
  final ValueChanged<String?> onChanged;

  const EmployeeWorkplaceDropdown({
    super.key,
    required this.selectedWorkplaceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    return workplacesAsync.when(
      data: (workplaces) {
        if (workplaces.isEmpty) {
          return TextFormField(
            enabled: false,
            decoration: buildEmployeeInputDeco('Lugar de trabajo',
                icon: Icons.business_outlined,
                hint: 'Sin lugares de trabajo disponibles'),
          );
        }
        return DropdownButtonFormField<String?>(
          initialValue: selectedWorkplaceId,
          decoration: buildEmployeeInputDeco('Lugar de trabajo (opcional)',
              icon: Icons.business_outlined),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin asignar',
                  style: TextStyle(color: AppColors.textWhite)),
            ),
            ...workplaces.map(
              (w) => DropdownMenuItem<String?>(
                value: w.id,
                child: Text(w.nombre,
                    style: const TextStyle(color: AppColors.textWhite)),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => TextFormField(
        enabled: false,
        decoration: buildEmployeeInputDeco('Lugar de trabajo',
            icon: Icons.business_outlined, hint: 'Cargando...'),
      ),
      error: (_, _) => TextFormField(
        enabled: false,
        decoration: buildEmployeeInputDeco('Lugar de trabajo',
            icon: Icons.business_outlined,
            hint: 'Sin lugares de trabajo disponibles'),
      ),
    );
  }
}

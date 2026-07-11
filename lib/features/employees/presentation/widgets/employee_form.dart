import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/update_employee_notifier.dart';
import '../providers/users_provider.dart';

class EmployeeForm extends ConsumerStatefulWidget {
  final bool isEditing;
  final UserModel? initialData;

  const EmployeeForm({
    super.key,
    this.isEditing = false,
    this.initialData,
  });

  @override
  ConsumerState<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _emailController;
  late final TextEditingController _dniController;
  late final TextEditingController _telefonoController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedWorkplaceId;
  UserRole _selectedRole = UserRole.employee;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nombreController = TextEditingController(text: data?.nombre ?? '');
    _apellidoController = TextEditingController(text: data?.apellido ?? '');
    _emailController = TextEditingController(text: data?.email ?? '');
    _dniController = TextEditingController(text: data?.dni ?? '');
    _telefonoController = TextEditingController(text: data?.telefono ?? '');
    _selectedWorkplaceId = data?.lugarDeTrabajoId;
    if (data?.rol != null) {
      _selectedRole = data!.rol;
    }
  }

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon,
              color: AppColors.gold.withValues(alpha: 0.85), size: 20)
          : null,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(
            color: AppColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(
            color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: const BorderSide(
            color: AppColors.error, width: 1.4),
      ),
    );
  }

  Widget _buildWorkplaceDropdown() {
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    return workplacesAsync.when(
      data: (workplaces) {
        if (workplaces.isEmpty) {
          return TextFormField(
            enabled: false,
            decoration: _inputDeco('Lugar de trabajo',
                icon: Icons.business_outlined,
                hint: 'Sin lugares de trabajo disponibles'),
          );
        }
        return DropdownButtonFormField<String?>(
          initialValue: _selectedWorkplaceId,
          decoration: _inputDeco('Lugar de trabajo (opcional)',
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
                child:
                    Text(w.nombre, style: const TextStyle(color: AppColors.textWhite)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedWorkplaceId = value);
          },
        );
      },
      loading: () => TextFormField(
        enabled: false,
        decoration: _inputDeco('Lugar de trabajo',
            icon: Icons.business_outlined, hint: 'Cargando...'),
      ),
      error: (_, _) => TextFormField(
        enabled: false,
        decoration: _inputDeco('Lugar de trabajo',
            icon: Icons.business_outlined,
            hint: 'Sin lugares de trabajo disponibles'),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      final updatedUser = widget.initialData!.copyWith(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        dni: _dniController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        rol: _selectedRole,
        lugarDeTrabajoId: _selectedWorkplaceId,
      );
      await ref
          .read(updateEmployeeProvider.notifier)
          .updateEmployee(updatedUser);
    } else {
      final data = EmployeeFormData(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        dni: _dniController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        password: _passwordController.text,
        rol: _selectedRole,
        lugarDeTrabajoId: _selectedWorkplaceId,
      );
      await ref
          .read(createEmployeeProvider.notifier)
          .createEmployee(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.isEditing
        ? ref.watch(updateEmployeeProvider).isLoading
        : ref.watch(createEmployeeProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: _inputDeco('Nombre *',
                      icon: Icons.person_outline),
                  validator: (value) =>
                      Validators.required(value, 'El nombre'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: _inputDeco('Apellido *',
                      icon: Icons.person_outline),
                  validator: (value) =>
                      Validators.required(value, 'El apellido'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _emailController,
            enabled: !widget.isEditing,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                color: AppColors.textWhite, fontSize: 14),
            decoration: _inputDeco('Correo electrónico *',
                icon: Icons.email_outlined),
            validator: (value) => Validators.email(value),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dniController,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: _inputDeco('DNI *',
                      icon: Icons.badge_outlined),
                  validator: (value) => Validators.dni(value),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: _inputDeco('Teléfono (opcional)',
                      icon: Icons.phone_outlined),
                ),
              ),
            ],
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Contraseña *',
                      labelStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                      filled: true,
                      fillColor:
                          Colors.black.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: BorderSide(
                            color: AppColors.gold
                                .withValues(alpha: 0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: BorderSide(
                            color: AppColors.gold
                                .withValues(alpha: 0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.4),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.4),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() =>
                            _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        Validators.password(value),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(
                        color: AppColors.textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña *',
                      labelStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                      filled: true,
                      fillColor:
                          Colors.black.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: BorderSide(
                            color: AppColors.gold
                                .withValues(alpha: 0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: BorderSide(
                            color: AppColors.gold
                                .withValues(alpha: 0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.4),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.4),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme la contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.md),
          DropdownButtonFormField<UserRole>(
            initialValue: _selectedRole,
            decoration: _inputDeco('Rol *',
                icon: Icons.admin_panel_settings_outlined),
            items: const [
              DropdownMenuItem(
                value: UserRole.employee,
                child: Text('Empleado',
                    style: TextStyle(color: AppColors.textWhite)),
              ),
              DropdownMenuItem(
                value: UserRole.supervisor,
                child: Text('Supervisor',
                    style: TextStyle(color: AppColors.textWhite)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
            validator: (value) {
              if (value == null) return 'Seleccione un rol';
              return null;
            },
          ),
          const SizedBox(height: AppSizes.md),
          _buildWorkplaceDropdown(),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSaving ? null : _submit,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  child: Center(
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Text(
                            widget.isEditing
                                ? 'Guardar cambios'
                                : 'Crear usuario',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

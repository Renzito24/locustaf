import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/models/user_model.dart';
import '../../domain/user_validation.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/update_employee_notifier.dart';
import '../providers/users_provider.dart';
import 'employee_form_components.dart';

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

  String? _validateDni(String? value, List<UserModel>? existingUsers) {
    final formatError = Validators.dni(value);
    if (formatError != null) return formatError;

    // Sin datos cargados del stream: no bloquear (la validación de formato ya
    // protege la integridad mínima del dato).
    if (existingUsers == null || value == null) return null;

    final duplicate = findDuplicateDni(
      existingUsers,
      dni: value.trim(),
      excludeUserId: widget.isEditing ? widget.initialData!.id : null,
    );
    if (duplicate != null) {
      return 'El DNI $duplicate ya está registrado en tu empresa.';
    }
    return null;
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
    // Lista de usuarios de la empresa (para detectar DNI duplicados). Se
    // observa desde build para que el stream esté activo cuando el validador
    // del DNI consulte la última lectura.
    final existingUsers = ref.watch(usersStreamProvider).value;

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
                  decoration: buildEmployeeInputDeco('Nombre *',
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
                  decoration: buildEmployeeInputDeco('Apellido *',
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
            decoration: buildEmployeeInputDeco('Correo electrónico *',
                icon: Icons.email_outlined),
            validator: (value) => Validators.email(value),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: buildEmployeeInputDeco('DNI *',
                      icon: Icons.badge_outlined),
                  validator: (value) => _validateDni(value, existingUsers),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                      color: AppColors.textWhite, fontSize: 14),
                  decoration: buildEmployeeInputDeco('Teléfono (opcional)',
                      icon: Icons.phone_outlined),
                ),
              ),
            ],
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: AppSizes.md),
            EmployeePasswordFields(
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
            ),
          ],
          const SizedBox(height: AppSizes.md),
          EmployeeRoleDropdown(
            selectedRole: _selectedRole,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          const SizedBox(height: AppSizes.md),
          EmployeeWorkplaceDropdown(
            selectedWorkplaceId: _selectedWorkplaceId,
            onChanged: (value) {
              setState(() => _selectedWorkplaceId = value);
            },
          ),
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

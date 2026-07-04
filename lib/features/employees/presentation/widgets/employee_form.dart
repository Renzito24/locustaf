import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../authentication/data/models/user_model.dart';
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

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nombreController = TextEditingController(text: data?.nombre ?? '');
    _apellidoController = TextEditingController(text: data?.apellido ?? '');
    _emailController = TextEditingController(text: data?.email ?? '');
    _dniController = TextEditingController(text: data?.dni ?? '');
    _telefonoController = TextEditingController(text: data?.telefono ?? '');
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
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      Validators.required(value, 'El nombre'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    border: OutlineInputBorder(),
                  ),
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
            decoration: InputDecoration(
              labelText: 'Correo electrónico *',
              border: const OutlineInputBorder(),
            ),
            validator: (value) => Validators.email(value),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => Validators.dni(value),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    border: OutlineInputBorder(),
                  ),
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
                    decoration: InputDecoration(
                      labelText: 'Contraseña *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => Validators.password(value),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
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
          TextFormField(
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Rol',
              hintText: 'Empleado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Lugar de trabajo',
              hintText: 'Próximamente',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Guardar cambios' : 'Crear empleado',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
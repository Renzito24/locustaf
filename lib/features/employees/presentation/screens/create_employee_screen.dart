import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/users_provider.dart';
import '../widgets/employee_form.dart';

class CreateEmployeeScreen extends ConsumerWidget {
  const CreateEmployeeScreen({super.key});

  String _mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'El correo electrónico ya está registrado';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres';
        case 'invalid-email':
          return 'El correo electrónico no es válido';
        case 'network-request-failed':
          return 'Error de red. Verifique su conexión e intente nuevamente';
        default:
          return 'Error de autenticación: ${error.message ?? error.code}';
      }
    }
    return 'Error inesperado. Intente nuevamente más tarde.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(createEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(createEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado creado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/employees');
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_mensajeError(error)),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alta de Empleado',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Complete el formulario para registrar un nuevo empleado.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: EmployeeForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
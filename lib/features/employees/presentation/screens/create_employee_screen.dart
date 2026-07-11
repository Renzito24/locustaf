import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
            AppTheme.successSnackBar('Usuario creado correctamente'),
          );
          context.go('/employees');
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar(_mensajeError(error)),
          );
        },
      );
    });

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.isMobile(context) ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo Usuario',
              style: AppTheme.headingLg,
            ),
            const SizedBox(height: 4),
            Text(
              'Complete el formulario para registrar un nuevo usuario.',
              style: AppTheme.bodyLg,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration(),
                  child: const EmployeeForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

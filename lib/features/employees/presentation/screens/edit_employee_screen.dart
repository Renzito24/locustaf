import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';
import '../providers/update_employee_notifier.dart';
import '../widgets/employee_form.dart';

class EditEmployeeScreen extends ConsumerWidget {
  const EditEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = GoRouterState.of(context).extra as UserModel?;

    if (employee == null) {
      return const Center(
        child: Text('Empleado no encontrado'),
      );
    }

    ref.listen<AsyncValue<void>>(updateEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(updateEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
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
            'Editar Empleado',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Editando a ${employee.nombreCompleto}.',
            style: const TextStyle(
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: EmployeeForm(
                    isEditing: true,
                    initialData: employee,
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
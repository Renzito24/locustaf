import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../providers/update_employee_notifier.dart';
import '../widgets/employee_form.dart';

class EditEmployeeScreen extends ConsumerWidget {
  const EditEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = GoRouterState.of(context).extra as UserModel?;

    if (employee == null) {
      return const Center(
        child: Text(
          'Empleado no encontrado',
          style: TextStyle(color: AppColors.textWhite),
        ),
      );
    }

    ref.listen<AsyncValue<void>>(updateEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(updateEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Usuario actualizado correctamente'),
          );
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error: $error'),
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
              'Editar Usuario',
              style: AppTheme.headingLg,
            ),
            const SizedBox(height: 4),
            Text(
              'Editando a ${employee.nombreCompleto}.',
              style: AppTheme.bodyLg,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration(),
                  child: EmployeeForm(
                    isEditing: true,
                    initialData: employee,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

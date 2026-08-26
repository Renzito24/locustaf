import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/models/user_model.dart';
import '../providers/delete_employee_notifier.dart';
import '../providers/reset_password_notifier.dart';
import '../providers/update_employee_notifier.dart';
import '../providers/users_provider.dart';
import '../widgets/employee_card.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/employee_filter_bar.dart';
import '../widgets/employee_search_bar.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEmployeesAsync = ref.watch(filteredEmployeesProvider);
    final isAdmin = ref.watch(isAdminProvider);

    ref.listen<AsyncValue<void>>(deleteEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(deleteEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Usuario eliminado correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al eliminar: $error'),
          );
        },
      );
    });

    ref.listen<AsyncValue<void>>(updateEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(updateEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Estado actualizado correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al actualizar: $error'),
          );
        },
      );
    });

    ref.listen<AsyncValue<void>>(resetPasswordProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(resetPasswordProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar(
                'Correo de restablecimiento enviado correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al enviar correo: $error'),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Empleados',
                        style: AppTheme.headingLg,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Administra, busca y filtra el personal de la empresa.',
                        style: AppTheme.bodyLg,
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  _GoldButton(
                    onPressed: () => context.push(RoutePaths.createEmployee),
                    icon: Icons.person_add,
                    label: 'Nuevo Usuario',
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 700) {
                    return const Row(
                      children: [
                        Expanded(flex: 3, child: EmployeeSearchBar()),
                        SizedBox(width: 16),
                        EmployeeFilterBar(),
                      ],
                    );
                  } else {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EmployeeSearchBar(),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: EmployeeFilterBar(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: filteredEmployeesAsync.when(
                data: (List<UserModel> employees) {
                  if (employees.isEmpty) {
                    return AppTheme.emptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No se encontraron usuarios',
                      subtitle:
                          'Intentá cambiar los términos de búsqueda o los filtros aplicados.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: employees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return EmployeeCard(
                        employee: employee,
                        onEdit: isAdmin
                            ? () => context.push(
                                  RoutePaths.editEmployee,
                                  extra: employee,
                                )
                            : null,
                        onToggleActive: isAdmin
                            ? () {
                                ref
                                    .read(updateEmployeeProvider.notifier)
                                    .updateEmployee(employee.copyWith(
                                      isActive: !employee.isActive,
                                    ));
                              }
                            : null,
                        onHistory: () => context.push(
                          RoutePaths.history,
                          extra: employee.id,
                        ),
                        onDelete: isAdmin
                            ? () {
                                ref
                                    .read(deleteEmployeeProvider.notifier)
                                    .deleteEmployee(employee.id);
                              }
                            : null,
                        onPasswordReset: isAdmin
                            ? () {
                                ref
                                    .read(resetPasswordProvider.notifier)
                                    .resetPassword(employee.email);
                              }
                            : null,
                      );
                    },
                  );
                },
                loading: () => AppTheme.loadingState(
                    message: 'Cargando usuarios...'),
                error: (error, stackTrace) => AppTheme.errorState(
                  'Ha ocurrido un error al cargar la información',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GoldButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

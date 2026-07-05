import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../authentication/data/models/user_model.dart';
import '../providers/delete_employee_notifier.dart';
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
            const SnackBar(
              content: Text('Empleado eliminado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $error'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    });

    ref.listen<AsyncValue<void>>(updateEmployeeProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(updateEmployeeProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $error'),
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
          // Header Section
          const Text(
            'Gestión de Empleados',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Administra, busca y filtra el personal de la empresa.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Search & Filter Controls Block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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

          // Main Contents Area (List / Grid / Loading / Error)
          Expanded(
            child: filteredEmployeesAsync.when(
              data: (List<UserModel> employees) {
                if (employees.isEmpty) {
                  return _buildEmptyState(context, ref);
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
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando empleados...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ha ocurrido un error al cargar la información',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron empleados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Intentá cambiar los términos de búsqueda o los filtros aplicados.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(employeeSearchQueryProvider.notifier).clear();
              ref
                  .read(employeeFilterProvider.notifier)
                  .setFilter(EmployeeStatusFilter.all);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Restablecer filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

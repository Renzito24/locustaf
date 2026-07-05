import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../../core/constants/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
    final attendancesAsync = ref.watch(allAttendancesStreamProvider);

    final totalEmployees = ref.watch(totalActiveEmployeesProvider);
    final presentToday = ref.watch(employeesPresentTodayProvider);
    final absentToday = ref.watch(employeesAbsentTodayProvider);
    final activeWorkplaces = ref.watch(activeWorkplacesCountProvider);

    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dateStr = '${now.day} de ${months[now.month - 1]} de ${now.year}';

    final anyLoaded = usersAsync.hasValue || workplacesAsync.hasValue || attendancesAsync.hasValue;
    final isLoading = !anyLoaded && (usersAsync.isLoading || workplacesAsync.isLoading || attendancesAsync.isLoading);
    final hasError = usersAsync.hasError || workplacesAsync.hasError || attendancesAsync.hasError;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Resumen general del estado del sistema.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildBody(isLoading, hasError, totalEmployees, presentToday, absentToday, activeWorkplaces),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    bool isLoading,
    bool hasError,
    int total,
    int present,
    int absent,
    int workplaces,
  ) {
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudieron obtener los datos del sistema.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildDashboard(total, present, absent, workplaces);
  }

  Widget _buildDashboard(int total, int present, int absent, int workplaces) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _KpiCard(
                icon: Icons.people,
                label: 'Empleados activos',
                value: total.toString(),
                color: AppColors.primary,
              ),
              _KpiCard(
                icon: Icons.check_circle,
                label: 'Presentes hoy',
                value: present.toString(),
                color: AppColors.success,
              ),
              _KpiCard(
                icon: Icons.cancel,
                label: 'Ausentes hoy',
                value: absent.toString(),
                color: absent > 0 ? AppColors.error : AppColors.success,
              ),
              _KpiCard(
                icon: Icons.business,
                label: 'Sucursales activas',
                value: workplaces.toString(),
                color: AppColors.warning,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

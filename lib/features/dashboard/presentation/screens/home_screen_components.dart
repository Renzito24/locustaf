import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../companies/domain/services/platform_metrics.dart';
import '../../../companies/presentation/providers/company_providers.dart';

class DashboardHeader extends StatelessWidget {
  final String subtitle;

  const DashboardHeader({super.key, required this.subtitle});

  String _todayString() {
    final now = DateTime.now();
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${now.day} de ${months[now.month - 1]} de ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
          child: const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(_todayString(), style: AppTheme.bodyLg),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTheme.bodyLg),
      ],
    );
  }
}

class DashboardKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double width;

  const DashboardKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.bodyMd),
          ],
        ),
      ),
    );
  }
}

class SuperadminDashboard extends ConsumerWidget {
  const SuperadminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(allCompaniesProvider);
    final metrics = ref.watch(platformMetricsProvider);
    final isMobile = AppTheme.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(subtitle: 'Resumen del estado de las empresas de la plataforma.'),
          const SizedBox(height: 24),
          companiesAsync.when(
            loading: () => AppTheme.loadingState(message: 'Cargando empresas...'),
            error: (_, _) => AppTheme.errorState('No se pudieron obtener los datos del sistema.'),
            data: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyKpis(metrics: metrics),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(RoutePaths.companies),
                  icon: const Icon(Icons.business_outlined, size: 18),
                  label: const Text('Gestionar empresas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyKpis extends StatelessWidget {
  final PlatformMetrics metrics;

  const _CompanyKpis({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 500 ? 2 : (width < 900 ? 3 : 4);
        final itemWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            DashboardKpiCard(
              icon: Icons.business_outlined,
              label: 'Total de empresas',
              value: metrics.total.toString(),
              color: AppColors.gold,
              width: itemWidth,
            ),
            DashboardKpiCard(
              icon: Icons.check_circle_outline,
              label: 'Empresas activas',
              value: metrics.activas.toString(),
              color: AppColors.success,
              width: itemWidth,
            ),
            DashboardKpiCard(
              icon: Icons.block_outlined,
              label: 'Empresas inactivas',
              value: metrics.suspendidas.toString(),
              color: metrics.suspendidas > 0 ? AppColors.error : AppColors.success,
              width: itemWidth,
            ),
            DashboardKpiCard(
              icon: Icons.event_outlined,
              label: 'Próximas a vencer',
              value: metrics.porVencer.toString(),
              color: metrics.porVencer > 0 ? AppColors.warning : AppColors.success,
              width: itemWidth,
            ),
            DashboardKpiCard(
              icon: Icons.science_outlined,
              label: 'En prueba',
              value: metrics.enPrueba.toString(),
              color: AppColors.info,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final int total;
  final int present;
  final int absent;
  final int workplaces;

  const AdminDashboard({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.total,
    required this.present,
    required this.absent,
    required this.workplaces,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.isMobile(context) ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(subtitle: 'Resumen general del estado del sistema.'),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (hasError) return AppTheme.errorState('No se pudieron obtener los datos del sistema.');
    if (isLoading) return AppTheme.loadingState(message: 'Cargando datos...');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 500 ? 2 : (width < 900 ? 3 : 4);
        final itemWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;

        return SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              DashboardKpiCard(
                icon: Icons.people_outline,
                label: 'Empleados activos',
                value: total.toString(),
                color: AppColors.gold,
                width: itemWidth,
              ),
              DashboardKpiCard(
                icon: Icons.check_circle_outline,
                label: 'Presentes hoy',
                value: present.toString(),
                color: AppColors.success,
                width: itemWidth,
              ),
              DashboardKpiCard(
                icon: Icons.cancel_outlined,
                label: 'Ausentes hoy',
                value: absent.toString(),
                color: absent > 0 ? AppColors.error : AppColors.success,
                width: itemWidth,
              ),
              DashboardKpiCard(
                icon: Icons.business_outlined,
                label: 'Sucursales activas',
                value: workplaces.toString(),
                color: AppColors.goldLight,
                width: itemWidth,
              ),
            ],
          ),
        );
      },
    );
  }
}

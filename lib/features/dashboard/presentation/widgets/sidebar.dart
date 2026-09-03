import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_routes.dart';
import 'sidebar_menu_item.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const List<_MenuItem> _items = [
    _MenuItem(icon: Icons.home_outlined, label: 'Inicio', route: RoutePaths.dashboard, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.business_outlined, label: 'Empresas', route: RoutePaths.companies, visibleFor: {UserRole.superadmin}),
    _MenuItem(icon: Icons.tune_outlined, label: 'Configuración', route: RoutePaths.companySettings, visibleFor: {UserRole.admin, UserRole.superadmin}),
    _MenuItem(icon: Icons.people_outline, label: 'Empleados', route: RoutePaths.employees, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.business_outlined, label: 'Lugares', route: RoutePaths.workplaces, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.fingerprint, label: 'Asistencia', route: RoutePaths.attendance, visibleFor: {UserRole.admin, UserRole.employee}),
    _MenuItem(icon: Icons.history_outlined, label: 'Historial', route: RoutePaths.history, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.medical_services_outlined, label: 'Documentación', route: RoutePaths.medicalDocuments, visibleFor: {UserRole.admin}),
    _MenuItem(icon: Icons.warning_amber_outlined, label: 'Incidencias', route: RoutePaths.incidences, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.bar_chart_outlined, label: 'Reportes', route: RoutePaths.reports, visibleFor: {UserRole.admin, UserRole.employee}),
    _MenuItem(icon: Icons.assignment_outlined, label: 'Justificativos', route: RoutePaths.employeeJustificativos, visibleFor: {UserRole.employee}),
    _MenuItem(icon: Icons.person_outline, label: 'Perfil', route: RoutePaths.profile, visibleFor: {UserRole.superadmin, UserRole.admin, UserRole.supervisor, UserRole.employee}),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final role = ref.watch(userRoleProvider);

    final visibleItems = _items.where((item) => item.visibleFor.contains(role)).toList();

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(color: AppColors.gold, width: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Logo
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
            child: const Text(
              'LOCUSTAF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Control de asistencia',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0),
                  AppColors.gold.withValues(alpha: 0.3),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in visibleItems)
                  SidebarMenuItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: currentRoute == item.route,
                    onTap: () {
                      _closeDrawerIfOpen(context);
                      context.go(item.route);
                    },
                  ),
              ],
            ),
          ),
          // Logout
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0),
                  AppColors.gold.withValues(alpha: 0.3),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SidebarMenuItem(
            icon: Icons.logout_outlined,
            label: 'Cerrar sesión',
            onTap: () async {
              _closeDrawerIfOpen(context);
              final container = ProviderScope.containerOf(context);
              final logout = container.read(logoutProvider);
              await logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Cierra el drawer del Scaffold si está abierto (solo aplica en móvil).
  /// En desktop no hay drawer, por lo que no hace nada.
  void _closeDrawerIfOpen(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Set<UserRole> visibleFor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.visibleFor,
  });
}

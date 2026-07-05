import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import 'sidebar_menu_item.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const List<_MenuItem> _items = [
    _MenuItem(icon: Icons.home, label: 'Inicio', route: RoutePaths.dashboard, visibleFor: {UserRole.admin, UserRole.supervisor, UserRole.employee}),
    _MenuItem(icon: Icons.people, label: 'Empleados', route: RoutePaths.employees, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.business, label: 'Lugares de trabajo', route: RoutePaths.workplaces, visibleFor: {UserRole.admin}),
    _MenuItem(icon: Icons.calendar_today, label: 'Asistencia', route: RoutePaths.attendance, visibleFor: {UserRole.admin, UserRole.employee}),
    _MenuItem(icon: Icons.history, label: 'Historial', route: RoutePaths.history, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.medical_services, label: 'Documentación Médica', route: RoutePaths.medicalDocuments, visibleFor: {UserRole.admin}),
    _MenuItem(icon: Icons.report_problem, label: 'Incidencias', route: RoutePaths.incidences, visibleFor: {UserRole.admin, UserRole.supervisor}),
    _MenuItem(icon: Icons.bar_chart, label: 'Reportes', route: RoutePaths.reports, visibleFor: {UserRole.admin}),
    _MenuItem(icon: Icons.person, label: 'Perfil', route: RoutePaths.profile, visibleFor: {UserRole.admin, UserRole.supervisor, UserRole.employee}),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final role = ref.watch(userRoleProvider);

    final visibleItems = _items.where((item) => item.visibleFor.contains(role)).toList();

    return Container(
      width: 240,
      color: const Color(0xFF1A56DB),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'LOCUSTAF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in visibleItems)
                  SidebarMenuItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: currentRoute == item.route,
                    onTap: () => context.go(item.route),
                  ),
              ],
            ),
          ),
          SidebarMenuItem(
            icon: Icons.logout,
            label: 'Cerrar sesion',
            onTap: () async {
              final container = ProviderScope.containerOf(context);
              final logout = container.read(logoutProvider);
              await logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
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

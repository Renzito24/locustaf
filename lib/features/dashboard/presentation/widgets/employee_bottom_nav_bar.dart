import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';

class EmployeeBottomNavBar extends ConsumerWidget {
  const EmployeeBottomNavBar({super.key});

  static const List<_Destination> _destinations = [
    _Destination(
      icon: Icons.space_dashboard_outlined,
      label: 'Principal',
      route: RoutePaths.employeePrincipal,
    ),
    _Destination(
      icon: Icons.fingerprint,
      label: 'Asistencia',
      route: RoutePaths.attendance,
    ),
    _Destination(
      icon: Icons.history_outlined,
      label: 'Historial',
      route: RoutePaths.history,
    ),
    _Destination(
      icon: Icons.bar_chart_outlined,
      label: 'Reportes',
      route: RoutePaths.reports,
    ),
    _Destination(
      icon: Icons.assignment_outlined,
      label: 'Justificativos',
      route: RoutePaths.employeeJustificativos,
    ),
    _Destination(
      icon: Icons.person_outline,
      label: 'Perfil',
      route: RoutePaths.profile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDarkTop,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final destination in _destinations)
              Expanded(
                child: _DestinationButton(
                  destination: destination,
                  isActive: currentPath == destination.route,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  final _Destination destination;
  final bool isActive;

  const _DestinationButton({
    required this.destination,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.gold : AppColors.textMuted;

    return InkWell(
      onTap: () => context.go(destination.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isActive ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  final IconData icon;
  final String label;
  final String route;

  const _Destination({
    required this.icon,
    required this.label,
    required this.route,
  });
}
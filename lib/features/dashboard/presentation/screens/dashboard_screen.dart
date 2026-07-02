import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCUSTAF'),
      ),
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: Text(
                  'Bienvenido al Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF6B7280),
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

class _SidebarItem {
  final String label;
  final IconData icon;

  const _SidebarItem({required this.label, required this.icon});
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  static const List<_SidebarItem> _menuItems = [
    _SidebarItem(label: 'Inicio', icon: Icons.home),
    _SidebarItem(label: 'Empleados', icon: Icons.people),
    _SidebarItem(label: 'Lugares de trabajo', icon: Icons.business),
    _SidebarItem(label: 'Asistencia', icon: Icons.calendar_today),
    _SidebarItem(label: 'Historial', icon: Icons.history),
    _SidebarItem(label: 'Justificativos', icon: Icons.description),
    _SidebarItem(label: 'Reportes', icon: Icons.bar_chart),
    _SidebarItem(label: 'Perfil', icon: Icons.person),
    _SidebarItem(label: 'Cerrar sesión', icon: Icons.logout),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1A56DB),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final item in _menuItems)
            _SidebarMenuItem(item: item),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final _SidebarItem item;

  const _SidebarMenuItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            if (item.label == 'Cerrar sesión') {
              final container = ProviderScope.containerOf(context);
              final logout = container.read(logoutProvider);

              await logout();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, color: Colors.white, size: 20),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
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

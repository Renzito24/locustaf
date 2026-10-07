import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/sidebar_menu_item.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// E2E del menú de navegación por rol: verifica contra `visibleFor` que cada
/// rol vea su menú y NO vea ítems de otros roles. Complementa a las reglas de
/// Firestore (defensa en profundidad: el menú oculto no es la autorización).
void main() {
  const allLabels = [
    'Inicio',
    'Principal',
    'Empresas',
    'Configuración',
    'Empleados',
    'Lugares',
    'Asistencia',
    'Historial',
    'Documentación',
    'Incidencias',
    'Comunicados',
    'Reportes',
    'Justificativos',
    'Recibos',
    'Perfil',
  ];

  // Página simulada para las rutas del menú: suficiente para que
  // GoRouterState.of(context) resuelva dentro de Sidebar.
  GoRouter routerForAllRoutes() {
    Widget page(String r) => Scaffold(
          body: Center(
            child: r == RoutePaths.dashboard
                ? const Sidebar()
                : Text(r),
          ),
        );
    return GoRouter(
      initialLocation: RoutePaths.dashboard,
      routes: [
        for (final r in [
          RoutePaths.dashboard,
          RoutePaths.employeePrincipal,
          RoutePaths.companies,
          RoutePaths.companySettings,
          RoutePaths.employees,
          RoutePaths.workplaces,
          RoutePaths.attendance,
          RoutePaths.history,
          RoutePaths.medicalDocuments,
          RoutePaths.incidences,
          RoutePaths.comunicados,
          RoutePaths.reports,
          RoutePaths.employeeJustificativos,
          RoutePaths.paystubs,
          RoutePaths.employeePaystubs,
          RoutePaths.profile,
        ])
          GoRoute(path: r, builder: (context, state) => page(r)),
      ],
    );
  }

  Future<void> pumpSidebar(WidgetTester tester, UserRole? role) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = routerForAllRoutes();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoleProvider.overrideWithValue(role),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectOnly(WidgetTester tester, Set<String> visible) {
    for (final label in allLabels) {
      final matcher = visible.contains(label)
          ? findsWidgets
          : findsNothing;
      expect(find.text(label), matcher, reason: 'rol: rótulo "$label"');
    }
  }

  group('Sidebar — visibilidad por rol', () {
    testWidgets('superadmin: Inicio + Empresas + Configuración + Perfil', (tester) async {
      await pumpSidebar(tester, UserRole.superadmin);
      expectOnly(tester, {'Inicio', 'Empresas', 'Configuración', 'Perfil'});
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('admin: menú administrativo completo', (tester) async {
      await pumpSidebar(tester, UserRole.admin);
      expectOnly(tester, {
        'Inicio',
        'Configuración',
        'Empleados',
        'Lugares',
        'Asistencia',
        'Historial',
        'Documentación',
        'Incidencias',
        'Comunicados',
        'Reportes',
        'Recibos',
        'Perfil',
      });
    });

    testWidgets('supervisor: solo lectura (sin Asistencia/Documentación/Configuración)', (tester) async {
      await pumpSidebar(tester, UserRole.supervisor);
      expectOnly(tester, {
        'Inicio',
        'Empleados',
        'Lugares',
        'Historial',
        'Incidencias',
        'Comunicados',
        'Recibos',
        'Perfil',
      });
    });

    testWidgets('employee: solo sus rutas', (tester) async {
      await pumpSidebar(tester, UserRole.employee);
      expectOnly(tester, {
        'Principal',
        'Asistencia',
        'Historial',
        'Comunicados',
        'Reportes',
        'Justificativos',
        'Recibos',
        'Perfil',
      });
    });

    testWidgets('sin rol (no autenticado dentro de la app): menú vacío', (tester) async {
      await pumpSidebar(tester, null);
      expectOnly(tester, {});
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('admin: el orden de las solapas es el esperado', (tester) async {
      await pumpSidebar(tester, UserRole.admin);
      final labels = tester
          .widgetList<SidebarMenuItem>(find.byType(SidebarMenuItem))
          .map((item) => item.label)
          .toList();
      expect(labels, [
        'Inicio',
        'Empleados',
        'Lugares',
        'Asistencia',
        'Historial',
        'Documentación',
        'Incidencias',
        'Comunicados',
        'Reportes',
        'Recibos',
        'Configuración',
        'Perfil',
        'Cerrar sesión',
      ]);
    });
  });
}
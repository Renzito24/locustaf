import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/employee_bottom_nav_bar.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    required UserRole role,
    required String path,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: path,
      routes: [
        ShellRoute(
          builder: (context, state, child) => DashboardLayout(child: child),
          routes: [
            GoRoute(
              path: path,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('CONTENIDO'))),
            ),
          ],
        ),
      ],
    );

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

  group('DashboardLayout — barra inferior del empleado en móvil', () {
    testWidgets('empleado en móvil: muestra las 6 solapas de la barra inferior', (
      tester,
    ) async {
      await pumpShell(
        tester,
        size: const Size(400, 800),
        role: UserRole.employee,
        path: RoutePaths.employeePrincipal,
      );

      expect(find.byType(EmployeeBottomNavBar), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Asistencia'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Justificativos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('empleado en escritorio: sin barra inferior y con sidebar', (
      tester,
    ) async {
      await pumpShell(
        tester,
        size: const Size(1280, 800),
        role: UserRole.employee,
        path: RoutePaths.employeePrincipal,
      );

      expect(find.byType(EmployeeBottomNavBar), findsNothing);
      expect(find.byType(Sidebar), findsOneWidget);
    });

    testWidgets('admin en móvil: sin barra inferior (drawer intacto)', (
      tester,
    ) async {
      await pumpShell(
        tester,
        size: const Size(400, 800),
        role: UserRole.admin,
        path: RoutePaths.dashboard,
      );

      expect(find.byType(EmployeeBottomNavBar), findsNothing);
    });

    testWidgets('empleado en móvil: sin barra inferior en la ruta del formulario', (
      tester,
    ) async {
      await pumpShell(
        tester,
        size: const Size(400, 800),
        role: UserRole.employee,
        path: RoutePaths.employeeCreateIncidence,
      );

      expect(find.byType(EmployeeBottomNavBar), findsNothing);
    });
  });
}
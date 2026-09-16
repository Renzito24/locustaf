import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/dashboard/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión del Dashboard del Super Admin (Fase B — 3ª corrección).
///
/// El Super Admin no administra empleados: su dashboard debe estar orientado a
/// EMPRESAS usando las métricas existentes de la plataforma, sin inventar
/// datos nuevos ni tocar Firestore/Rules.
void main() {
  final now = DateTime.now();

  final activeCompany = CompanyModel(
    id: 'c1',
    nombreComercial: 'Empresa A',
    razonSocial: 'Empresa A S.A.',
    cuit: '20111111112',
    estado: CompanyEstado.activa,
    createdAt: DateTime(2026),
    plan: CompanyPlan.mensual,
    paidUntil: now.add(const Duration(days: 30)),
    lastPaymentAt: now.subtract(const Duration(days: 10)),
  );

  final inactiveCompany = CompanyModel(
    id: 'c2',
    nombreComercial: 'Empresa B',
    razonSocial: 'Empresa B S.R.L.',
    cuit: '20222222222',
    estado: CompanyEstado.inactiva,
    createdAt: DateTime(2026),
  );

  Future<void> pumpHomeScreen(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  testWidgets('superadmin: dashboard con métricas de empresas (no empleados)',
      (tester) async {
    await pumpHomeScreen(
      tester,
      const Size(800, 1000),
      ProviderScope(
        overrides: [
          isSuperadminProvider.overrideWithValue(true),
          allCompaniesProvider.overrideWith((ref) => Stream.value([
            activeCompany,
            inactiveCompany,
          ])),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Total de empresas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Empresas activas'), findsOneWidget);
    expect(find.text('Empresas inactivas'), findsOneWidget);
    expect(find.text('Próximas a vencer'), findsOneWidget);
    expect(find.text('En prueba'), findsOneWidget);

    // Sin conceptos de empleados del dashboard de admin.
    expect(find.text('Empleados activos'), findsNothing);
    expect(find.text('Presentes hoy'), findsNothing);
    expect(find.text('Ausentes hoy'), findsNothing);
    expect(find.text('Sucursales activas'), findsNothing);

    // Acceso rápido a la gestión de empresas.
    expect(find.text('Gestionar empresas'), findsOneWidget);
  });

  testWidgets('superadmin: en teléfono chico (360x640) no produce overflow',
      (tester) async {
    await pumpHomeScreen(
      tester,
      const Size(360, 640),
      ProviderScope(
        overrides: [
          isSuperadminProvider.overrideWithValue(true),
          allCompaniesProvider.overrideWith((ref) => Stream.value([
            activeCompany,
            inactiveCompany,
          ])),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Empresas activas'), findsOneWidget);
  });

  testWidgets('admin: sigue mostrando métricas de empleados (regresión)',
      (tester) async {
    await pumpHomeScreen(
      tester,
      const Size(800, 1000),
      ProviderScope(
        overrides: [
          isSuperadminProvider.overrideWithValue(false),
          allUsersStreamProvider.overrideWith((ref) => Stream.value([])),
          allWorkplacesStreamProvider.overrideWith((ref) => Stream.value([])),
          allAttendancesStreamProvider.overrideWith((ref) => Stream.value([])),
          currentCompanyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Empleados activos'), findsOneWidget);
    expect(find.text('Presentes hoy'), findsOneWidget);
    expect(find.text('Ausentes hoy'), findsOneWidget);
    expect(find.text('Sucursales activas'), findsOneWidget);

    expect(find.text('Empresas activas'), findsNothing);
    expect(find.text('Gestionar empresas'), findsNothing);
  });

  testWidgets('admin: dashboard en escritorio 1200x800 no produce overflow',
      (tester) async {
    await pumpHomeScreen(
      tester,
      const Size(1200, 800),
      ProviderScope(
        overrides: [
          isSuperadminProvider.overrideWithValue(false),
          allUsersStreamProvider.overrideWith((ref) => Stream.value([])),
          allWorkplacesStreamProvider.overrideWith((ref) => Stream.value([])),
          allAttendancesStreamProvider.overrideWith((ref) => Stream.value([])),
          currentCompanyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Empleados activos'), findsOneWidget);
    expect(find.text('Sucursales activas'), findsOneWidget);
  });
}
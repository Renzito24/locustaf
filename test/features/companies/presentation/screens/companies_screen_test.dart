import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/features/companies/domain/services/platform_metrics.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/companies/presentation/screens/companies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool isSuperadmin,
    required AsyncValue<List<CompanyModel>> companiesState,
    PlatformMetrics metrics = const PlatformMetrics(total: 0, activas: 0, suspendidas: 0, porVencer: 0, enPrueba: 0),
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSuperadminProvider.overrideWithValue(isSuperadmin),
          allCompaniesProvider.overrideWithValue(companiesState),
          platformMetricsProvider.overrideWithValue(metrics),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CompaniesScreen(),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('shows warning if not superadmin', (tester) async {
    await pumpScreen(
      tester,
      isSuperadmin: false,
      companiesState: const AsyncValue.data([]),
    );

    expect(find.text('Solo el super administrador puede ver esta sección.'), findsOneWidget);
    expect(find.text('Total'), findsNothing); // Metrics shouldn't be visible
  });

  testWidgets('shows loading state', (tester) async {
    await pumpScreen(
      tester,
      isSuperadmin: true,
      companiesState: const AsyncValue.loading(),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no companies', (tester) async {
    await pumpScreen(
      tester,
      isSuperadmin: true,
      companiesState: const AsyncValue.data([]),
    );

    expect(find.text('No hay empresas registradas'), findsOneWidget);
    expect(find.text('Creá la primera empresa para comenzar.'), findsOneWidget);
  });

  testWidgets('shows list of companies and metrics', (tester) async {
    final now = DateTime.now();
    final company = CompanyModel(
      id: 'c1',
      nombreComercial: 'Test Company',
      razonSocial: 'Test Company LLC',
      cuit: '12-34567890-1',
      estado: CompanyEstado.activa,
      plan: CompanyPlan.mensual,
      createdAt: now,
      updatedAt: now,
      createdBy: 'u1',
    );

    await pumpScreen(
      tester,
      isSuperadmin: true,
      companiesState: AsyncValue.data([company]),
      metrics: const PlatformMetrics(total: 1, activas: 1, suspendidas: 0, porVencer: 0, enPrueba: 0),
    );

    expect(find.text('Test Company'), findsOneWidget);
    expect(find.text('Test Company LLC'), findsOneWidget);
    expect(find.text('CUIT: 12-34567890-1'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // Total and Activas
  });
}

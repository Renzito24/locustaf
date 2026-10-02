import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/payment_model.dart';
import 'package:app_locustaf/features/companies/domain/services/platform_metrics.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/companies/presentation/widgets/superadmin_settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 1);
  
  final mockCompany = CompanyModel(
    id: 'c1',
    nombreComercial: 'Empresa Test',
    razonSocial: 'Empresa Test SRL',
    cuit: '20-12345678-9',
    estado: CompanyEstado.activa,
    plan: CompanyPlan.mensual,
    createdAt: now,
    updatedAt: now,
    createdBy: 'u1',
  );

  final mockPayment = PaymentModel(
    id: 'p1',
    companyId: 'c1',
    companyName: 'Empresa Test',
    plan: CompanyPlan.mensual,
    paidUntil: now.add(const Duration(days: 30)),
    createdAt: now,
  );

  Future<void> pumpPanel(
    WidgetTester tester, {
    PlatformMetrics metrics = const PlatformMetrics(
      total: 5,
      activas: 2,
      suspendidas: 1,
      porVencer: 1,
      enPrueba: 1,
    ),
    AsyncValue<List<CompanyModel>> companiesState = const AsyncValue.data([]),
    AsyncValue<List<PaymentModel>> recentPaymentsState = const AsyncValue.data([]),
    AsyncValue<List<PaymentModel>> companyPaymentsState = const AsyncValue.data([]),
  }) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformMetricsProvider.overrideWithValue(metrics),
          allCompaniesProvider.overrideWith((ref) => Stream.value(companiesState.value ?? [])),
          recentPaymentsProvider.overrideWith((ref) => Stream.value(recentPaymentsState.value ?? [])),
          companyPaymentsProvider.overrideWith((ref, id) => Stream.value(companyPaymentsState.value ?? [])),
          // mock out registerPaymentProvider notifier if needed, though default might be fine
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SuperadminSettingsPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders metrics chips correctly', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Panel de la plataforma'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // Total
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Activas
    expect(find.text('Suspendidas'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(3)); // Suspendidas, porVencer, enPrueba
  });

  testWidgets('shows empty state for payments when no payments', (tester) async {
    await pumpPanel(tester);
    
    expect(find.text('Sin pagos registrados'), findsOneWidget);
  });

  testWidgets('shows recent payments', (tester) async {
    await pumpPanel(
      tester,
      recentPaymentsState: AsyncValue.data([mockPayment]),
    );
    
    expect(find.text('Empresa Test'), findsOneWidget);
    expect(find.textContaining('Vence 31/01/2025'), findsOneWidget);
  });

  testWidgets('selects first company and shows its history', (tester) async {
    await pumpPanel(
      tester,
      companiesState: AsyncValue.data([mockCompany]),
      companyPaymentsState: AsyncValue.data([mockPayment]),
    );
    
    // Dropdown shows company
    expect(find.text('Empresa Test'), findsOneWidget); // Dropdown
    expect(find.text('Historial de Empresa Test'), findsOneWidget);
    // Button Pagar should be enabled and present
    expect(find.text('Pagar'), findsOneWidget);
  });
}

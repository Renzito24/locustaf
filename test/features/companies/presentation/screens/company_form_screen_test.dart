import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/features/companies/domain/repositories/company_repository.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_action_provider.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/companies/presentation/screens/company_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regresión del caso reportado por el usuario: al entrar por primera vez a
/// "Nueva empresa" aparecía "Empresa creada correctamente" (y navegaba solo)
/// sin haber creado nada. Causa raíz: provider de acción con estado inicial
/// `AsyncData(null)` (= éxito). Ahora el estado inicial es idle y el mensaje
/// solo aparece tras una operación real.
class FakeCompanyRepository implements CompanyRepository {
  FakeCompanyRepository({this.fail = false});

  final bool fail;

  @override
  Stream<CompanyModel?> getCompany(String companyId) => Stream.value(null);

  @override
  Stream<List<CompanyModel>> getAllCompanies() => Stream.value(const []);

  @override
  Future<CompanyModel?> getCompanyOnce(String companyId) async => null;

  @override
  Future<String> createCompany(CompanyModel company) async {
    if (fail) throw Exception('fallo simulado');
    return 'company-1';
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    if (fail) throw Exception('fallo simulado');
  }

  @override
  Future<void> setEstado(String companyId, CompanyEstado estado) async {}

  @override
  Future<void> registerPayment(
    String companyId, {
    required DateTime paidUntil,
    CompanyPlan plan = CompanyPlan.mensual,
    String? nota,
  }) async {}
}

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    FakeCompanyRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => const Scaffold(body: CompanyFormScreen()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyRepositoryProvider.overrideWithValue(
            repository ?? FakeCompanyRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Entrar a la pantalla como navegación real (push): el éxito hizo
    // context.pop() y debe volver a '/'.
    router.push('/form');
    await tester.pumpAndSettle();

    final element = find.byType(CompanyFormScreen);
    expect(element, findsOneWidget);
    return ProviderScope.containerOf(tester.element(element));
  }

  const data = CompanyFormData(
    nombreComercial: 'ACME SA',
    razonSocial: 'ACME SA',
    cuit: '30-12345678-9',
  );

  testWidgets(
    'entrar a "Nueva empresa" NO muestra "Empresa creada" ni navega '
    '(regresión del falso éxito)',
    (tester) async {
      await pumpScreen(tester);

      // Con la causa raíz sin corregir este test fallaba: aparecía el snackbar
      // "Empresa creada" y además se ejecutaba context.pop().
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Empresa creada'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guardar empresa con fallo muestra error y NUNCA "Empresa creada"',
    (tester) async {
      final container = await pumpScreen(
        tester,
        repository: FakeCompanyRepository(fail: true),
      );

      await container
          .read(createCompanyProvider.notifier)
          .createCompany(data);
      await tester.pump();

      expect(find.text('Empresa creada'), findsNothing);
      expect(find.text('Error: Exception: fallo simulado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guardar empresa exitoso muestra "Empresa creada" exactamente una vez '
    'y vuelve al listado',
    (tester) async {
      final container = await pumpScreen(tester);

      await container.read(createCompanyProvider.notifier).createCompany(data);
      await tester.pumpAndSettle();

      expect(find.text('Empresa creada'), findsOneWidget);
      expect(find.text('home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
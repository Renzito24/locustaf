import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/features/companies/presentation/widgets/company_card.dart';

void main() {
  group('CompanyCard Tests', () {
    testWidgets('renders CompanyCard correctly for active company', (tester) async {
      final company = CompanyModel(
        id: 'test_company_1',
        nombreComercial: 'Empresa Test',
        cuit: '20-12345678-9',
        razonSocial: 'Test S.A.',
        email: 'test@empresa.com',
        estado: CompanyEstado.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin_id',
        plan: CompanyPlan.mensual,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: company),
            ),
          ),
        ),
      );

      expect(find.text('Empresa Test'), findsOneWidget);
      expect(find.text('CUIT: 20-12345678-9'), findsOneWidget);
      expect(find.text('Test S.A.'), findsOneWidget);
      expect(find.text('test@empresa.com'), findsOneWidget);
      expect(find.text('Activa'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    });

    testWidgets('renders CompanyCard correctly for inactive company', (tester) async {
      final company = CompanyModel(
        id: 'test_company_2',
        nombreComercial: 'Empresa Inactiva',
        cuit: '20-87654321-9',
        razonSocial: 'Inactiva S.A.',
        email: 'inactiva@empresa.com',
        estado: CompanyEstado.inactiva,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin_id',
        plan: CompanyPlan.mensual,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: company),
            ),
          ),
        ),
      );

      expect(find.text('Empresa Inactiva'), findsOneWidget);
      expect(find.text('CUIT: 20-87654321-9'), findsOneWidget);
      expect(find.text('Inactiva S.A.'), findsOneWidget);
      expect(find.text('inactiva@empresa.com'), findsOneWidget);
      expect(find.text('Inactiva'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outlined), findsOneWidget);
    });
  });
}

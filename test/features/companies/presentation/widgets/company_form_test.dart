import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/features/companies/presentation/widgets/company_form.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_action_provider.dart';

void main() {
  group('CompanyForm Tests', () {
    testWidgets('renders create form correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyForm(
                  onSubmit: (data) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nombre comercial *'), findsOneWidget);
      expect(find.text('Razón social *'), findsOneWidget);
      expect(find.text('CUIT *'), findsOneWidget);
      expect(find.text('Crear empresa'), findsOneWidget);
    });

    testWidgets('renders edit form correctly', (tester) async {
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
              body: SingleChildScrollView(
                child: CompanyForm(
                  existingCompany: company,
                  onSubmit: (data) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Empresa Test'), findsOneWidget);
      expect(find.text('Test S.A.'), findsOneWidget);
      expect(find.text('20-12345678-9'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('submits form correctly', (tester) async {
      CompanyFormData? submittedData;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyForm(
                  onSubmit: (data) {
                    submittedData = data;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre comercial *'), 'Nueva Empresa');
      await tester.enterText(find.widgetWithText(TextFormField, 'Razón social *'), 'Nueva S.A.');
      await tester.enterText(find.widgetWithText(TextFormField, 'CUIT *'), '20111111112');
      
      final button = find.text('Crear empresa');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(submittedData, isNotNull);
      expect(submittedData?.nombreComercial, 'Nueva Empresa');
      expect(submittedData?.razonSocial, 'Nueva S.A.');
      expect(submittedData?.cuit, '20111111112');
    });
  });
}

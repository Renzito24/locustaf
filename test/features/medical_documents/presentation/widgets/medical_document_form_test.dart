import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/widgets/medical_document_form.dart';

void main() {
  group('MedicalDocumentForm Tests', () {
    testWidgets('renders properly with fixed user id', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MedicalDocumentForm(
                fixedUserId: 'user123',
                onSubmit: (data) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<MedicalDocumentTipo>), findsOneWidget);
      expect(find.text('Fecha de emisión'), findsOneWidget);
      expect(find.text('Fecha de vencimiento'), findsOneWidget);
      expect(find.text('Crear documento'), findsOneWidget);
    });

    testWidgets('renders properly with users stream', (tester) async {
      final user = UserModel(
        id: 'user123',
        email: 'test@test.com',
        nombre: 'John',
        apellido: 'Doe',
        dni: '12345678',
        rol: UserRole.employee,
        isActive: true,
        isDeleted: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersStreamProvider.overrideWith((ref) => Stream.value([user])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MedicalDocumentForm(
                onSubmit: (data) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<MedicalDocumentTipo>), findsOneWidget);
      expect(find.text('Crear documento'), findsOneWidget);
    });
  });
}

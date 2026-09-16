import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/screens/medical_documents_screen.dart';

void main() {
  final user = UserModel(
    id: 'u1',
    nombre: 'Juan',
    apellido: 'Pérez',
    email: 'juan@test.com',
    dni: '33445566',
    rol: UserRole.employee,
    createdAt: DateTime(2026),
  );

  final doc = MedicalDocumentModel(
    id: 'd1',
    userId: 'u1',
    tipo: MedicalDocumentTipo.enfermedad,
    fechaInicio: DateTime(2026, 1, 1),
    fechaFin: DateTime(2026, 12, 31),
    motivo: 'Certificado por reposo',
    createdAt: DateTime(2026),
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    List<MedicalDocumentModel> docs = const <MedicalDocumentModel>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersStreamProvider.overrideWith((ref) => Stream.value([user])),
          filteredMedicalDocumentsProvider.overrideWith((ref) => docs),
          isAdminProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MedicalDocumentsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Fase B-Corrección: Documentación médica con datos en pantalla de '
    'teléfono chico (360x640) no produce BOTTOM OVERFLOWED',
    (tester) async {
      await pumpScreen(tester, size: const Size(360, 640), docs: [doc]);

      expect(tester.takeException(), isNull);

      // El listado queda alcanzable scrolleando (nada queda oculto).
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fase B-Corrección: Documentación médica sin datos en pantalla de '
    'teléfono chico (360x640) no produce BOTTOM OVERFLOWED',
    (tester) async {
      await pumpScreen(tester, size: const Size(360, 640));

      expect(tester.takeException(), isNull);

      // El estado vacío vive en un sliver al final de la página: hay que
      // scrollear hasta él (la página completa es scrolleable, nada queda
      // oculto ni produce overflow).
      await tester.scrollUntilVisible(
        find.text('Sin documentos médicos'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sin documentos médicos'), findsOneWidget);
    },
  );
}
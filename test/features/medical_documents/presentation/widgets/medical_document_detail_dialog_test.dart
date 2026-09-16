import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/widgets/medical_document_detail_dialog.dart';

/// Fase B — Corrección: el detalle de un documento médico con adjunto debe
/// previsualizar la imagen (o ofrecer abrir el PDF), NUNCA mostrar el URL de
/// Storage como sustituto.
///
/// Nota: en flutter_test el HttpClient de red devuelve 400, por lo que
/// `Image.network` cae en el errorBuilder ("No se pudo cargar la vista
/// previa") y "Abrir PDF" cae en el snackbar de error: ambas rutas se
/// verifican como manejadas.
void main() {
  MedicalDocumentModel buildDoc({
    required String archivoUrl,
    String? archivoNombre,
    String? mimeType,
  }) {
    return MedicalDocumentModel(
      id: 'd1',
      userId: 'u1',
      tipo: MedicalDocumentTipo.enfermedad,
      fechaInicio: DateTime(2026, 1, 1),
      fechaFin: DateTime(2026, 12, 31),
      motivo: 'Certificado por reposo',
      archivoUrl: archivoUrl,
      archivoNombre: archivoNombre,
      mimeType: mimeType,
      createdAt: DateTime(2026),
    );
  }

  Future<void> pumpDialog(WidgetTester tester, MedicalDocumentModel doc) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isAdminProvider.overrideWithValue(false)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MedicalDocumentDetailDialog(
                document: doc,
                employeeName: 'Juan Pérez',
                employeeEmail: 'juan@test.com',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'adjunto imagen: muestra vista previa y NUNCA el URL como texto',
    (tester) async {
      const url = 'https://firebasestorage.googleapis.com/cert.jpg?token=abc';
      await pumpDialog(
        tester,
        buildDoc(
          archivoUrl: url,
          archivoNombre: 'certificado.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      // No se muestra el URL como texto.
      expect(find.text(url), findsNothing);
      // Hay un widget Image de red (la vista previa real), no un enlace.
      expect(find.byType(Image), findsOneWidget);
      // El nombre del archivo sigue visible.
      expect(find.text('certificado.jpg'), findsOneWidget);
      // El fallback de carga por red invalida está manejado.
      expect(find.text('No se pudo cargar la vista previa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('adjunto PDF: botón "Abrir PDF" y NUNCA el URL como texto', (
    tester,
  ) async {
    const url = 'https://firebasestorage.googleapis.com/cert.pdf?token=abc';
    await pumpDialog(
      tester,
      buildDoc(
        archivoUrl: url,
        archivoNombre: 'certificado.pdf',
        mimeType: 'application/pdf',
      ),
    );

    expect(find.text(url), findsNothing);
    expect(find.text('Abrir PDF'), findsOneWidget);
    expect(find.text('certificado.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adjunto PDF: fallo de apertura muestra mensaje de error (no un '
      'falso éxito)', (tester) async {
    const url = 'https://firebasestorage.googleapis.com/cert.pdf?token=abc';
    await pumpDialog(
      tester,
      buildDoc(
        archivoUrl: url,
        archivoNombre: 'certificado.pdf',
        mimeType: 'application/pdf',
      ),
    );

    await tester.tap(find.text('Abrir PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo abrir el PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adjunto de otro tipo: conserva el comportamiento de copiar '
      'enlace y NUNCA muestra el URL como texto', (tester) async {
    const url = 'https://firebasestorage.googleapis.com/recibo.txt?token=abc';
    await pumpDialog(
      tester,
      buildDoc(
        archivoUrl: url,
        archivoNombre: 'recibo.txt',
        mimeType: 'text/plain',
      ),
    );

    expect(find.text(url), findsNothing);
    expect(find.text('recibo.txt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

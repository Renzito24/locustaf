import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/widgets/medical_document_detail_dialog.dart';

/// Fase B — Corrección: el detalle de un documento médico con adjunto debe
/// previsualizar la imagen (o ofrecer abrir el PDF), NUNCA mostrar el URL de
/// Storage como sustituto.
///
/// La vista previa y el PDF se descargan con el SDK de Storage
/// ([medicalAttachmentBytesProvider]) porque el bucket no envía cabeceras CORS
/// y en web `Image.network` / `http.get` fallaban. Por eso los tests inyectan
/// los bytes: sin override la descarga falla y se ejercita la ruta de error.
void main() {
  /// PNG 1x1 transparente válido.
  Uint8List transparentPng() =>
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

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

  Future<void> pumpDialog(
    WidgetTester tester,
    MedicalDocumentModel doc, {
    String? downloadUrl,
    Uint8List? bytes,
    bool isAdmin = false,
  }) async {
    final overrides = [isAdminProvider.overrideWithValue(isAdmin)];
    if (downloadUrl != null && bytes != null) {
      overrides.add(
        medicalAttachmentBytesProvider(
          downloadUrl,
        ).overrideWith((ref) async => bytes),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
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
    'adjunto imagen: renderiza la vista previa descargada y NUNCA el URL como texto',
    (tester) async {
      const url = 'https://firebasestorage.googleapis.com/cert.jpg?token=abc';
      await pumpDialog(
        tester,
        buildDoc(
          archivoUrl: url,
          archivoNombre: 'certificado.jpg',
          mimeType: 'image/jpeg',
        ),
        downloadUrl: url,
        bytes: transparentPng(),
      );
      // No se muestra el URL como texto.
      expect(find.text(url), findsNothing);
      // Hay un widget Image (la vista previa real), no un enlace.
      expect(find.byType(Image), findsOneWidget);
      // La imagen viene de memoria (descarga autenticada), no de la red.
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
        findsOneWidget,
      );
      expect(find.text('No se pudo cargar la vista previa'), findsNothing);
      // El nombre del archivo sigue visible.
      expect(find.text('certificado.jpg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('adjunto imagen: fallo de descarga muestra mensaje de error (no una '
      'imagen rota ni el URL)', (tester) async {
    const url = 'https://firebasestorage.googleapis.com/cert.jpg?token=abc';
    await pumpDialog(
      tester,
      buildDoc(
        archivoUrl: url,
        archivoNombre: 'certificado.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(find.text(url), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('No se pudo cargar la vista previa'), findsOneWidget);
    expect(find.text('certificado.jpg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('botones de aprobar/rechazar se muestran si es admin y estado pendiente', (tester) async {
    const url = 'https://firebasestorage.googleapis.com/recibo.txt?token=abc';
    await pumpDialog(
      tester,
      buildDoc(
        archivoUrl: url,
        archivoNombre: 'recibo.txt',
        mimeType: 'text/plain',
      ),
      isAdmin: true,
    );

    expect(find.text('Aprobar'), findsOneWidget);
    // Pueden haber dos si cuenta también el texto del OutlinedButton
    expect(find.widgetWithText(FilledButton, 'Aprobar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rechazar'), findsOneWidget);
  });
}

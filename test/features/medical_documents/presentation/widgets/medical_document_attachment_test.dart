import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/medical_documents/presentation/widgets/medical_document_attachment.dart';
import 'package:app_locustaf/features/medical_documents/domain/file_attachment_kind.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';

void main() {
  Widget createWidgetUnderTest(FileAttachmentKind kind, {List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(
          body: MedicalDocumentAttachment(
            fileName: 'test_file.ext',
            url: 'https://example.com/test_file.ext',
            kind: kind,
          ),
        ),
      ),
    );
  }

  testWidgets('Renders properly for kind = other', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(FileAttachmentKind.other));
    await tester.pumpAndSettle();

    expect(find.text('Archivo'), findsOneWidget);
    expect(find.text('test_file.ext'), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('Renders properly for kind = pdf', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(FileAttachmentKind.pdf));
    await tester.pumpAndSettle();

    expect(find.text('Archivo'), findsOneWidget);
    expect(find.text('test_file.ext'), findsOneWidget);
    expect(find.text('Abrir PDF'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf), findsWidgets);
  });

  testWidgets('Renders properly for kind = image with loading state', (tester) async {
    // Override the provider to return a loading state or error state if needed
    // But by default it will be in loading state unless the provider completes
    await tester.pumpWidget(createWidgetUnderTest(
      FileAttachmentKind.image,
      overrides: [
        medicalAttachmentBytesProvider('https://example.com/test_file.ext')
            .overrideWith((ref) => Future.delayed(const Duration(seconds: 1), () => throw Exception('test'))),
      ],
    ));

    expect(find.text('Archivo'), findsOneWidget);
    expect(find.text('test_file.ext'), findsOneWidget);
    
    // Test the loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the error state
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la vista previa'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_locustaf/features/incidences/presentation/widgets/incidence_form.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';

void main() {
  Widget createWidgetUnderTest({
    IncidenceModel? existingIncidence,
    bool isLoading = false,
    String? errorMessage,
    String? fixedUserId,
    required void Function(IncidenceFormData) onSubmit,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(
          body: IncidenceForm(
            existingIncidence: existingIncidence,
            isLoading: isLoading,
            errorMessage: errorMessage,
            fixedUserId: fixedUserId,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  testWidgets('Renders properly without fixedUserId and loading users', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      onSubmit: (_) {},
      overrides: [
        usersStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget); // Empleado
    expect(find.byType(DropdownButtonFormField<IncidenceType>), findsOneWidget); // Tipo
    expect(find.text('Fecha inicio'), findsOneWidget);
    expect(find.text('Fecha fin'), findsOneWidget);
    expect(find.text('Observaciones'), findsOneWidget);
    expect(find.text('Seleccionar archivo (opcional)'), findsOneWidget);
    expect(find.text('Crear incidencia'), findsOneWidget);
  });

  testWidgets('Validation shows errors when fields are empty', (tester) async {
    bool isSubmitted = false;

    await tester.pumpWidget(createWidgetUnderTest(
      fixedUserId: 'user-123',
      onSubmit: (_) {
        isSubmitted = true;
      },
      overrides: [],
    ));
    await tester.pumpAndSettle();

    // Clear observaciones field since it's required
    // By default it is empty, but just to be sure we trigger the submit button
    await tester.tap(find.text('Crear incidencia'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese las observaciones'), findsOneWidget);
    expect(isSubmitted, isFalse);
  });

  testWidgets('Submits correctly when fields are valid', (tester) async {
    IncidenceFormData? submittedData;

    await tester.pumpWidget(createWidgetUnderTest(
      fixedUserId: 'user-123',
      onSubmit: (data) {
        submittedData = data;
      },
      overrides: [],
    ));
    await tester.pumpAndSettle();

    // Enter observaciones
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Test de incidencia'
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear incidencia'));
    await tester.pumpAndSettle();

    expect(submittedData, isNotNull);
    expect(submittedData!.userId, 'user-123');
    expect(submittedData!.observaciones, 'Test de incidencia');
    expect(submittedData!.type, IncidenceType.vacaciones);
  });
}

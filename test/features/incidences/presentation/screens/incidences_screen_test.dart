import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/incidences/presentation/screens/incidences_screen.dart';

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

  final incidence = IncidenceModel(
    id: 'i1',
    userId: 'u1',
    type: IncidenceType.vacaciones,
    fechaInicio: DateTime(2026, 1, 1),
    fechaFin: DateTime(2026, 1, 20),
    observaciones: 'Vacaciones de verano',
    createdAt: DateTime(2026),
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    List<IncidenceModel> incidences = const <IncidenceModel>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersStreamProvider.overrideWith((ref) => Stream.value([user])),
          filteredIncidencesProvider.overrideWith((ref) => incidences),
          isAdminProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: Scaffold(body: IncidencesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Fase B-Corrección: Incidencias con datos en pantalla de teléfono chico '
    '(360x640) no produce BOTTOM OVERFLOWED',
    (tester) async {
      await pumpScreen(tester, size: const Size(360, 640), incidences: [incidence]);

      expect(tester.takeException(), isNull);

      // El listado queda alcanzable scrolleando (nada queda oculto).
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fase B-Corrección: Incidencias sin datos en pantalla de teléfono chico '
    '(360x640) no produce BOTTOM OVERFLOWED',
    (tester) async {
      await pumpScreen(tester, size: const Size(360, 640));

      expect(tester.takeException(), isNull);

      // El estado vacío vive en un sliver al final de la página: hay que
      // scrollear hasta él (la página completa es scrolleable, nada queda
      // oculto ni produce overflow).
      await tester.scrollUntilVisible(
        find.text('Sin incidencias'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sin incidencias'), findsOneWidget);
    },
  );
}
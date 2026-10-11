import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/comunicados/domain/models/comunicado_model.dart';
import 'package:app_locustaf/features/comunicados/presentation/providers/comunicados_provider.dart';
import 'package:app_locustaf/features/comunicados/presentation/screens/comunicados_screen.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

UserModel _user(String id, String nombre, String apellido, UserRole rol) {
  return UserModel(
    id: id,
    nombre: nombre,
    apellido: apellido,
    email: '$id@test.com',
    dni: id,
    rol: rol,
    createdAt: DateTime(2026, 1, 1),
  );
}

ComunicadoModel _comunicado({
  required String id,
  String? content,
  String? storagePath,
  required DateTime createdAt,
  String? title,
}) {
  return ComunicadoModel(
    id: id,
    companyId: 'c1',
    title: title ?? 'Comunicado $id',
    content: content,
    targetType: TargetType.all,
    storagePath: storagePath,
    createdBy: 'admin1',
    createdAt: createdAt,
  );
}

void main() {
  final empleado = _user('u1', 'Ana', 'García', UserRole.employee);
  final otroEmpleado = _user('u2', 'Luis', 'Pérez', UserRole.employee);

  final legible = _comunicado(
    id: 'c1',
    content:
        'Recordatorio: la próxima reunión de equipo es el viernes a las 10:00 hs en la sala principal.',
    createdAt: DateTime(2026, 10, 9, 9, 0),
  );
  final pdf = _comunicado(
    id: 'c2',
    storagePath: 'companies/c1/comunicados/c2.pdf',
    createdAt: DateTime(2026, 10, 5, 14, 30),
  );
  final largo = _comunicado(
    id: 'c3',
    title:
        'Aviso de actualización del reglamento interno de la empresa que requiere lectura atenta de todo el personal',
    content: List.filled(
      80,
      'contenido extenso para probar el envoltorio de texto largo',
    ).join(' '),
    createdAt: DateTime(2026, 9, 30, 8, 0),
  );

  Widget buildApp({
    required bool isAdmin,
    List<ComunicadoModel>? comunicados,
    List<String> readIds = const [],
    List<String>? readers,
  }) {
    return ProviderScope(
      overrides: [
        currentCompanyIdProvider.overrideWithValue('c1'),
        isAdminProvider.overrideWithValue(isAdmin),
        currentUserModelProvider.overrideWithValue(empleado),
        comunicadosForUserProvider.overrideWith(
          (ref) => AsyncValue.data(comunicados ?? [legible, pdf]),
        ),
        comunicadosReadIdsProvider.overrideWith((ref) => Stream.value(readIds)),
        usersStreamProvider.overrideWith(
          (ref) => Stream.value([empleado, otroEmpleado]),
        ),
        comunicadoReadersProvider.overrideWith(
          (ref, id) => Stream.value(readers ?? []),
        ),
      ],
      child: MaterialApp(home: const ComunicadosScreen()),
    );
  }

  group('Admin — Comunicados', () {
    testWidgets('renderiza lista con nuevo comunicado, badges y eliminar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: true));
      await tester.pumpAndSettle();

      expect(find.byType(ComunicadosScreen), findsOneWidget);
      expect(find.text('Nuevo Comunicado'), findsOneWidget);
      expect(find.text('Comunicado c1'), findsOneWidget);
      expect(find.text('Comunicado c2'), findsOneWidget);
      expect(find.byTooltip('Eliminar comunicado'), findsWidgets);
      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
    });

    testWidgets('abre el detalle de un comunicado de texto y ve "Leído por"', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: true, readers: ['u1', 'u2']));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comunicado c1'));
      await tester.pumpAndSettle();

      expect(find.text('Leído por:'), findsOneWidget);
      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('Luis Pérez'), findsOneWidget);
    });

    testWidgets('confirmación de eliminación se puede cancelar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Eliminar comunicado'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Comunicado c1'), findsOneWidget);
      expect(find.text('Comunicado c2'), findsOneWidget);
    });
  });

  group('Empleado — Comunicados', () {
    testWidgets('muestra badge NUEVO para comunicados no leídos', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: false, readIds: ['c1']));
      await tester.pumpAndSettle();

      expect(find.text('NUEVO'), findsOneWidget);
      expect(find.text('Comunicado c1'), findsOneWidget);
      expect(find.text('Comunicado c2'), findsOneWidget);
    });

    testWidgets('abre el detalle de texto al tocarlo (marca como leído)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: false, readIds: ['c1']));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comunicado c1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Recordatorio:'), findsOneWidget);
    });
  });

  group('Responsive — sin desbordes', () {
    const widths = [320.0, 375.0, 768.0, 1024.0, 1440.0];

    for (final w in widths) {
      testWidgets('admin a ${w.toInt()}px sin excepciones', (tester) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(
            isAdmin: true,
            comunicados: [legible, pdf, largo],
            readers: ['u1'],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ComunicadosScreen), findsOneWidget);
      });

      testWidgets('empleado a ${w.toInt()}px sin excepciones', (tester) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(
            isAdmin: false,
            comunicados: [legible, pdf, largo],
            readIds: ['c1', 'c2'],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ComunicadosScreen), findsOneWidget);
      });
    }
  });

  group('Casos borde', () {
    testWidgets('lista vacía muestra estado vacío enriquecido sin errores', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: false, comunicados: []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ComunicadosScreen), findsOneWidget);
    });

    testWidgets('título y contenido muy largos no rompen el layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: true, comunicados: [largo]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Aviso de actualización').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('contenido extenso'), findsOneWidget);
    });
  });
}

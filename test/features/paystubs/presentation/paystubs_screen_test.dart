import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/paystubs/domain/models/paystub_model.dart';
import 'package:app_locustaf/features/paystubs/presentation/providers/paystubs_provider.dart';
import 'package:app_locustaf/features/paystubs/presentation/screens/employee_paystubs_screen.dart';
import 'package:app_locustaf/features/paystubs/presentation/screens/paystubs_screen.dart';

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

PaystubModel _paystub({
  required String id,
  required String userId,
  required String periodo,
  required PaystubEstado estado,
  String? observacionRechazo,
}) {
  return PaystubModel(
    id: id,
    companyId: 'c1',
    userId: userId,
    periodo: periodo,
    documentUrl:
        'https://firebasestorage.googleapis.com/v0/b/test/o/$id.pdf?alt=media',
    storagePath: 'companies/c1/paystubs/$userId/$id.pdf',
    fileName: '$id.pdf',
    estado: estado,
    observacionRechazo: observacionRechazo,
    createdAt: DateTime(2026, 10, 5, 10, 30),
    updatedAt: DateTime(2026, 10, 5, 10, 30),
    isActive: true,
  );
}

void main() {
  final ana = _user('u1', 'Ana', 'García', UserRole.employee);
  final luis = _user('u2', 'Luis', 'Pérez', UserRole.employee);
  final carla = _user('u3', 'Carla', 'Díaz', UserRole.employee);
  const currentPeriodo = '2026-10';

  final paystubPendiente = _paystub(
    id: 'p1',
    userId: 'u1',
    periodo: currentPeriodo,
    estado: PaystubEstado.pendiente,
  );
  final paystubRechazado = _paystub(
    id: 'p2',
    userId: 'u2',
    periodo: currentPeriodo,
    estado: PaystubEstado.rechazado,
    observacionRechazo: 'El importe no coincide con la liquidación registrada.',
  );
  final paystubHistorico = _paystub(
    id: 'p3',
    userId: 'u1',
    periodo: '2026-09',
    estado: PaystubEstado.aceptado,
  );

  Widget buildApp({
    required bool isAdmin,
    required List<PaystubModel> paystubs,
    List<UserModel>? users,
  }) {
    return ProviderScope(
      overrides: [
        currentCompanyIdProvider.overrideWithValue('c1'),
        isAdminProvider.overrideWithValue(isAdmin),
        paystubsStreamProvider.overrideWith((ref) => Stream.value(paystubs)),
        usersStreamProvider.overrideWith(
          (ref) => Stream.value(users ?? [ana, luis]),
        ),
      ],
      child: MaterialApp(
        home: isAdmin ? const PaystubsScreen() : const EmployeePaystubsScreen(),
      ),
    );
  }

  group('Admin — Recibos', () {
    testWidgets('renderiza métricas, filtros y filas con badges de estado', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(isAdmin: true, paystubs: [paystubPendiente, paystubRechazado]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaystubsScreen), findsOneWidget);
      expect(find.text('Buscar empleado...'), findsOneWidget);
      expect(find.text('Mes / Año'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);
      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('Sin recibo'), findsOneWidget);
    });

    testWidgets('filtra por estado Rechazado', (tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(isAdmin: true, paystubs: [paystubPendiente, paystubRechazado]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechazado').last);
      await tester.pumpAndSettle();

      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.text('Ana García'), findsNothing);
    });

    testWidgets('filtro de búsqueda por nombre', (tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(isAdmin: true, paystubs: [paystubPendiente, paystubRechazado]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Luis');
      await tester.pumpAndSettle();

      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.text('Ana García'), findsNothing);
    });

    testWidgets('abre el detalle del recibo (Ver recibo) y lo cierra', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(isAdmin: true, paystubs: [paystubPendiente]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ver recibo'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de Recibo'), findsOneWidget);
      expect(find.text('Empleado'), findsWidgets);
      expect(find.text('Periodo'), findsOneWidget);
      expect(find.text('Ver Documento'), findsOneWidget);
      expect(find.text('Descargar'), findsOneWidget);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Detalle de Recibo'), findsNothing);
    });

    testWidgets(
      'admin NO ve botones Aceptar/Rechazar (decisión del empleado)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(isAdmin: true, paystubs: [paystubPendiente]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Ver recibo'));
        await tester.pumpAndSettle();

        expect(find.text('Detalle de Recibo'), findsOneWidget);
        expect(find.text('Aceptar Recibo'), findsNothing);
        expect(find.text('Rechazar Recibo'), findsNothing);
      },
    );
  });

  group('Empleado — Historial de recibos', () {
    testWidgets(
      'renderiza historial multi-mes con selector de año y tarjetas',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(
            isAdmin: false,
            paystubs: [paystubPendiente, paystubHistorico],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmployeePaystubsScreen), findsOneWidget);
        expect(find.text('Historial de Recibos'), findsOneWidget);
        expect(find.text('2026'), findsWidgets);
        expect(find.text('2025'), findsNothing);
        expect(find.byType(ChoiceChip), findsWidgets);
        expect(find.textContaining('Subido el'), findsNWidgets(2));
        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text('Aceptado'), findsOneWidget);
      },
    );

    testWidgets('empleado ve botones Aceptar/Rechazar en recibo pendiente', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildApp(isAdmin: false, paystubs: [paystubPendiente]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Subido el').first);
      await tester.pumpAndSettle();

      expect(find.text('Detalle de Recibo'), findsOneWidget);
      expect(find.text('Aceptar Recibo'), findsOneWidget);
      expect(find.text('Rechazar Recibo'), findsOneWidget);
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
            paystubs: [paystubPendiente, paystubRechazado],
            users: [ana, luis, carla],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PaystubsScreen), findsOneWidget);
      });

      testWidgets('empleado a ${w.toInt()}px sin excepciones', (tester) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(
            isAdmin: false,
            paystubs: [paystubPendiente, paystubHistorico],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(EmployeePaystubsScreen), findsOneWidget);
      });
    }
  });

  group('Casos borde', () {
    testWidgets('lista vacía de recibos muestra empleados sin recibo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(isAdmin: true, paystubs: []));
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.text('Sin recibo'), findsWidgets);
    });

    testWidgets('nombre y observación muy largos no rompen el layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final nombreLargo = _user(
        'u9',
        'Juan Carlos María de la Cruz Fernández',
        'González Pérez Gómez Rodríguez',
        UserRole.employee,
      );
      final textoLargo = List.filled(60, 'palabra larga').join(' ');
      final rechazadoLargo = _paystub(
        id: 'p9',
        userId: 'u9',
        periodo: currentPeriodo,
        estado: PaystubEstado.rechazado,
        observacionRechazo: textoLargo,
      );

      await tester.pumpWidget(
        buildApp(
          isAdmin: true,
          paystubs: [rechazadoLargo],
          users: [nombreLargo],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Ver recibo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

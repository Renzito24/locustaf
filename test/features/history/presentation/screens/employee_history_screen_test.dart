import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/history/presentation/screens/employee_history_screen.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Historial del empleado (Ronda 3A — B4): sus propias jornadas ordenadas por
/// fecha de ingreso descendente, sin datos de otras solapas ni de la empresa.
void main() {
  final workplaceModel = WorkplaceModel(
    id: 'w1',
    nombre: 'Sucursal Central',
    latitud: -34.5,
    longitud: -58.6,
    radio: 200,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  AttendanceModel completedRecord() {
    return AttendanceModel(
      id: 'att-1',
      userId: 'u1',
      checkInTime: DateTime(2026, 4, 1, 9, 0),
      checkOutTime: DateTime(2026, 4, 1, 18, 0),
      durationMinutes: 480,
      date: '2026-04-01',
      status: AttendanceStatus.completed,
      workplaceId: 'w1',
      companyId: 'c1',
    );
  }

  AttendanceModel activeRecord() {
    return AttendanceModel(
      id: 'att-2',
      userId: 'u1',
      checkInTime: DateTime(2026, 4, 2, 9, 30),
      date: '2026-04-02',
      status: AttendanceStatus.active,
      workplaceId: 'w1',
      companyId: 'c1',
    );
  }

  Future<void> pumpHistory(
    WidgetTester tester, {
    List<AttendanceModel>? attendances,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          userRoleProvider.overrideWithValue(UserRole.employee),
          attendancesByUserProvider('u1')
              .overrideWith((ref) => Stream.value(attendances ?? <AttendanceModel>[])),
          activeWorkplacesProvider
              .overrideWith((ref) => AsyncValue.data([workplaceModel])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EmployeeHistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las jornadas con estado, horarios y lugar', (tester) async {
    await pumpHistory(tester, attendances: [
      completedRecord(),
      activeRecord(),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Historial'), findsOneWidget);

    // La más reciente (activa, 02/04) se ordena primero; ambas están presentes.
    expect(find.text('2026-04-02'), findsOneWidget);
    expect(find.text('2026-04-01'), findsOneWidget);

    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);

    expect(find.textContaining('Lugar: Sucursal Central'), findsNWidgets(2));
    expect(find.textContaining('Entrada: 09:00'), findsOneWidget);
    expect(find.textContaining('Entrada: 09:30'), findsOneWidget);
    expect(find.textContaining('8h 0min'), findsOneWidget);
  });

  testWidgets('jornada activa no muestra salida ni duración', (tester) async {
    await pumpHistory(tester, attendances: [activeRecord()]);

    expect(find.textContaining('Entrada: 09:30'), findsOneWidget);
    expect(find.textContaining('Salida:'), findsNothing);
    expect(find.textContaining('min'), findsNothing);
  });

  testWidgets('sin registros: estado vacío', (tester) async {
    await pumpHistory(tester, attendances: []);

    expect(find.text('Sin registros de asistencia'), findsOneWidget);
    expect(find.textContaining('Aún no se registraron jornadas'), findsOneWidget);
  });
}
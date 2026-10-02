import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/widgets/admin_attendance_view.dart';


void main() {
  testWidgets('AdminAttendanceView Tests', (WidgetTester tester) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final mockUser = UserModel(
      id: 'user1',
      email: 'user1@test.com',
      nombre: 'User',
      apellido: 'Uno',
      dni: '12345678',
      rol: UserRole.employee,
      companyId: 'company1',
      lugarDeTrabajoId: 'workplace1',
      isActive: true,
      isDeleted: false,
      createdAt: now,
    );

    final mockWorkplace = WorkplaceModel(
      id: 'workplace1',
      companyId: 'company1',
      nombre: 'Oficina Central',
      direccion: 'Calle 123',
      latitud: -34.0,
      longitud: -58.0,
      radio: 50,
      createdAt: now,
      isActive: true,
    );

    final mockAttendance = AttendanceModel(
      id: 'att1',
      userId: 'user1',
      companyId: 'company1',
      workplaceId: 'workplace1',
      date: dateKey,
      checkInTime: now,
      checkInLatitud: -34.0,
      checkInLongitud: -58.0,
      status: AttendanceStatus.active,
      isLate: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUsersStreamProvider.overrideWith((ref) => Stream.value([mockUser])),
          allWorkplacesStreamProvider.overrideWith((ref) => Stream.value([mockWorkplace])),
          allAttendancesStreamProvider.overrideWith((ref) => Stream.value([mockAttendance])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AdminAttendanceView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check basic rendering
    expect(find.text('Asistencia'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('User Uno'), findsOneWidget);
    expect(find.text('Lugar: Oficina Central'), findsOneWidget);
    
    // Tap to open manual check in dialog
    await tester.tap(find.text('Registrar ingreso manual'));
    await tester.pumpAndSettle();

    // Dialog opens
    expect(find.text('User Uno'), findsNWidgets(2)); // One in list, one in dialog
    expect(find.text('Cancelar'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
}

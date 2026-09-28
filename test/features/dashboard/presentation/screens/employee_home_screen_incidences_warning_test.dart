import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/dashboard/presentation/screens/employee_home_screen.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final today = DateTime(now.year, now.month, now.day);

  UserModel buildEmployeeUser() => UserModel(
        id: 'u1',
        nombre: 'Juan',
        apellido: 'Pérez',
        email: 'juan@test.com',
        dni: '12345678',
        rol: UserRole.employee,
        companyId: 'c1',
        createdAt: monthStart,
      );

  CompanyModel buildCompany() => CompanyModel(
        id: 'c1',
        nombreComercial: 'ACME',
        razonSocial: 'ACME SA',
        cuit: '30-12345678-9',
        createdAt: monthStart,
      );

  AttendanceModel buildAttendance() => AttendanceModel(
        id: 'att-1',
        userId: 'u1',
        checkInTime: DateTime(today.year, today.month, today.day, 9),
        checkOutTime: DateTime(today.year, today.month, today.day, 18),
        durationMinutes: 480,
        date: '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        companyId: 'c1',
        status: AttendanceStatus.completed,
      );

  testWidgets('aviso visible cuando incidencesStreamProvider falla, sin romper la carga de asistencias', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          attendancesByUserProvider('u1').overrideWith(
            (ref) => Stream.value(<AttendanceModel>[buildAttendance()]),
          ),
          incidencesStreamProvider.overrideWith(
            (ref) => Stream.error(Exception('Fallo de red en incidencias')),
          ),
          currentAppUserProvider.overrideWith(
            (ref) => Stream.value(buildEmployeeUser()),
          ),
          currentCompanyProvider.overrideWith(
            (ref) => Stream.value(buildCompany()),
          ),
          activeWorkplacesProvider
              .overrideWith((ref) => const AsyncValue.data(<WorkplaceModel>[])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EmployeeHomeScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // El aviso visible debe estar presente
    expect(find.textContaining('no se pudieron cargar las incidencias'), findsOneWidget);

    // Las métricas de asistencias se cargan correctamente sin romperse
    expect(find.text('Días trabajados'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}

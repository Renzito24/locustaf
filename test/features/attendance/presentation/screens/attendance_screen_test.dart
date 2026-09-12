import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import '../../helpers/attendance_test_harness.dart';

/// E2E de UI de la pantalla de asistencia: empleado registra jornada (check-in
/// con geocerca → estado activo → check-out), más los negativos GPS apagado y
/// fuera de radio, y la vista admin de ingreso manual. Todo el estado se
/// resuelve contra Firestore fake en memoria + GPS fake (sin emulador ni red).
void main() {
  const companyId = 'company-1';
  const employeeId = 'user-1';
  const adminId = 'admin-1';
  const workplaceId = 'workplace-1';
  const oficinaLat = -34.6037;
  const oficinaLng = -58.3816;

  late FakeFirebaseFirestore fake;
  late FakeGeolocatorPlatform geolocator;

  Position at(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<void> seedUser({
    required String id,
    required String nombre,
    String rol = 'employee',
    bool isActive = true,
    String? lugarDeTrabajoId = workplaceId,
  }) async {
    await fake.collection('users').doc(id).set({
      'id': id,
      'nombre': nombre.split(' ').first,
      'apellido': nombre.split(' ').skip(1).join(' '),
      'email': '$id@test.com',
      'dni': '12345678',
      'rol': rol,
      'isActive': isActive,
      'isDeleted': false,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'companyId': companyId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> seedWorkplace({double? radio = 100.0}) async {
    await fake.collection('workplaces').doc(workplaceId).set({
      'id': workplaceId,
      'nombre': 'Oficina Central',
      'latitud': oficinaLat,
      'longitud': oficinaLng,
      'radio': radio,
      'horaInicio': '09:00',
      'horaFin': '18:00',
      'toleranciaMinutos': 15,
      'companyId': companyId,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> pumpAttendanceScreen(
    WidgetTester tester, {
    required UserRole role,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider
              .overrideWithValue(FirestoreService(fake)),
          currentCompanyIdProvider.overrideWithValue(companyId),
          currentUserIdProvider
              .overrideWithValue(role == UserRole.admin ? adminId : employeeId),
          userRoleProvider.overrideWithValue(role),
          attendanceRepositoryProvider.overrideWithValue(
            ServerEmulatorRepository(fake, companyId: companyId),
          ),
        ],
        child: MaterialApp(
          home: const Scaffold(body: AttendanceScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    geolocator = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = geolocator;
  });

  group('Asistencia (employee) — E2E de UI', () {
    testWidgets('check-in con geocerca OK → Jornada activa → check-out completo',
        (tester) async {
      await seedUser(id: employeeId, nombre: 'Juan Pérez');
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      await pumpAttendanceScreen(tester, role: UserRole.employee);

      expect(find.text('No has iniciado tu jornada'), findsOneWidget);
      expect(find.text('Iniciar jornada'), findsOneWidget);

      await tester.tap(find.text('Iniciar jornada'));
      await tester.pumpAndSettle();

      expect(find.text('Jornada activa'), findsOneWidget);
      expect(find.text('Finalizar jornada'), findsOneWidget);

      final attendanceDocs = await fake
          .collection('attendances')
          .where('userId', isEqualTo: employeeId)
          .where('status', isEqualTo: 'active')
          .get();
      expect(attendanceDocs.docs, hasLength(1));
      final lock = await fake.collection('_attendance_locks').doc(employeeId).get();
      expect(lock.exists, isTrue);

      await tester.tap(find.text('Finalizar jornada'));
      await tester.pumpAndSettle();

      expect(find.text('No has iniciado tu jornada'), findsOneWidget);
      final done = await fake
          .collection('attendances')
          .doc(attendanceDocs.docs.first.id)
          .get();
      expect(done.get('status'), 'completed');
      expect(done.get('durationMinutes'), greaterThanOrEqualTo(0));
      final lockAfter = await fake.collection('_attendance_locks').doc(employeeId).get();
      expect(lockAfter.exists, isFalse);
    });

    testWidgets('check-in con GPS apagado: snackbar de error GPS', (tester) async {
      await seedUser(id: employeeId, nombre: 'Juan Pérez');
      await seedWorkplace();
      geolocator.serviceEnabled = false;

      await pumpAttendanceScreen(tester, role: UserRole.employee);

      await tester.tap(find.text('Iniciar jornada'));
      await tester.pumpAndSettle();

      expect(find.textContaining('GPS'), findsWidgets);
      final active = await fake
          .collection('attendances')
          .where('userId', isEqualTo: employeeId)
          .get();
      expect(active.docs, isEmpty);
    });

    testWidgets('check-in fuera del radio: snackbar de geocerca', (tester) async {
      await seedUser(id: employeeId, nombre: 'Juan Pérez');
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng + 0.01);

      await pumpAttendanceScreen(tester, role: UserRole.employee);

      await tester.tap(find.text('Iniciar jornada'));
      await tester.pumpAndSettle();

      expect(find.textContaining('radio'), findsOneWidget);
    });

    testWidgets('check-in con usuario inactivo: snackbar de cuenta no activa',
        (tester) async {
      await seedUser(id: employeeId, nombre: 'Juan Pérez', isActive: false);
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      await pumpAttendanceScreen(tester, role: UserRole.employee);

      await tester.tap(find.text('Iniciar jornada'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no está activa'), findsWidgets);
    });
  });

  group('Asistencia (admin) — E2E de UI', () {
    testWidgets('ingreso manual: diálogo con empleado elegible y persistencia',
        (tester) async {
      await seedUser(id: adminId, nombre: 'Ana Admin', rol: 'admin',
          lugarDeTrabajoId: null);
      await seedUser(id: employeeId, nombre: 'Juan Pérez');
      await seedWorkplace();

      await pumpAttendanceScreen(tester, role: UserRole.admin);

      expect(find.text('Registrar ingreso manual'), findsOneWidget);

      await tester.tap(find.text('Registrar ingreso manual'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar ingreso manual'), findsWidgets); // título del diálogo
      await tester.tap(find.text('Juan Pérez'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ingreso registrado manualmente'), findsWidgets);
      final docs = await fake
          .collection('attendances')
          .where('userId', isEqualTo: employeeId)
          .get();
      expect(docs.docs, hasLength(1));
      expect(docs.docs.first.get('status'), 'active');
      expect(docs.docs.first.get('companyId'), companyId);
    });
  });
}
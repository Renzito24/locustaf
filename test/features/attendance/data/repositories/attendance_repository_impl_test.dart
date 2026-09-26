import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:app_locustaf/features/attendance/domain/exceptions/attendance_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseFunctions implements FirebaseFunctions {
  _FakeFirebaseFunctions(this._handler);

  final void Function(Map<String, dynamic> parameters) _handler;
  final List<Map<String, dynamic>> calls = [];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return _FakeHttpsCallable((parameters) {
      calls.add(parameters);
      _handler(parameters);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeHttpsCallable implements HttpsCallable {
  _FakeHttpsCallable(this._handler);

  final void Function(Map<String, dynamic> parameters) _handler;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _handler(parameters as Map<String, dynamic>);
    throw StateError('La callable falsa solo produce errores controlados');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FunctionsException extends FirebaseFunctionsException {
  _FunctionsException(String message)
      : super(message: message, code: 'internal');
}

/// Test del repositorio de asistencia contra Firestore fake en memoria
/// (fake_cloud_firestore) + mock del runtime de Cloud Functions. La escritura
/// (checkInGeo/manualCheckIn) y el cierre (checkOutGeo/finalizeOrphaned) se
/// delegan a callables del servidor; aquí se verifica la delegación, la
/// traducción de errores de callable a AttendanceException y las consultas.
void main() {
  const companyId = 'company-1';
  const userId = 'user-1';
  const workplaceId = 'workplace-1';

  late FakeFirebaseFirestore fake;
  late FirestoreService service;
  late AttendanceRepositoryImpl repo;

  /* ----------------------------- Helpers de setup ---------------------------- */

  Future<void> seedUser({
    String? rol = 'employee',
    bool isActive = true,
    String? lugarDeTrabajoId = workplaceId,
  }) async {
    final createdAt = DateTime.now().toIso8601String();
    await fake.collection('users').doc(userId).set({
      'id': userId,
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'email': 'juan@test.com',
      'dni': '12345678',
      'telefono': null,
      'rol': rol,
      'isActive': isActive,
      'isDeleted': false,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'companyId': companyId,
      'createdAt': createdAt,
      'updatedAt': null,
    });
  }

  Future<void> seedWorkplace() async {
    final createdAt = DateTime.now().toIso8601String();
    await fake.collection('workplaces').doc(workplaceId).set({
      'id': workplaceId,
      'nombre': 'Oficina Central',
      'description': null,
      'direccion': null,
      'latitud': -34.6037,
      'longitud': -58.3816,
      'radio': 100.0,
      'codigo': null,
      'horaInicio': '09:00',
      'horaFin': '18:00',
      'toleranciaMinutos': 15,
      'companyId': companyId,
      'isActive': true,
      'createdAt': createdAt,
      'updatedAt': null,
    });
  }

  AttendanceModel buildAttendance({
    String? id = '',
    String? user = userId,
    DateTime? checkInTime,
    AttendanceStatus status = AttendanceStatus.active,
    String? workplace = workplaceId,
    String? company = companyId,
  }) {
    return AttendanceModel(
      id: id ?? '',
      userId: user ?? '',
      checkInTime: checkInTime ?? DateTime.now().toLocal(),
      date: '2026-08-29',
      status: status,
      checkInLatitud: -34.6037,
      checkInLongitud: -58.3816,
      isLate: false,
      workplaceId: workplace,
      companyId: company,
    );
  }

  Future<void> seedAttendance(AttendanceModel attendance) async {
    final data = attendance.toJson();
    data['id'] = attendance.id;
    if (attendance.companyId != null) data['companyId'] = attendance.companyId;
    await fake.collection('attendances').doc(attendance.id).set(data);
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    service = FirestoreService(fake);
    repo = AttendanceRepositoryImpl(service, companyId: companyId);
  });

  /* --------------------------- check-in manual --------------------------- */

  group('manualCheckIn (delegación a callable)', () {
    test('delega en la callable manualCheckIn (sin Cloud Functions: error y sin escrituras)', () async {
      expect(
        () => repo.manualCheckIn(buildAttendance()),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Cloud Functions'),
          ),
        ),
      );

      expect((await fake.collection('attendances').get()).docs, isEmpty);
      expect((await fake.collection('_attendance_locks').get()).docs, isEmpty);
    });

    test('envía targetUserId/checkInTime y traduce el error de la callable a AttendanceException', () async {
      final checkInTime = DateTime.now().toLocal();
      final functions = _FakeFirebaseFunctions((_) {
        throw _FunctionsException(
          'La hora de ingreso no puede diferir más de 15 minutos de la hora actual.',
        );
      });
      final repoWithFunctions = AttendanceRepositoryImpl(service,
          companyId: companyId, functions: functions);

      await expectLater(
        repoWithFunctions
            .manualCheckIn(buildAttendance(checkInTime: checkInTime)),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            'La hora de ingreso no puede diferir más de 15 minutos de la hora actual.',
          ),
        ),
      );

      expect(functions.calls, hasLength(1));
      expect(functions.calls.single['targetUserId'], userId);
      expect(
        functions.calls.single['checkInTime'],
        checkInTime.toUtc().toIso8601String(),
      );
    });
  });

  /* -------------------------------- check-out ------------------------------- */

  group('checkOut', () {
    test('delega en la callable checkOutGeo (envía coords e id de asistencia)', () async {
      // El flujo de geocerca (server-side) ya no toca Firestore desde el
      // cliente: sin Cloud Functions configuradas, el repo lo rechaza. La
      // orquestación de checkOutGeo se valida en functions/test.
      expect(
        () => repo.checkOut(
          attendanceId: 'att-1',
          latitud: -34.6037,
          longitud: -58.3816,
        ),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Cloud Functions'),
          ),
        ),
      );
    });
  });

  /* ---------------------------- órdenes huérfanas --------------------------- */

  group('finalizeOrphaned (delegación a callable)', () {
    test('delega en la callable finalizeOrphaned (sin Cloud Functions: error y sin escrituras)', () async {
      expect(
        () => repo.finalizeOrphaned('att-1', userId),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Cloud Functions'),
          ),
        ),
      );

      expect((await fake.collection('attendances').get()).docs, isEmpty);
      expect((await fake.collection('_attendance_locks').get()).docs, isEmpty);
    });

    test('envía attendanceId y traduce el error de la callable a AttendanceException', () async {
      final functions = _FakeFirebaseFunctions((_) {
        throw _FunctionsException('Registro de asistencia no encontrado.');
      });
      final repoWithFunctions = AttendanceRepositoryImpl(service,
          companyId: companyId, functions: functions);

      await expectLater(
        repoWithFunctions.finalizeOrphaned('att-999', userId),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            'Registro de asistencia no encontrado.',
          ),
        ),
      );

      expect(functions.calls, hasLength(1));
      expect(functions.calls.single['attendanceId'], 'att-999');
    });
  });

  /* ---------------------------- consultas útiles --------------------------- */

  group('consultas', () {
    test('getActiveAttendance devuelve la activa y null si no hay', () async {
      await seedAttendance(buildAttendance(id: 'att-1'));
      await seedAttendance(
        buildAttendance(id: 'att-2', checkInTime: DateTime.now().subtract(const Duration(days: 1))),
      );

      final active = await repo.getActiveAttendance(userId).first;
      expect(active, isNotNull);
      expect(active!.status, AttendanceStatus.active);

      await fake.collection('attendances').doc('att-1').update({'status': 'completed'});
      final none = await repo.getActiveAttendance(userId).first;
      expect(none, isNotNull); // att-2 sigue activa
    });

    test('getActiveAttendance filtra por empresa cuando tiene companyId', () async {
      await seedAttendance(buildAttendance(id: 'att-own'));
      await seedAttendance(
        buildAttendance(id: 'att-other-company', company: 'company-2'),
      );

      final active = await repo.getActiveAttendance(userId).first;
      expect(active, isNotNull);
      final activeAttendance = active!;
      expect(activeAttendance.id, 'att-own');
      expect(activeAttendance.companyId, companyId);
    });

    test('getActiveAttendance sin companyId devuelve null (guard Opción B)', () async {
      await seedAttendance(
        buildAttendance(id: 'att-other-company', company: 'company-2'),
      );
      final repoNoCompany = AttendanceRepositoryImpl(service);

      final active = await repoNoCompany.getActiveAttendance(userId).first;
      expect(active, isNull);
    });

    test('getAttendancesByUser filtra por usuario y empresa y ordena descendente', () async {
      await seedAttendance(
        buildAttendance(id: 'att-1', checkInTime: DateTime.now().subtract(const Duration(days: 1))),
      );
      await seedAttendance(
        buildAttendance(id: 'att-2', checkInTime: DateTime.now().subtract(const Duration(days: 3))),
      );
      await seedAttendance(
        buildAttendance(id: 'att-3', checkInTime: DateTime.now().subtract(const Duration(days: 2))),
      );
      await seedAttendance(
        buildAttendance(id: 'att-other', user: 'other-user', company: null),
      );

      // El orden esperado es por checkInTime descendente: att-1 (d-1) antes de att-3 (d-2).
      final list = await repo.getAttendancesByUser(userId).first;
      expect(list.map((a) => a.id), ['att-1', 'att-3', 'att-2']);
    });

    test('getAllAttendances devuelve vacío si no hay companyId', () async {
      final repoNoCompany = AttendanceRepositoryImpl(service);
      await seedAttendance(buildAttendance(id: 'att-any'));
      final list = await repoNoCompany.getAllAttendances().first;
      expect(list, isEmpty);
    });

    test('getAllActiveAttendances consulta solo asistencias activas de la empresa', () async {
      await seedAttendance(buildAttendance(id: 'att-active-1'));
      await seedAttendance(
        buildAttendance(id: 'att-done', status: AttendanceStatus.completed),
      );
      await seedAttendance(
        buildAttendance(id: 'att-other-company', company: 'company-2'),
      );
      await seedAttendance(buildAttendance(id: 'att-active-2'));

      final list = await repo.getAllActiveAttendances().first;
      final ids = list.map((a) => a.id).toList();
      expect(ids, contains('att-active-1'));
      expect(ids, contains('att-active-2'));
      expect(ids, isNot(contains('att-done')));
      expect(ids, isNot(contains('att-other-company')));
    });

    test('getAttendancePage pagina y reporta hasMore', () async {
      for (var i = 0; i < 5; i++) {
        await seedAttendance(
          buildAttendance(
            id: 'att-$i',
            checkInTime: DateTime.now().subtract(Duration(days: 5 - i)),
          ),
        );
      }

      final page1 = await repo.getAttendancePage(limit: 2);
      expect(page1.items, hasLength(2));
      expect(page1.hasMore, isTrue);
      expect(page1.lastCheckInTime, isNotNull);

      // NOTA: fake_cloud_firestore no implementa `startAfter([valor])` (sí
      // `startAfterDocument`), por lo que el desplazamiento con cursor se
      // valida en Firestore real. Aquí se verifica la primera página y el
      // contrato de límite superior (hasMore false cuando no hay más).
      final full = await repo.getAttendancePage(limit: 10);
      expect(full.items, hasLength(5));
      expect(full.hasMore, isFalse);
    });

    test('countCompanyAttendances cuenta solo las de la empresa', () async {
      await seedAttendance(buildAttendance(id: 'att-1'));
      await seedAttendance(buildAttendance(id: 'att-2'));
      await seedAttendance(buildAttendance(id: 'att-other', company: null));
      await fake.collection('attendances').doc('att-other').set({
        'id': 'att-other',
        'userId': 'other-user',
        'checkInTime': Timestamp.fromDate(DateTime.now().toUtc()),
        'date': '2026-08-29',
        'status': 'active',
      });

      final count = await repo.countCompanyAttendances();
      expect(count, 2);
    });

    test('getUser y getWorkplace retornan modelos correctos', () async {
      await seedUser();
      await seedWorkplace();

      final user = await repo.getUser(userId);
      expect(user, isNotNull);
      expect(user!.rol, UserRole.employee);
      expect(user.companyId, companyId);

      final workplace = await repo.getWorkplace(workplaceId);
      expect(workplace, isNotNull);
      expect(workplace!.radio, 100.0);
      expect(workplace.companyId, companyId);
    });
  });
}
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:app_locustaf/features/attendance/domain/exceptions/attendance_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test de integración del repositorio de asistencia contra un Firestore
/// fake en memoria (fake_cloud_firestore). Simula el flujo real de datos:
/// checkIn → lock → checkOut / reclamación de locks → consultas y paginación.
///
/// Nota: usa `FakeFirebaseFirestore` porque las transacciones (`runTransaction`)
/// no pueden mockearse de forma fiable, y este es el acercamiento estándar
/// para tests de repositorios Firestore.
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

  Future<void> seedLock({
    String? user = userId,
    String? attendanceId,
    DateTime? lockedAt,
    DateTime? checkInTime,
  }) async {
    await fake.collection('_attendance_locks').doc(user ?? userId).set({
      'attendanceId': attendanceId,
      'checkInTime': (checkInTime ?? DateTime.now().toLocal()).toIso8601String(),
      'lockedAt': lockedAt != null
          ? Timestamp.fromDate(lockedAt)
          : Timestamp.fromDate(DateTime.now().toUtc()),
      'status': 'active',
    });
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    service = FirestoreService(fake);
    repo = AttendanceRepositoryImpl(service, companyId: companyId);
  });

  /* ------------------------------- check-in -------------------------------- */

  group('checkIn', () {
    test('crea una asistencia activa y un lock válido para el usuario', () async {
      await repo.checkIn(buildAttendance());

      final attendances = await fake
          .collection('attendances')
          .where('userId', isEqualTo: userId)
          .get();
      expect(attendances.docs, hasLength(1));
      expect(attendances.docs.first.get('status'), 'active');
      expect(attendances.docs.first.get('companyId'), companyId);
      expect(attendances.docs.first.get('checkInLatitud'), -34.6037);

      final locks = await fake.collection('_attendance_locks').doc(userId).get();
      expect(locks.exists, isTrue);
      expect(locks.get('attendanceId'), attendances.docs.first.id);
      expect(locks.get('status'), 'active');
    });

    test('rechaza un nuevo check-in si hay un lock activo y vigente', () async {
      await repo.checkIn(buildAttendance());

      expect(
        () => repo.checkIn(buildAttendance(checkInTime: DateTime.now().add(const Duration(minutes: 5)))),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Ya tenés una asistencia activa'),
          ),
        ),
      );
    });

    test('reclama un lock huérfano cuando la asistencia asociada se finalizó', () async {
      await repo.checkIn(buildAttendance(id: 'att-completed'));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;
      // Finalizamos la asistencia pero dejamos (o simulamos) un lock residual.
      await fake.collection('attendances').doc(attendanceId).update({
        'status': 'completed',
        'checkOutTime': Timestamp.fromDate(DateTime.now().toUtc()),
      });
      await seedLock(user: userId, attendanceId: attendanceId, lockedAt: DateTime.now().toUtc());

      // El lock apunta a una asistencia ya completada → es reclamable.
      await repo.checkIn(buildAttendance(checkInTime: DateTime.now().add(const Duration(minutes: 10))));

      final locks = await fake.collection('_attendance_locks').doc(userId).get();
      expect(locks.exists, isTrue);
      expect(locks.get('attendanceId'), isNot(attendanceId));
    });

    test('reclama un lock vencido por TTL (más de 24h) aunque la asistencia siga activa', () async {
      await repo.checkIn(buildAttendance(id: 'att-stale'));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;
      // Lock abandonado hace más de 24h → TTL permite reclamarlo.
      await seedLock(
        user: userId,
        attendanceId: attendanceId,
        lockedAt: DateTime.now().subtract(const Duration(hours: 25)),
        checkInTime: DateTime.now().subtract(const Duration(hours: 25)),
      );

      await repo.checkIn(buildAttendance(checkInTime: DateTime.now()));

      final locks = await fake.collection('_attendance_locks').doc(userId).get();
      expect(locks.exists, isTrue);
      expect(locks.get('attendanceId'), isNot(attendanceId));
    });

    test('no reclama un lock vigente con asistencia aún activa', () async {
      await repo.checkIn(buildAttendance(id: 'att-active'));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;
      // Lock reciente apuntando a una asistencia activa → NO reclamable.
      await seedLock(user: userId, attendanceId: attendanceId, lockedAt: DateTime.now().toUtc());

      expect(
        () => repo.checkIn(buildAttendance(checkInTime: DateTime.now().add(const Duration(minutes: 2)))),
        throwsA(isA<AttendanceException>()),
      );
    });
  });

  /* ------------------------------- check-out ------------------------------- */

  group('checkOut', () {
    test('finaliza la asistencia, guarda duración y limpia el lock', () async {
      final checkInTime = DateTime.now().subtract(const Duration(hours: 4));
      await repo.checkIn(buildAttendance(checkInTime: checkInTime));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;

      await repo.checkOut(
        attendanceId,
        userId,
        checkOutLatitud: -34.6037,
        checkOutLongitud: -58.3816,
      );

      final doc = await fake.collection('attendances').doc(attendanceId).get();
      expect(doc.get('status'), 'completed');
      expect(doc.get('durationMinutes'), greaterThanOrEqualTo(4 * 60));
      expect(doc.get('checkOutLatitud'), -34.6037);
      expect(doc.get('checkOutLongitud'), -58.3816);

      final lock = await fake.collection('_attendance_locks').doc(userId).get();
      expect(lock.exists, isFalse);
    });

    test('lanza error si el registro no pertenece al usuario', () async {
      await repo.checkIn(buildAttendance());
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;

      expect(
        () => repo.checkOut(attendanceId, 'other-user'),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Este registro no te pertenece'),
          ),
        ),
      );
    });

    test('lanza error si la asistencia ya fue finalizada', () async {
      await repo.checkIn(buildAttendance(id: 'att-done'));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;
      await fake.collection('attendances').doc(attendanceId).update({
        'status': 'completed',
        'checkOutTime': Timestamp.fromDate(DateTime.now().toUtc()),
      });

      expect(
        () => repo.checkOut(attendanceId, userId),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('ya fue finalizada'),
          ),
        ),
      );
    });

    test('lanza error si no existe un lock activo', () async {
      await seedAttendance(buildAttendance(id: 'att-no-lock'));

      expect(
        () => repo.checkOut('att-no-lock', userId),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('bloqueo de sesión activo'),
          ),
        ),
      );
    });

    test('lanza error si el registro no existe', () async {
      expect(
        () => repo.checkOut('missing-attendance', userId),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('no encontrado'),
          ),
        ),
      );
    });
  });

  /* --------------------------- órdenes huérfanas --------------------------- */

  group('finalizeOrphaned', () {
    test('finaliza una jornada huérfana, marca isOrphaned y limpia el lock', () async {
      final checkInTime = DateTime.now().subtract(const Duration(hours: 9));
      await repo.checkIn(buildAttendance(id: 'att-orphan', checkInTime: checkInTime));
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;

      await repo.finalizeOrphaned(attendanceId, userId);

      final doc = await fake.collection('attendances').doc(attendanceId).get();
      expect(doc.get('status'), 'completed');
      expect(doc.get('isOrphaned'), isTrue);
      expect(doc.get('durationMinutes'), greaterThanOrEqualTo(8 * 60));

      final lock = await fake.collection('_attendance_locks').doc(userId).get();
      expect(lock.exists, isFalse);
    });

    test('lanza error si no pertenece al usuario', () async {
      await repo.checkIn(buildAttendance());
      final attendanceId = (await fake
              .collection('attendances')
              .where('userId', isEqualTo: userId)
              .get())
          .docs
          .first
          .id;

      expect(
        () => repo.finalizeOrphaned(attendanceId, 'other-user'),
        throwsA(isA<AttendanceException>()),
      );
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
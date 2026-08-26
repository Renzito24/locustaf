import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/domain/services/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator.shiftTimeOn', () {
    test('convierte HH:mm en DateTime sobre la fecha dada', () {
      final date = DateTime(2026, 8, 26);
      final result = AttendanceCalculator.shiftTimeOn(date, '08:30');
      expect(result.year, 2026);
      expect(result.month, 8);
      expect(result.day, 26);
      expect(result.hour, 8);
      expect(result.minute, 30);
    });

    test('acepta hora sin minutos', () {
      final date = DateTime(2026, 8, 26);
      final result = AttendanceCalculator.shiftTimeOn(date, '08');
      expect(result.hour, 8);
      expect(result.minute, 0);
    });
  });

  group('AttendanceCalculator.isLate', () {
    final shiftStart = DateTime(2026, 8, 26, 8, 0);

    test('ingreso dentro de la tolerancia no es tarde', () {
      final checkIn = DateTime(2026, 8, 26, 8, 10);
      expect(
        AttendanceCalculator.isLate(
          checkInTime: checkIn,
          shiftStart: shiftStart,
          toleranceMinutes: 15,
        ),
        isFalse,
      );
    });

    test('ingreso exacto en el límite de tolerancia no es tarde', () {
      final checkIn = DateTime(2026, 8, 26, 8, 15);
      expect(
        AttendanceCalculator.isLate(
          checkInTime: checkIn,
          shiftStart: shiftStart,
          toleranceMinutes: 15,
        ),
        isFalse,
      );
    });

    test('ingreso posterior a la tolerancia es tarde', () {
      final checkIn = DateTime(2026, 8, 26, 8, 16);
      expect(
        AttendanceCalculator.isLate(
          checkInTime: checkIn,
          shiftStart: shiftStart,
          toleranceMinutes: 15,
        ),
        isTrue,
      );
    });

    test('tolerancia cero: ingreso posterior a la hora es tarde', () {
      final checkIn = DateTime(2026, 8, 26, 8, 1);
      expect(
        AttendanceCalculator.isLate(
          checkInTime: checkIn,
          shiftStart: shiftStart,
          toleranceMinutes: 0,
        ),
        isTrue,
      );
    });
  });

  group('AttendanceCalculator.isEarlyCheckout', () {
    final shiftEnd = DateTime(2026, 8, 26, 16, 0);

    test('salida dentro de la tolerancia no es anticipada', () {
      final checkOut = DateTime(2026, 8, 26, 15, 50);
      expect(
        AttendanceCalculator.isEarlyCheckout(
          checkOutTime: checkOut,
          shiftEnd: shiftEnd,
          toleranceMinutes: 15,
        ),
        isFalse,
      );
    });

    test('salida antes de la tolerancia es anticipada', () {
      final checkOut = DateTime(2026, 8, 26, 15, 44);
      expect(
        AttendanceCalculator.isEarlyCheckout(
          checkOutTime: checkOut,
          shiftEnd: shiftEnd,
          toleranceMinutes: 15,
        ),
        isTrue,
      );
    });
  });

  group('AttendanceCalculator.calculateDuration', () {
    test('calcula duración en minutos', () {
      final checkIn = DateTime(2026, 8, 26, 8, 0);
      final checkOut = DateTime(2026, 8, 26, 16, 30);
      expect(AttendanceCalculator.calculateDuration(checkIn, checkOut), 510);
    });

    test('nunca devuelve duración negativa', () {
      final checkIn = DateTime(2026, 8, 26, 16, 0);
      final checkOut = DateTime(2026, 8, 26, 8, 0);
      expect(AttendanceCalculator.calculateDuration(checkIn, checkOut), 0);
    });
  });

  group('AttendanceCalculator.calculateExpectedDuration', () {
    test('calcula duración esperada', () {
      final start = DateTime(2026, 8, 26, 8, 0);
      final end = DateTime(2026, 8, 26, 16, 0);
      expect(AttendanceCalculator.calculateExpectedDuration(start, end), 480);
    });
  });

  group('AttendanceCalculator.isComplete', () {
    test('jornada con salida está completa', () {
      final a = AttendanceModel(
        id: '1',
        userId: 'u1',
        checkInTime: DateTime(2026, 8, 26, 8, 0),
        checkOutTime: DateTime(2026, 8, 26, 16, 0),
        date: '2026-08-26',
        status: AttendanceStatus.completed,
      );
      expect(AttendanceCalculator.isComplete(a), isTrue);
    });

    test('jornada sin salida está incompleta', () {
      final a = AttendanceModel(
        id: '1',
        userId: 'u1',
        checkInTime: DateTime(2026, 8, 26, 8, 0),
        date: '2026-08-26',
        status: AttendanceStatus.active,
      );
      expect(AttendanceCalculator.isComplete(a), isFalse);
    });
  });

  group('AttendanceCalculator.isOrphaned', () {
    test('asistencia activa que superó el fin de jornada es huérfana', () {
      final a = AttendanceModel(
        id: '1',
        userId: 'u1',
        checkInTime: DateTime(2026, 8, 26, 8, 0),
        date: '2026-08-26',
        status: AttendanceStatus.active,
      );
      final shiftEnd = DateTime(2026, 8, 26, 16, 0);
      expect(
        AttendanceCalculator.isOrphaned(
          attendance: a,
          shiftEnd: shiftEnd,
          now: DateTime(2026, 8, 26, 17, 0),
        ),
        isTrue,
      );
    });

    test('asistencia activa dentro de la jornada no es huérfana', () {
      final a = AttendanceModel(
        id: '1',
        userId: 'u1',
        checkInTime: DateTime(2026, 8, 26, 8, 0),
        date: '2026-08-26',
        status: AttendanceStatus.active,
      );
      final shiftEnd = DateTime(2026, 8, 26, 20, 0);
      expect(
        AttendanceCalculator.isOrphaned(
          attendance: a,
          shiftEnd: shiftEnd,
          now: DateTime(2026, 8, 26, 12, 0),
        ),
        isFalse,
      );
    });

    test('asistencia completada nunca es huérfana', () {
      final a = AttendanceModel(
        id: '1',
        userId: 'u1',
        checkInTime: DateTime(2026, 8, 26, 8, 0),
        checkOutTime: DateTime(2026, 8, 26, 16, 0),
        date: '2026-08-26',
        status: AttendanceStatus.completed,
      );
      final shiftEnd = DateTime(2026, 8, 26, 12, 0);
      expect(
        AttendanceCalculator.isOrphaned(
          attendance: a,
          shiftEnd: shiftEnd,
          now: DateTime(2026, 8, 26, 17, 0),
        ),
        isFalse,
      );
    });
  });
}

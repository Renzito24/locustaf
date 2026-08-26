import '../../data/models/attendance_model.dart';

/// Motor de cálculo de jornada laboral.
///
/// Centraliza toda la lógica de cálculo de asistencia para que sea
/// consistente entre dashboard, historial y reportes, y testeable.
/// Es un servicio puro: no depende de Firebase ni de estado.
class AttendanceCalculator {
  AttendanceCalculator._();

  /// Convierte una hora "HH:mm" en un [DateTime] sobre la fecha dada.
  static DateTime shiftTimeOn(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Determina si un ingreso es tarde: supera [shiftStart] + [toleranceMinutes].
  static bool isLate({
    required DateTime checkInTime,
    required DateTime shiftStart,
    required int toleranceMinutes,
  }) {
    final allowed = shiftStart.add(Duration(minutes: toleranceMinutes));
    return checkInTime.isAfter(allowed);
  }

  /// Determina si una salida es anticipada: antes de [shiftEnd] - [toleranceMinutes].
  static bool isEarlyCheckout({
    required DateTime checkOutTime,
    required DateTime shiftEnd,
    required int toleranceMinutes,
  }) {
    final allowed = shiftEnd.subtract(Duration(minutes: toleranceMinutes));
    return checkOutTime.isBefore(allowed);
  }

  /// Duración efectiva en minutos (nunca negativa).
  static int calculateDuration(DateTime checkIn, DateTime checkOut) {
    final d = checkOut.difference(checkIn).inMinutes;
    return d < 0 ? 0 : d;
  }

  /// Duración esperada de la jornada en minutos (nunca negativa).
  static int calculateExpectedDuration(DateTime shiftStart, DateTime shiftEnd) {
    final d = shiftEnd.difference(shiftStart).inMinutes;
    return d < 0 ? 0 : d;
  }

  /// Indica si la jornada está completa (tiene salida registrada).
  static bool isComplete(AttendanceModel attendance) {
    return attendance.checkOutTime != null;
  }

  /// Indica si una asistencia activa quedó huérfana: el fin de jornada ya
  /// pasó ([now] es posterior a [shiftEnd]) sin registrar salida.
  static bool isOrphaned({
    required AttendanceModel attendance,
    required DateTime shiftEnd,
    required DateTime now,
  }) {
    if (attendance.checkOutTime != null) return false;
    return now.isAfter(shiftEnd);
  }
}

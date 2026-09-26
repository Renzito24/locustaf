/**
 * Lógica pura de cierre de jornada huérfana (finalizeOrphaned).
 *
 * Una jornada huérfana es una asistencia 'active' cuyo fin de jornada del
 * lugar de trabajo (horaFin) ya fue superado por el reloj del servidor y que
 * el empleado no pudo cerrar desde la geocerca (checkOutGeo), p. ej. por
 * olvido o por no haber podido volver al lugar de trabajo.
 *
 * Reglas server-side:
 *  - checkOutTime es la hora del SERVIDOR (nunca del cliente).
 *  - durationMinutes se deriva del servidor y queda ACOTADA: nunca mayor que
 *    el lapso checkInTime -> (horaFin + tolerancia) del workplace.
 *  - isOrphaned se marca true.
 * El cierre se rechaza si la jornada aún no superó horaFin: en ese caso la
 * salida debe registrarse por la callable geolocalizada.
 */

const { appTimezoneOffsetMinutes, toMillis } = require('./geoCheckIn');

const TOLERANCE_MINUTES_DEFAULT = 15;

/**
 * Instante UTC del fin de jornada: mismo día local (zona de la empresa) que el
 * check-in, a la hora `horaFin` ("HH:mm"). El día se toma del check-in porque
 * la jornada pertenece a ese día, no al momento actual.
 */
function localShiftEndUtc(checkInMillis, horaFin) {
  if (!horaFin) return null;
  const [hour, minute] = horaFin.split(':').map(Number);
  const local = new Date(checkInMillis + appTimezoneOffsetMinutes * 60000);
  return (
    Date.UTC(
      local.getUTCFullYear(),
      local.getUTCMonth(),
      local.getUTCDate(),
      hour || 0,
      minute || 0,
    ) -
    appTimezoneOffsetMinutes * 60000
  );
}

/**
 * Decisión pura de cierre de jornada huérfana.
 * Devuelve `{ ok: false, code, message }` ante cualquier rechazo o
 * `{ ok: true, code, checkOutTime, durationMinutes, isOrphaned }`.
 */
function decideFinalizeOrphaned({ user, workplace, attendance, now }) {
  if (!user) {
    return { ok: false, code: 'user-not-found', message: 'Usuario no encontrado.' };
  }
  const companyId = user.companyId || null;
  if (!user.isActive || user.isDeleted) {
    return {
      ok: false,
      code: 'account-inactive',
      message: 'La cuenta no está activa. No se puede finalizar la jornada.',
    };
  }
  if (user.rol !== 'employee') {
    return {
      ok: false,
      code: 'role-not-allowed',
      message: 'Tu rol no permite finalizar la jornada.',
    };
  }
  if (!attendance) {
    return {
      ok: false,
      code: 'attendance-not-found',
      message: 'Registro de asistencia no encontrado.',
    };
  }
  if (attendance.userId !== user.id) {
    return { ok: false, code: 'attendance-not-owner', message: 'Este registro no te pertenece.' };
  }
  if (attendance.companyId !== companyId) {
    return { ok: false, code: 'attendance-cross-company', message: 'Este registro no te pertenece.' };
  }
  if (attendance.status === 'completed') {
    return {
      ok: false,
      code: 'attendance-completed',
      message: 'Esta asistencia ya fue finalizada.',
    };
  }
  const workplaceId = user.lugarDeTrabajoId || null;
  if (!workplaceId) {
    return {
      ok: false,
      code: 'no-workplace',
      message: 'No tenés un lugar de trabajo asignado. Contactá al administrador.',
    };
  }
  if (!workplace || workplace.id !== workplaceId) {
    return {
      ok: false,
      code: 'workplace-not-found',
      message: 'El lugar de trabajo asignado no existe.',
    };
  }
  if (workplace.companyId !== companyId) {
    return {
      ok: false,
      code: 'workplace-mismatch',
      message: 'El lugar de trabajo no pertenece a tu empresa.',
    };
  }
  const checkInMillis = toMillis(attendance.checkInTime);
  if (checkInMillis == null) {
    return {
      ok: false,
      code: 'invalid-check-in-time',
      message: 'Asistencia con fecha de ingreso inválida.',
    };
  }
  if (!workplace.horaFin) {
    return {
      ok: false,
      code: 'no-shift-end',
      message: 'El lugar de trabajo no tiene horario de fin configurado.',
    };
  }
  const shiftEndUtc = localShiftEndUtc(checkInMillis, workplace.horaFin);
  const nowMillis = toMillis(now) ?? 0;
  if (nowMillis <= shiftEndUtc) {
    return {
      ok: false,
      code: 'shift-not-ended',
      message: 'Tu jornada aún no finalizó. Finalizala desde tu lugar de trabajo.',
    };
  }

  // Duración server-side acotada: nunca mayor que checkInTime -> horaFin + tolerancia.
  const toleranceMinutes =
    typeof workplace.toleranciaMinutos === 'number'
      ? workplace.toleranciaMinutos
      : TOLERANCE_MINUTES_DEFAULT;
  const shiftEndPlusTolerance = shiftEndUtc + toleranceMinutes * 60000;
  const rawDurationMinutes = Math.max(0, Math.floor((nowMillis - checkInMillis) / 60000));
  const maxDurationMinutes = Math.max(0, Math.floor((shiftEndPlusTolerance - checkInMillis) / 60000));
  const durationMinutes = Math.min(rawDurationMinutes, maxDurationMinutes);

  return {
    ok: true,
    code: 'ok',
    checkOutTime: now,
    durationMinutes,
    isOrphaned: true,
  };
}

module.exports = {
  localShiftEndUtc,
  decideFinalizeOrphaned,
};
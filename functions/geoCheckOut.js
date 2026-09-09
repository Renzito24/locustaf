/**
 * Lógica pura de finalización de jornada con geocerca server-side
 * (AUI-02, Fase 3).
 *
 * Mismo patrón que geoCheckIn.js: la validación de distancia (Haversine) y las
 * validaciones de negocio se centralizan aquí para poder unit-testearlas sin
 * depender del emulador. La callable `checkOutGeo` (index.js) orquesta la
 * transacción de cierre usando estas funciones.
 */

const { haversineDistance, formatDistance, toMillis } = require('./geoCheckIn');

/**
 * Valida las coordenadas y decide si el empleado puede cerrar su jornada.
 * Devuelve `{ ok: false, code, message }` ante cualquier rechazo o
 * `{ ok: true, code, distance, companyId, workplaceId }`.
 *
 * El lugar de trabajo se toma del documento del usuario (nunca del cliente),
 * igual que en el check-in. La asistencia se identifica por `attendanceId`
 * enviado por el cliente, pero su pertenencia/estado se validan contra el
 * documento real (nunca se confía en valores del payload).
 */
function decideRegisterCheckOut({ user, workplace, attendance, now, latitud, longitud }) {
  if (!user) {
    return { ok: false, code: 'user-not-found', message: 'Usuario no encontrado.' };
  }
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
      message: 'Tu rol no permite finalizar la jornada por geolocalización.',
    };
  }
  const companyId = user.companyId || null;
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
  if (!workplace.isActive) {
    return {
      ok: false,
      code: 'workplace-inactive',
      message: 'El lugar de trabajo está desactivado. Contactá al administrador.',
    };
  }
  if (workplace.companyId !== companyId) {
    return {
      ok: false,
      code: 'workplace-mismatch',
      message: 'El lugar de trabajo no pertenece a tu empresa.',
    };
  }
  const wpLat = workplace.latitud;
  const wpLng = workplace.longitud;
  const radio = workplace.radio;
  if (typeof wpLat !== 'number' || typeof wpLng !== 'number') {
    return {
      ok: false,
      code: 'no-coords',
      message: 'El lugar de trabajo no tiene coordenadas configuradas.',
    };
  }
  if (typeof radio !== 'number' || radio <= 0) {
    return {
      ok: false,
      code: 'no-radius',
      message: 'El lugar de trabajo no tiene un radio de geocerca configurado.',
    };
  }
  if (
    typeof latitud !== 'number' ||
    typeof longitud !== 'number' ||
    latitud < -90 || latitud > 90 ||
    longitud < -180 || longitud > 180
  ) {
    return {
      ok: false,
      code: 'invalid-coords',
      message: 'Coordenadas de ubicación inválidas.',
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
    return {
      ok: false,
      code: 'attendance-not-owner',
      message: 'Este registro no te pertenece.',
    };
  }
  if (attendance.status === 'completed') {
    return {
      ok: false,
      code: 'attendance-completed',
      message: 'Esta asistencia ya fue finalizada.',
    };
  }
  const distance = haversineDistance(latitud, longitud, wpLat, wpLng);
  if (distance > radio) {
    return {
      ok: false,
      code: 'out-of-geofence',
      message: `Estás a ${formatDistance(distance)} del lugar de trabajo (${workplace.nombre}). Debes estar dentro del radio de ${Math.round(radio)} m para finalizar tu jornada.`,
    };
  }
  return {
    ok: true,
    code: 'ok',
    distance,
    companyId,
    workplaceId,
  };
}

/**
 * Duración de la jornada en minutos completos desde el check-in, calculada en
 * el servidor (los clientes nunca la envían). Sin check-in parseable devuelve 0
 * (degradación no bloqueante, igual que el comportamiento previo del cliente).
 */
function computeCheckOutDuration(checkInTime, now) {
  const millis = toMillis(checkInTime);
  if (millis == null) return 0;
  return Math.max(0, Math.floor((now.getTime() - millis) / 60000));
}

module.exports = {
  computeCheckOutDuration,
  decideRegisterCheckOut,
};
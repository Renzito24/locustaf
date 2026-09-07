/**
 * Lógica pura de geocerca server-side y alta de asistencia del empleado
 * (AUI-02, Fase 2).
 *
 * La validación de distancia (Haversine) y la construcción del documento de
 * asistencia se centralizan aquí para poder unit-testearlas sin depender del
 * emulador de Cloud Functions. La callable `checkInGeo` (index.js) orquesta
 * las lecturas de Firestore y la transacción de alta usando estas funciones.
 */

const EARTH_RADIUS_METERS = 6371000;
const LOCK_STALE_MILLIS = 24 * 60 * 60 * 1000;

/**
 * Offset fijo de la zona horaria de la app (América/Argentina/Buenos_Aires,
 * UTC-3 sin horario de verano desde 2015). `date`/`isLate` deben derivarse en
 * la zona del lugar de trabajo; Cloud Functions corre en UTC, por lo que se
 * aplica un offset explícito (determinista, sin depender de TZ del entorno).
 */
const APP_TZ_OFFSET_MINUTES = -3 * 60;

function toRadians(degrees) {
  return (degrees * Math.PI) / 180;
}

/** Distancia Haversine en metros entre dos puntos geográficos. */
function haversineDistance(lat1, lon1, lat2, lon2) {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

/** True si la distancia entre el usuario y el workplace no supera el radio. */
function isWithinRadius(userLat, userLng, workplaceLat, workplaceLng, radiusMeters) {
  return haversineDistance(userLat, userLng, workplaceLat, workplaceLng) <= radiusMeters;
}

/** Fecha local (zona de la empresa) "YYYY-MM-DD" a partir de un instante UTC. */
function localDateString(now) {
  const local = new Date(now.getTime() + APP_TZ_OFFSET_MINUTES * 60000);
  const y = local.getUTCFullYear();
  const m = String(local.getUTCMonth() + 1).padStart(2, '0');
  const d = String(local.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Mismo criterio que AttendanceCalculator.isLate: tarde si el ingreso supera
 * la hora de inicio esperada + tolerancia. `horaInicio` es hora local de la
 * empresa; se convierte al instante UTC equivalente usando APP_TZ_OFFSET.
 * Devuelve null sin horaInicio.
 */
function isLateFor(now, horaInicio, toleranceMinutes) {
  if (!horaInicio) return null;
  const [hour, minute] = horaInicio.split(':').map(Number);
  const local = new Date(now.getTime() + APP_TZ_OFFSET_MINUTES * 60000);
  const shiftStartUtc = Date.UTC(
    local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate(), hour, minute || 0,
  ) - APP_TZ_OFFSET_MINUTES * 60000;
  const allowed = shiftStartUtc + (toleranceMinutes || 0) * 60000;
  return now.getTime() > allowed;
}

function formatDistance(meters) {
  return meters >= 1000
    ? `${(meters / 1000).toFixed(1)} km`
    : `${Math.round(meters)} m`;
}

/** Convierte lockedAt/checkInTime (Timestamp | Date | ISO-8601) a millis. */
function toMillis(value) {
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'string') {
    const t = Date.parse(value);
    return Number.isNaN(t) ? null : t;
  }
  return null;
}

/**
 * Un lock es huérfano si lleva más de LOCK_STALE_MILLIS sin check-out.
 * Si el timestamp es ilegible y el lock no referencia asistencia, se trata
 * como reclamable para no bloquear al empleado indefinidamente.
 */
function isStaleLock(lock, now) {
  const millis = toMillis(lock.lockedAt) ?? toMillis(lock.checkInTime);
  if (millis == null) return true;
  return now.getTime() - millis > LOCK_STALE_MILLIS;
}

/**
 * Decisión pura de check-in con geocerca.
 * Devuelve `{ ok: false, code, message }` ante cualquier rechazo o
 * `{ ok: true, code, companyId, workplaceId, date, isLate, distance }`.
 *
 * El lugar de trabajo se toma del documento del usuario (nunca del cliente),
 * para impedir elegir otro workplace con radio mayor.
 */
function decideRegisterCheckIn({ user, workplace, now, latitud, longitud }) {
  if (!user) {
    return { ok: false, code: 'user-not-found', message: 'Usuario no encontrado.' };
  }
  if (!user.isActive || user.isDeleted) {
    return {
      ok: false,
      code: 'account-inactive',
      message: 'La cuenta no está activa. No se puede registrar asistencia.',
    };
  }
  if (user.rol !== 'employee') {
    return {
      ok: false,
      code: 'role-not-allowed',
      message: 'Tu rol no permite registrar asistencia por geolocalización.',
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
  const distance = haversineDistance(latitud, longitud, wpLat, wpLng);
  if (distance > radio) {
    return {
      ok: false,
      code: 'out-of-geofence',
      message: `Estás a ${formatDistance(distance)} del lugar de trabajo (${workplace.nombre}). Debes estar dentro del radio de ${Math.round(radio)} m para registrar asistencia.`,
    };
  }
  return {
    ok: true,
    code: 'ok',
    distance,
    companyId,
    workplaceId,
    date: localDateString(now),
    isLate: isLateFor(now, workplace.horaInicio || null, workplace.toleranciaMinutos || 15),
  };
}

module.exports = {
  earthRadiusMeters: EARTH_RADIUS_METERS,
  lockStaleMillis: LOCK_STALE_MILLIS,
  appTimezoneOffsetMinutes: APP_TZ_OFFSET_MINUTES,
  haversineDistance,
  isWithinRadius,
  localDateString,
  isLateFor,
  formatDistance,
  toMillis,
  isStaleLock,
  decideRegisterCheckIn,
};
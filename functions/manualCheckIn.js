/**
 * Lógica pura del check-in manual realizado por un admin (AUI-06) vía callable.
 *
 * El cliente hoy escribe `attendances` + lock directo del admin; esto se mueve
 * a la callable `manualCheckIn` para que date/isLate/checkInTime sean
 * server-side y la entrada quede protegida por reglas (crear asistencia de un
 * empleado queda bloqueado para el flujo directo del cliente).
 *
 * Server-side:
 *  - Solo admin o superadmin. El destino debe ser employee del MISMO companyId
 *    (el superadmin, rol de plataforma, puede operar sobre cualquier empresa).
 *  - El destino no puede ser el propio operador.
 *  - checkInTime propuesto opcional: si se envía y difiere más de ±15 minutos
 *    del reloj del servidor, se rechaza. Sin propuesta: reloj del servidor.
 *  - date e isLate se derivan en UTC-3 (zone de la empresa), igual que
 *    checkInGeo. El workplace sale del documento del usuario, nunca del cliente.
 */

const { localDateString, isLateFor } = require('./geoCheckIn');

const CHECK_IN_TOLERANCE_MINUTES = 15;

/**
 * Decisión pura de check-in manual.
 * `caller` es el operador autenticado (admin/superadmin), `target` el empleado.
 * Devuelve `{ ok: false, code, message }` ante cualquier rechazo o
 * `{ ok: true, code, companyId, workplaceId, checkInTime, date, isLate }`.
 */
function decideManualCheckIn({ caller, target, workplace, now, proposedCheckInTime }) {
  if (!caller) {
    return { ok: false, code: 'user-not-found', message: 'Usuario no encontrado.' };
  }
  if (caller.rol !== 'admin' && caller.rol !== 'superadmin') {
    return {
      ok: false,
      code: 'role-not-allowed',
      message: 'Tu rol no permite registrar asistencias manuales.',
    };
  }
  if (!target) {
    return { ok: false, code: 'user-not-found', message: 'Usuario no encontrado.' };
  }
  if (!target.companyId) {
    return {
      ok: false,
      code: 'target-no-company',
      message: 'El empleado no tiene una empresa asignada.',
    };
  }
  const targetCompanyId = target.companyId;
  if (!target.isActive || target.isDeleted) {
    return {
      ok: false,
      code: 'account-inactive',
      message: 'La cuenta no está activa. No se puede registrar asistencia.',
    };
  }
  if (target.rol !== 'employee') {
    return {
      ok: false,
      code: 'target-role-not-allowed',
      message: 'El empleado debe tener rol empleado para registrar asistencia.',
    };
  }
  if (caller.rol !== 'superadmin' && caller.companyId !== targetCompanyId) {
    return {
      ok: false,
      code: 'cross-company',
      message: 'El empleado no pertenece a tu empresa.',
    };
  }
  const workplaceId = target.lugarDeTrabajoId || null;
  if (!workplaceId) {
    return {
      ok: false,
      code: 'no-workplace',
      message: 'El empleado no tiene un lugar de trabajo asignado.',
    };
  }
  if (!workplace || workplace.id !== workplaceId) {
    return {
      ok: false,
      code: 'workplace-not-found',
      message: 'El lugar de trabajo asignado no existe.',
    };
  }
  if (workplace.companyId !== targetCompanyId) {
    return {
      ok: false,
      code: 'workplace-mismatch',
      message: 'El lugar de trabajo no pertenece a la empresa del empleado.',
    };
  }
  if (workplace.isActive === false) {
    return {
      ok: false,
      code: 'workplace-inactive',
      message: 'El lugar de trabajo está desactivado.',
    };
  }

  const checkInTime = proposedCheckInTime || now;
  const diffMillis = Math.abs(checkInTime.getTime() - now.getTime());
  const toleranceMillis = CHECK_IN_TOLERANCE_MINUTES * 60000;
  if (diffMillis > toleranceMillis) {
    return {
      ok: false,
      code: 'tolerance-exceeded',
      message: `La hora de ingreso no puede diferir más de ${CHECK_IN_TOLERANCE_MINUTES} minutos de la hora actual.`,
    };
  }

  return {
    ok: true,
    code: 'ok',
    companyId: targetCompanyId,
    workplaceId,
    checkInTime,
    date: localDateString(checkInTime),
    isLate: isLateFor(
      checkInTime,
      workplace.horaInicio || null,
      workplace.toleranciaMinutos || CHECK_IN_TOLERANCE_MINUTES,
    ),
  };
}

module.exports = {
  CHECK_IN_TOLERANCE_MINUTES,
  decideManualCheckIn,
};
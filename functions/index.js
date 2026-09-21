/**
 * Cloud Functions de LOCUSTAF.
 *
 * Sincroniza el estado de la cuenta de Firebase Auth con el documento del
 * usuario en Firestore:
 *  - Si un usuario se marca como eliminado (isDeleted) o desactivado
 *    (isActive = false), se deshabilita su cuenta de Auth para que no pueda
 *    iniciar sesión.
 *  - Si se reactiva (isActive = true y isDeleted = false), se habilita.
 *
 * Esto cierra la brecha de seguridad donde un empleado "eliminado" conservaba
 * su sesión/credencial activa en el servidor.
 */
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { computeUserAuthUpdate } = require('./userStatus');
const { decideRegisterCheckIn, isStaleLock } = require('./geoCheckIn');
const { decideRegisterCheckOut, computeCheckOutDuration } = require('./geoCheckOut');
const { decideCompanyInitialBilling } = require('./companyBilling');
const {
  decideRateLimitAllow,
  appendRateLimitTimestamp,
  DEFAULT_MAX_ATTEMPTS,
  DEFAULT_WINDOW_MILLIS,
} = require('./rateLimit');

initializeApp();

const _db = getFirestore();

/**
 * Rate limit server-side por UID (FASE 1).
 *
 * - Clave de escala: `uid` (de `request.auth`, no falsificable). NUNCA por IP:
 *   los portales/NAT corporativos y las IPs compartidas generan falsos
 *   positivos que bloquean usuarios legítimos. Nunca por companyId: un abusador
 *   dentro de una empresa agotaría el cupo de sus compañeros (efecto espejo
 *   del problema IP). Nunca por datos del cliente (latitud/longitud/reloj).
 * - Reloj: `Date.now()` server-side. El cliente no aporta reloj ni ventana.
 * - Transaccional (ventana deslizante): se decide y se persiste el intento en
 *   la MISMA transacción Firestore, de modo que dos llamadas concurrentes del
 *   mismo uid se serializan (la segunda re-lee tras el commit del primero y
 *   cuenta el intento agregado). Resistente a ráfagas/abuso por volumen.
 * - Producción: max 6 intentos en 10 minutos por UID por operación
 *   (definidos en rateLimit.js: DEFAULT_MAX_ATTEMPTS / DEFAULT_WINDOW_MILLIS).
 * - Reintentos legítimos: un GPS impreciso dispara ~2-3 reintentos; 6 en 10
 *   min da holgura sin bloquear. Si el usuario llegara al tope, la ventana
 *   deslizante lo rehabilita automáticamente cuando caducan sus intentos
 *   (anti-lockout: nunca bloqueo permanente; se respeta `retryAfterMillis`).
 * - NO reemplaza el lock anti doble jornada (`_attendance_locks/{uid}`): esto
 *   es una capa anti-volumen adicional por operación, anterior a la lógica
 *   pesada (no se tocan los locks, no se cambia su semántica).
 */
async function enforceServerRateLimit({ op, uid }) {
  const nowMillis = Date.now();
  const ref = _db.doc(`_rate_limits/${op}/${uid}`);
  let decision;
  await _db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const timestamps = snap.exists ? (snap.data()?.timestamps ?? []) : [];
    const result = decideRateLimitAllow({
      timestamps,
      nowMillis,
      maxAttempts: DEFAULT_MAX_ATTEMPTS,
      windowMillis: DEFAULT_WINDOW_MILLIS,
    });
    if (!result.allow) {
      decision = { ok: false, retryAfterMillis: result.retryAfterMillis };
      return;
    }
    const next = appendRateLimitTimestamp({
      timestamps,
      nowMillis,
      windowMillis: DEFAULT_WINDOW_MILLIS,
    });
    tx.set(ref, { timestamps: next, updatedAt: new Date() }, { merge: true });
    decision = { ok: true, retryAfterMillis: 0 };
  });
  if (!decision.ok) {
    throw new HttpsError(
      'resource-exhausted',
      'Demasiados intentos en poco tiempo. Esperá unos minutos y volvé a intentar.',
      { retryAfterMillis: decision.retryAfterMillis }
    );
  }
}

exports.syncUserAuthStatus = onDocumentUpdated(
  {
    document: 'users/{userId}',
    region: 'southamerica-east1',
  },
  async (event) => {
    const userId = event.params.userId;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) {
      console.log(`Sin datos para el usuario ${userId}`);
      return;
    }

    // Lógica pura extraída a userStatus.js para poder unit-testearla.
    const decision = computeUserAuthUpdate(before, after);
    if (!decision.update) {
      return;
    }

    try {
      await getAuth().updateUser(userId, { disabled: decision.disabled });
      console.log(
        `Usuario ${userId} ${decision.disabled ? 'deshabilitado' : 'habilitado'} en Auth.`
      );
    } catch (err) {
      console.error(`Error al actualizar Auth del usuario ${userId}:`, err);
    }
  }
);

/**
 * Trigger de alta de empresas (TASK-014): al crearse una empresa sin datos de
 * facturación (p.ej. durante el onboarding), se le registra la prueba gratuita
 * de 90 días: `plan: mensual` y `paidUntil = created + 90 días` (server-side).
 * Si el documento ya trae campos de suscripción (alta del superadmin con pago
 * inicial) se respetan y no se aplica la prueba.
 */
exports.registerCompanyTrial = onDocumentCreated(
  {
    document: 'companies/{companyId}',
    region: 'southamerica-east1',
  },
  async (event) => {
    const data = event.data?.data();
    const decision = decideCompanyInitialBilling(data, new Date());
    if (!decision.shouldApplyTrial) {
      return;
    }
    await event.data.ref.update({
      plan: decision.plan,
      paidUntil: decision.paidUntil,
      updatedAt: new Date().toISOString(),
    });
  }
);

/**
 * Callable de check-in con geocerca (AUI-02, Fase 2).
 *
 * Recepción: `{ latitud, longitud }` (coordenadas GPS del dispositivo).
 * El lugar de trabajo se resuelve desde el documento del usuario autenticado,
 * nunca desde el cliente. Valida en el servidor que la distancia Haversine al
 * workplace no supere el radio configurado y, si pasa, crea la asistencia y su
 * lock en una transacción (una sola jornada activa por empleado).
 */
exports.checkInGeo = onCall(
  {
    region: 'southamerica-east1',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Debés iniciar sesión para registrar asistencia.');
    }
    const uid = request.auth.uid;
    const latitud = request.data?.latitud;
    const longitud = request.data?.longitud;

    await enforceServerRateLimit({ op: 'checkInGeo', uid });

    const userSnap = await _db.doc(`users/${uid}`).get();
    const user = userSnap.exists ? { ...userSnap.data(), id: uid } : null;

    let workplace = null;
    const workplaceId = user && user.lugarDeTrabajoId;
    if (user && workplaceId) {
      const wpSnap = await _db.doc(`workplaces/${workplaceId}`).get();
      if (wpSnap.exists) {
        workplace = { ...wpSnap.data(), id: workplaceId };
      }
    }

    const now = new Date();
    const decision = decideRegisterCheckIn({ user, workplace, now, latitud, longitud });
    if (!decision.ok) {
      throw new HttpsError('failed-precondition', decision.message);
    }

    const lockRef = _db.doc(`_attendance_locks/${uid}`);
    let attendanceId;
    try {
      await _db.runTransaction(async (tx) => {
        const lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          const lock = lockSnap.data();
          let reclaimable = isStaleLock(lock, now);
          if (!reclaimable && lock.attendanceId) {
            const attSnap = await tx.get(_db.doc(`attendances/${lock.attendanceId}`));
            reclaimable = !attSnap.exists || attSnap.data().status === 'completed';
          }
          if (!reclaimable) {
            throw new HttpsError(
              'failed-precondition',
              'Ya tenés una asistencia activa. Finalizala antes de registrar una nueva.'
            );
          }
        }

        const attRef = _db.collection('attendances').doc();
        attendanceId = attRef.id;
        tx.set(attRef, {
          id: attRef.id,
          userId: uid,
          companyId: decision.companyId,
          workplaceId: decision.workplaceId,
          date: decision.date,
          checkInTime: Timestamp.fromDate(now),
          status: 'active',
          isLate: decision.isLate,
          checkInLatitud: latitud,
          checkInLongitud: longitud,
        });
        tx.set(lockRef, {
          attendanceId: attRef.id,
          checkInTime: now.toISOString(),
          lockedAt: Timestamp.fromDate(now),
          status: 'active',
        });
      });
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      console.error('Error al registrar check-in geolocalizado:', err);
      throw new HttpsError('internal', 'Error al registrar la asistencia.');
    }

    return {
      attendanceId,
      checkInTime: now.toISOString(),
      isLate: decision.isLate,
      distanceMeters: Math.round(decision.distance),
    };
  }
);

/**
 * Callable de check-out con geocerca (AUI-02, Fase 3).
 *
 * Recepción: `{ latitud, longitud, attendanceId }`. Resuelve el lugar de
 * trabajo desde el documento del usuario (nunca del cliente), valida en el
 * servidor la distancia Haversine y cierra la jornada en una transacción:
 * - checkOutTime y durationMinutes se derivan del servidor (el cliente no los
 *   puede fijar).
 * - La asistencia debe existir, pertenecer al usuario y estar 'active'.
 * - Elimina el lock `_attendance_locks/{uid}` del empleado.
 */
exports.checkOutGeo = onCall(
  {
    region: 'southamerica-east1',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Debés iniciar sesión para finalizar la jornada.');
    }
    const uid = request.auth.uid;
    const latitud = request.data?.latitud;
    const longitud = request.data?.longitud;
    const attendanceId = request.data?.attendanceId;
    await enforceServerRateLimit({ op: 'checkOutGeo', uid });
    if (typeof attendanceId !== 'string' || attendanceId.length === 0) {
      throw new HttpsError('failed-precondition', 'Falta el identificador de la asistencia.');
    }

    const userSnap = await _db.doc(`users/${uid}`).get();
    const user = userSnap.exists ? { ...userSnap.data(), id: uid } : null;

    let workplace = null;
    const workplaceId = user && user.lugarDeTrabajoId;
    if (user && workplaceId) {
      const wpSnap = await _db.doc(`workplaces/${workplaceId}`).get();
      if (wpSnap.exists) {
        workplace = { ...wpSnap.data(), id: workplaceId };
      }
    }

    const attSnap = await _db.doc(`attendances/${attendanceId}`).get();
    const attendance = attSnap.exists ? { ...attSnap.data(), id: attendanceId } : null;

    const now = new Date();
    const decision = decideRegisterCheckOut({ user, workplace, attendance, now, latitud, longitud });
    if (!decision.ok) {
      throw new HttpsError('failed-precondition', decision.message);
    }

    const durationMinutes = computeCheckOutDuration(attendance.checkInTime, now);
    const lockRef = _db.doc(`_attendance_locks/${uid}`);
    try {
      await _db.runTransaction(async (tx) => {
        const attRef = _db.doc(`attendances/${attendanceId}`);
        const inTx = await tx.get(attRef);
        if (!inTx.exists) {
          throw new HttpsError('failed-precondition', 'Registro de asistencia no encontrado.');
        }
        const inTxData = inTx.data();
        if (inTxData.userId !== uid) {
          throw new HttpsError('failed-precondition', 'Este registro no te pertenece.');
        }
        if (inTxData.status === 'completed') {
          throw new HttpsError('failed-precondition', 'Esta asistencia ya fue finalizada.');
        }
        const lockSnap = await tx.get(lockRef);
        if (!lockSnap.exists) {
          throw new HttpsError(
            'failed-precondition',
            'No se encontró un bloqueo de sesión activo. Es posible que la sesión ya haya sido finalizada.'
          );
        }
        tx.update(attRef, {
          checkOutTime: Timestamp.fromDate(now),
          durationMinutes,
          status: 'completed',
          checkOutLatitud: latitud,
          checkOutLongitud: longitud,
        });
        tx.delete(lockRef);
      });
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      console.error('Error al registrar check-out geolocalizado:', err);
      throw new HttpsError('internal', 'Error al finalizar la jornada.');
    }

    return {
      attendanceId,
      checkOutTime: now.toISOString(),
      durationMinutes,
    };
  }
);

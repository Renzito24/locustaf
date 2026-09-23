// FASE 1 - B) INTEGRACION + C) CONCURRENCIA del rate limiting server-side.
//
// Se ejecuta SOLO con emulador activo (`npm run test:integration` -> levanta
// Firerepo emulado y setea FIRESTORE_EMULATOR_HOST). En un `npm test` comun
// (sin emulador) las pruebas quedan marcadas como skipped mediante el MIsmo
// guard `hasEmulator` que usan los tres .integration.test.js existentes:
//
//   const hasEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
//
// Se prueba la callable REAL `checkInGeo` (index.js), que internamente invoca
// `enforceServerRateLimit` (definida UNA sola vez, DEF_COUNT=1, verificada por
// node) con la ruta REAL `_rate_limits/{op}/attempts/{uid}`. NO se asume la ruta: se
// verifica el documento exacto que la implementacion real escribe.
//
// CLAVE DE DISENO (verificada sobre la implementacion real en index.js):
//   - `enforceServerRateLimit` se ejecuta ANTES de leer el user/workplace, de
//     modo que incluso con un UID inexistente quedan registrados los timestamps
//     del rate limit (ian cuando la operacion luego falle por usuario no
//     hallado). Eso permite probar el rate limit sin depender del seed geo.
//   - La transaccion Firestore hace append SOLO cuando allow=true; un rechazo
//     NO agrega timestamp (el doc no crece por el rechazo).
//   - El reloj es `Date.now()` del servidor; el cliente no puede elegir
//     maxAttempts/windowMillis/nowMillis (el request solo lee latitud/longitud).
//   - L mite real: 6 intentos en 10 min por UID y por operacion (checkInGeo).
//
// ASCII PURO a proposito: esta fase fue victimired de corrupciones de
// escritura del entorno; se evita todo caracter no-ASCII.
const test = require('node:test');
const assert = require('node:assert/strict');

const hasEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

let index = null;
let db = null;
let Timestamp = null;
if (hasEmulator) {
  index = require('../index');
  const firestoreAdmin = require('firebase-admin/firestore');
  db = firestoreAdmin.getFirestore();
  Timestamp = firestoreAdmin.Timestamp;
}

const OP_CHECK_IN = 'checkInGeo';
const MAX_REAL = 6;

function rateLimitDoc(op, uid) {
  if (!hasEmulator) return null;
  return db.doc(`_rate_limits/${op}/attempts/${uid}`);
}

async function readRateTimestamps(op, uid) {
  const snap = await rateLimitDoc(op, uid).get();
  if (!snap.exists) return [];
  const data = snap.data() || {};
  return Array.isArray(data.timestamps) ? data.timestamps : [];
}

function callCheckIn(uid, extraData = {}) {
  return index.checkInGeo.run({
    auth: { uid },
    data: { latitud: -34.6037, longitud: -58.3816, ...extraData },
  });
}

async function countAllowsAndRejects(promises) {
  const settled = await Promise.allSettled(promises);
  let allows = 0;
  let rejects = 0;
  for (const r of settled) {
    if (r.status === 'fulfilled') allows++;
    else if (r.reason && r.reason.code === 'resource-exhausted') rejects++;
  }
  return { allows, rejects, other: settled.length - allows - rejects };
}

async function cleanUp(uids) {
  if (!hasEmulator) return;
  const seen = new Set();
  for (const uid of uids) {
    const key = OP_CHECK_IN + '/' + uid;
    if (seen.has(key)) continue;
    seen.add(key);
    const doc = await rateLimitDoc(OP_CHECK_IN, uid).get();
    if (doc.exists) await rateLimitDoc(OP_CHECK_IN, uid).delete();
  }
}

const USED_UIDS = [];

test.after(async () => {
  await cleanUp(USED_UIDS);
});

test('B1. Un UID nuevo puede intentar y se registra el timestamp real', { skip: !hasEmulator }, async () => {
  const uid = 'b1-rate-new';
  USED_UIDS.push(uid);
  const before = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(before.length, 0);
  // El UID no existe como user: la callable falla por usuario inexistente PERO
  // enforceServerRateLimit ya se ejecuto (antes del fetch de user) y registro
  // el timestamp en Firestore.
  await callCheckIn(uid).then(
    () => assert.fail('se esperaba error por usuario inexistente'),
    () => {}
  );
  const after = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(after.length, 1);
  assert.equal(typeof after[0], 'number');
  // El timestamp es reloj del servidor (Date.now en el momento de la llamada),
  // no algo elegido por el cliente.
  assert.ok(Math.abs(after[0] - Date.now()) < 60_000);
});

test('B2. El tope real del servidor es 6 intentos en 10 min', { skip: !hasEmulator }, async () => {
  const uid = 'b2-rate-limit';
  USED_UIDS.push(uid);
  for (let i = 0; i < MAX_REAL; i++) {
    await callCheckIn(uid).then(() => {}, () => {});
  }
  const ts = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(ts.length, MAX_REAL);
  // Intento que excede el tope -> HttpsError resource-exhausted.
  const err = await callCheckIn(uid).then(
    () => null,
    (e) => e
  );
  assert.ok(err, 'se esperaba un error de rate limit');
  assert.equal(err.code, 'resource-exhausted');
});

test('B3. Al superar el limite, el rechazo NO aumenta el estado', { skip: !hasEmulator }, async () => {
  const uid = 'b3-rate-reject';
  USED_UIDS.push(uid);
  for (let i = 0; i < MAX_REAL; i++) {
    await callCheckIn(uid).then(() => {}, () => {});
  }
  const before = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(before.length, MAX_REAL);
  for (let i = 0; i < 3; i++) {
    await callCheckIn(uid).then(
      () => {},
      () => {}
    );
  }
  const after = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(after.length, MAX_REAL, 'los rechazos no deben agregar timestamps');
});

test('B4. Dos UIDs distintos son limites totalmente independientes', { skip: !hasEmulator }, async () => {
  const uidA = 'b4-rate-a';
  const uidB = 'b4-rate-b';
  USED_UIDS.push(uidA, uidB);
  for (let i = 0; i < MAX_REAL; i++) {
    await callCheckIn(uidA).then(() => {}, () => {});
  }
  // A bloqueado
  const errA = await callCheckIn(uidA).then(
    () => null,
    (e) => e
  );
  assert.equal(errA && errA.code, 'resource-exhausted');
  // B intacto: puede intentar y lo registra (independencia total)
  const tsB0 = await readRateTimestamps(OP_CHECK_IN, uidB);
  assert.equal(tsB0.length, 0);
  await callCheckIn(uidB).then(() => {}, () => {});
  const tsB1 = await readRateTimestamps(OP_CHECK_IN, uidB);
  assert.equal(tsB1.length, 1);
});

test('B5. El cliente NO puede elegir maxAttempts ni windowMillis', { skip: !hasEmulator }, async () => {
  const uid = 'b5-rate-tamper';
  USED_UIDS.push(uid);
  // El cliente intenta subir el tope y la ventana via el payload. La callable
  // real solo lee latitud/longitud: maxAttempts/windowMillis se IGNORAN.
  const extra = { maxAttempts: 9999, windowMillis: 1 };
  for (let i = 0; i < MAX_REAL; i++) {
    await callCheckIn(uid, extra).then(() => {}, () => {});
  }
  // Sigue siendo MAX_REAL (6), no 9999.
  const ts = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(ts.length, MAX_REAL);
  const err = await callCheckIn(uid, extra).then(
    () => null,
    (e) => e
  );
  assert.equal(err && err.code, 'resource-exhausted', 'el tope real debe ser 6 aunque el cliente envie 9999');
});

test('B6. El reloj es del servidor, el nowMillis del cliente se IGNORA', { skip: !hasEmulator }, async () => {
  const uid = 'b6-rate-clock';
  USED_UIDS.push(uid);
  // Cliente envia un nowMillis muy futuro para intentar "expiar" la ventana.
  const extra = { nowMillis: Date.now() + 10 * 60 * 1000 };
  for (let i = 0; i < MAX_REAL; i++) {
    await callCheckIn(uid, extra).then(() => {}, () => {});
  }
  // Aun registrados (no expiados): el servidor usa su propio Date.now().
  const ts = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(ts.length, MAX_REAL);
  const err = await callCheckIn(uid, extra).then(
    () => null,
    (e) => e
  );
  assert.equal(err && err.code, 'resource-exhausted', 'el reloj del cliente no debe exprimir la ventana');
});

test('B7. El documento real que usa enforceServerRateLimit se persiste en _rate_limits/{op}/attempts/{uid}', { skip: !hasEmulator }, async () => {
  const uid = 'b7-rate-path';
  USED_UIDS.push(uid);
  await callCheckIn(uid).then(() => {}, () => {});
  // MARCA_9f3a1c
  const snap = await rateLimitDoc(OP_CHECK_IN, uid).get();
  assert.equal(snap.exists, true, 'el doc real _rate_limits/checkInGeo/attempts/' + uid + ' debe existir');
  const data = snap.data() || {};
  assert.ok(Array.isArray(data.timestamps), 'el doc real debe tener timestamps array');
  assert.equal(data.timestamps.length, 1);
  assert.ok(data.updatedAt, 'el doc real debe persistir updatedAt');
});

test('C1. Concurrencia real: 12 llamadas simultaneas mismo UID -> max 6 permitidas', { skip: !hasEmulator }, async () => {
  const uid = 'c1-rate-concurrent';
  USED_UIDS.push(uid);
  const calls = Array.from({ length: 12 }, () => callCheckIn(uid));
  const { allows, rejects } = await countAllowsAndRejects(calls);
  // La transaccion Firestore serializa los appends: nunca mas de MAX_REAL.
  assert.ok(allows <= MAX_REAL, 'no deben permitirse mas de ' + MAX_REAL + ' (' + allows + ')');
  assert.ok(rejects > 0, 'debe haber rechazos por resource-exhausted');
  const ts = await readRateTimestamps(OP_CHECK_IN, uid);
  assert.equal(ts.length, MAX_REAL, 'el estado final debe tener exactamente ' + MAX_REAL + ' timestamps');
});

// C2 (doble jornada por concurrencia sobre checkInGeo) queda FUERA DE ALCANCE
// de este archivo de rate limit: la proteccion anti doble jornada ya esta
// cubierta por el lock `_attendance_locks` y sus props son probadas en
// checkInGeo.integration.test.js. No se inventa esa cobertura aqui.

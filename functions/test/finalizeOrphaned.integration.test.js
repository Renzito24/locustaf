// Orquestación `finalizeOrphaned` (index.js) contra el emulador de Firestore.
//
// Cubre la transacción completa de cierre de jornada huérfana: validaciones
// de ownership/empresa/estado, puerta de hora fin de jornada (server-side),
// derivación acotada de duración y borrado del lock con Admin SDK.
//
// Se ejecutan solo con emulador activo (`npm run test:integration`).
const test = require('node:test');
const assert = require('node:assert');

const hasEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

let index = null;
let db = null;
let Timestamp = null;
let getFirestore = null;
if (hasEmulator) {
  index = require('../index');
  const firestoreAdmin = require('firebase-admin/firestore');
  getFirestore = firestoreAdmin.getFirestore;
  db = getFirestore();
  Timestamp = firestoreAdmin.Timestamp;
}

// La app deriva fecha/horarios en UTC-3 fijo (appTimezoneOffsetMinutes).
const APP_OFFSET_MINUTES = -180;

function utc3Parts(d) {
  const shifted = new Date(d.getTime() + APP_OFFSET_MINUTES * 60000);
  return {
    y: shifted.getUTCFullYear(),
    mo: shifted.getUTCMonth(),
    d: shifted.getUTCDate(),
    h: shifted.getUTCHours(),
    mi: shifted.getUTCMinutes(),
  };
}

function pad2(n) {
  return String(n).padStart(2, '0');
}

function hhmm(d) {
  const p = utc3Parts(d);
  return `${pad2(p.h)}:${pad2(p.mi)}`;
}

// horaFin = hora local del instante dado (el server ancla el fin al MISMO dia
// local del checkIn, por lo que shiftEnd == el instante aportado, sin
// dependencias de wraps de medianoche).
function workplaceDoc(horaFin) {
  return {
    nombre: 'Sucursal Central',
    companyId: 'emp-1',
    isActive: true,
    horaInicio: '09:00',
    horaFin,
    toleranciaMinutos: 15,
  };
}

async function seedUser(uid, overrides = {}) {
  await db.doc(`users/${uid}`).set({
    companyId: 'emp-1',
    rol: 'employee',
    lugarDeTrabajoId: 'wp-1',
    isActive: true,
    isDeleted: false,
    ...overrides,
  });
}

async function seedWorkplace(wpId = 'wp-1', overrides = {}) {
  await db.doc(`workplaces/${wpId}`).set({
    companyId: 'emp-1',
    isActive: true,
    horaInicio: '09:00',
    horaFin: '12:00',
    toleranciaMinutos: 15,
    ...overrides,
  });
}

async function seedAttendance(attId, overrides = {}) {
  await db.doc(`attendances/${attId}`).set({
    id: attId,
    userId: 'u1',
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    date: '2026-09-07',
    checkInTime: Timestamp.fromDate(new Date('2026-09-07T10:00:00Z')),
    status: 'active',
    ...overrides,
  });
}

function callFinalize(uid, attendanceId) {
  return index.finalizeOrphaned.run({ auth: { uid }, data: { attendanceId } });
}

async function assertHttpsError(promise, code, messagePart) {
  const err = await promise.then(
    () => null,
    (e) => e
  );
  assert.ok(err, 'se esperaba un error de HttpsError');
  assert.strictEqual(err.code, code);
  if (messagePart) {
    assert.ok(err.message.includes(messagePart), `mensaje inesperado: "${err.message}"`);
  }
  return err;
}

test.after(async () => {
  if (!hasEmulator) return;
  const collections = ['users', 'workplaces', 'attendances', '_attendance_locks'];
  for (const name of collections) {
    const docs = await db.collection(name).listDocuments();
    await Promise.all(docs.map((d) => d.delete()));
  }
});

test('finalizeOrphaned: rechaza sin autenticación', { skip: !hasEmulator }, async () => {
  await assertHttpsError(
    index.finalizeOrphaned.run({ data: { attendanceId: 'att-1' } }),
    'unauthenticated',
    'Debés iniciar sesión'
  );
});

test('finalizeOrphaned: rechaza sin attendanceId', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  await seedWorkplace('wp-1');
  await assertHttpsError(
    index.finalizeOrphaned.run({ auth: { uid: 'u1' }, data: {} }),
    'failed-precondition',
    'Falta el identificador'
  );
});

test('finalizeOrphaned: happy path cierra con duración acotada y limpia el lock', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  const now0 = new Date();
  // checkIn al minuto exacto (sin segundos): horaFin == checkIn -> tope exacto de 15 min
  const checkIn = new Date(Math.floor((now0.getTime() - 4 * 3600 * 1000) / 60000) * 60000);
  await seedWorkplace('wp-1', { horaFin: hhmm(checkIn) }); // fin == checkIn -> ya superado
  const attId = 'att-happy';
  await seedAttendance(attId, { checkInTime: Timestamp.fromDate(checkIn) });

  const result = await callFinalize('u1', attId);
  assert.strictEqual(result.attendanceId, attId);
  assert.ok(!Number.isNaN(Date.parse(result.checkOutTime)), 'checkOutTime ISO válido');
  // cap = fin(==checkIn) + 15 min de tolerancia -> 15 minutos exactos.
  assert.strictEqual(result.durationMinutes, 15);

  const att = (await db.doc(`attendances/${attId}`).get()).data();
  assert.strictEqual(att.status, 'completed');
  assert.strictEqual(att.isOrphaned, true);
  assert.strictEqual(att.durationMinutes, 15);
  assert.ok(att.checkOutTime.toDate() <= new Date(), 'checkOutTime es del servidor (pasado)');

  const lockSnap = await db.doc('_attendance_locks/u1').get();
  assert.strictEqual(lockSnap.exists, false, 'el lock queda eliminado');
});

test('finalizeOrphaned: rechaza asistencia de otro usuario', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  await seedWorkplace('wp-1');
  await seedAttendance('att-owner', { userId: 'otro' });
  await assertHttpsError(
    callFinalize('u1', 'att-owner'),
    'failed-precondition',
    'no te pertenece'
  );
});

test('finalizeOrphaned: rechaza asistencia ya completada', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  await seedWorkplace('wp-1');
  await seedAttendance('att-done', { status: 'completed' });
  await assertHttpsError(
    callFinalize('u1', 'att-done'),
    'failed-precondition',
    'ya fue finalizada'
  );
});

test('finalizeOrphaned: rechaza asistencia de otra empresa (cross-company)', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  await seedWorkplace('wp-1');
  await seedAttendance('att-cross', { companyId: 'emp-2' });
  await assertHttpsError(
    callFinalize('u1', 'att-cross'),
    'failed-precondition',
    'no te pertenece'
  );
});

test('finalizeOrphaned: rechaza cuando el horario de fin aún no fue superado', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  const now0 = new Date();
  const futureCheckIn = new Date(now0.getTime() + 3600 * 1000); // 1h al futuro
  await seedWorkplace('wp-1', { horaFin: hhmm(futureCheckIn) }); // fin == checkIn futuro
  await seedAttendance('att-future', { checkInTime: Timestamp.fromDate(futureCheckIn) });
  await assertHttpsError(
    callFinalize('u1', 'att-future'),
    'failed-precondition',
    'aún no finalizó'
  );
});

test('finalizeOrphaned: borra el lock existente del empleado (Admin SDK)', { skip: !hasEmulator }, async () => {
  await seedUser('u1');
  const now0 = new Date();
  const checkIn = new Date(Math.floor((now0.getTime() - 4 * 3600 * 1000) / 60000) * 60000);
  await seedWorkplace('wp-1', { horaFin: hhmm(checkIn) });
  const attId = 'att-lock';
  await seedAttendance(attId, { checkInTime: Timestamp.fromDate(checkIn) });
  await db.doc('_attendance_locks/u1').set({
    attendanceId: attId,
    checkInTime: checkIn.toISOString(),
    lockedAt: Timestamp.now(),
    status: 'active',
  });

  const result = await callFinalize('u1', attId);
  assert.strictEqual(result.attendanceId, attId);

  const lockSnap = await db.doc('_attendance_locks/u1').get();
  assert.strictEqual(lockSnap.exists, false, 'el lock debe eliminarse en la transacción');
});
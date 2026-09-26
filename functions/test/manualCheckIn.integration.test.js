// Orquestación `manualCheckIn` (index.js) contra el emulador de Firestore.
//
// Cubre el alta manual del admin (AUI-06) server-side: validaciones de rol,
// tenant, tolerancia de reloj, lock anti-duplicado y alta de asistencia + lock
// en una transacción con Admin SDK.
//
// Se ejecutan solo con emulador activo (`npm run test:integration`).
const test = require('node:test');
const assert = require('node:assert');

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

async function seedWorkplace(wpId = 'wp-1', overrides = {}) {
  await db.doc(`workplaces/${wpId}`).set({
    nombre: 'Sucursal Central',
    companyId: 'emp-1',
    isActive: true,
    horaInicio: '09:00',
    toleranciaMinutos: 15,
    ...overrides,
  });
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

function callManual(uid, data) {
  return index.manualCheckIn.run({ auth: { uid }, data });
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

async function allAttendancesOf(uid) {
  const snaps = await db.collection('attendances').where('userId', '==', uid).get();
  return snaps.docs.map((d) => d.data());
}

test.after(async () => {
  if (!hasEmulator) return;
  const collections = ['users', 'workplaces', 'attendances', '_attendance_locks'];
  for (const name of collections) {
    const docs = await db.collection(name).listDocuments();
    await Promise.all(docs.map((d) => d.delete()));
  }
});

test('manualCheckIn: rechaza sin autenticación', { skip: !hasEmulator }, async () => {
  await assertHttpsError(
    index.manualCheckIn.run({ data: { targetUserId: 'u-t' } }),
    'unauthenticated',
    'Debés iniciar sesión'
  );
});

test('manualCheckIn: rechaza sin targetUserId', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin0', { rol: 'admin' });
  await assertHttpsError(
    index.manualCheckIn.run({ auth: { uid: 'u-admin0' }, data: {} }),
    'failed-precondition',
    'Falta el identificador'
  );
});

test('manualCheckIn: happy path admin crea asistencia y lock del empleado', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin1', { rol: 'admin' });
  await seedUser('u-t1');
  await seedWorkplace('wp-1');

  const result = await callManual('u-admin1', { targetUserId: 'u-t1' });
  assert.ok(result.attendanceId, 'debe devolver attendanceId');
  assert.match(result.date, /^\d{4}-\d{2}-\d{2}$/);
  assert.ok(!Number.isNaN(Date.parse(result.checkInTime)), 'checkInTime ISO válido');
  assert.ok(result.isLate === true || result.isLate === false || result.isLate === null);

  const attendances = await allAttendancesOf('u-t1');
  assert.strictEqual(attendances.length, 1);
  const att = attendances[0];
  assert.strictEqual(att.id, result.attendanceId);
  assert.strictEqual(att.userId, 'u-t1');
  assert.strictEqual(att.companyId, 'emp-1');
  assert.strictEqual(att.workplaceId, 'wp-1');
  assert.strictEqual(att.status, 'active');
  assert.ok(att.checkInTime.toDate() instanceof Date);

  const lockSnap = await db.doc('_attendance_locks/u-t1').get();
  assert.ok(lockSnap.exists, 'debe existir el lock del empleado');
  assert.strictEqual(lockSnap.data().attendanceId, result.attendanceId);
});

test('manualCheckIn: un empleado no puede usarla', { skip: !hasEmulator }, async () => {
  await seedUser('u-employee');
  await seedWorkplace('wp-1');
  await assertHttpsError(
    callManual('u-employee', { targetUserId: 'u-employee' }),
    'failed-precondition',
    'Tu rol no permite'
  );
});

test('manualCheckIn: admin no puede registrar un empleado de otra empresa', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin2', { rol: 'admin' });
  await seedUser('u-cross', { companyId: 'emp-2', lugarDeTrabajoId: 'wp-2' });
  await seedWorkplace('wp-2', { companyId: 'emp-2' });
  await assertHttpsError(
    callManual('u-admin2', { targetUserId: 'u-cross' }),
    'failed-precondition',
    'no pertenece a tu empresa'
  );
});

test('manualCheckIn: fuera de tolerancia (+/- 15 min) es rechazado', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin3', { rol: 'admin' });
  await seedUser('u-t2');
  await seedWorkplace('wp-1');

  const tooOld = new Date(Date.now() - 30 * 60 * 1000).toISOString();
  const err = await assertHttpsError(
    callManual('u-admin3', { targetUserId: 'u-t2', checkInTime: tooOld }),
    'failed-precondition',
    'no puede diferir'
  );
  assert.ok(err.message.includes('15 minutos'), err.message);

  const attendances = await allAttendancesOf('u-t2');
  assert.strictEqual(attendances.length, 0, 'no se crea asistencia');
});

test('manualCheckIn: lock activo vigente bloquea y no duplica', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin4', { rol: 'admin' });
  await seedUser('u-t3');
  await seedWorkplace('wp-1');

  await db.collection('attendances').doc('att-x').set({
    id: 'att-x',
    userId: 'u-t3',
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    date: '2026-09-07',
    checkInTime: Timestamp.now(),
    status: 'active',
  });
  await db.doc('_attendance_locks/u-t3').set({
    attendanceId: 'att-x',
    checkInTime: new Date().toISOString(),
    lockedAt: Timestamp.now(),
    status: 'active',
  });

  await assertHttpsError(
    callManual('u-admin4', { targetUserId: 'u-t3' }),
    'failed-precondition',
    'Ya tenés una asistencia activa'
  );
  const attendances = await allAttendancesOf('u-t3');
  assert.strictEqual(attendances.length, 1, 'no se duplica la jornada activa');
});

test('manualCheckIn: destino eliminado es rechazado', { skip: !hasEmulator }, async () => {
  await seedUser('u-admin5', { rol: 'admin' });
  await seedUser('u-del', { isDeleted: true });
  await seedWorkplace('wp-1');
  await assertHttpsError(
    callManual('u-admin5', { targetUserId: 'u-del' }),
    'failed-precondition',
    'no está activa'
  );
});
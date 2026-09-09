// Orquestación `checkOutGeo` (index.js) contra el emulador de Firestore.
//
// Cubre la transacción de cierre de jornada: resolución de usuario/workplace,
// validación de geocerca, control de lock, derivación server-side de
// checkOutTime/durationMinutes y mapeo de errores a HttpsError.
//
// Se ejecuta solo con emulador activo (`npm run test:integration`).
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

const OBELISCO = { lat: -34.6037, lng: -58.3816 };

async function seedUser(uid, overrides = {}) {
  await db.doc(`users/${uid}`).set({
    companyId: 'emp-1',
    rol: 'employee',
    lugarDeTrabajoId: 'wp-1',
    isActive: true,
    isDeleted: false,
    ...overrides,
  });
  await db.doc('workplaces/wp-1').set({
    nombre: 'Sucursal Central',
    companyId: 'emp-1',
    isActive: true,
    latitud: OBELISCO.lat,
    longitud: OBELISCO.lng,
    radio: 100,
    horaInicio: '08:00',
    toleranciaMinutos: 15,
  });
}

async function seedAttendance(uid, attId, overrides = {}) {
  await db.doc(`attendances/${attId}`).set({
    id: attId,
    userId: uid,
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    date: '2026-09-07',
    status: 'active',
    isLate: false,
    checkInTime: new Date('2026-09-07T10:00:00Z'),
    ...overrides,
  });
}

async function seedLock(uid, attId) {
  await db.doc(`_attendance_locks/${uid}`).set({
    attendanceId: attId,
    checkInTime: new Date().toISOString(),
    lockedAt: Timestamp.now(),
    status: 'active',
  });
}

function callCheckOut(uid, data) {
  return index.checkOutGeo.run({ auth: { uid }, data });
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

test('checkOutGeo: rechaza sin autenticación', { skip: !hasEmulator }, async () => {
  await assertHttpsError(
    index.checkOutGeo.run({
      data: { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-x' },
    }),
    'unauthenticated',
    'Debés iniciar sesión'
  );
});

test('checkOutGeo: rechaza rol distinto a employee', { skip: !hasEmulator }, async () => {
  await seedUser('u2', { rol: 'supervisor' });
  await assertHttpsError(
    callCheckOut('u2', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-1' }),
    'failed-precondition',
    'Tu rol no permite finalizar'
  );
});

test('checkOutGeo: rechaza fuera de la geocerca', { skip: !hasEmulator }, async () => {
  await seedUser('u3');
  await seedAttendance('u3', 'att-1');
  await seedLock('u3', 'att-1');
  await assertHttpsError(
    callCheckOut('u3', { latitud: OBELISCO.lat + 0.02, longitud: OBELISCO.lng, attendanceId: 'att-1' }),
    'failed-precondition',
    'finalizar tu jornada'
  );
});

test('checkOutGeo: rechaza falta de attendanceId', { skip: !hasEmulator }, async () => {
  await seedUser('u4');
  await assertHttpsError(
    callCheckOut('u4', { latitud: OBELISCO.lat, longitud: OBELISCO.lng }),
    'failed-precondition',
    'identificador de la asistencia'
  );
  await assertHttpsError(
    callCheckOut('u4', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: '' }),
    'failed-precondition',
    'identificador de la asistencia'
  );
});

test('checkOutGeo: rechaza asistencia inexistente', { skip: !hasEmulator }, async () => {
  await seedUser('u5');
  await assertHttpsError(
    callCheckOut('u5', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'nope' }),
    'failed-precondition',
    'no encontrado'
  );
});

test('checkOutGeo: rechaza asistencia de otro usuario', { skip: !hasEmulator }, async () => {
  await seedUser('u6');
  await seedAttendance('owner', 'att-6');
  await assertHttpsError(
    callCheckOut('u6', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-6' }),
    'failed-precondition',
    'no te pertenece'
  );
});

test('checkOutGeo: rechaza asistencia ya finalizada', { skip: !hasEmulator }, async () => {
  await seedUser('u7');
  await seedAttendance('u7', 'att-7', { status: 'completed' });
  await assertHttpsError(
    callCheckOut('u7', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-7' }),
    'failed-precondition',
    'ya fue finalizada'
  );
});

test('checkOutGeo: rechaza si no existe un lock activo', { skip: !hasEmulator }, async () => {
  await seedUser('u8');
  await seedAttendance('u8', 'att-8');
  await assertHttpsError(
    callCheckOut('u8', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-8' }),
    'failed-precondition',
    'bloqueo de sesión activo'
  );
});

test('checkOutGeo: cierra la jornada, deriva duración y limpia el lock', { skip: !hasEmulator }, async () => {
  await seedUser('u9');
  const checkIn = new Date(Date.now() - 4 * 60 * 60 * 1000);
  await seedAttendance('u9', 'att-9', { checkInTime: checkIn });
  await seedLock('u9', 'att-9');

  const result = await callCheckOut('u9', {
    latitud: OBELISCO.lat,
    longitud: OBELISCO.lng,
    attendanceId: 'att-9',
  });

  assert.strictEqual(result.attendanceId, 'att-9');
  assert.strictEqual(typeof result.checkOutTime, 'string');
  assert.ok(!Number.isNaN(Date.parse(result.checkOutTime)), 'checkOutTime ISO');
  assert.ok(result.durationMinutes >= 4 * 60, `duración inesperada: ${result.durationMinutes}`);

  const snapshot = await db.doc('attendances/att-9').get();
  const att = snapshot.data();
  assert.strictEqual(att.status, 'completed');
  assert.strictEqual(att.durationMinutes, result.durationMinutes);
  assert.strictEqual(att.checkOutLatitud, OBELISCO.lat);
  assert.strictEqual(att.checkOutLongitud, OBELISCO.lng);
  assert.ok(att.checkOutTime, 'debe tener checkOutTime');

  const lock = await db.doc('_attendance_locks/u9').get();
  assert.strictEqual(lock.exists, false, 'el lock debe eliminarse en la transacción');
});
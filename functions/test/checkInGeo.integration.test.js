// Orquestación `checkInGeo` (index.js) contra el emulador de Firestore.
//
// Estos tests cubren la transacción completa del callable: resolución del
// usuario/workplace, validación de geocerca, lock anti-duplicado, alta de la
// asistencia y mapeo de errores a HttpsError.
//
// Se ejecutan solo con emulador activo (`npm run test:integration`). En un
// `npm test` común (sin FIRESTORE_EMULATOR_HOST) quedan marcados como skipped.
const test = require('node:test');
const assert = require('node:assert');

const hasEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

let index = null;
let db = null;
let Timestamp = null;
if (hasEmulator) {
  // index.js inicializa Firebase: solo se carga cuando hay emulador.
  index = require('../index');
  const firestoreAdmin = require('firebase-admin/firestore');
  db = firestoreAdmin.getFirestore();
  Timestamp = firestoreAdmin.Timestamp;
}

const OBELISCO = { lat: -34.6037, lng: -58.3816 };

function workplaceDoc() {
  return {
    nombre: 'Sucursal Central',
    companyId: 'emp-1',
    isActive: true,
    latitud: OBELISCO.lat,
    longitud: OBELISCO.lng,
    radio: 100,
    horaInicio: '08:00',
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
  await db.doc('workplaces/wp-1').set(workplaceDoc());
}

function callCheckIn(uid, data) {
  return index.checkInGeo.run({ auth: { uid }, data });
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

test('checkInGeo: rechaza sin autenticación', { skip: !hasEmulator }, async () => {
  const err = await assertHttpsError(
    index.checkInGeo.run({ data: { latitud: OBELISCO.lat, longitud: OBELISCO.lng } }),
    'unauthenticated',
    'Debés iniciar sesión'
  );
  assert.ok(err.message.length > 0);
});

test('checkInGeo: rechaza rol distinto a employee', { skip: !hasEmulator }, async () => {
  await seedUser('u2', { rol: 'supervisor' });
  await assertHttpsError(
    callCheckIn('u2', { latitud: OBELISCO.lat, longitud: OBELISCO.lng }),
    'failed-precondition',
    'Tu rol no permite'
  );
});

test('checkInGeo: rechaza fuera de la geocerca', { skip: !hasEmulator }, async () => {
  await seedUser('u3');
  await assertHttpsError(
    callCheckIn('u3', { latitud: OBELISCO.lat + 0.02, longitud: OBELISCO.lng }),
    'failed-precondition',
    'Estás a'
  );
});

test('checkInGeo: crea la asistencia y el lock en una transacción', { skip: !hasEmulator }, async () => {
  await seedUser('u4');
  const result = await callCheckIn('u4', {
    latitud: OBELISCO.lat,
    longitud: OBELISCO.lng,
  });

  assert.ok(result.attendanceId, 'debe devolver attendanceId');
  assert.strictEqual(typeof result.checkInTime, 'string');
  assert.ok(!Number.isNaN(Date.parse(result.checkInTime)), 'checkInTime debe ser ISO válido');
  assert.strictEqual(typeof result.isLate, 'boolean');
  assert.strictEqual(typeof result.distanceMeters, 'number');

  const attendances = await allAttendancesOf('u4');
  assert.strictEqual(attendances.length, 1);
  const att = attendances[0];
  assert.strictEqual(att.id, result.attendanceId);
  assert.strictEqual(att.userId, 'u4');
  assert.strictEqual(att.companyId, 'emp-1');
  assert.strictEqual(att.workplaceId, 'wp-1');
  assert.strictEqual(att.status, 'active');
  assert.match(att.date, /^\d{4}-\d{2}-\d{2}$/);
  assert.strictEqual(att.checkInLatitud, OBELISCO.lat);
  assert.strictEqual(att.checkInLongitud, OBELISCO.lng);

  const lockSnap = await db.doc('_attendance_locks/u4').get();
  assert.ok(lockSnap.exists, 'debe existir el lock');
  assert.strictEqual(lockSnap.data().attendanceId, result.attendanceId);
});

test('checkInGeo: bloquea un nuevo check-in con lock activo vigente', { skip: !hasEmulator }, async () => {
  await seedUser('u5');
  await callCheckIn('u5', { latitud: OBELISCO.lat, longitud: OBELISCO.lng });
  await assertHttpsError(
    callCheckIn('u5', { latitud: OBELISCO.lat, longitud: OBELISCO.lng }),
    'failed-precondition',
    'Ya tenés una asistencia activa'
  );
  // No se duplica la asistencia activa.
  const attendances = await allAttendancesOf('u5');
  assert.strictEqual(attendances.length, 1);
});

test('checkInGeo: reclama el lock si la asistencia ya fue completada (lock fresco)', { skip: !hasEmulator }, async () => {
  await seedUser('u6');
  const attRef = db.collection('attendances').doc();
  await attRef.set({
    id: attRef.id,
    userId: 'u6',
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    date: '2026-09-07',
    checkInTime: Timestamp.fromDate(new Date('2026-09-07T10:00:00Z')),
    checkOutTime: Timestamp.fromDate(new Date('2026-09-07T17:00:00Z')),
    status: 'completed',
  });
  await db.doc('_attendance_locks/u6').set({
    attendanceId: attRef.id,
    checkInTime: new Date().toISOString(),
    lockedAt: Timestamp.now(),
    status: 'active',
  });

  const result = await callCheckIn('u6', { latitud: OBELISCO.lat, longitud: OBELISCO.lng });
  assert.ok(result.attendanceId);
  const attendances = await allAttendancesOf('u6');
  assert.strictEqual(attendances.length, 2);
  const lock = (await db.doc('_attendance_locks/u6').get()).data();
  assert.strictEqual(lock.attendanceId, result.attendanceId);
});

test('checkInGeo: reclama un lock corrupto (timestamp ilegible)', { skip: !hasEmulator }, async () => {
  await seedUser('u7');
  await db.doc('_attendance_locks/u7').set({
    attendanceId: 'no-existe',
    lockedAt: 'no-valido',
  });

  const result = await callCheckIn('u7', { latitud: OBELISCO.lat, longitud: OBELISCO.lng });
  assert.ok(result.attendanceId);
  const lock = (await db.doc('_attendance_locks/u7').get()).data();
  assert.strictEqual(lock.attendanceId, result.attendanceId);
});
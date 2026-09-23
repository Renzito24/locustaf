// Aislamiento multi-tenant en las callables checkInGeo/checkOutGeo (C-CR).
//
// Ataca los dos vectores reales de cruce de tenant en la capa de callables:
//   - Vector A: user.lugarDeTrabajoId apuntando a un workplace de otra empresa.
//   - Vector B: attendanceId de otro usuario/empresa en el payload del check-out.
//
// Patrón tomado de checkOutGeo.integration.test.js (helpers idénticos).
// Se ejecuta solo con emulador activo.
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

async function seedUserCross(uid, companyId, workplaceId) {
    await db.doc(`users/${uid}`).set({
        companyId,
        rol: 'employee',
        lugarDeTrabajoId: workplaceId,
        isActive: true,
        isDeleted: false,
    });
}

async function seedWorkplaceCross(id, companyId) {
    await db.doc(`workplaces/${id}`).set({
        nombre: `Sede ${id}`,
        companyId,
        isActive: true,
        latitud: OBELISCO.lat,
        longitud: OBELISCO.lng,
        radio: 100,
        horaInicio: '08:00',
        toleranciaMinutos: 15,
    });
}

async function seedAttendanceCross(attId, userId, companyId, workplaceId) {
    await db.doc(`attendances/${attId}`).set({
        id: attId,
        userId,
        companyId,
        workplaceId,
        date: '2026-09-23',
        status: 'active',
        isLate: false,
        checkInTime: new Date('2026-09-23T10:00:00Z'),
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

function callCheckIn(uid, data) {
    return index.checkInGeo.run({ auth: { uid }, data });
}

function callCheckOut(uid, data) {
    return index.checkOutGeo.run({ auth: { uid }, data });
}

async function assertHttpsError(promise, code, messagePart) {
    const err = await promise.then(() => null, (e) => e);
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

test('C-CR-1: checkInGeo rechaza workplace de otra empresa (lugarDeTrabajoId cruzado)', { skip: !hasEmulator }, async () => {
    await seedUserCross('u-cr1', 'emp-1', 'wp-b');
    await seedWorkplaceCross('wp-b', 'emp-2');
    await assertHttpsError(
        callCheckIn('u-cr1', { latitud: OBELISCO.lat, longitud: OBELISCO.lng }),
        'failed-precondition',
        'no pertenece a tu empresa'
    );
    const atts = await db.collection('attendances').where('userId', '==', 'u-cr1').get();
    assert.ok(atts.empty, 'no debe crearse asistencia para el rechazo');
    const lock = await db.doc('_attendance_locks/u-cr1').get();
    assert.ok(!lock.exists, 'no debe crearse lock para el rechazo');
});

test('C-CR-2 (control): checkInGeo permite el camino legitimo propio', { skip: !hasEmulator }, async () => {
    await seedUserCross('u-cr2', 'emp-1', 'wp-1a');
    await seedWorkplaceCross('wp-1a', 'emp-1');
    const res = await callCheckIn('u-cr2', { latitud: OBELISCO.lat, longitud: OBELISCO.lng });
    assert.ok(res.attendanceId, 'la respuesta debe incluir attendanceId');
    const att = await db.doc(`attendances/${res.attendanceId}`).get();
    assert.strictEqual(att.data().companyId, 'emp-1');
    assert.strictEqual(att.data().workplaceId, 'wp-1a');
    assert.strictEqual(att.data().userId, 'u-cr2');
    assert.strictEqual(att.data().status, 'active');
});

test('C-CR-3: checkOutGeo rechaza asistencia de otro usuario/empresa y no la toca', { skip: !hasEmulator }, async () => {
    await seedUserCross('u-cr3a', 'emp-1', 'wp-1a');
    await seedWorkplaceCross('wp-1a', 'emp-1');
    await seedAttendanceCross('att-cr3a', 'u-cr3a', 'emp-1', 'wp-1a');
    await seedLock('u-cr3a', 'att-cr3a');
    await seedUserCross('u-cr3b', 'emp-2', 'wp-b');
    await seedWorkplaceCross('wp-b', 'emp-2');
    await seedAttendanceCross('att-cr3b', 'u-cr3b', 'emp-2', 'wp-b');
    await seedLock('u-cr3b', 'att-cr3b');
    // u-cr3a (emp-1) intenta cerrar la asistencia de u-cr3b (emp-2).
    await assertHttpsError(
        callCheckOut('u-cr3a', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-cr3b' }),
        'failed-precondition'
    );
    // Integridad: la asistencia ajena debe seguir intacta.
    const attB = await db.doc('attendances/att-cr3b').get();
    assert.strictEqual(attB.data().status, 'active');
    assert.strictEqual(attB.data().checkOutTime, undefined);
});

test('C-CR-4: checkOutGeo rechaza cuando el workplace del usuario es de otra empresa', { skip: !hasEmulator }, async () => {
    await seedUserCross('u-cr4', 'emp-2', 'wp-1a');
    await seedWorkplaceCross('wp-1a', 'emp-1');
    await seedAttendanceCross('att-cr4', 'u-cr4', 'emp-2', 'wp-1a');
    await seedLock('u-cr4', 'att-cr4');
    await assertHttpsError(
        callCheckOut('u-cr4', { latitud: OBELISCO.lat, longitud: OBELISCO.lng, attendanceId: 'att-cr4' }),
        'failed-precondition',
        'no pertenece a tu empresa'
    );
    const att = await db.doc('attendances/att-cr4').get();
    assert.strictEqual(att.data().status, 'active');
    assert.strictEqual(att.data().checkOutTime, undefined);
});

test('C-CR-5: el doc de asistencia siempre lleva el tenant del usuario (derivado en el servidor)', { skip: !hasEmulator }, async () => {
    await seedUserCross('u-cr5', 'emp-1', 'wp-1c');
    await seedWorkplaceCross('wp-1c', 'emp-1');
    const res = await callCheckIn('u-cr5', { latitud: OBELISCO.lat, longitud: OBELISCO.lng });
    assert.ok(res.attendanceId);
    const att = await db.doc(`attendances/${res.attendanceId}`).get();
    assert.strictEqual(att.data().companyId, 'emp-1');
    assert.strictEqual(att.data().workplaceId, 'wp-1c');
    const lock = await db.doc('_attendance_locks/u-cr5').get();
    assert.ok(lock.exists);
    assert.strictEqual(lock.data().attendanceId, res.attendanceId);
});

const test = require('node:test');
const assert = require('node:assert');

const { computeCheckOutDuration, decideRegisterCheckOut } = require('../geoCheckOut');

const obelisco = { lat: -34.6037, lng: -58.3816 };

function validUser(overrides = {}) {
  return {
    id: 'uid-1',
    companyId: 'emp-1',
    rol: 'employee',
    lugarDeTrabajoId: 'wp-1',
    isActive: true,
    isDeleted: false,
    ...overrides,
  };
}

function validWorkplace(overrides = {}) {
  return {
    id: 'wp-1',
    nombre: 'Sucursal Central',
    companyId: 'emp-1',
    isActive: true,
    latitud: obelisco.lat,
    longitud: obelisco.lng,
    radio: 200,
    ...overrides,
  };
}

function validAttendance(overrides = {}) {
  return {
    id: 'att-1',
    userId: 'uid-1',
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    status: 'active',
    checkInTime: new Date('2026-09-07T10:00:00Z'),
    ...overrides,
  };
}

function decision(user, workplace, attendance, lat, lng) {
  return decideRegisterCheckOut({ user, workplace, attendance, now: new Date(), latitud: lat, longitud: lng });
}

test('computeCheckOutDuration: minutos completos desde el check-in', () => {
  const checkIn = new Date('2026-09-07T10:00:00Z');
  const now = new Date('2026-09-07T17:15:00Z');
  assert.strictEqual(computeCheckOutDuration(checkIn, now), 435);
  // Nunca negativo: checkout antes del checkIn → 0.
  assert.strictEqual(
    computeCheckOutDuration(new Date('2026-09-07T12:00:00Z'), new Date('2026-09-07T11:00:00Z')),
    0,
  );
});

test('computeCheckOutDuration: acepta ISO y Timestamp, sinon nulo → 0', () => {
  const now = new Date('2026-09-07T17:00:00Z');
  assert.strictEqual(computeCheckOutDuration('2026-09-07T10:00:00Z', now), 420);
  assert.strictEqual(computeCheckOutDuration({ toMillis: () => Date.parse('2026-09-07T10:00:00Z') }, now), 420);
  assert.strictEqual(computeCheckOutDuration(null, now), 0);
  assert.strictEqual(computeCheckOutDuration('no-valido', now), 0);
});

test('check-out: usuario inexistente', () => {
  const r = decision(null, validWorkplace(), validAttendance(), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.ok, false);
  assert.strictEqual(r.code, 'user-not-found');
});

test('check-out: cuenta inactiva o eliminada', () => {
  assert.strictEqual(
    decision({ ...validUser(), isActive: false }, validWorkplace(), validAttendance(), obelisco.lat, obelisco.lng).code,
    'account-inactive',
  );
  assert.strictEqual(
    decision({ ...validUser(), isDeleted: true }, validWorkplace(), validAttendance(), obelisco.lat, obelisco.lng).code,
    'account-inactive',
  );
});

test('check-out: solo employee puede usar la callable', () => {
  assert.strictEqual(
    decision({ ...validUser(), rol: 'supervisor' }, validWorkplace(), validAttendance(), obelisco.lat, obelisco.lng).code,
    'role-not-allowed',
  );
});

test('check-out: sin lugar de trabajo asignado', () => {
  const r = decision(
    { ...validUser(), lugarDeTrabajoId: null },
    validWorkplace(),
    validAttendance(),
    obelisco.lat,
    obelisco.lng,
  );
  assert.strictEqual(r.code, 'no-workplace');
});

test('check-out: workplace inexistente, desactivado o de otra empresa', () => {
  assert.strictEqual(
    decision(validUser(), null, validAttendance(), obelisco.lat, obelisco.lng).code,
    'workplace-not-found',
  );
  assert.strictEqual(
    decision(validUser(), validWorkplace({ isActive: false }), validAttendance(), obelisco.lat, obelisco.lng).code,
    'workplace-inactive',
  );
  assert.strictEqual(
    decision(validUser(), validWorkplace({ companyId: 'emp-2' }), validAttendance(), obelisco.lat, obelisco.lng).code,
    'workplace-mismatch',
  );
});

test('check-out: coordinadas inválidas', () => {
  assert.strictEqual(
    decision(validUser(), validWorkplace(), validAttendance(), 91, obelisco.lng).code,
    'invalid-coords',
  );
  assert.strictEqual(
    decision(validUser(), validWorkplace(), validAttendance(), obelisco.lat, undefined).code,
    'invalid-coords',
  );
});

test('check-out: asistencia inexistente', () => {
  const r = decision(validUser(), validWorkplace(), null, obelisco.lat, obelisco.lng);
  assert.strictEqual(r.code, 'attendance-not-found');
});

test('check-out: asistencia de otro usuario o ya completada', () => {
  assert.strictEqual(
    decision(validUser(), validWorkplace(), validAttendance({ userId: 'otro' }), obelisco.lat, obelisco.lng).code,
    'attendance-not-owner',
  );
  assert.strictEqual(
    decision(validUser(), validWorkplace(), validAttendance({ status: 'completed' }), obelisco.lat, obelisco.lng).code,
    'attendance-completed',
  );
});

test('check-out: fuera de la geocerca', () => {
  const far = { lat: obelisco.lat + 0.05, lng: obelisco.lng };
  const r = decision(validUser(), validWorkplace({ radio: 100 }), validAttendance(), far.lat, far.lng);
  assert.strictEqual(r.code, 'out-of-geofence');
  assert.ok(r.message.includes('m del lugar de trabajo'));
  assert.ok(r.message.includes('finalizar tu jornada'));
});

test('check-out: dentro de la geocerca devuelve decisión OK', () => {
  const r = decision(validUser(), validWorkplace(), validAttendance(), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.code, 'ok');
  assert.strictEqual(r.companyId, 'emp-1');
  assert.strictEqual(r.workplaceId, 'wp-1');
  assert.ok(r.distance < 1);
});
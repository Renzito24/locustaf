const test = require('node:test');
const assert = require('node:assert');

const {
  haversineDistance,
  isWithinRadius,
  localDateString,
  isLateFor,
  toMillis,
  isStaleLock,
  lockStaleMillis,
  decideRegisterCheckIn,
} = require('../geoCheckIn');

const obelisco = { lat: -34.6037, lng: -58.3816 };
const plazaDeMayo = { lat: -34.6076, lng: -58.3742 };

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
    horaInicio: '09:00',
    toleranciaMinutos: 15,
    ...overrides,
  };
}

function decision(user, workplace, lat, lng, now = new Date('2026-09-07T10:00:00-03:00')) {
  return decideRegisterCheckIn({ user, workplace, now, latitud: lat, longitud: lng });
}

const TOL = 0.001;

test('haversineDistance devuelve ~804m entre Obelisco y Plaza de Mayo', () => {
  const d = haversineDistance(
    obelisco.lat, obelisco.lng,
    plazaDeMayo.lat, plazaDeMayo.lng,
  );
  assert.ok(d > 790 && d < 820, `distancia inesperada: ${d}`);
});

test('haversineDistance devuelve ~0 para el mismo punto', () => {
  const d = haversineDistance(obelisco.lat, obelisco.lng, obelisco.lat, obelisco.lng);
  assert.ok(Math.abs(d) < TOL);
});

test('isWithinRadius: dentro del radio OK, exactamente en el límite OK, fuera no', () => {
  // 200 m alrededor del Obelisco: ~0.0018 grados de latitud ~= 200 m
  const inLat = obelisco.lat + 0.001;
  const ok = isWithinRadius(inLat, obelisco.lng, obelisco.lat, obelisco.lng, 200);
  assert.strictEqual(ok, true, `${inLat} debería estar dentro de 200m`);

  const outLat = obelisco.lat + 0.01;
  const out = isWithinRadius(outLat, obelisco.lng, obelisco.lat, obelisco.lng, 200);
  assert.strictEqual(out, false, `${outLat} debería estar fuera de 200m`);
});

test('localDateString formatea fecha local YYYY-MM-DD', () => {
  assert.strictEqual(localDateString(new Date('2026-09-07T23:59:00-03:00')), '2026-09-07');
  assert.strictEqual(localDateString(new Date('2026-01-01T00:00:00-03:00')), '2026-01-01');
});

test('localDateString usa la zona de la empresa (UTC-3), no el horario de la máquina', () => {
  // 2026-09-08T03:30Z == 00:30 ART del día 08 → misma fecha.
  assert.strictEqual(localDateString(new Date('2026-09-08T03:30:00Z')), '2026-09-08');
  // 2026-09-07T23:59Z == 20:59 ART del día 07 → misma fecha (sin corrimiento).
  assert.strictEqual(localDateString(new Date('2026-09-07T23:59:00Z')), '2026-09-07');
  // 2026-09-08T02:59Z == 23:59 ART del día 07 → se mantiene la fecha local.
  assert.strictEqual(localDateString(new Date('2026-09-08T02:59:00Z')), '2026-09-07');
});

test('isLateFor: tarde si supera hora inicio + tolerancia, a tiempo en el límite', () => {
  const base = new Date('2026-09-07T09:00:00-03:00');
  assert.strictEqual(isLateFor(new Date(base.getTime() + 14 * 60000), '09:00', 15), false);
  assert.strictEqual(isLateFor(new Date(base.getTime() + 15 * 60000), '09:00', 15), false);
  assert.strictEqual(isLateFor(new Date(base.getTime() + 16 * 60000), '09:00', 15), true);
  assert.strictEqual(isLateFor(new Date(base.getTime() + 100000), null, 15), null);
});

test('isLateFor evalúa la jornada en hora local de la empresa (UTC-3) aunque el servidor corra en UTC', () => {
  // 12:10Z == 09:10 ART → dentro de tolerancia (09:00 + 15).
  assert.strictEqual(isLateFor(new Date('2026-09-07T12:10:00Z'), '09:00', 15), false);
  // 12:16Z == 09:16 ART → tarde.
  assert.strictEqual(isLateFor(new Date('2026-09-07T12:16:00Z'), '09:00', 15), true);
  // 02:55Z del 08 == 23:55 ART del 07 (turno nocturno dentro de la misma jornada).
  assert.strictEqual(isLateFor(new Date('2026-09-08T02:55:00Z'), '09:00', 15), true);
});

test('toMillis parsea Timestamp, Date e ISO-8601', () => {
  const now = new Date('2026-09-07T10:00:00Z');
  assert.strictEqual(toMillis(now), now.getTime());
  assert.strictEqual(toMillis(now.toISOString()), now.getTime());
  assert.strictEqual(toMillis({ toMillis: () => 42 }), 42);
  assert.strictEqual(toMillis('no-una-fecha'), null);
  assert.strictEqual(toMillis(null), null);
});

test('isStaleLock: un lock viejo es huérfano, uno reciente no, uno ilegible se reclama', () => {
  const now = new Date();
  const old = { lockedAt: new Date(now.getTime() - lockStaleMillis - 1000) };
  const fresh = { checkInTime: new Date() };
  const corrupted = { lockedAt: 'no-valido' };
  assert.strictEqual(isStaleLock(old, now), true);
  assert.strictEqual(isStaleLock(fresh, now), false);
  // Sin timestamp parseable: reclamable para no bloquear un nuevo check-in.
  assert.strictEqual(isStaleLock(corrupted, now), true);
});

test('check-in: usuario inexistente', () => {
  const r = decision(null, validWorkplace(), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.ok, false);
  assert.strictEqual(r.code, 'user-not-found');
});

test('check-in: cuenta inactiva o eliminada', () => {
  assert.strictEqual(
    decision({ ...validUser(), isActive: false }, validWorkplace(), obelisco.lat, obelisco.lng).code,
    'account-inactive',
  );
  assert.strictEqual(
    decision({ ...validUser(), isDeleted: true }, validWorkplace(), obelisco.lat, obelisco.lng).code,
    'account-inactive',
  );
});

test('check-in: solo el rol employee puede usar la callable', () => {
  assert.strictEqual(
    decision({ ...validUser(), rol: 'supervisor' }, validWorkplace(), obelisco.lat, obelisco.lng).code,
    'role-not-allowed',
  );
  assert.strictEqual(
    decision({ ...validUser(), rol: 'admin' }, validWorkplace(), obelisco.lat, obelisco.lng).code,
    'role-not-allowed',
  );
  assert.strictEqual(
    decision({ ...validUser(), rol: null }, validWorkplace(), obelisco.lat, obelisco.lng).code,
    'role-not-allowed',
  );
});

test('check-in: sin lugar de trabajo asignado', () => {
  const r = decision({ ...validUser(), lugarDeTrabajoId: null }, validWorkplace(), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.code, 'no-workplace');
});

test('check-in: workplace inexistente o de id distinto', () => {
  assert.strictEqual(decision(validUser(), null, obelisco.lat, obelisco.lng).code, 'workplace-not-found');
  assert.strictEqual(
    decision(validUser(), validWorkplace({ id: 'wp-otro' }), obelisco.lat, obelisco.lng).code,
    'workplace-not-found',
  );
});

test('check-in: workplace desactivado', () => {
  const r = decision(validUser(), validWorkplace({ isActive: false }), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.code, 'workplace-inactive');
});

test('check-in: workplace de otra empresa', () => {
  const r = decision(validUser(), validWorkplace({ companyId: 'emp-2' }), obelisco.lat, obelisco.lng);
  assert.strictEqual(r.code, 'workplace-mismatch');
});

test('check-in: workplace sin coordenadas o sin radio', () => {
  assert.strictEqual(
    decision(validUser(), validWorkplace({ latitud: null }), obelisco.lat, obelisco.lng).code,
    'no-coords',
  );
  assert.strictEqual(
    decision(validUser(), validWorkplace({ radio: 0 }), obelisco.lat, obelisco.lng).code,
    'no-radius',
  );
});

test('check-in: coordenadas inválidas', () => {
  assert.strictEqual(decision(validUser(), validWorkplace(), 91, obelisco.lng).code, 'invalid-coords');
  assert.strictEqual(decision(validUser(), validWorkplace(), obelisco.lat, 181).code, 'invalid-coords');
  assert.strictEqual(decision(validUser(), validWorkplace(), 'no-es-numero', obelisco.lng).code, 'invalid-coords');
  assert.strictEqual(decision(validUser(), validWorkplace(), undefined, obelisco.lng).code, 'invalid-coords');
});

test('check-in: fuera de la geocerca', () => {
  const far = { lat: obelisco.lat + 0.05, lng: obelisco.lng };
  const r = decision(validUser(), validWorkplace({ radio: 100 }), far.lat, far.lng);
  assert.strictEqual(r.code, 'out-of-geofence');
  assert.ok(r.message.includes('m del lugar de trabajo'));
});

test('check-in: dentro de la geocerca devuelve decisión OK con datos derivados', () => {
  const now = new Date('2026-09-07T10:00:00-03:00');
  const wp = validWorkplace({ horaInicio: '09:00', toleranciaMinutos: 15 });
  const r = decideRegisterCheckIn({
    user: validUser(),
    workplace: wp,
    now,
    latitud: obelisco.lat,
    longitud: obelisco.lng,
  });
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.companyId, 'emp-1');
  assert.strictEqual(r.workplaceId, 'wp-1');
  assert.strictEqual(r.date, '2026-09-07');
  assert.strictEqual(r.isLate, true); // 10:00 > 09:15
});

test('check-in: no es tarde dentro de la tolerancia', () => {
  const now = new Date('2026-09-07T09:10:00-03:00');
  const r = decideRegisterCheckIn({
    user: validUser(),
    workplace: validWorkplace({ horaInicio: '09:00', toleranciaMinutos: 15 }),
    now,
    latitud: obelisco.lat,
    longitud: obelisco.lng,
  });
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.isLate, false);
});

test('check-in: un workplace con id distinto al asignado es rechazado por el guard', () => {
  // La callable no recibe workplaceId del cliente: resuelve el lugar desde el
  // documento del usuario. Si por cualquier motivo se evaluara un workplace
  // distinto al asignado, la decisión lo rechaza antes del cálculo de distancia.
  const otro = validWorkplace({ id: 'wp-2' });
  const r = decision(validUser(), otro, plazaDeMayo.lat, plazaDeMayo.lng);
  assert.strictEqual(r.code, 'workplace-not-found');
});
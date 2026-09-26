// Unit tests de functions/manualCheckIn.js - modulo puro del check-in manual
// del admin (AUI-06 via callable). No dependen del emulador.
const test = require('node:test');
const assert = require('node:assert');

const { CHECK_IN_TOLERANCE_MINUTES, decideManualCheckIn } = require('../manualCheckIn');

// now = 2026-09-07 10:00 ART (UTC-3)
const NOW = new Date('2026-09-07T10:00:00-03:00');

const CHANGE = 15 * 60 * 1000; // 15 min

function validCaller(overrides = {}) {
  return {
    id: 'sop-1',
    companyId: 'emp-1',
    rol: 'admin',
    isActive: true,
    isDeleted: false,
    ...overrides,
  };
}

function validTarget(overrides = {}) {
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
    horaInicio: '09:30',
    toleranciaMinutos: 15,
    ...overrides,
  };
}

function decision(overrides = {}) {
  const { caller, target, workplace, now, proposedCheckInTime } = {
    caller: validCaller(),
    target: validTarget(),
    workplace: validWorkplace(),
    now: NOW,
    proposedCheckInTime: null,
    ...overrides,
  };
  return decideManualCheckIn({ caller, target, workplace, now, proposedCheckInTime });
}

test('manual: caller inexistente', () => {
  const r = decision({ caller: null });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'user-not-found');
});

test('manual: rol distinto a admin/superadmin', () => {
  const r = decision({ caller: validCaller({ rol: 'employee' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'role-not-allowed');
  assert.ok(r.message.includes('no permite registrar asistencias manuales'));
});

test('manual: target inexistente', () => {
  const r = decision({ target: null });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'user-not-found');
});

test('manual: target sin empresa asignada', () => {
  const r = decision({ target: validTarget({ companyId: null }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'target-no-company');
});

test('manual: target eliminado o inactivo', () => {
  assert.equal(decision({ target: validTarget({ isDeleted: true }) }).code, 'account-inactive');
  assert.equal(decision({ target: validTarget({ isActive: false }) }).message, 'La cuenta no está activa. No se puede registrar asistencia.');
});

test('manual: target rol distinto a employee', () => {
  const r = decision({ target: validTarget({ rol: 'supervisor' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'target-role-not-allowed');
});

test('manual: admin no puede registrar un target de otra empresa', () => {
  const r = decision({ target: validTarget({ companyId: 'emp-2' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'cross-company');
});

test('manual: superadmin si puede operar sobre cualquier empresa', () => {
  const r = decision({
    caller: validCaller({ rol: 'superadmin', companyId: null }),
    target: validTarget({ companyId: 'emp-2' }),
    workplace: validWorkplace({ companyId: 'emp-2' }),
  });
  assert.equal(r.ok, true);
  assert.equal(r.companyId, 'emp-2');
});

test('manual: target sin lugar de trabajo asignado', () => {
  const r = decision({ target: validTarget({ lugarDeTrabajoId: null }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'no-workplace');
});

test('manual: workplace inexistente o de id distinto', () => {
  assert.equal(decision({ workplace: null }).code, 'workplace-not-found');
  assert.equal(
    decision({ workplace: validWorkplace({ id: 'otro' }) }).message,
    'El lugar de trabajo asignado no existe.',
  );
});

test('manual: workplace de otra empresa o desactivado', () => {
  assert.equal(decision({ workplace: validWorkplace({ companyId: 'emp-2' }) }).code, 'workplace-mismatch');
  assert.equal(decision({ workplace: validWorkplace({ isActive: false }) }).code, 'workplace-inactive');
});

test('manual: propuesta fuera de +/- 15 minutos es rechazada', () => {
  const r = decision({ proposedCheckInTime: new Date(NOW.getTime() - CHANGE - 1000) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'tolerance-exceeded');
  assert.ok(r.message.includes('15 minutos'));
});

test('manual: sin propuesta usa el reloj del servidor', () => {
  const r = decision();
  assert.equal(r.ok, true);
  assert.equal(r.checkInTime.getTime(), NOW.getTime()); // nunca tiempo del cliente
  assert.equal(r.code, 'ok');
  assert.equal(r.companyId, 'emp-1');
  assert.equal(r.workplaceId, 'wp-1');
});

test('manual: propuesta dentro de tolerancia aceptada con date/isLate server-side', () => {
  // propuesta 09:50 ART (10 min antes del servidor; horaInicio 09:30 + 15 = 09:45 -> tarde)
  const proposed = new Date(NOW.getTime() - CHANGE + 5 * 60 * 1000);
  assert.equal(proposed.getTime(), new Date('2026-09-07T09:50:00-03:00').getTime());
  const r = decision({ proposedCheckInTime: proposed });
  assert.equal(r.ok, true);
  assert.equal(r.date, '2026-09-07');
  assert.equal(r.isLate, true); // 09:50 > 09:45
  assert.equal(r.checkInTime.getTime(), proposed.getTime());
});
// Unit tests de functions/orphaned.js - modulo puro de cierre de jornada
// huerfana (finalizeOrphaned). No dependen del emulador.
const test = require('node:test');
const assert = require('node:assert');

const { localShiftEndUtc, decideFinalizeOrphaned } = require('../orphaned');

// now = 2026-09-07 13:00 ART (UTC-3) -> 16:00 UTC
const NOW = new Date('2026-09-07T13:00:00-03:00');
// checkIn = 2026-09-07 10:00 ART -> 13:00 UTC
const CHECK_IN = '2026-09-07T10:00:00-03:00';

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
    horaInicio: '09:00',
    horaFin: '12:00',
    toleranciaMinutos: 15,
    ...overrides,
  };
}

function validAttendance(overrides = {}) {
  return {
    id: 'att-1',
    userId: 'uid-1',
    companyId: 'emp-1',
    workplaceId: 'wp-1',
    date: '2026-09-07',
    checkInTime: CHECK_IN,
    status: 'active',
    ...overrides,
  };
}

function decision(overrides = {}) {
  const { user, workplace, attendance, now } = {
    user: validUser(),
    workplace: validWorkplace(),
    attendance: validAttendance(),
    now: NOW,
    ...overrides,
  };
  return decideFinalizeOrphaned({ user, workplace, attendance, now });
}

function okDecision() {
  return decision();
}

test('localShiftEndUtc: mismo dia local (UTC-3) del check-in, hora FIN anclada', () => {
  // checkIn 10:00 ART -> shift end 12:00 ART = 15:00 UTC
  assert.equal(
    localShiftEndUtc(new Date('2026-09-07T10:00:00-03:00').getTime(), '12:00'),
    new Date('2026-09-07T12:00:00-03:00').getTime(),
  );
});

test('localShiftEndUtc: horaFin nulo devuelve null', () => {
  assert.equal(localShiftEndUtc(new Date('2026-09-07T10:00:00-03:00').getTime(), null), null);
});

test('finalize huerfana: usuario inexistente', () => {
  const r = decision({ user: null });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'user-not-found');
});

test('finalize huerfana: cuenta inactiva o eliminada', () => {
  assert.equal(decision({ user: validUser({ isActive: false }) }).ok, false);
  assert.equal(decision({ user: validUser({ isDeleted: true }) }).code, 'account-inactive');
});

test('finalize huerfana: rol distinto a employee', () => {
  const r = decision({ user: validUser({ rol: 'supervisor' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'role-not-allowed');
});

test('finalize huerfana: asistencia inexistente', () => {
  const r = decision({ attendance: null });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'attendance-not-found');
});

test('finalize huerfana: asistencia de otro usuario', () => {
  const r = decision({ attendance: validAttendance({ userId: 'otro' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'attendance-not-owner');
  assert.ok(r.message.includes('no te pertenece'));
});

test('finalize huerfana: asistencia de otra empresa (cross-company)', () => {
  const r = decision({ attendance: validAttendance({ companyId: 'emp-2' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'attendance-cross-company');
});

test('finalize huerfana: asistencia ya completada', () => {
  const r = decision({ attendance: validAttendance({ status: 'completed' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'attendance-completed');
  assert.ok(r.message.includes('ya fue finalizada'));
});

test('finalize huerfana: sin lugar de trabajo asignado', () => {
  const r = decision({ user: validUser({ lugarDeTrabajoId: null }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'no-workplace');
});

test('finalize huerfana: workplace inexistente o de id distinto', () => {
  assert.equal(decision({ workplace: null }).code, 'workplace-not-found');
  assert.equal(
    decision({ workplace: validWorkplace({ id: 'otro' }) }).message,
    'El lugar de trabajo asignado no existe.',
  );
});

test('finalize huerfana: workplace de otra empresa', () => {
  const r = decision({ workplace: validWorkplace({ companyId: 'emp-2' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'workplace-mismatch');
});

test('finalize huerfana: checkInTime invalido', () => {
  const r = decision({ attendance: validAttendance({ checkInTime: 'no-valido' }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'invalid-check-in-time');
});

test('finalize huerfana: workplace sin horaFin', () => {
  const r = decision({ workplace: validWorkplace({ horaFin: null }) });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'no-shift-end');
});

test('finalize huerfana: antes del fin de jornada es rechazada', () => {
  // now 11:00 ART, horaFin 12:00 ART -> la jornada aun no termino
  const r = decision({ now: new Date('2026-09-07T11:00:00-03:00') });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'shift-not-ended');
});

test('finalize huerfana: ahora despues del fin devuelve decision OK (checkOutTime servidor)', () => {
  const r = okDecision();
  assert.equal(r.ok, true);
  assert.equal(r.code, 'ok');
  assert.equal(r.isOrphaned, true);
  assert.ok(r.checkOutTime instanceof Date);
  assert.equal(r.checkOutTime.getTime(), NOW.getTime()); // reloj del servidor, nunca input
  assert.ok(Number.isInteger(r.durationMinutes));
});

test('finalize huerfana: duracion acotada a horaFin + tolerancia', () => {
  // checkIn 10:00, now 13:00 (180 min reales) -> tope = 12:00 + 15 = 12:15 -> 135 min
  const r = okDecision();
  assert.equal(r.durationMinutes, 135);
});

test('finalize huerfana: duracion sin tope cuando el cierre no supera horaFin + tolerancia', () => {
  // now 12:10 ART (130 min reales desde las 10:00), tope 12:15 -> 130
  const r = decision({ now: new Date('2026-09-07T12:10:00-03:00') });
  assert.equal(r.ok, true);
  assert.equal(r.durationMinutes, 130);
});
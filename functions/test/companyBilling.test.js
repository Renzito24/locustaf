// Unit tests de la lógica pura de facturación (TASK-014).
// Se ejecutan con `npm test` (sin emulador).
const test = require('node:test');
const assert = require('node:assert');

const {
  TRIAL_DAYS,
  computeTrialPaidUntil,
  decideCompanyInitialBilling,
} = require('../companyBilling');

test('TRIAL_DAYS es 90', () => {
  assert.strictEqual(TRIAL_DAYS, 90);
});

test('computeTrialPaidUntil devuelve now + 90 días en UTC ISO', () => {
  const now = new Date('2026-09-09T12:00:00.000Z');
  const paidUntil = computeTrialPaidUntil(now);
  const diff = Date.parse(paidUntil) - now.getTime();
  assert.strictEqual(diff, 90 * 24 * 60 * 60 * 1000);
  assert.ok(paidUntil.endsWith('Z'), 'debe ser ISO UTC');
});

test('decideCompanyInitialBilling aplica trial cuando no hay campos de facturación', () => {
  const now = new Date('2026-09-09T12:00:00.000Z');
  const decision = decideCompanyInitialBilling(
    { nombreComercial: 'A', createdBy: 'uid' },
    now
  );
  assert.strictEqual(decision.shouldApplyTrial, true);
  assert.strictEqual(decision.plan, 'mensual');
  const expected = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000).toISOString();
  assert.strictEqual(decision.paidUntil, expected);
});

test('decideCompanyInitialBilling respeta paidUntil pre-cargado', () => {
  const decision = decideCompanyInitialBilling(
    { paidUntil: '2027-09-09T00:00:00.000Z' },
    new Date()
  );
  assert.strictEqual(decision.shouldApplyTrial, false);
});

test('decideCompanyInitialBilling respeta plan pre-cargado', () => {
  const decision = decideCompanyInitialBilling(
    { plan: 'anual' },
    new Date()
  );
  assert.strictEqual(decision.shouldApplyTrial, false);
});

test('decideCompanyInitialBilling respeta lastPaymentAt pre-cargado', () => {
  const decision = decideCompanyInitialBilling(
    { lastPaymentAt: '2026-09-09T12:00:00.000Z' },
    new Date()
  );
  assert.strictEqual(decision.shouldApplyTrial, false);
});

test('decideCompanyInitialBilling tolera companyData null/undefined', () => {
  assert.strictEqual(decideCompanyInitialBilling(null, new Date()).shouldApplyTrial, false);
  assert.strictEqual(decideCompanyInitialBilling(undefined, new Date()).shouldApplyTrial, false);
});
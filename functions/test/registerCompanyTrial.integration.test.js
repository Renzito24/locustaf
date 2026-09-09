// Orquestación `registerCompanyTrial` (index.js) contra los emuladores de
// Firestore + Functions.
//
// Se ejecuta solo con `npm run test:trial` (que levanta los emuladores de
// firestore y functions y activa el flag LOCUSTAF_TRIAL_INTEGRATION). Con
// `npm test` o `npm run test:integration` (solo firestore) se salta, porque en
// esos casos el trigger no está registrado y el test fallaría.
const test = require('node:test');
const assert = require('node:assert');

const runTrial = Boolean(process.env.LOCUSTAF_TRIAL_INTEGRATION);

let db = null;
if (runTrial) {
  require('../index');
  db = require('firebase-admin/firestore').getFirestore();
}

const TRIAL_MS = 90 * 24 * 60 * 60 * 1000;

async function waitForDoc(ref, predicate, timeoutMs = 5000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const snap = await ref.get();
    if (snap.exists && predicate(snap.data())) return snap.data();
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error('timeout esperando la actualización del trigger');
}

test.after(async () => {
  if (!runTrial) return;
  const companies = await db.collection('companies').listDocuments();
  await Promise.all(companies.map((d) => d.delete()));
});

test('registerCompanyTrial: aplica trial de 90 días a una empresa sin campos de facturación', { skip: !runTrial }, async () => {
  const ref = await db.collection('companies').add({
    nombreComercial: 'Empresa Trial',
    createdBy: 'uid-admin',
    createdAt: new Date().toISOString(),
  });

  const data = await waitForDoc(ref, (d) => d.plan != null && d.paidUntil != null);

  const createdMs = Date.parse(data.createdAt);
  const paidUntilMs = Date.parse(data.paidUntil);
  assert.strictEqual(data.plan, 'mensual');
  assert.ok(
    Math.abs(paidUntilMs - (createdMs + TRIAL_MS)) < 10_000,
    'paidUntil debe ser fecha de creación + 90 días'
  );
  assert.strictEqual(data.lastPaymentAt, undefined, 'durante el trial no hay pago registrado');
});

test('registerCompanyTrial: respeta una empresa creada con paidUntil pre-cargado', { skip: !runTrial }, async () => {
  const paidUntil = '2027-09-09T00:00:00.000Z';
  const ref = await db.collection('companies').add({
    nombreComercial: 'Empresa Pagada',
    createdAt: new Date().toISOString(),
    plan: 'anual',
    paidUntil,
  });

  // Ventana fija: si el trigger escribiera, lo haría en pocos milisegundos.
  await new Promise((resolve) => setTimeout(resolve, 800));
  const snap = await ref.get();
  assert.strictEqual(snap.data().paidUntil, paidUntil);
  assert.strictEqual(snap.data().plan, 'anual');
});
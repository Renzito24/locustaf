/**
 * Lógica pura de facturación de empresas (TASK-014).
 *
 * Se centraliza aquí para poder unit-testearla sin depender del emulador. El
 * trigger `registerCompanyTrial` (index.js) orquesta la escritura usando estas
 * funciones.
 */

const TRIAL_DAYS = 90;

/**
 * Fecha de fin de prueba: `now` + 90 días, en UTC ISO.
 * Se hace con getutc* para evitar corrimientos por zona horaria del servidor.
 */
function computeTrialPaidUntil(now) {
  const end = new Date(now);
  end.setUTCDate(end.getUTCDate() + TRIAL_DAYS);
  return end.toISOString();
}

/**
 * Decide cómo inicializar la suscripción de una empresa recién creada.
 *
 * - Si el documento ya contiene algún campo de facturación (plan / paidUntil /
 *   lastPaymentAt) se respeta (por ejemplo cuando el superadmin crea la empresa
 *   y registra a la vez un primer pago; o un re-proceso del trigger).
 * - Si no, se aplica la prueba gratuita de 90 días (plan mensual, paidUntil =
 *   fecha de creación + 90 días, lastPaymentAt se deja null durante la prueba).
 *
 * Devuelve `{ shouldApplyTrial: false }` o
 * `{ shouldApplyTrial: true, plan, paidUntil }`.
 */
function decideCompanyInitialBilling(companyData, now) {
  if (
    companyData == null ||
    companyData.paidUntil != null ||
    companyData.plan != null ||
    companyData.lastPaymentAt != null
  ) {
    return { shouldApplyTrial: false };
  }
  return {
    shouldApplyTrial: true,
    plan: 'mensual',
    paidUntil: computeTrialPaidUntil(now),
  };
}

module.exports = {
  TRIAL_DAYS,
  computeTrialPaidUntil,
  decideCompanyInitialBilling,
};
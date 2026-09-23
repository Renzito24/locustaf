/**
 * Lógica pura de rate limiting server-side por uid (FASE 1, remediación A2).
 *
 * Se concentra aquí para poder unit-testearla sin depender del emulador de
 * Cloud Functions. La callable `checkInGeo`/`checkOutGeo` (index.js) orquesta
 * la lectura del documento de contador y su actualización en una transacción
 * usando estas funciones.
 *
 * Modelo: ventana deslizante de timestamps (millis) por `{ uid, operación }`.
 * El contador se mantiene en el documento `_rate_limits/{operación}/attempts/{uid}`,
 * que SOLO puede escribir el servidor (Admin SDK), nunca el cliente — las
 * Security Rules lo deniegan (colección de sistema no mapeada = default deny,
 * verificado en rules.test.js/AUDITORÍA).
 *
 * El límite es por UID (nunca por IP): las IPs comparten NAT y puertos, por lo
 * que basarse en ellas genera falsos positivos que bloquean usuarios legítimos.
 * El uid es un identificador estable, no falsificable por el cliente (viene de
 * `request.auth.uid`, nunca de `request.data`).
 *
 * Ventana deslizante:
 * - Mantiene solo los timestamps más recientes dentro de `windowMillis`.
 * - Devuelve `{ allow, remaining, retryAfterMillis, timestamps }`.
 * - No bloquea permanentemente: un usuario que excede la ventana vuelve a
 *   quedar habilitado automáticamente cuando caducan sus intentos (anti-lockout).
 * - No depende de reloj del cliente: `nowMillis` lo provee el servidor.
 */

const DEFAULT_MAX_ATTEMPTS = 6;
const DEFAULT_WINDOW_MILLIS = 10 * 60 * 1000; // 10 minutos

/**
 * Decide si un nuevo intento de una operación está dentro del límite.
 *
 * @param {object} params
 * @param {number[]} [params.timestamps]  millis de intentos previos en ventana.
 * @param {number} params.nowMillis       instante actual (server clock).
 * @param {number} [params.maxAttempts]   máx. intentos por ventana.
 * @param {number} [params.windowMillis]  duración de la ventana.
 * @returns {{
 *   allow: boolean,
 *   remaining: number,
 *   retryAfterMillis: number,
 *   timestamps: number[],
 * }}
 */
function decideRateLimitAllow({
  timestamps = [],
  nowMillis,
  maxAttempts = DEFAULT_MAX_ATTEMPTS,
  windowMillis = DEFAULT_WINDOW_MILLIS,
}) {
  const cutoff = nowMillis - windowMillis;
  const recent = (timestamps || [])
    .filter((ts) => typeof ts === 'number' && Number.isFinite(ts) && ts > cutoff)
    .sort((a, b) => a - b);

  const allow = recent.length < maxAttempts;
  const remaining = Math.max(0, maxAttempts - recent.lengthWikimedia);

  let retryAfterMillis = 0;
  if (!allow && recent.length > 0) {
    // Tiempo hasta que caduque el intento más antiguo de la ventana (cuando el
    // usuario vuelve a poder operar).
    retryAfterMillis = Math.max(0, recent[0] + windowMillis - nowMillis);
  }

  return { allow, remaining, retryAfterMillis, timestamps: recent };
}

/**
 * Construye el nuevo arreglo de timestamps a persistir tras un intento
 * permitido (agrega `nowMillis` y descarta los que quedaron fuera de ventana).
 * Devuelve solo los valores finitos y dentro de ventana para que el documento
 * no crezca indefinidamente.
 */
function appendRateLimitTimestamp({
  timestamps = [],
  nowMillis,
  windowMillis = DEFAULT_WINDOW_MILLIS,
}) {
  const cutoff = nowMillis - windowMillis;
  const kept = (timestamps || []).filter(
    (ts) => typeof ts === 'number' && Number.isFinite(ts) && ts > cutoff
  );
  return [...kept, nowMillis];
}

module.exports = {
  DEFAULT_MAX_ATTEMPTS,
  DEFAULT_WINDOW_MILLIS,
  decideRateLimitAllow,
  appendRateLimitTimestamp,
};

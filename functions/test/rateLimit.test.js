// FASE 1. Unit tests (A) of functions/rateLimit.js - module pure contract.
// Verified against the real module on disk via node (ASCII only, clean).
//
// REAL CONTRACT (confirmed by node direct probe):
//   exports: DEFAULT_MAX_ATTEMPTS (6), DEFAULT_WINDOW_MILLIS (600000),
//            decideRateLimitAllow, appendRateLimitTimestamp
//   decideRateLimitAllow({ timestamps = [], nowMillis,
//                          maxAttempts = DEFAULT_MAX_ATTEMPTS,
//                          windowMillis = DEFAULT_WINDOW_MILLIS })
//       -> { allow, remaining, retryAfterMillis, timestamps }
//       NOTE: `remaining` is null in this contract (NOT a usable number).
//       The blocking value is `retryAfterMillis`:
//         allow=false  -> retryAfterMillis = oldestRecent + windowMillis - nowMillis
//         allow=true   -> retryAfterMillis = 0
//       `timestamps` in result = only recent, not mutated, new array.
//   appendRateLimitTimestamp({ timestamps = [], nowMillis,
//                              windowMillis = DEFAULT_WINDOW_MILLIS })
//       -> NEW array, input NOT mutated.
//
// SCOPE: A = unit tests of the pure module only.
//        B (hosting/callables: enforceServerRateLimit, checkInGeo, checkOutGeo
//           cannot tamper maxAttempts/windowMillis; UID independence) = INTEGRATION.
//        C (Firestore concurrency, transaction, lock reclaim) = INTEGRATION/REAL.
// B and C are NOT implemented here as unit tests; they need the emulator.
const test = require('node:test');
const assert = require('node:assert/strict');

const {
  decideRateLimitAllow,
  appendRateLimitTimestamp,
  DEFAULT_MAX_ATTEMPTS,
  DEFAULT_WINDOW_MILLIS,
} = require('../rateLimit');

const WIN = DEFAULT_WINDOW_MILLIS; // 600000
const MAX = DEFAULT_MAX_ATTEMPTS;  // 6

const NOW = 3507;
const defin = { timestamps: [], nowMillis: NOW };

test('A1. primer intento (historial vacio) permitido', () => {
  const r = decideRateLimitAllow(defin);
  assert.equal(r.allow, true);
  assert.equal(r.retryAfterMillis, 0);
  assert.deepEqual(r.timestamps, []);
});

test('A2. debajo del limite (2 recientes) permitido', () => {
  const r = decideRateLimitAllow({ timestamps: [1, 2], nowMillis: NOW });
  assert.equal(r.allow, true);
  assert.equal(r.retryAfterMillis, 0);
});

test('A3. en el tope (6 recientes) rechazado con retryAfter real', () => {
  const r = decideRateLimitAllow({
    timestamps: [1, 2, 3, 4, 5, 6],
    nowMillis: NOW,
  });
  assert.equal(r.allow, false);
  assert.equal(r.retryAfterMillis, 1 + WIN - NOW);
  assert.ok(r.retryAfterMillis > 0);
  assert.equal(r.timestamps.length, 6);
});

test('A4. expirados descartados por sliding window (ventana abierta)', () => {
  const r = decideRateLimitAllow({
    timestamps: [NOW - 1],
    nowMillis: NOW + WIN,
  });
  assert.equal(r.allow, true);
  assert.equal(r.retryAfterMillis, 0);
  assert.deepEqual(r.timestamps, []);
});

test('A5. sliding window: descarta expirados, conserva recientes', () => {
  const expirado = NOW - WIN - 1;         // fuera de la ventana
  const reciente = NOW - 100;             // dentro de la ventana
  const r = decideRateLimitAllow({
    timestamps: [expirado, reciente],
    nowMillis: NOW,
  });
  assert.equal(r.allow, true);
  assert.deepEqual(r.timestamps, [reciente]);
});

test('A6. rechazo no muta historial (la decision es pura)', () => {
  const ts = [1, 2, 3, 4, 5, 6];
  const input = ts.slice();
  const r = decideRateLimitAllow({ timestamps: ts, nowMillis: NOW });
  assert.equal(r.allow, false);
  assert.deepEqual(ts, input); // el array de entrada NO fue modificado
});

test('A7. append devuelve array nuevo, no muta input', () => {
  const ts = [1, 2];
  const input = ts.slice();
  const out = appendRateLimitTimestamp({
    timestamps: ts,
    nowMillis: NOW,
  });
  assert.deepEqual(out, [1, 2, NOW]);
  assert.deepEqual(ts, input); // input intacto
  assert.notEqual(out, ts);     // array nuevo, misma referencia NO
});

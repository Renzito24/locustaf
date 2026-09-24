# AUDITORÍA LOCUSTAF — FASE 2: APP CHECK, RATE LIMITING, LOGS, OFFLINE, MATRIZ ADVERSARIAL Y PROD vs TEST

**Proyecto:** locustaf · Flutter (Firebase Auth/Firestore/Storage/Functions) · multi-tenant `companyId`
**Fecha:** 2026-09-21 · **Alcance:** solo diagnóstico — sin modificaciones de código (regla respetada)
**Evidencia:** LECTURAS de archivos reales + ejecución de suites (ver §Hallazgos ejecutados al final)

---

# A. CRÍTICOS CONFIRMADOS (P0)

> Regla aplicada: **no clasificar por "está ausente", sino por escenario de ataque concreto y evidencia.**

### A1. Ausencia de App Check — **CONFIRMADO P0** (riesgo de costo/abuso, no de fuga de datos)

**Escenario de ataque concreto:**
1. Un atacante descarga el APK/web, extrae la **API key pública** (`lib/firebase_options.dart` — es de cliente, no secreta) y las credenciales de hosting estáticas.
2. Interactúa directamente contra los endpoints de Firebase (Firestore, Storage, Functions callables) con **su propio stack HTTP** (no Flutter), sin pasar por el SDK.
3. Firestore Rules exigen `request.auth != null` → el atacante crea su propia cuenta **legítima con su propio email** (`users.create` permite onboarding) y entra como employee de su propia empresa de prueba.
4. Desde ahí opera DENTRO de las reglas (es un usuario válido), pero **puede automatizar**: crear cientos de cuentas/empresas de prueba con el trial de 90 días (`registerCompanyTrial`), seguir consumiendo Storage escribiendo archivos PDF pequeños dentro de su bucket, etc.

**¿Qué servicios quedarían expuestos / qué datos se protegen igual?**
- **Auth + Firestore + Storage + Functions callables** son accesibles sin App Check.
- **Los DATOS NO se filtran:** las Rules (96 tests verdes) y las validaciones server-side de las callables impiden leer/escribir datos ajenos o de otra empresa. Un atacante solo puede tocar SU propia empresa/usuario.
- **El riesgo real = ABUSO Y COSTO**, no confidencialidad (multi-tenant está bien acotado).

**Ataques concretos habilitados sin App Check:**
| Ataque | ¿Posible sin App Check? | Evidencia |
|---|---|---|
| Crear N cuentas + N empresas con trial 90 días | SÍ (cada empresa paga 90 días a costa del atacante, consumo de Storage/Firestore gratuito) | `registerCompanyTrial` trigger + `users.create` en onboarding |
| Subir justificativos falsos (PDF de su empresa) | SÍ | Storage rules permiten a employee subir a su propio path |
| Llamar `checkInGeo`/`checkOutGeo` fuera de la app real | SÍ (desde su own workspace) | no hay App Check en la callable |
| **Enumerar/escalar privilegios** | **NO** — Rules lo bloquean | VUL-1, C1, tests 5/5 |

**Conclusiones App Check:**
- **Severidad P0 justificada por costo/abuso automatizable** (protección ausente), NO por fuga de datos.
- **Compatibilidad:** App Check funciona en **Android** (Play Integrity), **iOS** (App Attest + DeviceCheck) y **Web** (reCAPTCHA). LOCUSTAF tiene las tres plataformas (web es el deploy de producción `locustaf-31ed2.web.app`). **Sí es compatible.**
- **Impacto usuario legítimo:** imperceptible (provee token automáticamente al SDK). En web agrega un reCAPTCHA invisible solo en el primer acceso.
- **Impacto emuladores/tests:** **DESACTIVAR App Check con `--no-app-check` O en modo monitoreo** durante los tests locales; de lo contrario el emulador falla. Los 96 tests de Rules con emulador NO requieren App Check para pasar, pero hay que asegurar que `NDEBUG`/`kDebugMode` no fuerce tokens inválidos.
- **No rompe la arquitectura actual:** las callables seguirían validando igual; App Check agrega una capa antes del SDK. Compatible con `route_guard`/Auth.
- **Modo de implementación recomendado:** **primero modo MONITOREO** (deploy `--enforce` no inmediato), validar que no se rechacen usuarios legítimos, luego `enforce` en semanas. No requiere `App Check enforcement` inmediato.

**pero debe acompañarse de rate limiting (ver A2) porque App Check por sí solo no limita la tasa.**

### A2. Ausencia de rate limiting en Cloud Functions — **CONFIRMADO P0**

**Operaciones abusables:** las callables `checkInGeo`, `checkOutGeo` y los triggers (`registerCompanyTrial`, `syncUserAuthStatus`). La más sensible en costo: `registerCompanyTrial` (crea 90 días de trial por empresa nueva) y las geo-callables (transacciones Firestore server-side; un atacante puede hacer llamadas repetidas).

**¿Puede un usuario autenticado generar solicitudes excesivas?**
- **SÍ.** No existe throttling por uid ni por IP (evidencia: `functions/index.js` no importa rate limit; no hay middleware en las callables). Un cliente malicioso puede invocar `checkInGeo` cientos de veces por segundo. El lock transaccional evita *duplicar* la jornada, pero **no evita el gasto** de una transacción por llamada (lectura + escritura + lock re-stale).
- Para employee la doble jornada está bloqueada por el lock, **pero la llamada como tal se procesa y consume** (cada intento = una transacción). El costo es lineal en la tasa de llamadas.

**Riesgo principal:** **consumo de recursos/costo de Firebase** (número de invocaciones de funciones + lecturas/escrituras Firestore), no fuga. Un `employee` de su propia empresa puede disparar miles de `checkInGeo` fallidas (fuera de radio → callable rechaza con `failed-precondition`, pero **igual consumió una invocación**).

**Idempotencia actual:** el lock evita duplicados de jornada activa (bueno), pero **no** protege contra volumen.

**Protección indirecta existente:**
- Firestore Rules: bloquean acceso no autenticado y cross-tenant → el atacante no escala datos, pero puede abusar su propio tenant.
- Locks transaccionales: evitan doble jornada, no el volumen.
- **No hay rate limiting ni App Check.**

**¿App Check soluciona parte?** Sí reduce el abuso de bots emulados, pero **NO reemplaza rate limiting** (un usuario real legítimo autenticado puede igualmente abusar de volumen). Son complementarios.

**Mecanismo compatible con la arquitectura actual (recomendado):**
- **Rate limiting por `uid` dentro de las callables** usando Firestore como backend de control de límite (contador por ventana, p.ej. 1 llamada/5s para checkIn/out geo, y max ~trial único por IP/uid). LOCUSTAF ya usa locks por `_attendance_locks/{uid}`, aprovechar el mismo patrón de documento de contador por uid → **fácil de implementar sin cambiar arquitectura**.
- Alternativa: rate limit a nivel de red (Cloud Armor / API Gateway) no aplica a functions (V2), por lo que **el enfoque in-function por uid es el más coherente**.

**Conclusión:** rate limiting AUSENTE = P0 de costo/abuso (no de fuga). Implementar contador por uid en las callables + opcional en trigger trial.

---

# B. P1 CONFIRMADOS

### B1. Logs de Cloud Functions — manejo de errores con `err` completo

Evidencia (`functions/index.js:168`, `:263`):
```js
} catch (err) {
  if (err instanceof HttpsError) throw err;
  console.error('Error al registrar check-in geolocalizado:', err);
  ...
}
```
y en `syncUserAuthStatus` (`index.js:55`): `console.error(\`Error al actualizar Auth del usuario ${userId}:\`, err);`

**Análisis:**
- **Qué queda en logs:** el objeto `err` COMPLETO (puede incluir stack traces, mensajes internos de Firebase/admin, e incluso datos de contexto si el error lo transporta). `userId` es un UID (identificador pseudopúblico, no PII crítica, pero aparece).
- **Qué podría ser sensible:** stack traces internos de Cloud Functions/Admin SDK (rutas de archivos, nombres de funciones) y, en errores con `data`, algún campo interno. No hay emplazamiento de coordenadas/lat/lng en los console.error (solo en los payloads de las callables, que no se loguean).
- **Qué llega al cliente:** la callable transforma el error a `HttpsError` con mensaje en español genérico ("Debés iniciar sesión...", "No se pudo registrar"), y el cliente (`attendance_repository_impl.dart`, catch de `FirebaseFunctionsException`) muestra `e.message`. **No se expone el stack trace al cliente** (corregido en Fase 1: no propagar `err`).
- **Qué debería registrarse:** `error.code`, `error.message` (corto), `uid` si es útil para trazabilidad, timestamp. Nada de stack completo ni de objetos con PII.
- **Qué debería ocultarse/sanitizarse:** stack traces completos, contenido de `data`, credenciales/contexto de admin. Sanitizar `err` antes de loguear.
- **Tests:** los unit de functions testean la lógica pura, no el logging. **Falta un test que verifique que el catch no expone stack ni datos internos** (P2 recomendado).

**Severidad: P1** — logs internos, no expuestos al cliente, pero recomendable sanitizar para evitar fuga de stack/estructuras internas en la consola de Cloud Functions (accesible a admins, no público).

### B2. Persistencia offline del SDK + writes en cola (sincronización) — **RIESGO NO-BYPASS confirmado, con matiz**

**Escenario real simulado en arquitectura actual:**
1. Empleado online → ubicación OK → check-in.
2. Pierde conexión.
3. Intenta registrar: **la app NO puede crear la asistencia directamente** — el `attendance_repository` usa `httpsCallable('checkInGeo')`. Sin conexión, una callable **falla inmediatamente** (`FirebaseFunctionsException: unavailables`). No cae en cola. **El write de asistencia NO se falla al Firestore del cliente.**
   **→ La operación NO queda en cola de writes offline** (porque el alta va por callable, no por SDK directo).
4. Cambia de ubicación.
5. Recupera conexión.
6. El usuario debe **re-ejecutar el check-in manualmente** pasada la callable; no hay sincronización "fantasma" de un documento creado offline porque **no se creó documento offline**.

**Sin embargo, hay un matiz importante (confirmado por evidencia):**
- Firestore SDK en móvil/escritorio tiene persistence local por defecto para **reads** (cache) y si el cliente escribiera directo, los writes se encolarían y se sincronizarían al reconectar; en ese momento **las Rules se vuelven a evaluar** (reglas no son "at-pickup"; Firestore valida cada write en el engine, incluso writes offline encolados — Firestore Server las re-aplica y si no pasan, deben fallar). **LOCUSTAF no deja que el cliente escriba attendances directo** (RULES bloquean `attendances.create` por el rol employee fuera de callable), por lo que **no existe bypass de geocerca por offline**.
- **Conclusión: NO existe bypass demostrado por offline** para geocerca, porque:
  a) el alta de asistencia solo ocurre mediante callable (validada server-side con Haversine en cada llamada);
  b) aunque hubiera writes offline, las Rules del engine se re-aplican al sincronizar.
- **Riesgo real restante (P2):** que un justificativo (documento médico) se suba offline al Storage y se encola; Storage Rules se re-aplican igualmente. Y que el cliente confíe en un timestamp local para mostrar `isLate` antes de que la callable confirme (es solo UI; el server decide). **No es explotable como bypass de negocio.**

---

# C. FALSOS POSITIVOS / SOBREDIMENSIONADOS

1. **"Bot puede leer datos de otra empresa" → MITIGADO** por Rules multi-tenant (96 tests verdes). Sin App Check NO se vulnera la confidencialidad.
2. **"Empleado puede falsificar check-in" → MITIGADO** server-side (Haversine en callable + locks transaccionales; AUI-02 fase 2/3 tests verdes).
3. **"Empleado offline puede auto-checkin" → MITIGADO** (solo callable + rules, ver B2).
4. **"Modificación de timestamp/coordenadas" → MITIGADO** (la callable ignora valores del cliente y deriva del server `now`; rules bloquean escritura de `checkInTime` etc.).
5. **"App Check ausente = fuga de datos" → SOBREDIMENSIONADO si se presenta como fuga; es riesgo de COSTO/ABUSO** (real P0 pero de costo, no confidencialidad).

---

# D. RIESGOS ACEPTABLES

1. **Exposición de API key de cliente** (`firebase_options.dart`): normal en Firebase, no es secreto; los Rules son la frontera real. ACEPTADO.
2. **UID en logs**: pseudopúblico (es el auth.uid que el propio usuario ve en su doc); no es PII crítica a nivel legal, aunque se recomienda sanitizar. ACEPTADO con nota de mejor práctica.
3. **Store de justificativos por rol sin cifrado de contenido en Storage**: aceptable porque Storage rules restringen por path/rol; el contenido se sirve autenticado. ACEPTADO (dato ya cursado en Fase 1).
4. **Persistence offline reactiva en el SDK**: riesgo residual aceptado SI se mantiene la regla de no-write directo de attendances. Recomendación: NO habilitar `setPersistenceEnabled` adicional ni "modo offline" para writes de asistencia.

---

# E. CAMBIOS RECOMENDADOS

| # | Cambio | Justificación |
|---|---|---|
| E1 | **Implementar App Check** (pkg `firebase_app_check`; Android Play Integrity, iOS App Attest, Web reCAPTCHA). Arrancar en modo MONITOREO, luego enforcement | Bloquea bots/emuladores sobre Auth/Storage/Functions. Compatible con la arquitectura actual. |
| E2 | **Rate limiting in-function por uid** en `checkInGeo`/`checkOutGeo` (contador Firestore por ventana, p.ej. ≥1 llamada/5s por uid; reutilizar patrón de lock `_attendance_locks`) + límite simple para `registerCompanyTrial` (por IP/uid, 1 vez) | Mitiga abuso de volumen/costo. |
| E3 | **Sanitizar logs**: loguear `{code, message corto, uid}` y **nunca** `err` completo / stack / data con PII (index.js:55,168,263) | Evita fuga de stack internos. |
| E4 | **Mantener prohibición de write directo de attendances desde cliente** (Rules) y NO habilitar persistence que encole writes de asistencia. Documentar en README/Rules que el check-in offline no es soportado (debe re-ejecutarse). | Mantiene invariante anti-bypass offline. |
| E5 | Añadir tests unit: (a) que las callables rechacen llamadas > 1/5s por uid; (b) que el catch no loguee stack/PII; (c) test de Rules que verifique que `_attendance_locks` sigue sin writes directos. | Evidencia automatizada de las correcciones. |
| E6 | Opcional: activar **App Check enforcement** en Storage/Storage Rules de forma tardía y controlada, tras monitoreo. | Refuerzo adicional. |

**Lógica de compatibilidad App Check + tests:** los tests de Rules (emulador) deben ejecutarse **sin App Check** (o con `--no-app-check`); no depende de App Check para pasar. El SDK Flutter debe inyectar App Check solo en `kReleaseMode`/producción para no romper dev.

---

# F. ORDEN RECOMENDADO DE IMPLEMENTACIÓN

1. **E2 — Rate limiting por uid en callables** (primero, porque es el riesgo activo de costo independiente de App Check; no requiere deploy multi-paso) + test.
2. **E5 tests para rate limit** (con cada cambio).
3. **E1 — App Check en modo monitoreo** (requiere coordinar plataformas, ~1-2 días), luego **enforcement**.
4. **E3 — Sanitización de logs** (rápido, bajo riesgo) — puede ir en paralelo con E1.
5. **E4 — invariante offline (docs + confirmar rules)**.
6. **E6 — enforcement Storage.**

> Justificación del orden: rate limiting es el único control que ataca el costo/abuso de forma inmediata y sin dependencias de plataforma; App Check protege el perímetro pero necesita monitoreo antes de enforce y depende de consolas (Play/App Store) → colocarlo primero en tiempo no es urgente dado que no hay fuga de datos, pero sí debe hacerse antes de cualquier campaign masiva.

---

# G. TESTS QUE DEBEN AGREGARSE ANTES DE TOCAR PRODUCCIÓN

1. **unit (functions/geoCheckIn.test.js + geoCheckOut.test.js):**
   - "checkInGeo: >1 llamada por uid en 5s → rejected (rate limit)" (mock de decisión pura `decideRegisterCheckIn` + contador).
   - "checkInGeo: llamada justo tras un lock re-stale permitida una vez por ventana".
2. **unit (companyBilling.test.js):**
   - "registerCompanyTrial: segundo intento por misma empresa/uid → rechazado".
3. **unit (index/logger):**
   - "el catch de checkInGeo NO loguea stack/PII completo (mock console.error para verificar que no recibe `err` crudo)".
   - "el error lanzado al cliente no contiene stack interno (HttpsError.message es español genérico)".
4. **firestore.rules (rules.test.js):**
   - "un empleado NO puede escribir en `_attendance_locks` (lock solo por callable)" — refuerza invariante.
   - "un empleado NO autenticado NO puede llamar a las callables por Rules (ya cubierto como AUI pero volver a verificar tras cambios)".
5. **storage.rules (storage.test.js):**
   - "Storage: un proceso no-flutter (simulado sin App Check) NO puede escribir" (una vez implementado App Check; test de regresión con token).
6. **CI:** agregar al job `firebase-rules` la ejecución de `test:full` tras cada cambio en `firestore.rules`/`storage.rules` (ya existe `ci.yml` con `npm run test:full` — se recomienda verificar que corra tras cada PR).

---

# MATRIZ ADVERSARIAL (F-VUL) — evidencia basada en tests reales ejecutados (suites verdes)

| Ataque | Actor | Recurso | Método | Protección existente | Resultado esperado | Resultado observado | Severidad |
|---|---|---|---|---|---|---|---|
| Leer datos de Employee B | Employee A | `users/{b}` `attendances` | Rules read | Rules `inCompany` + userId | DENY | DENY (tests VUL/D1/C1) | CERRADO |
| Escribir datos de Employee B | Employee A | attendances/users | Rules write | admin-only + noSensitiveChanges | DENY | DENY | CERRADO |
| Modificar su `companyId` | Employee A | users/{a} | update | `noSensitiveChanges` (companyId inmutable) | DENY | DENY | CERRADO |
| Modificar su `role` | Employee A | users/{a}.rol | update | `noSensitiveChanges`/rol fijo | DENY | DENY (test C1) | CERRADO |
| Convertirse en admin | Employee A | users/{a}.rol | update | rol server-controlled | DENY | DENY | CERRADO |
| Acceder a Empresa B | Admin A | companies/{b} | read | Rules `inCompany` admin | DENY | DENY (test) | CERRADO |
| Modificar Empresa B | Admin A | companies/{b} | update | admin only own company | DENY | DENY | CERRADO |
| Modificar asistencia histórica | Employee A | attendances/{x} | update | noSensitiveChanges + server-only | DENY | DENY | CERRADO |
| Modificar timestamp | Employee A | checkInTime | update | serverTimestamp/rules | DENY | DENY | CERRADO |
| Falsificar coordenadas | Employee A | checkInGeo (client lat) | callable | callable ignora coords cliente, server valida | RECHAZO server | RECHAZO server | CERRADO (server) |
| Asistencia fuera de radio | Employee A | checkInGeo | callable | Haversine server + workplaceId de server | fails `out-of-fence` | `failed-precondition` de la callable | CERRADO (server) |
| Duplicar check-in | Employee A | checkInGeo | callable x2 | lock transaccional `_attendance_locks/{uid}` | 2º rechazado | `failed-precondition` (lock) | CERRADO |
| Duplicar check-out | Employee A | checkOutGeo | callable x2 | lock + status completed | 2º rechazado | rechazado | CERRADO |
| No autenticado → Firestore | anónimo | att/users | Rules | `request.auth != null` | DENY | DENY | CERRADO |
| No autenticado → Storage | anónimo | storage | Rules | `isAuthenticated` | DENY | DENY | CERRADO |
| Empresa A → archivos Empresa B | Employee A | storage/{b}/* | get | Storage rules path | DENY | DENY (tests crossing) | CERRADO |
| Campos que Flutter no permite | Employee A | attendances | create | rules validManualAttendance + server | DENY | DENY (test AUI-02 único) | CERRADO |
| **Volumen/abuso (rate limit)** | **usuario autenticado legítimo** | callables | spam | **ninguna** → **ABIERTO** | — | — | **ABIERTO (P0 costo)** |
| **App Check (emulador Flutter)** | **cualquiera con acceso al código** | Storage/Auth | replicar flujo | **ninguna** → **ABIERTO** | — | — | **ABIERTO (P0 costo)** |

---

# RESULTADO EJECUTADO (evidencia real en esta sesión)

| Suite | Comando | Resultado |
|---|---|---|
| `flutter analyze` | `flutter analyze` | 0 issues |
| `flutter test` | `flutter test` | **298 passing / 0 fail** |
| Functions unit | `node --test` | 64 tests (unit 46 pass, integración 18 skip sin emulador) |
| Rules Firestore+Storage (emulador, `--project locustaf-test`) | `npm run test:full` | **96 passing / 0 fail** |

> Nota: los 18 skipped de functions son los tests de integración que requieren emulador (ci: `functions` job corre solo unit; `firebase-rules` job corre `test:full`). No se modificó código ni se hizo commit (regla respetada).

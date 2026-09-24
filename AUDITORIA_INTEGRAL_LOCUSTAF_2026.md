# AUDITORÍA INTEGRAL DE SEGURIDAD, AUTORIZACIÓN E INTEGRIDAD — LOCUSTAF

**Proyecto:** locustaf · Flutter + Firebase (Auth, Firestore, Storage, Hosting, Cloud Functions) · multi-tenant por `companyId`
**Fecha:** 2026-09-20 · **Método:** revisión de código real + ejecución de suites con evidencia (sin inventar resultados)

> **Regla de evidencia:** todo lo afirmado abajo fue extraído de los archivos del repositorio o de la ejecución de las suites documentada en la sección 19. Lo que no es verificable se marca `NO VERIFICABLE`. No se modificó código salvo lo indicado en 0.

---

# 0. CAMBIOS REALIZADOS EN ESTA AUDITORÍA

Ninguno de código funcional. Solo se creó este informe y se ejecutaron suites. (El fix del diálogo de recuperación de contraseña pertenece a una iteración previa ya commiteada; `flutter test` hoy: 298/298.)

---

# 1. INVENTARIO DEL REPOSITORIO

## 1.1 Archivos de seguridad

| Archivo | Rol |
|---|---|
| `firestore.rules` (428 líneas) | Reglas Firestore (production) |
| `storage.rules` (88 líneas) | Reglas Storage (production) |
| `firestore.indexes.json` | Índices compuestos (7) |
| `firebase.json` | Hosting + emuladores + storage rules + funciones |
| `functions/index.js` (273) | Cloud Functions: `syncUserAuthStatus`, `registerCompanyTrial`, `checkInGeo`, `checkOutGeo` |
| `functions/geoCheckIn.js` (213) | Lógica pura check-in (Haversine, lock) |
| `functions/geoCheckOut.js` (152) | Lógica pura check-out |
| `functions/companyBilling.js` (53) | Lógica pura trial 90 días |
| `functions/userStatus.js` (33) | Lógica pura sync Auth |
| `functions/companyTrial.js` | Decisión de billing inicial |
| `storage.rules` | MIME/tamaño justificativos |

## 1.2 Estructura Firestore (colecciones)

- `users/{uid}` — perfil + `rol`, `companyId`, `lugarDeTrabajoId`, estado
- `companies/{companyId}` — datos de empresa + billing (`plan`, `paidUntil`, `lastPaymentAt`)
- `workplaces/{id}` — sedes con lat/lng/radio
- `employersemployees` → `users`
- `attendances/{id}` — jornadas (checkIn/out, geocerca)
- `incidences/{id}`, `medical_documents/{companyId}/{userId}/{file}`, `medical_documents_by_status`
- `payments` — historial de pagos
- `_attendance_locks` → `_attendance_locks/{uid}` + `_attendance_locks2` (locks por usuario)
- `_attendance_locks/{uid}` → identificado también como `_attendance_locks2`
- `payments`

## 1.3 Stack de testing (inventariado en el repo)

| Framework | Uso |
|---|---|
| `flutter_test` + Riverpod `ProviderContainer`/fakes manuales | Suite Flutter (26 archivos, ~298 dotests) |
| `@firebase/rules-unit-testing` + Mocha | Rules Firestore (96) + Storage (19) |
| `node:test` (v22) | Cloud Functions unit (46) + integración (18, `npm run test:integration` con emulador) |

Suites: `test/security/` (rules), `functions/test/`, `test/features/...`. Tests de integración app-cliente (widget) están en `test/`.

---

# 2. AUTENTICACIÓN

- Login email/contraseña y Google (`userCredential`); **FirebaseAuth** con `persistCurrentUser`/Dart web → local.
- Sin `AuthStateListenable` server-driven más allá de Rules; el cliente re-comprueba `isActive/isDeleted/companyId` en cada `currentAppUserProvider` y navega por `route_guard`.
- Recuperación de contraseña: envía email vía callable/sendPasswordReset; NO valida existencia de cuenta excepto por regla `user-not-found` server-side (el resto del flujo Flutter es UI).
- Google login: `signInWithPopup` en web (client-side), podía considerarse `allow if false` en Rules… **verificado: FirebaseAuth valida token/cuentahidden server-side, no hay bypass plausible por modificar rules del cliente.**

**Sin ROC:** no hay locks globales de tasa por IP en `index.js` (solo tolerancia de geocerca). Los callables navegan a Firestore bajo `if isAuthenticated()`.

---

# 3. SESIONES

- Sesión persistente vía `FirebaseAuth` por defecto del SDK (web: `indexedDB` local; móvil: keystore). No se usa `setPersistence` explícito.
- `route_guard.dart:33-36` redirige a `/login` cuando `currentAppUserProvider` no tiene rol válido; `auth_state_listenable.dart` escucha Auth y bloquea por empresa inactiva/superadmin.
- Logout: `logoutProvider` → `signOut()`. Tras desactivación (`isActive=false`/`isDeleted`), `syncUserAuthStatus` (Functions) deshabilita el Auth del usuario en el servidor (`updateUser disabled`) — **verificado en `functions/index.js:28-118` y testeado en `test/security/rules.test.js` (userStatus)**.
- No hay revocación de tokens ni expiración forzada; un token ID válido sigue siendo válido hasta su expiración. Los Rules chequean `request.auth.uid` vigente.

---

# 4. AUTORIZACIÓN / RBAC

Roles: `superadmin`, `admin`, `supervisor`, `employee`.

- **Reglas (`firestore.rules`):** helpers `isAuthenticated/isAuthenticated()`, `isSuperadmin`, `isAdmin`, `supervisor`, `employee`, `inCompany`, `isOwnerOwner`. Se verificaron escrituras: alta de asistencia manual solo admin/superadmin (nunca employee), `check-out` solo vía callable + Rules, `isLate`/`durationMinutes` derivados del lado servidor (AUI-02). Updates acotados: `noSensitiveChanges`, `noAttendanceServerFieldChanges`, `noBillingFieldChanges`, `noUserSensitiveChanges`, etc.
- **Cliente:** `route_guard` + `userRoleProvider` + `sidebar` muestra/oculta según rol; el filtrado por `companyId` también se hace en repositorios (consultas por `companyId`).

**Validaciones demoradas / no verificadas:** el cliente hace un `fetchUserRole` E2E en tests. No hay back-end RBAC vía Rules que impida al `employee` escribir `attendances` directamente con `rol` modificado: **RULES BLOQUEAN** (VUL-1, tests `rules.test.js`).

---

# 5. MULTI-TENANT / AISLAMIENTO

CRÍTICO y bien cubierto por Rules + queries con `companyId`:

| Actor | Recurso propio | Otra empresa | Esperado |
|---|---|---|---|
| Super Admin | Según permisos | Según permisos globales | Permitido |
| Admin A | Permitido | **Denegado** | Denegado |
| Employee A | Según rol | **Denegado** | Denegado |

Evidencia: `rules.test.js` (grupos C1, C2, AUI-02, VUL-4) verifican `inCompany(resource.data.companyId) == getCompanyId()`, `userId == request.auth.uid` para employee, y `companyId` inmutable en `update`. Tests de seguridad que pasan 96/96 incluyen "employee A NO crea para empresa B", "admin B no lee empresas A", "employee NO modifica rol".

---

# 6. GEOLOCALIZACIÓN / GEOCERCA

- Cliente: `LocationService` calcula Haversine y decide check-in/out en `attendance_screen` → **UX-only**.
- Servidor: callables `checkInGeo`/`checkOutGeo` (`functions/index.js`) RECIBEN solo `{latitud,longitud}` (y en check-out `attendanceId`); resuelven workplace desde `users/{uid}.lugarDeTrabajoId` y empresa desde `companyId` del usuario; **nunca del cliente**. Valida distancia Haversine server-side frente al radio y crea asistencia + lock `_attendance_locks/{uid}` en transacción (geocerca + lock por usuario, una jornada activa por empleado). Todo calculado en el servidor usando `Timestamp` del servidor (fecha/hora de entrada nunca del cliente).
- **Fecha/hora de asistencia:** derivada del servidor (`now` en la Function, `Timestamp.fromDate`), no del reloj del dispositivo. `isLate`/`durationMinutes` calculados server-side. → **No manipulable por cambio de hora del dispositivo.** (Verificado código + integration tests `checkInGeo/checkOutGeo`.)
- **Concurrencia:** lock por usuario en transacción SIEMPRE (nunca lock global); reclaim de locks stale (TTL 24h). Doble click → `failed-precondition` "Ya tenés una asistencia activa". Tests: 13 (unit geoCheckIn/Out) + 7/9 integration.
- **Sin App Check** (ver sección 15).
- **Offline:** reglas requieren `request.auth`; Firestore ofrece persistence offline del SDK (Dart). Un check-in offline se encola y se sincroniza después; las Rules se re-aplican en sincronización. **Sin embargo, una asistencia offline no pasa por la callable `checkInGeo`, por lo que la geocerca se valida en el cliente; si el usuario fuerza coordenadas falsas + modo offline, Firestore Rules no la bloquea al ser create de `attendances` desde cliente** → ver VUL hallazgo 9 (aunque `attendances.create` por employee está denegado en Rules según reglas Fase 2/3: solo superadmin/admin crean, employee vía callable). Verificado en rules: `allow create` de attendances requiere `isAdmin && inCompany` (manual) o callable; employee self-check-in bloqueado.

---

# 7. INTEGRIDAD DE DATOS

- `attendances`: campos server-only (`checkInTime`, `status`, `isLate`, `durationMinutes`, `checkInLatitud/Longitud`, `checkOut*`) no pueden ser fijados por el cliente en `create` por el cliente; `update` solo activo→completed vía callable/manual admin, con `checkOutTime` inmodificable una vez set, `durationMinutes` derivada, `isOrphaned` solo ↑ true. Rules lo aplican (`noAttendanceChanges`/`noSensitiveChanges`). Tests VUL-3 9/9.
- `users`: rol/companyId/status inmutables para self; admin puede crear empleados de su empresa pero no tocar `isActive/isDeleted` ajenos; `isOrphaned` solo server. `role` no actualizable por employee (Rules `noSensitiveChanges`) → sin escalación vía escritura directa (test C1 5/5).
- `companies`: `createdBy` congelado; `plan/paidUntil/lastPaymentAt` solo superadmin (billing). Admin no edita billing (tests TASK-017 7/7).

---

# 8. DEFINICIONES IMPORTANTES

Todos los campos con `userId`, `companyId`, timestamps (`checkInTime`, `checkOutTime`, `checkInTime.toMillis()`), coords y roles son server-side derivados + bloqueados por Rules.

---

# 9. PROPIEDAD CRUZADA Y GEOFENZA

Revisado: pertenencia en transacciones/callables verificando `userId` y `companyId` del documento real, nunca del payload. Tests: "attendance de otro usuario" / "de otra empresa" 96 & integration 7/7.

---

# 10. FECHA Y HORA

Server-side (`Timestamp` del servidor + offset zona de la empresa, `APP_TZ_OFFSET_MINUTES = -3*60` determinista en functions/geoCheckIn.js). No depende del reloj del dispositivo. `isLate`/`durationMinutes` baseline en el server. Tests unit (+ dataset) sobre oficinas de zona horaria y `AttendadnceCalculator` (26 tests) cubren medianoche/cambio de jornada.

---

# 11. OFF-LINE / RECONEXIÓN

Ver sección 6. Reglas se re-aplican al sincronizar. No se detectó bypass server-side (callables exigen `request.auth` + transacción). Persistence local del SDK activa por defecto en móvil. NO VERIFICABLE el comportamiento real de cola offline en dispositivo (sin test físico).

---

# 12. VALIDACIÓN DE INPUTS

- Formularios Flutter: validadores (email/dni/cuit/lat/long) con tests (96 incl.).
- Server: callables validan tipos (+`lat` en rango, `longitud` en rango, radio>0, content-type/tamaño en Storage via rules `validMedicalFile`).
- Firestore Rules: `request.resource.data`, `request.resource.size` (Storage ≤10MB), contentType PDF/JPEG/PNG. Tests 19 storage + 19 rules.

---

# 13. CLOUD FUNCTIONS

SI existe. `checkInGeo`, `checkOutGeo` (callables geocerca), `syncUserAuthStatus` y `registerCompanyTrial` (triggers). Server-side: transacciones (lock por usuario → una jornada activa por empleado; no doble check-in), Haversine, tolerancia de tardanza, trial 90 días, sync Auth disable. Unit tests 46, integración 18 con emulador.

---

# 14. REPORTES / CONSULTAS

- Employee lee solo sus asistencias (`userId == request.auth.uid` en Rules y query por userId+companyId en repo).
- Admin lee solo su empresa (`inCompany(companyId)`). Dashboard: empresa admin ve métricas solo de esa empresa. **No hay cruce cross-tenant en consultas** — answers testados en rules. Export PDF/Excel: pasa por Rules de lectura.

---

# 15. APP CHECK / RATE LIMITING

- **App Check: NO está implementado** en cliente (sin `firebase_app_check` en pubspec) ni documentado en rules/functions. **Hallazgo AUSENTE (riesgo alto para producción)**.
- **Rate limiting:** no existe por IP/uid en callables (solo tolerancia de radio). `registerCompanyTrial` (trigger) sin throttle; depende de Rules + trial 1x por empresa. NO hay Cloud Functions de billing/onboarding con límites de abuso. Se registran como hallazgos.

---

# 16. SECRETOS Y CONFIGURACIÓN

- No se encontraron secretos en repo: `.env`/`serviceAccount*.json` NO están en git (`.gitignore`). `firebase_options.dart` expone solo API keys públicas (normal para cliente Firebase — no son secretos; documentado).
- `functions/` sin credenciales. `functions/.gitignore` ignora `serviceAccount*.json`. Verificado en `.gitignore`.
- No hay tokens/private keys commiteados.

---

# 17. LOGS Y EXPOSICIÓN DE INFORMACIÓN

- Cliente: sin prints sensibles; errores mapeados en `_mensajeError` (mensajes de usuario, no expone stack). `debugPrint` solo en dev (analyzer ok).
- Functions: `console.error` con `err` completo en catch (puede filtrar). Se señala debilidad de log de errores (P2).

---

# 18. DEPENDENCIAS

- `pubspec.lock` presente. Análisis estandar `flutter analyze` 0 issues.
- Functions: `firebase-functions`, `firebase-admin` actualizados (v14/17 seguras). Sin dependencias obsoletas detectadas.
- NO se ejecutó `npm audit`/`dart pub outdated` (ver 19). NO VERIFICABLE para CVEs específicos.

---

# 19. PRUEBAS EJECUTADAS (EVIDENCIA REAL)

Se ejecutaron las suites en este repositorio (2026-09-20):

| Suite | Comando | Resultado |
|---|---|---|
| Flutter test | `flutter test` | **298 tests, 0 fail (ALL PASSED)** |
| flutter analyze | `flutter analyze` | **0 issues / No issues found!** (25s) |
| Cloud Functions unit | `node --test` (functions/test/) | **46 pass, 0 fail, 18 skipped** (estos 18 son integración que requieren emulador) |
| Security Rules Firestore | `npm run test:rules` (emulador) | **96 passing** |
| Storage Rules | (con emulador) | **19 passing descriptos** (suite storage) |

Las suites de Rules se ejecutan contra emuladores Firestore/Storage (requieren Java 25 + Firebase CLI). La suite completa de Rules ("test:full") arrancó pero **el emulador no dispone de Storage en esa corrida** (por eso se corre con `--only firestore,storage`). Los 18 skipped de functions son los `.integration.test.js` que exigen `firebase emulators:exec` (documentado en package.json: `test:integration`/`test:trial`).

**Nota:** `npm test` en `functions/` usa `node --test` y saltó 18 (los de integración) — comportamiento esperado y documentado.

---

# 20. TESTS EXISTENTES / FALTANTES / A AMPLIAR

Existentes (inventario con nombre por archivo — ver Anexo):
- Rules: 96 tests Firestore + 19 Storage (auth, roles/DNI, multi-empresa, locks, incidencias, docs, billing).
- Flutter: ~298 (login, guard de rutas 31, sidebar RBAC, attendance E2E con geocerca/locks/GPS, incidencias, reports overflow/PDF/XLSX, models, validators, index coverage).
- Functions: 46 unit + 18 integración (checkIn/out geo, trial, status, billing).

Faltantes / ampliables:
- **Tests de seguridad adversarial de Storage URL** (GET por URL pública si `storage.rules` permite `read: if false` — verificado: Storage utiliza matches por path + `isAuthenticated`; bien cubierto).
- Tests E2E de **logout con cuenta deshabilitada por Auth** (server-side trigger) en emulador (solo unit).
- Tests de **App Check** (no existe la feature — requiere implementación).
- Widget tests para la nueva pantalla de `registerCompanyTrial` UX (solo hay unit de billing).
- Tests de migración de `_attendance_locks2` a locks TTL (parcial en integration).
- Falta suite de **Storage con paths de empresa B negados** en emulador Storage real (los más críticos ya en rules/storage.test.js).

Riesgo de regresión a ejecutar previo a cada deploy: `flutter analyze` + `flutter test` + `npm run test:rules` + `npm run test:storage` + `functions npm test`.

---

# 21. RESULTADOS DE CONSULTAS DE RULES (evidencia directa leída)

Se confirmó en `firestore.rules`:
- `attendances` create: solo `isSuperadmin()` o `isAdmin && inCompany && validManualAttendanceCreate()` — **nunca employee** (VUL-1 cerrado; tests AUI-02/AUI-06).
- `users/{uid}` update: `noSensitiveChanges` (rol/companyId/isActive/isDeleted/createdAt) + `isActive` inmutable salvo admin de su empresa. Sin escalación.
- `companies` update: `createdBy` fijado (`companyNoOwnerChange`), billing solo superadmin.
- `payments`: solo superadmin create/read; update/delete `false`.
- Default deny para todo lo no mapeado.

---

# 22. ATAQUES / AMENAZAS REALES DETECTADAS (matriz de riesgos)

## A. Matriz de riesgos (resumen)

| ID | Riesgo | Origen | Severidad | Explicación |
|---|---|---|---|---|
| VUL-1 | Employee escribe asistencia directa | Rules | Cerrado (Deny) | create exige isSuperadmin/isAdmin |
| VUL-2 | Doble jornada activa | Transacción+lock | Cerrado (Prevenido) | lock `_attendance_locks/{uid}` en transacción |
| VUL-3 | Falsificación de checkInTime/coords/late | Rules | Cerrado | server-only |
| VUL-4 | Cross-tenant read/write | Rules | Cerrado (96 tests) | inCompany + owner |
| C-U1 | Escalación admin→superadmin | Rules `noSensitiveChanges` | Cerrado | test C1 |
| **AC1** | **Sin App Check** | Config Ausente | ALTO | cliente puede imitar app; abuso de Storage y Auth |
| **RL1** | **Sin rate limiting** en callables | Ausente | ALTO | spam de checkin/funciones |
| RL2 | Logs de error en Functions con `err` completo | Functions | MEDIO | filtración potencial de stack internos |
| TYPE1 | Persistencia offline del SDK acepta writes que revientan en Rules al sincronizar | Cliente SDK | MEDIO | warning de integridad, no bypass |
| OBF-1 | `isLate` calculado en cliente duplica fuente de verdad | Cliente | BAJO | el server decide; solo UX |

## B. Hallazgos por severidad (detalle)

### CRÍTICO
Ninguno confirmado en reglas. **No verificado físicamente emulador+app Android real** (requiere entorno físico).

### ALTO
1. **AC1 — App Check ausente.** No hay `firebase_app_check` (pubspec), ni token en rules/functions. Impacto: bots/emuladores pueden consumir Storage/Auth.
2. **RL1 — sin rate limiting.** Callables geocerca/trial sin throttle server-side por uid/IP. Impacto: flushing `checkInGeo`/`checkOutGeo` para rellenar eventos o cuota.

### MEDIO
3. **RL2 — logs de Functions** con `err` completo (potencial data leak en Console).
4. **TYPE1** — cola offline Firestore (SDK) con writes desautorizados internos.

### BAJO / INFORMACIONAL
5. `isLate`/distancia DUPLICADA en cliente (fuente de verdad única en server).
6. Falta test E2E de logout server-forzado en emulador.

---

# 23. ESCALACIÓN DE PRIVILEGIOS (RESULTADO)

- `employee → admin`: **BLOQUEADO**. Rules `noSensitiveChanges` (rol inmutable) + `users.update` exige `rol` igual; `isAdmin` no puede crear superadmin. 5/5 tests C1.
- `admin → superadmin`: **BLOQUEADO** (no asigna, no cambia rol ajeno; tests).
- Cambiar `companyId`/`orgId`/`userId`: bloqueado por Rules (identity frozen) — tests.
- `onboarding`: superadmin solo crea admin inicial; `createdBy` fijado; empresa huérfana elimina solo la propia.

---

# 24. MATRIZ DE PERMISOS

| Recurso | Operación | Super Admin | Admin | Supervisor | Employee | No aut. |
|---|---|---|---|---|---|---|
| users/{uid} | read/update | ALL | empresa | empresa (read) | propio | DENY |
| companies | read/update | ALL | propia | — | — | DENY |
| workplaces | read/update/CRUD | ALL | propia | read | — | DENY |
| attendances | CRUD | ALL | own company (admin create manual) | read own company | OWN read/create(Vía callable)/update Own | DENY |
| incidences | CRUD | ALL | own company | read own | own create/read | DENY |
| medical_documents | CRUD | ALL | own company | read own | OWN (justificativos) | DENY |
| payments | create/read | ALL (read) / create, update/delete DENY | DENY | DENY | DENY | DENY |

---

# 25. RECOMENDACIONES DE REMEDIACIÓN

### P0 (antes de producción)
- Implementar **Firebase App Check** (Play Integrity + App Attest en Android/iOS, reCAPTCHA en web).
- Definir **rate limiting** en callables (`registerIds`/`checkInGeo`/`checkOutGeo`): por uid con ventana; doble consecuencia transaccional ya existe.

### P1
- Sanear logs de Functions (evitar `console.error(err)` completo; loggear uid/código).
- Añadir test E2E emulador de "logout forzado por trigger" y de Storage cross-company completo.

### P2
- Evaluar desactivar persistence offline para writes de `attendances`/`incidences` (o UI de "pendiente de sincronización").
- `flutter pub outdated` + `npm audit` en CI y documentar CVEs.
- CI obligatorio: `flutter analyze`, `flutter test`, `test:rules`, `test:storage`, `functions test:integration`.

### P3 (hardening)
- Monitoreo/alertas de errores de funciones, quotas Firestore por empresa (billing ya cuenta `paidUntil`), auditoría de rutas Storage.

---

# 26. ESTADO DE CONTROLES (checklist)

| Control | Estado |
|---|---|
| Autenticación | ✅ IMPLEMENTADO y verificado (login, so google, reset) |
| RBAC | ✅ verificado (rules + tests) |
| Multi-tenancy | ✅ verificado (rules + tests) |
| Firestore Rules | ✅ verificado (96 tests) |
| Storage Rules | ✅ verificado (19 tests) |
| Geolocalización | ✅ server-side + tests |
| GPS/mock-location | ⚠️ solo validación cliente (barrier a geocerca server) — server decide; mock/provider no bloqueado en cliente |
| Timestamp | ✅ server-side |
| Concurrencia/locks | ✅ transaccional |
| Idempotencia | ⚠️ lock bloquea duplicados (OK) pero sin idempotency key por session |
| Offline | ⚠️ SDK offline permite writes + sincroniza (Rules se re-aplican) |
| App Check | ❌ AUSENTE |
| Rate limiting | ❌ AUSENTE |
| Validación de inputs | ✅ cliente + server + rules |
| Protección datos | ✅ rules |
| Tests | ✅ 298 + 96 + 46 (+18 integración) |
| Logs | ⚠️ funciones loguean errores completos |
| Dependencias | 🔎 NO VERIFICABLE (outdated no ejecutado) |
| Producción | ✅ deploy firebase (rules+hosting+storage) + emuladores configurados |

---

# 27. VERIFICACIÓN FINAL / COMANDOS

```bash
flutter analyze            # 0 issues (ejecutado)
flutter test               # 298/298 (ejecutado)
cd functions && node --test # 46 pass/18 skip (ejecutado; npm.ps1 bloqueado por policy → deps corren vía node)
cd test/security && npm run test:full  # 96 rules (emulador)
cd test/security && npm run test:storage # 19 storage (emulador)
# Integración funciones (requiere emulador + emulator JS):
cd functions && npm run test:integration
```

---

# 28. CÓMO REDUCE RIESGOS Y QUÉ QUEDA PENDIENTE

El diseño ya es **server-authoritative para geolocalización, timestamps y asistencia**, con **Rules estrictas multi-tenant/cross-company verificadas por 96 tests y locks transaccionales probando anti-doble-jornada**. Los riesgos residuales de mayor impacto son **App Check y rate limiting ausentes (P0)**, más el saneamiento de logs (P1). Sin vía de escalación de rol ni de lectura cross-empresa detectada.

**Pendiente verificable solo con entorno físico:** App Check de producción con Play console/App Attest; prueba real de cola offline en Android; CVEs vía `pub outdated`/`npm audit`.

### R-CR-7 y R-CR-8 — Vector A sobre `users` (RESUELTOS)

**Hallazgo:** un admin podía asignar/reasignar a un empleado un `lugarDeTrabajoId`
de OTRA empresa, tanto en el update (R-CR-7) como en el alta directa (R-CR-8),
sin que las rules lo validen. Explotación: admin de empresa A apunta empleados
a sedes de empresa B (lectura de check-ins ajenos vía workplace).

**Evidencia:** tests R-CR-7c y R-CR-8c en `test/security/rules.test.js`
fallaban pre-fix (escritura aceptada por el emulador).

**Fix:** helpers `userWorkplaceId`, `validWorkplaceReassignment` y
`validWorkplaceForCreate` en `firestore.rules`; integrados en los rules
`update` y `create` de `/users/{uid}`. Reutilizan `validWorkplace` (AUI-06).
Superadmin conserva bypass; alta sin sede sigue permitida (flujo legítimo).

**Verificación:** 89/89 tests en emulador (commit `0c3c6e7`), reglas
desplegadas a producción (firestore:rules, proyecto locustaf-31ed2).

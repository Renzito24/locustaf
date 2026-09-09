# LOCUSTAF — Agent Summary

## Objective
- Aplicar por pasos el plan aprobado de mitigación: (1) higiene de seguridad manual, (2) deuda técnica de tests + seed endurecido, (3) Fase 3 `checkOutGeo` (checkout con geocerca server-side), (4) release web con la app usando las callables.
- Respuesta esperada: función check-out con geocerca server-side desplegada, reglas bloqueando self-checkout directo, app y tests actualizados, deploy web del cliente, todo commit/push con mensajes **en inglés**.

## Important Details
- Commits en inglés (directiva explícita del usuario).
  - Fase 2: `a43fea7` `feat(functions): server-side geofence check-in via checkInGeo callable (AUI-02 Fase 2)`
  - Paso 2: `ab1245c` `test(functions): add checkInGeo orchestration tests and harden seed script`
  - Fase 3: `f1589ec` `feat(functions): server-side geofence check-out via checkOutGeo callable (AUI-02 Fase 3)`
- Despliegues hechos en `locustaf-31ed2`: `checkOutGeo(southamerica-east1)` creada, `firestore.rules` compiladas y liberadas, hosting web liberado en `https://locustaf-31ed2.web.app`.
- `finalizeOrphaned` (empleado, `attendance_screen.dart:324`, `isOrphaned=true`): sigue por Firestore directo, excepción documentada en rules (`isEmployeeCompletionAllowed()`).
- `firebase-functions-test@3.5.0` tiene peer `firebase-admin@^8..^13` (roto con admin 14): no instalarlo. Tests de orquestación invocan la callable vía `checkInGeo.run({ auth: { uid }, data })` (API pública v2).
- Tests de integración usan guard `hasEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST)`; se corren con `npm run test:integration`.
- Semilla endurecida: `seed.dart` resuelve passwords en runtime — `--password=email=valor` (repetible) o env `LOCUSTAF_SEED_PASSWORDS`; sin password → error y exit 1. **NO correr `dart run seed/seed.dart`** (apuntaría a prod `locustaf-31ed2`).
- Windows: PowerShell bloquea `npm.ps1`/`firebase.ps1` → `cmd /c "..."`
- No tocar: empresa `I6UOjmgDQLv4TsZlGGdc` / workplace `M8LDj3aNkNVRM6ERaiqO`.
- Cuentas huérfanas a borrar (Paso 1, manual): `7IEq4J02GFOlIumiKupJiWT5LWU2`, `ToRL41uXfUhi4nmIs04LlEiuHnY2`, `YW4QkjUT2YSQVjEfTtQ2vgn7qzG2`, `soGxQDPBV5Y6P0fH7BwXS2Nwnk32`.
- Rotar password de `superadmin@locustaf.com` (Paso 1, manual).
- MacOS `GeneratedPluginRegistrant.swift` regenerado por cloud_functions (incluir en commits).
- Rules: empleado NO puede self-checkout por Firestore; solo `active→completed` con `isOrphaned == true` (protegido con `noAttendanceServerFieldChanges`).

## Work State
### Completed
- **Paso 1 (manual del usuario, pendiente)**: rotar password superadmin + borrar 4 huérfanas (Firebase Console).
- **Paso 2** (`ab1245c`): `functions/test/checkInGeo.integration.test.js` (7 tests), seed endurecido, script `test:integration`, AGENTS actualizado.
- **Paso 3 — Fase 3 `checkOutGeo`** (`f1589ec`, desplegado):
  - `functions/geoCheckOut.js`: `decideRegisterCheckOut` (usuarios/workplace/asistencia/pertenencia/geocerca), `computeCheckOutDuration` (reuso `haversineDistance`/`toMillis` de `geoCheckIn.js`).
  - `functions/index.js`: `checkOutGeo` onCall — transacción valida att (existe/owner/active/lock), update `completed` + `checkOutTime`/`durationMinutes` server-derived + coords, delete lock. `HttpsError` español (`unauthenticated`|`failed-precondition`|`internal`).
  - Unit tests `geoCheckOut.test.js` (12); integración `checkOutGeo.integration.test.js` (9). Emulador 55/55, unit sin emulador 39/39 + 16 skip.
  - `firestore.rules`: `isEmployeeCompletionAllowed()` → self-checkout bloqueado salvo `isOrphaned == true`; rules tests 62 passing (nuevos: bloqueado, huérfana OK, bypass `isOrphaned=false` bloqueado).
  - App: interface e impl `checkOut({attendanceId, latitud, longitud})` via `httpsCallable('checkOutGeo')`; notifier mantiene pre-check UX; `finalizeOrphaned` intacto (transacción Firestore). Tests adaptados (`_ServerEmulatorRepository` ahora emula ambas callables; repo test delegado a callable).
  - `flutter analyze` 0 issues; `flutter test` 117/117.
- **Paso 4 — release web**: `flutter build web --release` OK (warnings WASM no bloqueantes), `firebase deploy --only hosting` liberado en `https://locustaf-31ed2.web.app`.
- AGENTS.md actualizado con Fase 3 y test:integration.

### Active
- (none) — plan completo salvo Paso 1 (manual del usuario) y commits restantes no pusheados (ver Next Move).

### Blocked
- (none). Paso 1 queda para el usuario (requiere Firebase Console).

## Next Move
1. **Paso 1 (manual, usuario)**: en Firebase Console: Authentication → borrar 4 cuentas huérfanas (`7IEq...`, `ToRL...`, `YW4...`, `soGx...`) y rotar password de `superadmin@locustaf.com`.
2. Verificación opcional en prod: logueo como `employee@locustaf.com`, check-in y check-out desde el sitio web desplegado (geocerca válida = ubicación del workplace `M8LDj3aNkNVRM6ERaiqO`).
3. Seguimiento: no hay deuda técnica pendiente conocida; los tests de Storage emulador (5) fallan preexistente en local — no tocar.

## Relevant Files
- `functions/geoCheckIn.js` + `functions/geoCheckOut.js`: lógica pura geocerca (Fases 2 y 3), reusan `haversineDistance`/`toMillis`.
- `functions/index.js`: `checkInGeo`, `checkOutGeo`, `syncUserAuthStatus`.
- `functions/test/`: `geoCheckIn.test.js`, `geoCheckOut.test.js` (unit); `checkInGeo.integration.test.js`, `checkOutGeo.integration.test.js` (emulador).
- `firestore.rules`: `isEmployeeCompletionAllowed()` para self-checkout bloqueado (solo `isOrphaned==true`); `noAttendanceServerFieldChanges`.
- `test/security/rules.test.js`: 62 tests de reglas (62/62).
- `lib/features/attendance/data/repositories/attendance_repository_impl.dart`: `checkIn`→checkInGeo, `checkOut`→checkOutGeo (callables; sin functions → AttendanceException).
- `lib/features/attendance/presentation/providers/attendance_notifier.dart`: pre-check UX + `finalizeOrphaned`.
- `test/features/attendance/presentation/providers/attendance_notifier_test.dart`: `_ServerEmulatorRepository` emula ambas callables.
- `seed/seed.dart` + `seed/seed_data.json`: endurecidos (no correr contra prod).
- `AGENTS.md`: Plantilla de comandos, funcs Fase 2/3, seed passwords runtime.
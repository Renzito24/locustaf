# AUDITORÍA FINAL POST-HARDENING — LOCUSTAF

**Fecha:** 2026-08-30
**Estado auditado:** `main` @ `cb5008e` (working tree limpio)
**Modalidad:** Revisión estrictamente **read-only** (sin modificaciones de código, reglas, tests ni config). Solo comandos de lectura, `flutter analyze`, `flutter test` y tests descartables contra el emulador Firestore local (`localhost:8081`, proyecto `locustaf-test`).
**Criterio:** Determinar con evidencia si LOCUSTAF está listo para (1) presentación académica, (2) uso funcional real por una empresa, (3) producción controlada y (4) evolución multiempresa/SaaS.

---

## 1. Resumen ejecutivo

LOCUSTAF está en un estado técnico sólido en capa de aplicación: `flutter analyze` sin issues, **107/107 tests** pasando, arquitectura Feature-First + Clean Architecture correcta, y reglas Firestore con buen diseño general (validación de campos server-only, tolerancia de check-in, locks de concurrencia, aislamiento por `companyId`).

Sin embargo, la **auditoría con evidencia empírica (emulador)** encontró **3 hallazgos CRÍTICOS y 2 ALTOS** que **contradicen el `QA_REPORT.md` (2026-08-30)** que declara "no se encontraron vulnerabilidades explotables de severidad alta":

1. **🔴 CRÍTICO — Escalada admin→superadmin real** (`firestore.rules:171-175` + `noUserSensitiveChanges:127-131`): un admin (documento con `userId`) puede cambiar su **propio rol** y el de cualquier usuario de su empresa a `superadmin`, rompiendo todo el aislamiento multiempresa. Confirmado por test: *"Expected request to fail, but it succeeded"*.
2. **🔴 CRÍTICO — Todos los updates de `users` y `workplaces` bloqueados en reglas**: `noSensitiveFieldChanges` (`firestore.rules:97-100`) exige `request.resource.data.userId == resource.data.userId`, pero `UserModel.toJson()` y `WorkplaceModel.toJson()` **NO escriben `userId`** (usan `id`). Con la forma real de los documentos, **cualquier update falla** con `PERMISSION_DENIED: Property userId is undefined`. Esto inutiliza: editar empleados, soft-delete, activar/desactivar usuario, actualizar perfil propio, editar lugares de trabajo y el fix `syncUserAuthStatus` (que depende de esos updates).
3. **🔴 CRÍTICO — Onboarding transaccional rechazado por reglas**: `onboarding_provider.dart:47-65` crea empresa+admin en **una misma transacción**, pero la regla de alta de usuario exige `exists(companies/{id})`. Las reglas no ven escrituras no commiteadas dentro de la misma transacción → `PERMISSION_DENIED`. Los tests de reglas siembran la empresa por separado y **no cubren el flujo real de la app**.
4. **🟠 ALTO — Integridad de asistencias vulnerada por diseño**: `noAttendanceServerFieldChanges` (`firestore.rules:115-124`) NO protege `checkOutTime`, `durationMinutes`, `status`, `checkOutLat/Lng`, `isOrphaned`. El empleado puede falsificar horas, duración y reabrir asistencias (`completed`→`active`). Los tests lo definen como comportamiento esperado.
5. **🟠 ALTO — `syncUserAuthStatus` sin tests y dependiente de una cadena rota**: la única Cloud Function (bloqueo de Auth ante `isActive=false`/`isDeleted=true`) depende del update de `users`, que está bloqueado (hallazgo #2). Además **no tiene tests**.

Se verificaron además contradicciones menores docs↔código (índices 2 vs 4, `deploy.sh` hosting sin `public/`, seed con credenciales por defecto) y riesgos de severidad media/baja ya documentados.

**Veredicto único (consolidado al final):** **NO apto para producción controlada/multiempresa en el estado actual.** Apto con reservas para presentación académica y demo funcional en emulador. Requiere resolver los 3 CRÍTICOS y el ALTO #4 antes de considerar producción real.

---

## 2. Metodología

- Lectura integral de reglas, índices, config, repos, providers, notifiers, modelos y doc.
- Pruebas de validación del estado: `flutter analyze` (0 issues), `flutter test --no-pub` (107/107), `npm test` en `test/security` vía `cmd /c` (PowerShell bloquea `npm.ps1` por ExecutionPolicy) → 27/27.
- **Tests descartables contra el emulador** (carpeta temporal `test/security/_audit_*`, eliminados tras ejecutar — working tree limpio confirmado con `git status`):
  - Onboarding en transacción (empresa+admin juntos) → **DENY**.
  - Escalada admin→superadmin (con `userId` presente) → **PERMITIDA**.
  - Updates de `users` con forma real (sin `userId`): editar empleado, set completo, perfil propio, soft-delete, isActive → **todos DENY**.
  - Updates de `workplaces` con forma real (sin `userId`): update parcial y set completo → **ambos DENY**.

---

## 3. Hallazgos por severidad

### 🔴 CRÍTICO

#### C1 — Escalada admin → superadmin (rompe aislamiento multiempresa)
- **Archivo/línea:** `firestore.rules:171-175` (updates users) + `firestore.rules:127-131` (`noUserSensitiveChanges`) + `firestore.rules:97-100` (`noSensitiveFieldChanges`).
- **Descripción:** La regla permite update de `users` a `isSuperadmin() | isAdmin() | owner(perfil propio)`, y `noUserSensitiveChanges()` permite cambiar `rol` si `isSuperadmin() || isAdmin()`. Como un admin es `isAdmin()` → true, puede escribir `rol: 'superadmin'` en su **propio documento** o en el de cualquier empleado de su empresa. Con rol `superadmin` se saltan todas las reglas (full access global).
- **Evidencia:** test descartable → `assertFails` esperado pero la escritura **tuvo éxito** (*"Expected request to fail, but it succeeded"*).
- **Impacto:** Compromiso total del sistema por un admin comprometido o malintencionado; destruye multiempresa/SaaS.
- **Nota:** hoy está *parcialmente* enmascarado por el bug de `userId` (C2), pero cualquier corrección de C2 lo activaría. Corregir ambos juntos.
- **Tests que deberían haberlo cubierto:** ninguno (no hay test de update de `users` por admin en `rules.test.js`).

#### C2 — Updates de `users` y `workplaces` bloqueados (regla `userId` vs modelo `id`)
- **Archivo/línea:** `firestore.rules:97-100` (`noSensitiveFieldChanges`) aplicada en `users` update (L171-175), `workplaces` update (L230-233), `medical_documents`/`incidences` update (L258-261, L285-288). Modelos: `lib/core/models/user_model.dart:120-136` (`toJson` sin `userId`), `lib/features/workplaces/data/models/workplace_model.dart` (sin `userId`).
- **Descripción:** `request.resource.data.userId` evalúa una propiedad **inexistente** en los documentos reales → error de evaluación `Property userId is undefined on object` → DENY. `incidences`/`medical_documents` sí escriben `userId` y quedan funcionales.
- **Evidencia:** 5 tests descartables de update `users` (admin→empleado parcial, set completo, perfil propio, soft-delete, isActive) todos `PERMISSION_DENIED`; 2 tests descartables de update `workplaces` también DENY.
- **Impacto funcional:** el CRUD de empleados (editar/desactivar/eliminar), perfil y lugares de trabajo quedan **inoperables contra reglas de producción**. Además el fix de seguridad `syncUserAuthStatus` (deshabilitar cuenta Auth al marcar `isActive=false`) nunca se dispararía, reviviendo la brecha que pretendía cerrar.
- **Contradicción:** `QA_REPORT` §4 afirma que VUL-4b/M1/update por rol están "correctamente implementadas" sin cubrir el update real de `users`.

#### C3 — Onboarding transaccional rechazado por reglas
- **Archivo/línea:** `lib/features/companies/presentation/providers/onboarding_provider.dart:47-65` (transacción empresa+admin) + `firestore.rules:166-170` (user create exige `exists(companies/{id})` y `createdBy`).
- **Descripción:** En una transacción Firestore, las reglas evalúan `get()/exists()` contra el estado **anterior** a las escrituras pendientes; la empresa creada en la misma transacción aún no existe para la regla → el alta de usuario es DENY → falla todo el onboarding.
- **Evidencia:** test descartable con el flujo exacto de la app → `PERMISSION_DENIED (false for 'create' @ L160)`.
- **Impacto:** una nueva empresa no puede registrarse vía app (flujo primario de adquisición). El seed no sufre porque siembra empresa y usuarios en requests separados.

### 🟠 ALTO

#### A1 — Empleado puede falsificar asistencias (checkOut/duration/status reabriendo)
- **Archivo/línea:** `firestore.rules:115-124` (`noAttendanceServerFieldChanges` deja libres `checkOutTime`, `durationMinutes`, `status`, `checkOutLat/Lng`, `isOrphaned`) + update de asistencias L209-213.
- **Evidencia:** `test/security/rules.test.js:144-165` **asume como deseado** que el empleado modifique `checkOutTime`, `status` y `durationMinutes` (*assertSucceeds*).
- **Impacto:** fraude de horas/jornadas y reapertura de asistencias completadas → reportes/dashboard incorrectos.
- **Contradicción con QA_REPORT:** R1 (se menciona como severidad BAJA) pero la superficie es mayor (también `status` reabre jornadas completadas).

#### A2 — `syncUserAuthStatus` sin tests y detrás de una cadena rota
- **Archivo/línea:** `functions/index.js:20-52`; `functions/package.json` (node 22, firebase-functions ^7.3.2). Sin directorio de tests de functions.
- **Impacto:** el control de bloquear cuentas desactivadas/eliminadas es indirecto (depende de updates de `users` bloqueados por C2) y no tiene cobertura.

### 🟡 MEDIO

#### M1 — Storage rules sin validación server-side
- **Archivo/línea:** `storage.rules:42-59`.
- **Descripción:** no se valida `request.resource.size` ni `request.resource.contentType`; el tope de 10MB y solo pdf/jpg/jpeg/png es solo de cliente (`storage_service.dart`, `file_utils.dart`). `getUserData()` (L13-17) sin guard `exists()` → fail-closed.
- **Impacto:** un cliente malicioso puede subir archivos de cualquier tipo/tamaño, incurriendo en costos y con allowed-contentType control solo client-side.

#### M2 — Credenciales por defecto publicadas en el seed
- **Archivo/línea:** `seed/seed.dart:5-6` (API key hardcodeada `AIzaSyCM6lWOpDTj060m8f1gsegtPkiyCn-Y4sM`, projectId `locustaf-31ed2`); `seed/seed_data.json` (superadmin/admin/supervisor/employee con contraseñas conocidas).
- **Impacto:** si se ejecuta contra producción, se crean accounts con credenciales públicas (especialmente `superadmin@locustaf.com / SuperAdmin123!`).

#### M3 — Config de deploy incoherente (hosting)
- **Archivo/línea:** `scripts/deploy.sh:77-83` despliega hosting (`flutter build web --release` + `firebase deploy --only hosting`), pero `firebase.json` **no tiene bloque de hosting** ni existe `public/`/`hosting/`. `docs/qa/MONITORING_PLAN.md` referencia métricas de Hosting.
- **Impacto:** `./deploy.sh production` fallaría en el paso 5.

#### M4 — Docs/índices: 2 vs 4
- **Archivo/línea:** `AGENTS.md` (declara 2 índices compuestos) vs `firestore.indexes.json:1-37` (4 índices: userId+checkInTime DESC, userId+status, companyId+checkInTime DESC, userId+companyId+checkInTime DESC).
- **Impacto:** incongruencia de documentación/operación.

#### M5 — Cobertura: ausencia de pruebas de reglas para rutas críticas
- **Archivo/línea:** `test/security/rules.test.js` (27 tests) **no cubre**: updates de `users` por admin/superadmin/owner, updates de `workplaces`, flujo transaccional de onboarding, escalada admin→superadmin con doc real, size/contentType de Storage.
- **Impacto:** falsa sensación de seguridad que permitió que C1-C3 pasaran como "27/27 verde".

### 🔵 BAJO / DEUDA TÉCNICA (heredado del QA y validado)
- `checkOutTime` arbitrario en el pasado (R1 QA).
- `validAttendanceCreate` admite `checkInTime` en el futuro hasta tolerancia (R2 QA).
- Lógica duplicada check-in/check-out en `attendance_notifier.dart` (R3 QA).
- `getAllAttendances` sin paginación (R4 QA).
- Reportes: `report_exporter.dart` solo CSV/PDF (no XLSX) — confirmar si la spec promete Excel.
- Supervisor: `app_router.dart:93-98` restringe `/reports`, `/settings`, etc. — revisar si la spec FASE 3 espera lectura de reportes por supervisor (coherencia con reglas que sí permiten leer asistencias).

---

## 4. Matriz de evaluación por área (22 áreas)

| # | Área | Estado | Nota |
|---|------|--------|------|
| 1 | Análisis de requisitos/spec | ✅ | Master/F2/F3 consistentes con la mayoría de features |
| 2 | Arquitectura general | ✅ | Feature-First + Clean Architecture sólida |
| 3 | Modelado de dominio | ✅ | UserRole/CompanyEstado/AttendanceStatus bien definidos |
| 4 | Gestión de estado | ✅ | Riverpod 3.3.2 (Notifier/AsyncNotifier), sin StateProvider |
| 5 | Navegación/guards por rol | ✅ | GoRouter con `refreshListenable` + redirects |
| 6 | Autenticación | ✅ | email/password + Google; bloqueo de cuenta inactiva/eliminada operativo |
| 7 | Autorización por rol | ⚠️ | CRÍTICO C1 (escalada a superadmin) |
| 8 | Aislamiento multiempresa | ⚠️ | CRÍTICO C1 rompe aislamiento una vez presente `userId` |
| 9 | Reglas de Firestore | ⚠️ | fallas en `noSensitiveFieldChanges`/`userId` (C2), escalada (C1) |
| 10 | Reglas de Storage | 🔶 | sin validación server-side M1 |
| 11 | Integridad de asistencias | ⚠️ | empleado falsifica checkOut/duration/status (A1) |
| 12 | Concurrencia (locks TTL) | ✅ | transacciones + locks `_attendance_locks` validados |
| 13 | Funciones Cloud | ⚠️ | `syncUserAuthStatus` sin tests y detrás de cadena rota (A2) |
| 14 | Índices Firestore | ✅ | 4 índices declarados; docs desactualizadas (M4) |
| 15 | Modelos de datos/migraciones | ✅ | `AttendanceModel.fromJson` tolerante (BUG-1 resuelto) |
| 16 | Consultas/read paths | ✅ | paginación presente; filtros por company |
| 17 | Reportes | ✅ | CSV/PDF; dashboard/reportes por rol |
| 18 | Portal de empleado/justificativos | ✅ | auto-aprobación bloqueada por reglas (validServiceCreate) |
| 19 | Tests (Flutter) | ✅ | 107/107; análisis estático 0 |
| 20 | Tests de seguridad (reglas) | ⚠️ | 27/27 pero con huecos críticos (M5) |
| 21 | Documentación | 🔶 | contradictoria en puntos clave (QA_REPORT, AGENTS índices, MONITORING_PLAN) |
| 22 | Despliegue/operación | 🔶 | deploy.sh hosting roto (M3); seed con credenciales (M2); onboarding roto (C3) |

**Leyenda:** ✅ Cumple · ⚠️ Riesgo/bloqueante · 🔶 Parcial/mejorable.

---

## 5. % de completitud desglosado

- **Funcionalidad implementada (vs spec):** ~90% (todas las features core presentes; pendiente verificar promesas puntuales como Excel y acceso supervisor a reportes).
- **Seguridad (reglas + autenticación):** ~55% (buen fundamento, pero 1 CRÍTICO de escalada + bloqueo de updates + falsificación de asistencias).
- **Robustez/testing:** ~85% (107 Flutter + 27 rules, pero con huecos de cobertura críticos — M5).
- **Producción/operación:** ~45% (feedback de onboarding roto, deploy.sh parcial, credentiales seed, syncUserAuthStatus sin tests).
- **Preparación para multiempresa/SaaS:** ~40% (iso por companyId presente, pero C1 lo anula; sin tenancy, facturación, admin global real).

| Área | % |
|---|---|
| Funcional | 90% |
| Seguridad | 55% |
| Tests/robustez | 85% |
| Producción/operación | 45% |
| Multiempresa/SaaS | 40% |

---

## 6. Veredicto único

**LOCUSTAF NO está listo para producción controlada ni para evolución multiempresa/SaaS en el estado actual (`cb5008e`).** El bloqueo total de updates de `users`/`workplaces` (C2), la escalada admin→superadmin una vez presente `userId` (C1), el onboarding transaccional rechazado (C3) y la falsificación de asistencias (A1) son bloqueantes para el uso real por una empresa.

- **Presentación académica:** ✅ Aceptable (demo en emulador convincente, 107 tests, buena arquitectura) — siempre que se enmarque como "auditoría que encontró los bloqueantes" (fortalece la defensa).
- **Uso funcional real por una empresa:** ❌ Bloqueado (no se pueden editar/desactivar empleados, ni lugares, ni se puede dar de alta una empresa nueva vía app contra reglas de producción).
- **Producción controlada:** ❌ No hasta resolver C1+C2+C3+A1.
- **Multiempresa/SaaS:** ❌ Exigiría resolver C1 (aislamiento) y C2 como mínimo.

---

## 7. Plan de acción documentado (SOLO DOCUMENTAR — no implementar)

> Los fixes propuestos se documentan para su ejecución en una fase posterior, con aprobación humana previa. Commits en español, verificación `flutter analyze` 0 + `npm test` en `test/security` vía `cmd /c` antes/después.

### TASK-FINAL-001 — Corregir campo `userId` vs `id` en reglas y modelos (C2)
- **Problema:** `noSensitiveFieldChanges` compara `userId` (inexistente en docs users/workplaces) → todos los updates DENY.
- **Solución propuesta (2 opciones):**
  - (a) Agregar `'userId': id` al `toJson()` de `UserModel` y `WorkplaceModel` (y backfill de docs existentes), **y** al seed; o
  - (b) Definir en reglas un helper de items sensibles por colección que compare `companyId` y el campo de identidad correcto (`id` para users/workplaces, `userId` para attendances/incidences/medical_documents).
- **Criterio de aceptación:** tests descartables de update admin→empleado, perfil propio, soft-delete, isActive, workplace → deben pasar; `npm test` 27/27; `flutter analyze` 0.
- **ADVERTENCIA:** al activar C2 queda expuesta la escalada C1: implementar TASK-FINAL-002 **en el mismo ciclo**.

### TASK-FINAL-002 — Bloquear escalada admin→superadmin (C1)
- **Problema:** `noUserSensitiveChanges` permite a un admin cambiar el rol (incl. a `superadmin`) de sí mismo y de usuarios de su empresa.
- **Solución propuesta:** en `users` update, exigir que el `rol` solo pueda cambiarlo `isSuperadmin()`, o que un admin solo pueda asignar `employee`/`supervisor` y nunca modificar el rol de su propio documento ni a `superadmin`/`admin`.
- **Criterio de aceptación:** test descartable: admin NO puede escribir `rol: 'superadmin'` en su doc ni en el de empleado; superadmin sí.

### TASK-FINAL-003 — Reparar onboarding transaccional (C3)
- **Solución propuesta (opciones):** (a) escribir primero la empresa y luego el usuario en requests separados (perdiendo atomicidad, con limpieza del doc órfano en error); (b) mantener la transacción pero relajar `noUserSensitiveChanges`/regla de alta para la empresa creada en la misma escritura — **no posible con reglas actuales** (no ven writes pendientes); (c) mover el alta a una Cloud Function (única forma de conservar atomicidad y validar del lado servidor).
- **Criterio de aceptación:** test descartable del flujo real (transacción empresa+admin) → `assertSucceeds`; o E2E de onboarding en emulador.

### TASK-FINAL-004 — Proteger campos server-only en updates de asistencias (A1)
- **Problema:** empleado puede setear `checkOutTime`, `durationMinutes`, `status`, coords de salida.
- **Solución propuesta:** en `noAttendanceServerFieldChanges`, exigir que `status` solo pase `active`→`completed` (nunca reabrir), `checkOutTime != null || resource.data.status == 'active'`, y `durationMinutes`/coords de salida solo se modifiquen si `checkOutTime` presente y >= `checkInTime`.
- **Criterio de aceptación:** test descartable: empleado NO puede reabrir `completed`→`active` ni fijar `durationMinutes` sin `checkOutTime`.

### TASK-FINAL-005 — Tests de reglas para rutas críticas ausentes (M5)
- **Agregar a `rules.test.js`:** updates de users (admin/superadmin/owner), updates de workplaces, flujo transaccional de onboarding, escalada admin→superadmin (positivo/negativo).

### TASK-FINAL-006 — Cobertura de Cloud Functions (A2)
- **Agregar:** tests unitarios de `syncUserAuthStatus` (o al menos documentar contrato) y validar end-to-end el ciclo `isActive=false` → account disabled → login bloqueado.

### TASK-FINAL-007 — Storage server-side (M1)
- **Reglas:** exigir `request.resource.size <= 10*1024*1024` y `contentType` en whitelist para `medical_documents`; agregar `exists()` guard en `getUserData`.

### TASK-FINAL-008 — Docs y operación (M2, M3, M4)
- Reconciliar `AGENTS.md` con 4 índices; quitar paso de hosting de `deploy.sh` o agregar config de hosting + `public/`; advertir sobre credenciales seed y no usar el seed contra producción; actualizar `QA_REPORT`/`MONITORING_PLAN` con estos hallazgos.

---

## 8. Anexo: evidencia de validaciones

| Comando | Resultado |
|---|---|
| `flutter analyze` | "No issues found!" (20.8s) |
| `flutter test --no-pub` | +107 all tests passed |
| `cmd /c "npm test"` (en `test/security`) | 27 passing |
| Test descartable onboarding transacción | `PERMISSION_DENIED (false for 'create' @ L160)` |
| Test descartable escalada admin→superadmin (+`userId`) | `Expected request to fail, but it succeeded` |
| 5 tests updates users (doc real sin `userId`) | todos `PERMISSION_DENIED (Property userId is undefined)` |
| 2 tests updates workplaces (doc real sin `userId`) | ambos `PERMISSION_DENIED` |
| Distribución tests Flutter | calculators 19, validators 29, model 11, repo 19, location 9, notifier 10, file_utils 9, widget 1 = 107 |

*Los archivos `test/security/_audit_*.mjs` se eliminaron tras la ejecución; `git status` limpio (sin artefactos residuales).*
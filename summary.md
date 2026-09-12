# LOCUSTAF — Agent Summary

## Objective
- Sistema SaaS completo de gestión de personal y control de asistencia para PyMEs.
- Arquitectura multiempresa (multi-tenant) sobre Firebase (Auth, Firestore, Storage, Cloud Functions).
- Rol `superadmin` = dueño de plataforma; `admin` = dueño de empresa; `supervisor`/`employee` = personal.
- Todos los commits en **inglés**. Deploy de `firestore.rules`/funciones se detalla al usuario antes de ejecutar.

## Important Details
- Windows: PowerShell bloquea `.ps1` scripts → usar `cmd /c "..."` o `npm.cmd`/`firebase.cmd`.
- No correr `dart run seed/seed.dart` sin password args (apunta a prod `locustaf-31ed2`).
- `test:integration` = solo emulador firestore; `test:trial` = firestore+functions + env `LOCUSTAF_TRIAL_INTEGRATION=1`.
- Empresa legacy `I6UOjmgDQLv4TsZlGGdc`: sin `paidUntil` → se muestra «En prueba» (retrocompat OK). No tocar. Workplace `M8LDj3aNkNVRM6ERaiqO` tampoco.
- Superadmin real = Gmail del usuario (promovido en console). `superadmin@locustaf.com` deshabilitada.
- Bloqueo de empresa: `isUsableAt(now)` = `isActive == true` AND (`paidUntil == null` OR `paidUntil.isAfter(now)`). Legacy sin `paidUntil` = utilizable (retrocompat).
- `companyNoBillingFieldChanges` (rules): admin no puede tocar `plan`/`paidUntil`/`lastPaymentAt`; solo superadmin.
- Trial 90 días: trigger `registerCompanyTrial` (onDocumentCreated companies) aplica solo si el doc no trae campos de facturación.
- Pago = manual externo (la app solo registra `paidUntil`): modal «Registrar pago» con +1 mes / +1 año / fecha a medida.
- Check-in/check-out: server-side via callables `checkInGeo`/`checkOutGeo` (geocerca Haversine). El cliente solo envía coords.
- Regla de oro: UI no guarda `isUsable` en el modelo; solo el superadmin ve la sección Empresas.

## Work State

### ✅ Completed — Todo commiteado y pusheado a `origin/main`

| Commit | Tarea | Descripción |
|--------|-------|-------------|
| `9e98638` | TASK-017 | Panel historial de pagos en dashboard superadmin |
| `5a3e5aa` | TASK-016 | Superadmin nunca bloqueado por empresa inactiva |
| `be35517` | TASK-015 | Confirmaciones antes de desactivar + guard self-lockout |
| `46d549d` | TASK-014 | Trial gratuito 90 días en creación de empresa (Cloud Function) |
| `54bfd51` | TASK-013 | Onboarding: checkbox obligatorio con `acceptedPoliciesAt` |
| `f6483bf` | TASK-010..012 | Modelo billing + dashboard plataforma + reglas billing Firestore |
| `f1589ec` | AUI-02 Fase 3 | `checkOutGeo` callable server-side con geocerca |
| `ab1245c` | — | Tests orquestación `checkInGeo` + seed script reforzado |
| `a43fea7` | AUI-02 Fase 2 | `checkInGeo` callable server-side con geocerca |
| `9483678` | AUI-03 | Exportación de reportes a Excel .xlsx nativo |
| `0d99b66` | AUI-02/05/06 | Rules: mitigación check-in, protección `createdBy`, alta manual asistencia |
| `d629571` | — | Índices compuestos Firestore + auditoría integral |

### ✅ Tests — Estado actual
| Suite | Estado |
|-------|--------|
| `flutter analyze` | ✅ 0 issues |
| `flutter test` | ✅ 157/157 pasan |
| `npm test` (functions unit) | ✅ 46/46 pasan (18 skip = integración) |
| `firebase emulators:exec` (security rules) | ✅ 87/87 pasan (project: `locustaf-test`) |

### Active
- (ninguna). El árbol de trabajo está limpio. `git status`: nothing to commit.

### Blocked
- (ninguna).

## Next Move
No hay trabajo pendiente definido. El proyecto está en estado **listo para producción**.

Posibles próximos pasos si el usuario lo requiere:
1. Deploy de `firestore.rules` y `functions` a producción si hay cambios nuevos.
2. `flutter build web --release` + `firebase deploy --only hosting` para actualizar la web.
3. Funcionalidades adicionales (Fase 3 multiempresa real, app móvil nativa, notificaciones push, etc.).
4. Integración de payment gateway real (Mercado Pago, Stripe) en reemplazo del registro manual.

## Relevant Files

### Core
- [`lib/core/models/company_model.dart`](lib/core/models/company_model.dart) — Modelo empresa con billing (`CompanyPlan`, `paidUntil`, `isUsableAt`)
- [`lib/core/models/user_model.dart`](lib/core/models/user_model.dart) — Modelo usuario con `acceptedPoliciesAt`
- [`lib/core/router/app_router.dart`](lib/core/router/app_router.dart) — GoRouter con guards por rol

### Features
- [`lib/features/companies/presentation/screens/companies_screen.dart`](lib/features/companies/presentation/screens/companies_screen.dart) — Dashboard superadmin (métricas + historial pagos)
- [`lib/features/companies/domain/services/platform_metrics.dart`](lib/features/companies/domain/services/platform_metrics.dart) — Lógica pura métricas plataforma
- [`lib/features/companies/domain/repositories/company_repository.dart`](lib/features/companies/domain/repositories/company_repository.dart) — `registerPayment`
- [`lib/features/attendance/data/repositories/attendance_repository_impl.dart`](lib/features/attendance/data/repositories/attendance_repository_impl.dart) — `checkIn`/`checkOut` via callables

### Cloud Functions
- [`functions/index.js`](functions/index.js) — `checkInGeo`, `checkOutGeo`, `syncUserAuthStatus`, `registerCompanyTrial`
- [`functions/geoCheckIn.js`](functions/geoCheckIn.js) / [`functions/geoCheckOut.js`](functions/geoCheckOut.js) — Lógica pura geocerca
- [`functions/companyBilling.js`](functions/companyBilling.js) — Lógica pura trial 90 días

### Security & Rules
- [`firestore.rules`](firestore.rules) — Reglas producción (billing-safe, role-based)
- [`storage.rules`](storage.rules) — Reglas Storage
- [`test/security/rules.test.js`](test/security/rules.test.js) — 87 tests de reglas Firestore
- [`test/security/storage.test.js`](test/security/storage.test.js) — Tests reglas Storage

### Tests
- [`test/core/models/company_model_test.dart`](test/core/models/company_model_test.dart) — 12 tests modelo billing
- [`test/core/models/user_model_test.dart`](test/core/models/user_model_test.dart) — Tests `acceptedPoliciesAt`
- [`test/features/companies/domain/services/platform_metrics_test.dart`](test/features/companies/domain/services/platform_metrics_test.dart) — 13 tests métricas
- [`functions/test/companyBilling.test.js`](functions/test/companyBilling.test.js) — 7 tests trial billing
- [`functions/test/checkInGeo.integration.test.js`](functions/test/checkInGeo.integration.test.js) — Integración (emulador)
- [`functions/test/checkOutGeo.integration.test.js`](functions/test/checkOutGeo.integration.test.js) — Integración (emulador)
- [`functions/test/registerCompanyTrial.integration.test.js`](functions/test/registerCompanyTrial.integration.test.js) — Integración trial (emulador)

### Docs
- [`AGENTS.md`](AGENTS.md) — Comandos, arquitectura y reglas para agentes AI
- [`AUDITORIA_INTEGRAL_LOCUSTAF_FINAL.md`](AUDITORIA_INTEGRAL_LOCUSTAF_FINAL.md) — Auditoría completa (2026-09)
- [`LOCUSTAF_MASTER_SPEC.md`](LOCUSTAF_MASTER_SPEC.md) — Especificación master del sistema
- [`.ai/rules/LOCUSTAF_AI_RULES.md`](.ai/rules/LOCUSTAF_AI_RULES.md) — Reglas obligatorias para agentes
- [`.ai/workflows/locustaf-task-loop.md`](.ai/workflows/locustaf-task-loop.md) — Flujo PLAN→aprobación→ejecución
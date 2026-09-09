# LOCUSTAF — Agent Summary

## Objective
- Convertir LOCUSTAF en SaaS (plan aprobado TASK-010..014, sin merge aún): plataforma superadmin para ver todas las empresas y gestionar pagos, suscripción por plan (mensual/anual) con bloqueo por vencimiento, prueba gratuita de 90 días automática, y onboarding con aceptación de políticas.
- Ruta: FASE 1 modelo (TASK-010) → FASE 2 dashboard (TASK-011) → FASE 3 reglas billing (TASK-012) → FASE 4 políticas (TASK-013) → FASE 5 trial 90 días (TASK-014) → FASE 6 retrocompat + deploy (pendiente).
- Todo commit con mensajes **en inglés**; cada deploy de `firestore.rules`/funciones se detalla al usuario antes de ejecutarlo.

## Important Details
- Commits (inglés):
  - Plan previo: `a43fea7` (checkInGeo), `ab1245c` (test/seed), `f1589ec` (checkOutGeo, pusheado + desplegado).
  - SaaS: `f6483bf` `feat(saas): subscription billing model, platform dashboard and billing field rules (TASK-010..012)`.
- Modelo de negocio: superadmin = dueño de plataforma que habilita/deshabilita empresas según pago; admin = dueño de empresa. El superadmin real es el Gmail del usuario (promovido a `superadmin` en console); `superadmin@locustaf.com` deshabilitada; 4 huérfanas de Auth eliminadas (Paso 1 manual completo).
- Pago = manual (externo a la app: transferencia/Mercado Pago; la app solo registra `paidUntil`): modal «Registrar pago» con `+1 mes / +1 año / fecha a medida` + selector de plan.
- Trial 90 días: trigger `onDocumentCreated companies` (`registerCompanyTrial`) aplica `plan: mensual` + `paidUntil = created + 90d` solo si el doc no trae campos de facturación; `lastPaymentAt` queda null (trial).
- Bloqueo de empresa: `isUsableAt` = `estado activa` Y (`paidUntil == null` O `paidUntil.isAfter(now)`). Legacy sin `paidUntil` = utilizable hasta el primer vencimiento/pago (retrocompat).
- `companyNoBillingFieldChanges` (rules): admin no puede tocar `plan`/`paidUntil`/`lastPaymentAt`; accesos con `in` + fallback null para docs legacy sin campos.
- Windows: PowerShell bloquea `npm.ps1`/`firebase.ps1` → `cmd /c "..."`.
- No correr `dart run seed/seed.dart` (apunta a prod `locustaf-31ed2`).
- `test:integration` es solo firestore emulator; `test:trial` necesita firestore+functions y env `LOCUSTAF_TRIAL_INTEGRATION=1` (si no, el trigger no está registrado y el test se salta).
- Regla de oro de la app: la UI no guarda `isUsable` en el modelo de empresa; solo el superadmin ve la sección Empresas (`isSuperadminProvider`).
- No tocar: empresa `I6UOjmgDQLv4TsZlGGdc` (legacy, sin `paidUntil` → se muestra «En prueba»), workplace `M8LDj3aNkNVRM6ERaiqO`. Si admin@locustaf.com necesita acceso operativo (mail dummy), script Admin SDK de un solo uso pendiente.

## Work State
### Completed
- **Paso 1 (manual, usuario)**: Gmail real promovido a superadmin; 4 huérfanas Auth eliminadas; `superadmin@locustaf.com` deshabilitada.
- **Paso 3 Fase 3 `checkOutGeo`** (`f1589ec`, pusheado y desplegado): `functions/geoCheckOut.js`, `checkOutGeo` en `index.js` (transacción + derivación server-side), `firestore.rules` (`isEmployeeCompletionAllowed`), app `checkOut`→`httpsCallable('checkOutGeo')`, tests.
- **Paso 4 release web**: `flutter build web --release` + hosting → `https://locustaf-31ed2.web.app`.
- **FASE 1 / TASK-010** (`f6483bf`): `CompanyModel` con `CompanyPlan` (mensual/anual), `plan`, `paidUntil`, `lastPaymentAt`, `isUsableAt()`/`daysRemainingAt()`; fromJson legacy-safe (sin campos → default mensual/billing null). `test/core/models/company_model_test.dart` (12).
- **FASE 2 / TASK-011** (`f6483bf`): `CompanyRepository.registerPayment` + impl (UTC ISO); `PlatformMetrics` (dominio puro: total/activas/suspendidas/porVencer≤7d/enPrueba) + `platformMetricsProvider`; dashboard `companies_screen.dart`: `_PlatformMetricsRow` (5 tarjetas), `_SubscriptionInfo` (chip Plan/Prueba/Vencida + días restantes), botón `payment` → `_RegisterPaymentDialog` (`+1 mes/+1 año/Fecha`, selector de plan, preview paidUntil). `platform_metrics_test.dart` (13).
- **FASE 3 / TASK-012** (`f6483bf`): `firestore.rules` `companyNoBillingFieldChanges()` (null-safe legacy) exigido al admin en `companies.update`; superadmin conserva bypass. Tests rules TASK-012 (7 nuevos): admin no edita plan/paidUntil/lastPaymentAt, sí edita config sin billing, superadmin sí puede. Rules emulador 69/69.
- **FASE 4 / TASK-013** (sin commit aún): `UserModel.acceptedPoliciesAt` (campo + copyWith + json + props, null-safe legacy); onboarding provider fija `acceptedPoliciesAt = now`; onboarding screen con checkbox obligatorio «Acepto términos y políticas» (FormField validado). `test/core/models/user_model_test.dart` (5 nuevos).
- **FASE 5 / TASK-014** (sin commit aún): `functions/companyBilling.js` (`decideCompanyInitialBilling`, `computeTrialPaidUntil` = +90d UTC) + trigger `registerCompanyTrial` en `index.js` (respeta docs con billing ya cargado). Unit `companyBilling.test.js` (7); integración `registerCompanyTrial.integration.test.js` (2, vía `npm run test:trial` con emuladores firestore+functions). `flutter analyze` 0; `flutter test` 147/147.

### Active
- **FASE 6** (pendiente): verificar retrocompat empresa `I6UOjmgDQLv4TsZlGGdc` sin `paidUntil` (utilizable como trial en UI), backfill opcional guiado, deploy final (`firestore.rules` + `functions` + UI web), push de `f6483bf` y commits FASE 4/5 con aprobación del usuario.

### Blocked
- (none). Deploys de FASE 3 (rules) y FASE 5 (functions) requieren detalle previo y aprobación del usuario por directiva de la FASE 3.

## Next Move
1. Commit FASE 4 (`feat(saas): onboarding accept policies storage (TASK-013)`) y FASE 5 (`feat(functions): auto-apply 90-day trial on company creation (TASK-014)`), en inglés.
2. Push de `f6483bf` + FASE 4/5 con aprobación.
3. FASE 6: asegurar que la empresa legacy `I6UOjmgDQLv4TsZlGGdc` aparece «En prueba» en el dashboard; opcional backfill de `paidUntil` si el usuario lo pidiera; `flutter build web` + `firebase deploy –only hosting`; deploy de `firestore.rules` y `registerCompanyTrial` tras detallárselo al usuario.
4. Recordatorio: `git push` no hecho de `f6483bf`; commits FASE 4/5 aún locales.

## Relevant Files
- `lib/core/models/company_model.dart` + `test/core/models/company_model_test.dart`: suscripción (FASE 1).
- `lib/features/companies/domain/services/platform_metrics.dart` + test: métricas plataforma (FASE 2).
- `lib/features/companies/domain/repositories/company_repository.dart` + `data/repositories/company_repository_impl.dart`: `registerPayment` (FASE 2).
- `lib/features/companies/presentation/providers/company_providers.dart` (`platformMetricsProvider`) + `company_action_provider.dart` (`registerPaymentProvider`).
- `lib/features/companies/presentation/screens/companies_screen.dart`: tarjetas métricas + chip suscripción + `_RegisterPaymentDialog`.
- `lib/core/models/user_model.dart` + `test/core/models/user_model_test.dart`: `acceptedPoliciesAt` (FASE 4).
- `lib/features/companies/presentation/screens/onboarding_screen.dart` + `providers/onboarding_provider.dart`: checkbox políticas (FASE 4).
- `firestore.rules` + `test/security/rules.test.js`: `companyNoBillingFieldChanges` (FASE 3, 69/69).
- `functions/companyBilling.js` + `functions/test/companyBilling.test.js` + `functions/test/registerCompanyTrial.integration.test.js`: trial 90 días (FASE 5).
- `functions/index.js`: `registerCompanyTrial` trigger (FASE 5).
- `functions/geoCheckIn.js`/`geoCheckOut.js`/`userStatus.js` + tests: geocerca Fases 2-3 previas.
- `docs/FIRESTORE_RULES.md`, `AGENTS.md`: documentación actualizada (rules billing, trial, comandos).
- `LOCUSTAF_MASTER_SPEC.md:57`, `.ai/workflows/locustaf-task-loop.md`, `.ai/rules/LOCUSTAF_AI_RULES.md`, `.ai/skills/locustaf-safe-development/SKILL.md`: flujo obligatorio PLAN→aprobación.
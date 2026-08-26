# LOCUSTAF — FASE 2 SPECIFICATION

## Locus Staff — Fase 2: Consolidación y Profesionalización

**Versión:** 1.0  
**Estado:** Aprobación del Project Lead  
**Fase:** 2  
**Modelo empresarial:** Empresa única  
**Preparación futura:** Multiempresa / Multi-tenant — Fase 3  
**Base:** LOCUSTAF_MASTER_SPEC.md + STD-001 + auditoría técnica de Fase 1

---

# 1. PROPÓSITO

La Fase 2 tiene como objetivo transformar la base funcional desarrollada durante la Fase 1 en una aplicación profesional, segura, mantenible, testeable, responsive y preparada para evolucionar hacia un modelo multiempresa en la Fase 3.

Durante esta fase LOCUSTAF funcionará bajo un modelo de:

> **UNA ÚNICA EMPRESA**

No se implementará todavía el modelo multiempresa.

La arquitectura deberá, sin embargo, evitar decisiones que dificulten o requieran una reescritura completa del sistema cuando se implemente la Fase 3.

---

# 2. OBJETIVO GENERAL

Al finalizar la Fase 2, LOCUSTAF deberá contar con:

- Seguridad consistente por rol y usuario.
- Firestore Rules correctamente alineadas con el modelo funcional.
- Storage Rules seguras.
- Asistencia funcional y confiable.
- Tolerancia configurable.
- Detección de llegadas tarde.
- Persistencia de precisión GPS.
- Gestión de jornadas activas y huérfanas.
- Flujo completo de justificativos.
- Historial funcional y eficiente.
- Reportes funcionales.
- Dashboard con KPIs correctos.
- Consultas Firestore optimizadas.
- Paginación.
- Design System consolidado.
- Responsive desde 360 px.
- Arquitectura más desacoplada y testeable.
- Suite de tests para funcionalidades críticas.
- Documentación actualizada.
- Base técnica preparada para Fase 3.

---

# 3. MODELO EMPRESARIAL DE FASE 2

## 3.1 Modelo operativo

Durante toda la Fase 2 LOCUSTAF funcionará con una única empresa.

No se implementará:

- `companyId` obligatorio en todas las entidades.
- Gestión de múltiples empresas.
- Alta de empresas.
- Cambio de empresa.
- Selector de empresa.
- Aislamiento multi-tenant.
- Administración SaaS.
- Suscripciones por empresa.

## 3.2 Preparación para Fase 3

Aunque no se implemente multiempresa, las decisiones arquitectónicas deberán permitir incorporar posteriormente:

- `companyId`.
- Entidad Company.
- Usuarios pertenecientes a empresas.
- Recursos pertenecientes a empresas.
- Filtrado por empresa.
- Firestore Rules multi-tenant.
- Storage Rules multi-tenant.
- Dashboard por empresa.
- Reportes por empresa.

La incorporación futura de multiempresa deberá poder realizarse mediante una evolución controlada de modelos, repositories, providers y reglas, evitando una reescritura completa de la aplicación.

## 3.3 Regla fundamental

> Fase 2 = producto profesional para una empresa.
>
> Fase 3 = implementación real de múltiples empresas.

No deberá implementarse una solución híbrida o parcial de multiempresa durante Fase 2.

---

# 4. ALCANCE DE FASE 2

La Fase 2 comprende:

1. Seguridad.
2. Arquitectura y desacoplamiento.
3. Design System.
4. Asistencia.
5. Justificativos.
6. Historial.
7. Reportes.
8. Dashboard.
9. Responsive.
10. Performance.
11. Testing.
12. Documentación.
13. Corrección de bugs heredados.

---

# 5. FUERA DE ALCANCE

Quedan fuera de Fase 2:

- Multiempresa real.
- `companyId` como requisito funcional general.
- Administración de empresas.
- SaaS.
- Suscripciones.
- Facturación.
- App Android/iOS.
- Notificaciones push.
- Código QR.
- Integraciones externas.
- Analítica avanzada.
- Turnos rotativos complejos.
- Motor avanzado de jornadas.
- Feriados parametrizables completos.
- Cloud Functions para validación server-side completa.

Las funcionalidades excluidas deberán documentarse como backlog o alcance de Fase 3.

---

# 6. ARQUITECTURA

## 6.1 Stack

Se mantiene:

- Flutter Web.
- Dart.
- Riverpod.
- GoRouter.
- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage.
- Firebase Hosting.
- Git/GitHub.

No se incorporarán tecnologías adicionales sin justificación técnica.

## 6.2 Arquitectura

Se mantiene:

> Feature First + Clean Architecture adaptada + Repository Pattern.

Cada feature deberá respetar, cuando corresponda:

```text
feature/
├── data/
├── domain/
└── presentation/
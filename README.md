# LOCUSTAF

Sistema Web de Control de Asistencia Laboral desarrollado con Flutter y Firebase.

## Descripción

LOCUSTAF (Locus Staff) es una aplicación web orientada a la administración del personal de una organización.

El sistema permite gestionar empleados, lugares de trabajo, asistencia con geolocalización, historial de movimientos, justificativos (incidencias y certificados médicos), reportes y perfiles de usuario desde una única plataforma.

El proyecto fue desarrollado desde cero utilizando una arquitectura limpia y escalable (Clean Architecture + Feature First) para facilitar su mantenimiento y evolución.

---

# Estado del proyecto

**Versión:** Fase 2 (empresa única, preparado para Fase 3 multiempresa)

## Funcionalidades implementadas

* Autenticación con Firebase Authentication (email/contraseña + Google Sign-In)
* Onboarding: creación de empresa + usuario admin
* Gestión de empleados (CRUD, soft-delete, búsqueda)
* Gestión de lugares de trabajo (CRUD, geocerca con radio, geocoding)
* Control de asistencia con GPS (check-in / check-out, geocerca, tolerancia)
* Detección de llegadas tarde y jornadas huérfanas
* Historial de asistencias con filtros múltiples
* Justificativos: incidencias y certificados médicos (con carga de archivos)
* Aprobación/rechazo de justificativos por admin
* Reportes con exportación Excel (.xlsx) y PDF
* Dashboard con KPIs
* Roles de usuario: superadmin / admin / supervisor / employee
* Protección de rutas por rol (GoRouter + Riverpod)
* Sidebar dinámico según rol

## Seguridad

* Firestore Rules restrictivas por rol y por empresa (ver `docs/FIRESTORE_RULES.md`)
* Campos server-only protegidos en asistencias (checkInTime, date, isLate, workplaceId, coordenadas de entrada)
* Locks transaccionales para prevenir doble check-in
* Onboarding atómico (empresa + usuario en una transacción)
* Trazabilidad de aprobaciones (reviewedBy / reviewedAt)
* Cloud Function `syncUserAuthStatus` (desactiva la cuenta Auth al marcar un usuario como eliminado)

---

# Tecnologías utilizadas

## Frontend

* Flutter Web
* Material Design 3

## Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Cloud Functions (2ª generación, Node 22)

## Arquitectura

* Clean Architecture
* Feature First
* Repository Pattern

## Gestión de estado

* Flutter Riverpod 3.x (Notifier / AsyncNotifier)

## Navegación

* GoRouter

---

# Estructura del proyecto

```text
lib/
│
├── core/
│   ├── constants/
│   ├── models/
│   ├── router/
│   ├── services/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── authentication/
│   ├── companies/
│   ├── dashboard/
│   ├── employees/
│   ├── attendance/
│   ├── workplaces/
│   ├── history/
│   ├── incidences/
│   ├── medical_documents/
│   ├── justificativos/
│   ├── reports/
│   └── splash/
│
├── firebase_options.dart
└── main.dart
```

Cada feature sigue la estructura de capas `data/`, `domain/` y `presentation/`.

---

# Instalación

## Clonar el proyecto

```bash
git clone https://github.com/Renzito24/locustaf.git
```

## Instalar dependencias

```bash
flutter pub get
```

## Configurar Firebase

```bash
flutterfire configure
```

## Ejecutar el proyecto

```bash
flutter run -d chrome
```

---

# Seed de datos

El proyecto incluye un script de seed independiente (sin dependencias de Flutter) que crea usuarios de Auth y documentos de Firestore vía REST API.

```bash
# 1. Desplegar reglas permisivas (solo para seed)
firebase deploy --only firestore:rules firestore.rules.seed

# 2. Ejecutar el seed
dart run seed/seed.dart

# 3. Desplegar reglas de producción + índices
firebase deploy --only firestore
```

Usuarios de prueba creados por el seed:

| Rol | Email | Contraseña |
|-----|-------|------------|
| Superadmin | superadmin@locustaf.com | SuperAdmin123! |
| Admin | admin@locustaf.com | Admin123! |
| Supervisor | supervisor@locustaf.com | Super123! |
| Empleado | employee@locustaf.com | Empl123! |

> **Importante:** el seed usa reglas permisivas temporalmente. Nunca dejar las reglas permisivas desplegadas en producción.

---

# Despliegue

```bash
# Verificación de código
flutter analyze
flutter test

# Desplegar reglas de Firestore
firebase deploy --only firestore:rules

# Desplegar índices
firebase deploy --only firestore:indexes

# Desplegar Storage
firebase deploy --only storage

# Desplegar Cloud Functions
firebase deploy --only functions
```

---

# Documentación

* `LOCUSTAF_MASTER_SPEC.md` — especificación maestra
* `LOCUSTAF_FASE_2_SPEC.md` — especificación de Fase 2
* `LOCUSTAF_FASE_3_SPEC.md` — especificación de Fase 3
* `LOCUSTAF_DESARROLLO.md` — bitácora de desarrollo
* `docs/FIRESTORE_RULES.md` — documentación de reglas de Firestore
* `docs/tasks/` — tareas de desarrollo
* `docs/specifications/` — especificaciones por módulo

---

# Objetivo del proyecto

Construir un sistema moderno, escalable y mantenible para la administración del presentismo laboral, aplicando buenas prácticas de arquitectura de software y desarrollo con Flutter.

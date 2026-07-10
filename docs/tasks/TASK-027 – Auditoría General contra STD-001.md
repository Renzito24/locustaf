# TASK-027 — Auditoría General contra STD-001

## Contexto

Auditoría completa del proyecto LOCUSTAF contra la especificación técnica `STD-001.md`. Realizada en Julio 2026. Referencia: `STD-001 v1.0`.

**Estado: PENDIENTE DE APROBACIÓN**

---

## 1. Estado General del Proyecto

### Módulos Implementados

| Módulo | Estado | % Estimado |
|--------|--------|------------|
| Authentication | Funcional | 85% |
| Employees | Funcional | 90% |
| Workplaces | Funcional | 90% |
| Attendance | Funcional (core) | 65% |
| History | Funcional | 75% |
| Medical Documents (Justificativos) | Funcional | 80% |
| Incidences | Funcional | 80% |
| Reports | Parcial | 40% |
| Dashboard | Parcial | 50% |
| Profile | Parcial | 40% |
| Splash | Funcional | 90% |

### flutter analyze: 0 issues (12 info en seed.dart, script externo)

---

## 2. Comparación contra STD-001

### §4 — Alcance del MVP

| Requisito MVP | Estado |
|---------------|--------|
| Login | Cumplido |
| Logout | Cumplido |
| Control de sesión | Cumplido |
| Protección de rutas | Cumplido |
| Gestión de roles | Cumplido |
| Alta de empleados | Cumplido |
| Consulta de información | Cumplido |
| Administración de estados | Cumplido |
| Gestión de perfiles | Parcial — solo lectura, sin edición |
| Creación de lugares | Cumplido |
| Configuración de ubicación | Cumplido |
| Definición de radio | Cumplido |
| Asociación con empleados | Cumplido |
| Registro de entrada | Cumplido |
| Registro de salida | Cumplido |
| Validación geolocalización | Cumplido |
| Control de duplicados | Cumplido |
| Historial de asistencia | Cumplido |
| Cálculo de jornada | Parcial — duración bruta sin desglose |
| Justificativos | Parcial — CRUD + Storage, sin flujo aprobación |
| Reportes | Parcial — solo tabla de asistencia, sin exportación |
| Estadísticas básicas | Parcial — 4 KPI en dashboard |

### §11 — Modelo de usuarios y roles

| Requisito | Estado |
|-----------|--------|
| Admin: control completo | Cumplido |
| Supervisor: permisos limitados | Cumplido |
| Empleado: solo registro propio | Cumplido |
| Autorización en UI + Firebase | Cumplido |

### §12 — Reglas de negocio

| Regla | Estado |
|-------|--------|
| 12.1 Registro de asistencia | Cumplido |
| 12.2 Control de doble registro | Cumplido |
| 12.3 Jornada laboral (turno) | No implementado |
| 12.4 Validación de horario | No implementado |
| 12.5 Tolerancia | No implementado |
| 12.6 Horas trabajadas | Solo duración bruta |
| 12.7 Horas extra | No implementado |
| 12.8 Asistencia incompleta | No implementado |
| 12.9 Ausencias | No implementado |

### §17-22 — UI/UX

| Requisito | Estado |
|-----------|--------|
| Layout sidebar + contenido | Cumplido |
| Dashboard con métricas | Parcial — 4 cards, sin gráficos |
| Tablas con filtros | Cumplido |
| Formularios validados | Cumplido |
| Loading/Empty/Error states | Cumplido |
| Responsive design | Cumplido |
| Paleta de colores STD-001 | No coincide |
| Consistencia visual entre módulos | Parcial |

---

## 3. Estado por Módulo

### Authentication (85%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model, service, repository_impl | Cumplido |
| domain/ | repository (abstract) | Cumplido |
| application/ | auth_state_listenable | Cumplido |
| presentation/ | providers, login_screen, profile_stub | Cumplido |

**Problemas:**
- Doble sistema de auth-state: `AuthStateListenable` (router) + `auth_provider.dart` (UI) se duplican
- Domain layer expone `UserCredential` de Firebase (acoplamiento)
- `register()`, `deleteUser()`, `sendPasswordReset()` existen en AuthService pero no llegan al domain/repository
- No se valida `isActive`/`isDeleted` al hacer login (usuario desactivado puede entrar)
- `profile_screen.dart` en authentication es dead code (el real esta en `features/profile/`)

**Pendientes:**
- Unificar sistema de auth-state
- Desacoplar domain de Firebase Auth
- Agregar guard de isActive/isDeleted en login
- Eliminar dead code

---

### Employees (90%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | repository_impl (Auth+Firestore) | Cumplido |
| domain/ | repository (abstract) | Cumplido |
| presentation/ | 4 providers, 3 screens, 5 widgets | Cumplido |

**Funcionalidades:** CRUD completo, busqueda 4 dimensiones, filtros 3 dimensiones, soft-delete, toggle activo/inactivo, reset password.

**Problemas:**
- `employee_form_fields.dart` — archivo vacio (dead code)
- `CreateEmployeeNotifier` y `EmployeeFormData` embebidos en `users_provider.dart` (inconsistencia con otros notifiers que tienen archivos propios)
- Soft-delete no revoca Firebase Auth (usuario "eliminado" puede autenticarse)
- Toggle activo/inactivo no tiene confirmacion
- `UserModel` vive en `authentication/data/` pero se usa en 5+ features

**Pendientes:**
- Extraer `CreateEmployeeNotifier` a archivo propio
- Eliminar `employee_form_fields.dart` vacio
- Evaluar revocacion de Auth en soft-delete

---

### Workplaces (90%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model, repository_impl, geocoding_service | Cumplido |
| domain/ | repository (abstract) | Cumplido |
| presentation/ | 2 providers, 2 screens, 1 widget (map_picker) | Cumplido |

**Funcionalidades:** CRUD completo, mapa interactivo, geocoding (Nominatim), "Mi ubicacion", radio configurable, soft-delete/reactivar.

**Problemas:**
- `firestoreServiceProvider` definido localmente (duplicado)
- `GeocodingService` instanciado directamente en widget (no inyectado via DI)
- Soft-delete no tiene confirmacion, pero reactivar si

**Pendientes:**
- Centralizar `firestoreServiceProvider`
- Inyectar `GeocodingService` via Riverpod

---

### Attendance (65%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model, repository_impl, location_service | Cumplido |
| domain/ | repository, exception | Cumplido |
| presentation/ | 1 provider (330 lineas), 1 screen | Cumplido |

**Reglas implementadas:**
- Check-in con validacion de usuario, workplace, GPS, geocerca
- Check-out con validacion de propiedad
- Control de concurrencia via `_attendance_locks`
- Transacciones Firestore atomicas
- Precision GPS <= 25m
- Formato de duracion

**Reglas faltantes:**
- Turno asignado / validacion de horario
- Tolerancia configurable
- Horas extra
- Asistencia incompleta
- Ausencias automaticas
- Check-out con geolocalizacion
- Admin puede crear/editar asistencia manualmente

**Problemas:**
- Muestra `workplaceId` raw en historial de AttendanceScreen (no resuelve nombre)
- Fecha generada en cliente (`DateTime.now()`), vulnerable a manipulacion
- Locks huerfanos sin mecanismo de limpieza
- Estado de accion no se resetea automaticamente
- Sin tests

---

### History (75%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | history_record_model (view model) | Cumplido |
| domain/ | repository (TODO stub) | No implementado |
| presentation/ | 1 provider, 1 screen, 3 widgets | Cumplido |

**Funcionalidades:** Lista completa de asistencias, enriquecimiento con datos de usuario/lugar, 6 filtros, tarjetas indicadoras, layout responsive, dialogo de detalle.

**Problemas:**
- `history_repository.dart` es TODO stub
- Sin `data/repositories/` — no tiene repository propio
- `allAttendancesProvider` crea suscripcion independiente a Firestore (3ra suscripcion a la misma coleccion)
- Sin paginacion

**Pendientes:**
- Completar repository
- Evaluar paginacion

---

### Medical Documents (80%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model, repository_impl | Cumplido |
| domain/ | repository, exception (unused) | Parcial |
| presentation/ | 4 providers, 3 screens, 4 widgets | Cumplido |

**Funcionalidades:** CRUD completo, upload a Firebase Storage con progreso, validacion de archivos (pdf/jpg/png), rollback en error, filtros, indicadores de vigencia, soft-delete.

**Problemas:**
- `MedicalDocumentEstado` (pendiente/aprobado/rechazado) existe en modelo pero nunca se usa — no hay flujo de aprobacion
- `MedicalDocumentException` definida pero nunca lanzada ni capturada
- Domain layer importa modelo de data layer (viola Clean Architecture)
- Logica de vigencia duplicada en 3 archivos
- `storageServiceProvider` definido en presentation (no centralizado)

**Pendientes:**
- Implementar flujo de aprobacion/rechazo
- Centralizar `storageServiceProvider`
- Eliminar dead code (`MedicalDocumentException`)

---

### Incidences (80%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model, repository_impl | Cumplido |
| domain/ | repository | Cumplido |
| presentation/ | 1 provider, 3 screens, 4 widgets | Cumplido |

**Funcionalidades:** CRUD completo, 11 tipos de incidencia, estado automatico (programada/en curso/finalizada), filtros, soft-delete.

**Problemas:**
- `_firestoreService` instanciado como constante privada a nivel de modulo (no via DI)
- `documentoRelacionado` es texto libre sin validacion ni adjunto
- `IncidenceState` no tiene `fromString()`
- Naming collision: campo `state` en filter vs Riverpod `state`

**Pendientes:**
- Adjuntos de archivos (como medical_documents)
- Centralizar `FirestoreService`

---

### Reports (40%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model (TODO stub) | No implementado |
| domain/ | repository (TODO stub) | No implementado |
| presentation/ | 1 provider (156 lineas), 1 screen (348 lineas) | Cumplido |

**Funcionalidades:** Tabla de asistencias con filtros por fecha/lugar, 4 KPI cards, metricas de empleados/presentes/ausentes.

**Problemas:**
- data y domain layers son TODO stubs — toda la logica esta en presentation
- Streams duplicados de users/workplaces/attendances
- `FirestoreService` instanciado localmente
- Sin exportacion (CSV/PDF)
- Sin reportes de incidencias ni justificativos
- Filtro de fecha es texto libre (sin DatePicker)
- Sin paginacion
- Sin gating por rol

**Pendientes:**
- Completar data/domain layers
- Agregar exportacion
- Centralizar streams
- Agregar mas tipos de reporte

---

### Dashboard (50%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | model (TODO stub) | No implementado |
| domain/ | repository (TODO stub) | No implementado |
| presentation/ | 1 screen, 3 widgets | Cumplido |

**Funcionalidades:** 4 KPI cards reales (empleados activos, presentes hoy, ausentes hoy, sucursales activas), layout responsive, sidebar con roles.

**Problemas:**
- data y domain layers son TODO stubs
- Importa providers de `reports/presentation/providers/` (acoplamiento cross-feature)
- Sidebar hardcodeada con color primario en vez de color oscuro segun STD-001
- "Ausentes hoy" puede dar negativo (sin `max(0, ...)`)
- Sin graficos ni tendencias
- Sin variante por rol (admin/supervisor/ven lo mismo)

**Pendientes:**
- Completar data/domain layers
- Separar providers propios
- Agregar graficos
- Corregir bug de ausentes negativos

---

### Profile (40%)

| Capa | Archivos | Estado |
|------|----------|--------|
| data/ | (vacio) | No implementado |
| domain/ | (vacio) | No implementado |
| presentation/ | 1 screen, 4 widgets | Cumplido |

**Funcionalidades:** Vista de solo lectura con info personal, laboral y del sistema.

**Problemas:**
- Sin capas data/domain
- Solo lectura — no permite editar nombre, telefono, etc.
- Sin cambio de contrasena
- Sin avatar upload
- Depende de providers de authentication y workplaces (cross-feature)

**Pendientes:**
- Agregar modo edicion
- Completar data/domain layers

---

## 4. Arquitectura

### Cumplimiento por principio

| Principio | Estado |
|-----------|--------|
| Feature First | 11 features separadas |
| Clean Architecture | Parcial — domain importa data en 4 features |
| Repository Pattern | Interfaces abstractas + impl concretas |
| Riverpod 3.3.2 | Notifier/AsyncNotifier, sin StateProvider |
| GoRouter 17.3.0 | Redirects basados en roles |

### Duplicaciones detectadas

| Duplicacion | Ubicacion | Severidad |
|-------------|-----------|-----------|
| `firestoreServiceProvider` x3 | attendance, workplaces, employees | Critica |
| `storageServiceProvider` | medical_documents (no centralizado) | Alta |
| `_formatDate()` x5+ | attendance, history, medical_documents, incidences | Media |
| `_IndicatorCard` x3 | history, medical_documents, incidences | Media |
| `_InfoChip` x3 | history, medical_documents, incidences | Media |
| `_DetailRow` x3 | history, medical_documents, incidences | Media |
| `_VigenciaBadge`/`_StatusBadge` x3 | history, medical_documents, incidences | Media |
| Streams Firestore duplicados x3 | attendances collection: attendance, reports, history | Alta |

### Malas practicas detectadas

| Practica | Ubicacion | Severidad |
|----------|-----------|-----------|
| Domain layer importa data layer | employees, medical_documents, incidences | Alta |
| `FirestoreService` instanciado inline (no DI) | reports, incidences, auth_provider | Alta |
| `TextEditingController` creado en `build()` | history_filter_bar, medical_document_filter_bar | Media |
| Archivos TODO stub sin implementar | reports (2), dashboard (2), history (1), core (5) | Media |
| Colors hardcoded bypassing AppColors | sidebar, dashboard_layout, profile | Baja |
| Archivo vacio dead code | employee_form_fields.dart, core/theme/app_colors.dart | Baja |

### Inconsistencias

| Inconsistencia | Detalle |
|----------------|---------|
| Paleta de colores | STD-001 dice `#2563EB`, codigo usa `#1A56DB` |
| Sidebar color | STD-001 dice `#1E293B` (oscuro), codigo usa `#1A56DB` (igual que primario) |
| Background | STD-001 dice `#F5F7FA`, codigo usa `#F3F4F6` |
| Soft-delete | Users usa `isDeleted`, otros usan `isActive` |
| Repository pattern | Algunas features tienen repo, otras no (reports, history, dashboard, profile) |

---

## 5. Seguridad

### Firestore Rules

| Coleccion | Reglas | Estado |
|-----------|--------|--------|
| `users` | Admin: CRUD, Supervisor: read, Employee: own read | Cumplido |
| `attendances` | Admin: CRUD, Supervisor: read + own write, Employee: own CRUD | Cumplido |
| `workplaces` | Admin: CRUD, Supervisor: read | Cumplido |
| `medical_documents` | Admin only | Cumplido |
| `incidences` | Admin: CRUD, Supervisor: read | Cumplido |
| `_attendance_locks` | Autenticados | Cumplido (agregado en TASK-025) |

### Storage Rules

| Ruta | Reglas | Estado |
|------|--------|--------|
| `medical_documents/{userId}/{fileName}` | Autenticados | Cumplido |
| Resto | Denegado | Cumplido |

### Problemas de seguridad

| Problema | Severidad |
|----------|-----------|
| Usuario desactivado puede hacer login (no se verifica `isActive`) | Alta |
| Soft-delete no revoca Firebase Auth | Alta |
| Fecha de asistencia generada en cliente (manipulable) | Media |
| Sin rate limiting en Firestore rules | Baja |
| Seed rules son extremadamente permisivas (documentado en TASK-025) | Baja (solo dev) |

---

## 6. Calidad

### flutter analyze: 0 issues

### Errores potenciales

| Error | Ubicacion | Severidad |
|-------|-----------|-----------|
| `employeesAbsentTodayProvider` puede dar negativo | reports_provider.dart:68 | Media |
| `AttendanceActionState` no se auto-resetea | attendance_notifier.dart | Baja |
| `TextEditingController` se recrea en cada build | filter bars (multiples) | Media |
| Locks huerfanos sin limpieza | attendance_repository_impl.dart | Alta |
| Splash redirige a `/login` siempre (flicker) | splash_screen.dart | Baja |

### Deuda tecnica

| Deuda | Cantidad |
|-------|----------|
| TODO stubs sin implementar | 11 archivos |
| Providers duplicados (`firestoreServiceProvider`) | 3 definiciones |
| Widgets privados duplicados (`_IndicatorCard`, etc.) | 15+ instancias |
| Streams Firestore duplicados | 3 suscripciones a `attendances` |
| Archivos vacios dead code | 3 archivos |
| Sin tests | 0 tests en todo el proyecto |
| Domain layers que importan data | 4 features |
| Colores hardcoded bypassing constantes | 40+ instancias |

---

## 7. Lista Priorizada de Trabajo

### Critico — Antes de produccion

| # | Item | Modulos |
|---|------|---------|
| C1 | Centralizar `firestoreServiceProvider` — definir una sola vez en `core/services/` | core, attendance, workplaces, employees |
| C2 | Validar `isActive`/`isDeleted` en login — bloquear usuarios desactivados | authentication |
| C3 | Corregir paleta de colores — alinear con STD-001 (`#2563EB`, `#1E293B`, `#F5F7FA`) | core/theme, sidebar |
| C4 | Bug: ausentes hoy puede ser negativo — agregar `max(0, ...)` | reports |
| C5 | Muestra `workplaceId` raw — resolver nombre del lugar en historial | attendance |

### Alto — Antes del MVP

| # | Item | Modulos |
|---|------|---------|
| A1 | Completar data/domain de Reports — implementar `ReportModel` y `ReportRepository` | reports |
| A2 | Completar data/domain de Dashboard — implementar `DashboardDataModel` y `DashboardRepository` | dashboard |
| A3 | Completar data/domain de History — implementar `HistoryRepository` | history |
| A4 | Implementar flujo de aprobacion de justificativos — usar `MedicalDocumentEstado` | medical_documents |
| A5 | Revocar Auth en soft-delete de empleados — llamar Admin SDK | employees |
| A6 | Agregar gates de rol a Reports — admin/supervisor ven todo, empleado no | reports |
| A7 | Limpiar locks huerfanos — mecanismo de limpieza o override admin | attendance |
| A8 | Eliminar dead code — `employee_form_fields.dart`, `core/theme/app_colors.dart`, `profile_screen.dart` (auth) | employees, core, authentication |

### Medio — Mejoras importantes

| # | Item | Modulos |
|---|------|---------|
| M1 | Centralizar `storageServiceProvider` en core | medical_documents |
| M2 | Desacoplar domain de data — mover `UserModel` a shared, definir entidades domain | employees, medical_documents, incidences |
| M3 | Extraer widgets compartidos — `_IndicatorCard`, `_InfoChip`, `_DetailRow`, `_formatDate` | core/presentation/widgets |
| M4 | Mover `CreateEmployeeNotifier` a archivo propio | employees |
| M5 | Unificar auth-state — eliminar duplicacion `AuthStateListenable` vs `auth_provider` | authentication |
| M6 | Agregar DatePicker en filtro de fechas de Reports | reports |
| M7 | Mover streams Firestore a providers compartidos — evitar 3 suscripciones a `attendances` | reports, history |
| M8 | Corregir `TextEditingController` en build() — usar `value` o mover a state | filter bars |
| M9 | Verificar que `incidence_model.dart` tenga `IncidenceState.fromString()` | incidences |
| M10 | Agregar modo edicion a Profile | profile |

### Bajo — Deuda tecnica

| # | Item | Modulos |
|---|------|---------|
| D1 | Eliminar TODO stubs vacios o implementarlos | reports, dashboard, history, core |
| D2 | Centralizar `firestoreServiceProvider` en 3 archivos | attendance, workplaces, employees |
| D3 | Agregar tests unitarios y de widget | todo el proyecto |
| D4 | Agregar paginacion a queries Firestore | attendance, history, employees |
| D5 | Corregir colores hardcoded para usar `AppColors` | sidebar, dashboard_layout, profile |
| D6 | Evaluar revocacion de Auth en soft-delete de workplaces | employees |
| D7 | Agregar validacion de telefono en `Validators` | core |
| D8 | Completar `IncidenceState.fromString()` | incidences |

---

## 8. Recomendacion Final

**LOCUSTAF NO esta listo para fase de implementacion masiva con Antigravity en su estado actual.**

### Razones

1. Problemas criticos de seguridad — usuarios desactivados pueden hacer login, Auth no se revoca en soft-delete
2. Duplicacion de `firestoreServiceProvider` — riesgo de errores de compilacion y comportamiento impredecible
3. 4 features sin data/domain layer — reports, dashboard, history y profile no siguen Clean Architecture
4. Paleta de colores no coincide con STD-001 — inconsistencia visual con la especificacion
5. Sin tests — cero cobertura de pruebas
6. Reglas de negocio de asistencia incompletas — 6 de 9 reglas del STD-001 no implementadas

### Que se necesita antes de escalar

**Fase minima (1-2 sesiones):**
- Corregir los 5 items Criticos (C1-C5)
- Limpiar dead code (A8)

**Fase MVP (3-5 sesiones):**
- Completar data/domain de Reports, Dashboard, History (A1-A3)
- Implementar flujo de aprobacion de justificativos (A4)
- Agregar gates de rol (A6)
- Limpiar locks huerfanos (A7)

**Fase pre-produccion:**
- Centralizar providers y widgets compartidos (M1-M3)
- Desacoplar domain de data (M2)
- Agregar tests (D3)
- Completar reglas de negocio de asistencia (turnos, tolerancia, horas extra)

### Verdicto

LOCUSTAF tiene una base solida — la arquitectura Feature First + Riverpod + GoRouter esta bien establecida, los modulos core (auth, employees, workplaces) estan maduros, y el sistema de asistencia con geolocalizacion y locks funciona. Sin embargo, hay deuda tecnica significativa que debe resolverse antes de confiar el proyecto a herramientas automatizadas de generacion masiva de codigo, ya que estos problemas se amplificarian.

---

## Fase de Implementacion

| Fase | Items | Estado |
|------|-------|--------|
| Critico (C1-C5) | firestoreServiceProvider, isActive login, colores, negativos, workplaceId | Pendiente |
| Dead code (A8) | employee_form_fields, app_colors.dart, profile_screen.dart (auth) | Pendiente |
| Alto MVP (A1-A3) | data/domain Reports, Dashboard, History | Pendiente |
| Alto MVP (A4-A8) | justificativos aprobacion, auth soft-delete, gates rol, locks cleanup | Pendiente |
| Medio (M1-M10) | centralizar providers, desacoplar, extraer widgets, auth-state, etc. | Pendiente |
| Bajo (D1-D8) | TODO stubs, tests, paginacion, colores, etc. | Pendiente |

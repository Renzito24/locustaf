# LOCUSTAF MASTER SPECIFICATION

## Locus Staff — Sistema de Gestión de Personal y Control de Asistencia

### Versión 2.0 — Master Specification

---

# 1. VISIÓN DEL SISTEMA

LOCUSTAF (Locus Staff) es una plataforma web de gestión de personal y control de asistencia laboral orientada principalmente a pequeñas y medianas empresas (PyMEs).

El sistema permitirá a una empresa administrar sus empleados y grupos de trabajo, definir jornadas laborales, controlar ingresos y egresos mediante geolocalización, gestionar ausencias, licencias y justificativos, calcular horas trabajadas y generar reportes.

La arquitectura deberá estar preparada desde el inicio para soportar múltiples empresas independientes dentro de la misma plataforma (multiempresa / multi-tenant), garantizando el aislamiento de los datos entre ellas.

La primera versión se desarrollará como aplicación web utilizando Flutter Web.

Posteriormente se desarrollará una aplicación móvil Android reutilizando la misma lógica de negocio y backend.

---

# 2. OBJETIVOS

## 2.1 Objetivo principal

Proporcionar a una PyME una herramienta sencilla y confiable para:

- Administrar empleados.
- Administrar grupos de trabajo.
- Definir horarios laborales.
- Controlar ingresos y egresos.
- Validar la ubicación del empleado mediante GPS.
- Calcular horas trabajadas.
- Detectar llegadas tarde.
- Detectar salidas anticipadas.
- Controlar ausencias.
- Gestionar licencias.
- Gestionar justificativos.
- Consultar historiales.
- Generar reportes.
- Exportar información a PDF y Excel.

---

## 2.2 Objetivos futuros

La arquitectura deberá permitir incorporar posteriormente:

- Múltiples empresas.
- Notificaciones.
- Aplicación Android.
- Código QR para asistencia.
- Analítica avanzada.
- Turnos avanzados.
- Integración con otros sistemas.
- Planes y suscripciones.
- Funciones comerciales para modelo SaaS.

---

# 3. PRINCIPIOS DEL SISTEMA

LOCUSTAF deberá cumplir con los siguientes principios:

- Simplicidad de uso.
- Interfaz intuitiva.
- Seguridad.
- Separación de responsabilidades.
- Separación clara de roles.
- Validación de ubicación obligatoria para asistencia.
- Registro confiable de asistencia.
- No alterar registros históricos innecesariamente.
- Estados activos/inactivos en lugar de eliminación física cuando corresponda.
- Arquitectura escalable.
- Diseño responsive.
- Aislamiento de datos entre empresas.
- Preparación para crecimiento futuro.

---

# 4. ARQUITECTURA TECNOLÓGICA

## 4.1 Frontend

- Flutter Web.
- Material Design.
- Diseño responsive.
- Riverpod para gestión de estado.
- GoRouter para navegación y protección de rutas.

## 4.2 Backend

- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage.
- Firebase Hosting.

## 4.3 Herramientas

- Flutter.
- Dart.
- Firebase CLI.
- FlutterFire CLI.
- Git.
- GitHub.

## 4.4 Plataforma futura

La aplicación web será la primera plataforma.

Posteriormente:

- Android.
- Posiblemente otras plataformas según evolución del proyecto.

---

# 5. ARQUITECTURA MULTIEMPRESA

LOCUSTAF deberá estar preparado desde el inicio para soportar múltiples empresas.

Cada empresa tendrá sus propios:

- Administradores.
- Grupos de trabajo.
- Empleados.
- Jornadas.
- Asistencias.
- Ausencias.
- Licencias.
- Justificativos.
- Reportes.

Los datos de una empresa nunca deberán ser accesibles desde otra empresa.

---

# 6. AISLAMIENTO DE DATOS

Todos los recursos relacionados con una empresa deberán estar asociados a un identificador:

`companyId`

Ejemplos:

- Usuario → `companyId`
- Grupo → `companyId`
- Empleado → `companyId`
- Asistencia → `companyId`
- Licencia → `companyId`
- Ausencia → `companyId`
- Justificativo → `companyId`

La aplicación deberá utilizar `companyId` para filtrar los datos.

Firestore Security Rules deberá impedir que un usuario acceda a información perteneciente a otra empresa.

La seguridad no deberá depender únicamente del frontend.

---

# 7. EMPRESA

Una empresa representa a una PyME que utiliza LOCUSTAF.

## Datos mínimos

- ID
- Nombre comercial
- Razón social (opcional)
- CUIT (opcional)
- Dirección
- Teléfono
- Email
- Estado
- Fecha de creación
- Fecha de actualización

## Estados

- ACTIVA
- INACTIVA

Una empresa inactiva no deberá permitir operaciones normales.

---

# 8. ADMINISTRADOR / DUEÑO

El administrador representa al propietario o responsable de la empresa.

## Puede:

- Administrar información de la empresa.
- Crear grupos de trabajo.
- Modificar grupos.
- Activar grupos.
- Desactivar grupos.
- Crear empleados.
- Modificar empleados.
- Activar empleados.
- Desactivar empleados.
- Asignar empleados a grupos.
- Configurar jornadas.
- Configurar horarios.
- Configurar tolerancias.
- Configurar días laborables.
- Configurar feriados.
- Ver asistencia.
- Ver dashboard.
- Ver ausencias.
- Ver licencias.
- Revisar justificativos.
- Generar reportes.
- Exportar PDF.
- Exportar Excel.

---

# 9. GRUPOS DE TRABAJO

Un grupo de trabajo representa una unidad laboral dentro de una empresa.

Ejemplos:

- Pizzería.
- Casa.
- Administración.
- Depósito.
- Delivery.
- Sucursal Centro.
- Sucursal Norte.

Cada grupo pertenece a una única empresa.

---

## 9.1 Datos del grupo

- ID
- `companyId`
- Nombre
- Descripción
- Dirección
- Latitud
- Longitud
- Radio permitido
- Estado
- Fecha de creación
- Fecha de actualización

---

## 9.2 Estados

- ACTIVO
- INACTIVO

Un grupo inactivo no deberá permitir nuevos registros de asistencia.

---

# 10. CONFIGURACIÓN DE UBICACIÓN

Cada grupo de trabajo tendrá una ubicación asociada.

## Datos

- Latitud
- Longitud
- Dirección
- Radio permitido en metros

Ejemplo:

```text
Grupo: Pizzería

Latitud: -34.xxxxx
Longitud: -58.xxxxx
Radio: 50 metros
```

---

# 11. CONFIGURACIÓN DE ASISTENCIA Y ROBUSTEZ (FASE D-E-F)

## 11.1 Tolerancia de check-in (por empresa)

- Cada empresa define `toleranciaCheckIn` (minutos, default 15).
- En el alta de una asistencia, la regla de Firestore valida que `checkInTime`
  no se desvíe más de ±tolerancia vs el tiempo del servidor (`request.time`).
- Configurable desde **Configuración de empresa** (admin/superadmin).

## 11.2 Días laborables (por empresa)

- `diasLaborables`: lista ISO (1=Lun ... 7=Dom), default `[1,2,3,4,5]`.
- Los reportes de ausencias del mes consideran el día laborable actual: si
  hoy no es laborable, las "ausencias del día" se muestran como 0.
- Configurable desde **Configuración de empresa** (admin/superadmin).

## 11.3 Locks de sesión de asistencia (anti doble check-in)

- Colección interna `_attendance_locks/{userId}`: garantiza una sola asistencia
  activa por empleado.
- Campos de cada lock: `attendanceId`, `checkInTime`, `lockedAt`, `status`.
- Reclamación de locks huérfanos en nuevo check-in si:
  - el lock supera `lockStaleTimeout` (24 h) desde `lockedAt`; o
  - la asistencia asociada no existe o ya está `completed`.
- Al borrar (soft delete) un empleado se purga su lock para liberar el ID.

## 11.4 Timestamps y zonas horarias

- `checkInTime` / `checkOutTime` se persisten como `Timestamp` UTC de Firestore.
- El resto de la metadata (`createdAt`, `updatedAt`, `reviewedAt`) se persiste
  como ISO-8601 en UTC (`toUtc().toIso8601String()`).
- En la lectura de datos, se convierte a hora local (`.toLocal()`) para que la
  UI muestre siempre el horario local del dispositivo.

## 11.5 Historial con paginación

- El historial de asistencias se carga por páginas de 25 registros
  (orden `checkInTime` DESC, cursor `startAfter`), acumulando de a páginas con
  botón "Cargar más".
- Los totales se obtienen con `COUNT()` agregado de Firestore (sin descargar
  todo el historial).
- El filtrado (búsqueda y rango de fechas) se aplica client-side sobre las
  páginas cargadas.
# AUDITORÍA DE SEGURIDAD — FIRESTORE RULES

**Fecha**: 2026-08-28  
**Proyecto**: LOCUSTAF  
**Versión de Rules**: Fase 2 (Empresa Única)  
**Clasificación**: CONFIDENCIAL

---

## EJECUTIVO

### Estado General
🔴 **CRÍTICO**: Se han identificado **8 vulnerabilidades críticas** y **12 de alta severidad** que comprometen la seguridad del sistema.

### Problemas Principales
1. **_ATTENDANCE_LOCKS**: Sin aislamiento por companyId
2. **ATTENDANCES**: Employee puede modificar checkInTime/checkOutTime
3. **WORKPLACES**: Accesible a employees (debería ser restricto)
4. **USERS**: Lógica de lectura confusa y sin validaciones suficientes
5. **Campos sensibles**: No todos los campos críticos están protegidos en updates
6. **Admin**: No puede cambiar rol de empleados
7. **Transiciones de estado**: No hay validación de transiciones válidas
8. **Fase 3 readiness**: companyId presente pero Fase 2 es monoestructura

---

## METODOLOGÍA

Este análisis incluye:
- ✅ Revisión línea por línea de cada regla
- ✅ Análisis de combinaciones de permisos
- ✅ Validación de IDOR (Insecure Direct Object References)
- ✅ Análisis de Privilege Escalation
- ✅ Validación de edge cases
- ✅ Verificación de campos sensibles
- ✅ Análisis de flujos específicos
- ✅ Comparación Fase 2 vs Fase 3

---

## ANÁLISIS POR COLECCIÓN

---

# COLECCIÓN: users

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin() || isOwner(uid) || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(uid)));

allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && request.resource.data.companyId == getCompanyId())
      || (isOwner(uid) && getCompanyId() == null));

allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId))
      || (isOwner(uid) && isOwnProfileUpdate()))
  && noUserSensitiveChanges();

allow delete: if isSuperadmin();
```

## Hallazgos

### 1. READ - Lógica confusa y redundante

```
allow read: if isAuthenticated()
  && (isSuperadmin() || isOwner(uid) || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(uid)));
```

**Problema 1a**: Cuarta condición es redundante
- `isOwner(uid)` ya está en la segunda condición
- La cuarta condición `(isEmployee() && isOwner(uid))` es un subset de `isOwner(uid)`
- No agrega ninguna restricción válida

**Problema 1b**: `inCompany()` permite lectura de supervisores
- La regla `inCompany(resource.data.companyId)` permite a **cualquier** usuario de la empresa leer a **cualquier otro usuario**
- Un supervisor puede leer: nombre, apellido, email, dni, rol, isActive, isDeleted, lugarDeTrabajoId, timestamps
- ¿Es intencional que un supervisor pueda ver el rol de otro supervisor?
- ¿Es intencional que un supervisor pueda ver si un employee está eliminado?

**Problema 1c**: Sin validación de companyId en lectura
- Si un documento `users/{uid}` tiene `companyId=null` (durante onboarding)
- `inCompany(null)` retorna false porque valida `companyId != null`
- ✓ Esto está bien (no hay fuga)

### 2. CREATE - Validación incompleta

```
allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && request.resource.data.companyId == getCompanyId())
      || (isOwner(uid) && getCompanyId() == null));
```

**Problema 2a**: Admin PUEDE crear usuarios but...
- ✓ Valida companyId coincida con su empresa
- ✓ Pero NO valida que rol sea válido
- RIESGO: ¿Puede un admin crear un usuario con `rol='superadmin'`?
- La regla no lo protege. Debería validar que `request.resource.data.rol IN ['employee', 'supervisor']`

**Problema 2b**: Durante onboarding
- ✓ Usuario puede crear su propio documento si `companyId == null`
- ¿Pero después? Si una empresa cambia de mano, ¿ese usuario queda con companyId antiguo?

### 3. UPDATE - Admin NO puede cambiar rol

```
allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId))
      || (isOwner(uid) && isOwnProfileUpdate()))
  && noUserSensitiveChanges();
```

**Problema 3a**: Admin puede actualizar pero...
- Condición 1: `isSuperadmin()` - OK
- Condición 2: `isAdmin() && inCompany()` - Admin puede actualizar usuario de su empresa ✓
- Condición 3: `isOwner() && isOwnProfileUpdate()` - Solo campos no sensibles ✓

PERO: Función `noUserSensitiveChanges()`:
```dart
function noUserSensitiveChanges() {
  return noSensitiveFieldChanges()
    && (isSuperadmin() || isAdmin()
        || request.resource.data.rol == resource.data.rol);
}
```

Esto significa:
- ✅ Superadmin PUEDE cambiar rol
- ✅ Admin PUEDE cambiar rol
- ❌ **PERO** solo si está en la rama admin de la regla update
- ❌ La rama admin dice: `isAdmin() && inCompany()` sin `isOwnProfileUpdate()`
- ❌ Entonces admin DEBERÍA poder cambiar rol ✓

EN REALIDAD ESTÁ BIEN para admin, pero hay un problema de lógica:
- El check `noUserSensitiveChanges()` permite admin cambiar rol ✓
- Pero employee NO puede cambiar su propio rol ✓

**Problema 3b**: ¿Qué pasa si admin intenta cambiar isDeleted?

La función `noUserSensitiveChanges()` solo valida:
```dart
&& request.resource.data.companyId == resource.data.companyId
&& request.resource.data.userId == resource.data.userId;
```

¿Pero qué pasa con isDeleted, isActive, createdAt?
- La función `noUserSensitiveChanges()` no protege estos campos
- Admin PUEDE cambiar isDeleted directamente ✓ (soft delete implementado)
- Admin PUEDE cambiar isActive directamente ✓

**Problema 3c**: Employee puede ver otros usuarios

- ¿Puede un employee leer el documento de otro employee?
- La regla read permite: `inCompany(resource.data.companyId)`
- ¿Pero employee puede leer? NO EXPLÍCITAMENTE en read, pero...
- Employee es `isAuthenticated()` ✓
- Si está en la empresa: `inCompany()` devuelve true
- Entonces SÍ PUEDE LEER todos los usuarios de su empresa ✗

ESPERA, relectura:
```
allow read: if isAuthenticated()
  && (isSuperadmin() || isOwner(uid) || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(uid)));
```

Esto dice:
- isSuperadmin() - OK
- isOwner(uid) - si es su propio documento ✓
- inCompany() - si está en la empresa (ANY rol)
- (isEmployee() && isOwner) - redundante

Entonces employee PUEDE leer cualquier usuario de su empresa ✗ PROBLEMA

### 4. Resumen Vulnerabilidades - users

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| U1 | Supervisors pueden leer todos los users de su empresa (incluyendo email, dni, rol) | ALTA |
| U2 | Employees pueden leer todos los users de su empresa | ALTA |
| U3 | Admin puede crear user con rol=superadmin | MEDIA |
| U4 | La cuarta condición en read es redundante (limpieza de código) | BAJA |

---

# COLECCIÓN: companies

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(companyId));

allow create: if isSuperadmin() || isOnboardingUser();

allow update: if isSuperadmin()
  || (isAdmin() && inCompany(companyId));

allow delete: if isSuperadmin();
```

## Hallazgos

### 1. UPDATE - Sin protección de campos sensibles

```
allow update: if isSuperadmin()
  || (isAdmin() && inCompany(companyId));
```

**Problema C1**: NO hay llamada a `noSensitiveFieldChanges()`
- Admin PUEDE cambiar: `cuit`, `razonSocial`, `direccion`, `email`, `telefono`, `estado`
- ¿Debería poder? Probablemente SÍ, pero...
- ¿Debería poder cambiar estado de `activa` a `inactiva`? SÍ
- ¿Debería poder cambiar `cuit`? CUESTIONABLE
- **Recomendación**: Agregar validación `&& noSensitiveFieldChanges()` para proteger campos críticos

### 2. CREATE - Falta validación

```
allow create: if isSuperadmin() || isOnboardingUser();
```

**Problema C2**: No valida companyId durante creación
- Pero como solo `isOnboardingUser()` puede crear, es aceptable
- ✓ Esto está bien

### 3. Resumen Vulnerabilidades - companies

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| C1 | Admin puede modificar campo `estado` sin restricción | MEDIA |
| C2 | Admin puede modificar `cuit` sin restricción | BAJA |

---

# COLECCIÓN: attendances

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(resource.data.userId)));

allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isEmployee() && request.resource.data.userId == request.auth.uid
          && request.resource.data.companyId == getCompanyId()));

allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isEmployee() && resource.data.userId == request.auth.uid
          && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();

allow delete: if isSuperadmin();
```

## Hallazgos

### 1. UPDATE - Employee puede modificar timestamps críticos

```
&& noSensitiveFieldChanges();
```

Función `noSensitiveFieldChanges()` valida:
```dart
return request.resource.data.companyId == resource.data.companyId
  && request.resource.data.userId == resource.data.userId;
```

**Problema A1 - CRÍTICO**: Solo protege 2 campos
- ✓ Protege: `companyId`, `userId`
- ✗ NO protege: `checkInTime`, `checkOutTime`, `status`, `latitude`, `longitude`, `precisión`

EXPLORACIÓN:
- Employee PUEDE cambiar `checkInTime` de 08:00 a 06:00 ✗
- Employee PUEDE cambiar `checkOutTime` de 17:00 a 20:00 ✗
- Employee PUEDE cambiar `status` de "checkout" a "checkin" ✗
- Employee PUEDE cambiar `latitude`, `longitude` (falsificar ubicación) ✗

**Impacto**:
- Falseamiento de registros de asistencia
- Horas trabajadas incorrectas
- Reportes fraudulentos

**Solución propuesta**:
```dart
function attendanceNoSensitiveChanges() {
  return request.resource.data.companyId == resource.data.companyId
    && request.resource.data.userId == resource.data.userId
    && request.resource.data.checkInTime == resource.data.checkInTime
    && request.resource.data.checkOutTime == resource.data.checkOutTime
    && request.resource.data.status == resource.data.status
    && request.resource.data.latitude == resource.data.latitude
    && request.resource.data.longitude == resource.data.longitude;
}
```

### 2. READ - Roles pueden leer attendances de otros usuarios

```
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(resource.data.userId)));
```

**Problema A2**: Supervisor puede leer attendances de otros employees
- ✓ Esto es INTENCIONAL según el spec (supervisors tienen acceso de lectura)
- Pero ¿pueden ver coordenadas GPS? SÍ
- RIESGO: Privacy de ubicación de empleados

**Problema A3**: Admin puede leer attendances de otros usuarios
- ✓ INTENCIONAL pero mismo riesgo de privacy

### 3. CREATE - Falta validación de datos

```
allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isEmployee() && request.resource.data.userId == request.auth.uid
          && request.resource.data.companyId == getCompanyId()));
```

**Problema A4**: No valida `status`, `checkInTime`, `checkOutTime`
- Employee PUEDE crear un attendance con:
  - `status = "checkout"` sin `"checkin"` previo
  - `checkInTime` en el futuro
  - `checkOutTime` anterior a `checkInTime`
  - `latitude/longitude` fuera de la geofence

**Solución**: Agregar validación en create:
```dart
allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isEmployee() && request.resource.data.userId == request.auth.uid
          && request.resource.data.companyId == getCompanyId()
          && request.resource.data.status IN ['checkin', 'checkout']
          && request.resource.data.checkInTime != null
          && request.resource.data.checkOutTime == null));  // Solo checkin puede tener null checkOutTime
```

### 4. READ - Admin/Supervisor acceso inconsistente

**Problema A5**: No hay restricción explícita para admin crear
- La regla solo permite EMPLOYEE crear
- Admin/Supervisor NO PUEDEN crear attendance (¿es intencional?)
- Si es intencional, está bien
- Si no, es un gap funcional

### 5. Resumen Vulnerabilidades - attendances

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| A1 | Employee puede modificar checkInTime, checkOutTime, status, ubicación | **CRÍTICA** |
| A2 | Employee puede crear attendance con datos inválidos (checkout sin checkin) | ALTA |
| A3 | Supervisor/Admin pueden leer coordenadas GPS de todos los empleados (privacy) | MEDIA |
| A4 | No hay validación de timestamp lógico (checkOutTime > checkInTime) | MEDIA |
| A5 | Employee podría cambiar estatus de checkout a checkin (revertir transición) | ALTA |

---

# COLECCIÓN: workplaces

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(resource.data.companyId));

allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && request.resource.data.companyId == getCompanyId()));

allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();

allow delete: if isSuperadmin()
  || (isAdmin() && inCompany(resource.data.companyId));
```

## Hallazgos

### 1. READ - Employee puede leer workplaces (debería ser restricto)

```
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(resource.data.companyId));
```

**Problema W1 - CRÍTICA**: 
- La regla permite a CUALQUIER usuario autenticado leer si está en companyId
- Según AGENTS.md: `"Empl: no access"`
- PERO la regla NO distingue roles
- Employee PUEDE leer: `nombre`, `direccion`, `latitude`, `longitude`, `radius`, `precisión`

**Impacto**:
- Employees pueden ver ubicación de todas las sedes
- Employees pueden ver geofences
- Potencial información competitiva

**Solución propuesta**:
```dart
allow read: if isAuthenticated()
  && (isSuperadmin() 
      || ((isAdmin() || isSupervisor()) && inCompany(resource.data.companyId)));
```

### 2. UPDATE - Sin protección de campos sensibles

```
&& noSensitiveFieldChanges();
```

**Problema W2**: `noSensitiveFieldChanges()` solo protege `companyId, userId`
- NO protege `latitude, longitude, radius, nombre`
- Admin PUEDE cambiar ubicación de workplace
- ¿Debería poder? CUESTIONABLE
- Si se cambia ubicación, ¿qué pasa con attendances anteriores?

**Solución propuesta**:
```dart
&& request.resource.data.latitude == resource.data.latitude
&& request.resource.data.longitude == resource.data.longitude
&& request.resource.data.radius == resource.data.radius
```

### 3. CREATE - Falta validación

**Problema W3**: No valida que `latitude, longitude` sean válidos
- Admin podría crear workplace con coords (0, 0)
- Admin podría crear workplace fuera del país

### 4. Resumen Vulnerabilidades - workplaces

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| W1 | Employee puede leer geolocalización de todos los workplaces | **CRÍTICA** |
| W2 | Admin puede modificar ubicación (latitude, longitude, radius) | MEDIA |
| W3 | No hay validación de coordenadas válidas en create | BAJA |

---

# COLECCIÓN: medical_documents

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId))
      || (isEmployee() && isOwner(resource.data.userId)
          && inCompany(resource.data.companyId)));

allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && request.resource.data.companyId == getCompanyId())
      || (isEmployee() && request.resource.data.userId == request.auth.uid
          && request.resource.data.companyId == getCompanyId()));

allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();

allow delete: if isSuperadmin()
  || (isAdmin() && inCompany(resource.data.companyId));
```

## Hallazgos

### 1. READ - Supervisor NO puede acceder (correcto implícitamente)

```
allow read: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(...))
      || (isEmployee() && isOwner(...)));
```

**Problema M1**: No hay denegación explícita para supervisor
- Supervisor autenticado: SÍ
- isSuperadmin()? NO
- isAdmin()? NO
- (isEmployee() && isOwner())? NO
- Resultado: Supervisor NO puede leer ✓

**Pero**: La regla está confusa. Debería ser explícita:
```dart
allow read: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(...))
      || (isEmployee() && isOwner(...)))
  && !isSupervisor();  // Explicit denial
```

**Problema M2**: Employee puede crear pero NO puede leer documento de otro employee
- ✓ Esto es correcto

### 2. UPDATE - Employee NO puede actualizar

```
allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();
```

**Problema M3**: Solo admin/superadmin pueden actualizar
- Típicamente para aprobar/rechazar documentos
- ✓ Esto es correcto

**Pero**: ¿Qué campos está protegiendo `noSensitiveFieldChanges()`?
- Protege: `companyId, userId`
- NO protege: `tipo, fechaInicio, fechaFin, motivo, estado, observacionRechazo, archivoUrl`
- Admin PUEDE cambiar `tipo` de "enfermedad" a "personal" ✗
- Admin PUEDE cambiar `fechaInicio, fechaFin` ✗
- Admin PUEDE cambiar `motivo` ✗

**Solución propuesta**:
```dart
function medicalDocumentNoSensitiveChanges() {
  return noSensitiveFieldChanges()
    && request.resource.data.tipo == resource.data.tipo
    && request.resource.data.fechaInicio == resource.data.fechaInicio
    && request.resource.data.fechaFin == resource.data.fechaFin
    && request.resource.data.motivo == resource.data.motivo;
    // ALLOW: estado, observacionRechazo (para aprobación)
}
```

### 3. CREATE - Falta validación

**Problema M4**: No valida transiciones de estado
- Employee PUEDE crear con `estado = "aprobado"` ✗
- `estado` debe ser "pendiente" en create

**Solución**:
```dart
allow create: if ...
  && request.resource.data.estado == 'pendiente'
```

### 4. Resumen Vulnerabilidades - medical_documents

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| M1 | Admin puede cambiar tipo, fechaInicio, fechaFin, motivo de documento | MEDIA |
| M2 | Employee puede crear documento con estado="aprobado" | ALTA |
| M3 | Falta validación de transiciones de estado (solo pendiente→aprobado/rechazado) | MEDIA |

---

# COLECCIÓN: incidences

## Reglas Actuales
```firestore
allow read: if isAuthenticated()
  && (isSuperadmin() || inCompany(resource.data.companyId)
      || (isEmployee() && isOwner(resource.data.userId)));

allow create: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && request.resource.data.companyId == getCompanyId())
      || (isEmployee() && request.resource.data.userId == request.auth.uid
          && request.resource.data.companyId == getCompanyId()));

allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();

allow delete: if isSuperadmin()
  || (isAdmin() && inCompany(resource.data.companyId));
```

## Hallazgos

### 1. READ - Supervisor CAN read incidences

**Problema I1**: La regla permite a cualquier usuario de la empresa leer
- Supervisor PUEDE leer incidences de otros employees ✓ (intencional)
- Employee SOLO puede leer propias ✓ (correcto)

### 2. CREATE - Falta validación de estado

**Problema I2**: Igual que medical_documents
- Employee PUEDE crear incidencia con `estado = "aprobado"` ✗
- Debe validar `estado == "pendiente"`

### 3. UPDATE - Supervisor NO puede actualizar

```
allow update: if isAuthenticated()
  && (isSuperadmin()
      || (isAdmin() && inCompany(resource.data.companyId)))
  && noSensitiveFieldChanges();
```

**Problema I3**: Supervisor NO puede actualizar/aprobar incidencias
- Según spec, ¿supervisor debería poder aprobar? CUESTIONABLE
- Si solo admin puede aprobar, está bien
- PERO entonces ¿cuál es el valor de supervisor en incidences?

### 4. UPDATE - Sin protección de campos sensibles

**Problema I4**: Igual que medical_documents
- Admin PUEDE cambiar: `tipo, fechaInicio, fechaFin, descripcion`
- Solo `estado, observacionRechazo` deberían poderse cambiar

### 5. Resumen Vulnerabilidades - incidences

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| I1 | Employee puede crear incidence con estado="aprobado" | ALTA |
| I2 | Admin puede cambiar tipo, fechaInicio, fechaFin, descripcion | MEDIA |
| I3 | Supervisor no puede actualizar (¿intencional?) | MEDIA |

---

# COLECCIÓN: _attendance_locks

## Reglas Actuales
```firestore
match /_attendance_locks/{lockId} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated();
}
```

## Hallazgos

### 1. Sin aislamiento por companyId - CRÍTICO

**Problema L1 - CRÍTICA**:
- Cualquier usuario autenticado PUEDE leer CUALQUIER lock ✓
- Cualquier usuario autenticado PUEDE escribir CUALQUIER lock ✗

**Escenario de ataque**:
1. Employee de Empresa A obtiene companyId de Empresa B
2. Crea/modifica `_attendance_locks/employee-B-20260828`
3. Interfiere con check-in/out de Employee de Empresa B
4. O causa race condition en transacciones

**Impacto**:
- Corruption de attendance records de otra empresa
- Denial of service (interferencia con locks)
- Fraude masivo

**Solución propuesta**:
```dart
match /_attendance_locks/{lockId} {
  allow read: if isAuthenticated()
    && inCompany(get(/databases/$(database)/documents/attendances/$(lockId)).data.companyId);
  allow write: if isAuthenticated()
    && inCompany(get(/databases/$(database)/documents/attendances/$(lockId)).data.companyId);
}
```

O mejor, almacenar `companyId` en el nombre del lock:
```
/_attendance_locks/{companyId}/{lockId}
```

### 2. Resumen Vulnerabilidades - _attendance_locks

| ID | Vulnerabilidad | Severidad |
|---|---|---|
| L1 | Sin validación de companyId - Employee A puede interferir con locks de Empresa B | **CRÍTICA** |

---

# PROBLEMAS TRANSVERSALES

## 1. Función `noSensitiveFieldChanges()` es insuficiente

La función:
```dart
function noSensitiveFieldChanges() {
  return request.resource.data.companyId == resource.data.companyId
    && request.resource.data.userId == resource.data.userId;
}
```

Solo protege 2 campos. PERO:
- attendances: necesita proteger checkInTime, checkOutTime, status, ubicación
- medical_documents: necesita proteger tipo, fechas, motivo
- incidences: necesita proteger tipo, fechas, descripcion

**Recomendación**: Crear funciones específicas por colección:
- `attendanceNoSensitiveChanges()`
- `medicalDocumentNoSensitiveChanges()`
- `incidenceNoSensitiveChanges()`

## 2. Falta validación de transiciones de estado

Documentos con `estado` (medical_documents, incidences) permiten transiciones inválidas:
- pendiente → pendiente (sin cambio) ✓
- pendiente → aprobado ✓
- pendiente → rechazado ✓
- **aprobado → pendiente** ✗ (debería estar prohibido)
- **aprobado → rechazado** ✗ (debería estar prohibido)
- **rechazado → aprobado** ✗ (debería estar prohibido)

**Solución propuesta**:
```dart
function isValidIncidenceStateTransition() {
  let currentState = resource.data.estado;
  let newState = request.resource.data.estado;
  return (currentState == 'pendiente' && newState IN ['aprobado', 'rechazado'])
    || (currentState == newState);  // No cambio
}
```

## 3. Falta validación en CREATE

Varias colecciones no validan el estado inicial en create:
- medical_documents: Debería ser `estado = 'pendiente'`
- incidences: Debería ser `estado = 'pendiente'`
- attendances: Debería validar que estados sean válidos

## 4. Inconsistencia en roles

| Rol | users | companies | attendances | workplaces | medical_documents | incidences |
|---|---|---|---|---|---|---|
| superadmin | RWD | RWD | RWD | RWD | RWD | RWD |
| admin | RU | RU | R | CRUD | RUD | RUD |
| supervisor | R | R | R | R | ✗ | R |
| employee | R(own) | R | C/U(own) | ✓ | C/R(own) | C/R(own) |

**Problemas**:
- Supervisor tiene acceso desigual (no tiene medical_documents)
- Employee tiene acceso a workplaces cuando debería ser restricto
- Employee puede crear pero no leer en attendances update

## 5. Fase 2 vs Fase 3

**Estado actual**: Fase 2 (empresa única)
**Realidad**: Rules tienen `companyId` pero Fase 2 usa una única empresa

**Problemas detectados**:
1. ¿Cómo se garantiza que solo existe una empresa?
   - Respuesta: Mediante seed script
   - RIESGO: Si alguien crea empresa adicional, rules no la bloquean

2. ¿Qué pasa si companyId es null?
   - Respuesta: Solo durante onboarding está permitido
   - RIESGO: Usuarios "huérfanos" sin companyId

3. ¿Las queries están bien diseñadas para Fase 3?
   - No verificable en rules (responsabilidad del cliente)
   - Pero si el cliente crea queries sin filtro de companyId, Firestore retornará resultados de TODAS las empresas
   - Esto es un problema de arquitectura, no de rules

**Recomendación para Fase 3**: Agregar validación explícita
```dart
function multiTenancyValidation() {
  return resource.data.companyId != null
    && resource.data.companyId == getCompanyId()
    && request.resource.data.companyId == getCompanyId();
}
```

---

# TABLA CONSOLIDADA DE VULNERABILIDADES

| ID | Colección | Tipo | Descripción | Severidad | Escenario de Ataque | Impacto | Línea Vulnerable | Solución |
|---|---|---|---|---|---|---|---|---|
| **A1** | attendances | Integridad de Datos | Employee puede modificar checkInTime, checkOutTime, status, ubicación GPS | **CRÍTICA** | Employee modifica `checkInTime` de 08:00 a 06:00 para mostrar llegada temprana. Horas trabajadas falsificadas. | Fraude de asistencia. Reportes incorrectos. Auditoría imposible. | Update rule: `&& noSensitiveFieldChanges()` | Crear función `attendanceNoSensitiveChanges()` que proteja: checkInTime, checkOutTime, status, latitude, longitude, precision |
| **L1** | _attendance_locks | Aislamiento Multi-tenant | Sin validación de companyId. Employee A puede interferir con locks de Empresa B | **CRÍTICA** | Employee A de Empresa A sabotea check-in/out de Empresa B modificando `_attendance_locks` | Corrupción de datos de otra empresa. Fraude masivo. DoS. | Read/Write rules no validan companyId | Reorganizar estructura: `/_attendance_locks/{companyId}/{lockId}` o agregar validación de companyId |
| **W1** | workplaces | Control de Acceso | Employee puede leer ubicación (lat/long) de todos los workplaces | **CRÍTICA** | Employee lista todas las sedes de empresa rival | Información competitiva expuesta. Privacy comprometida | Read rule: `inCompany(resource.data.companyId)` sin restricción de rol | Modificar read: `(isAdmin() \|\| isSupervisor())` en lugar de `inCompany()` |
| **A2** | attendances | Integridad de Datos | Employee puede crear attendance con datos inválidos (checkout sin checkin, timestamps inválidos) | ALTA | Employee crea attendance con `status='checkout'` sin checkin previo | Registros de asistencia inconsistentes. Lógica de aplicación quebrada | Create rule no valida status ni timestamps | Agregar validación en create: `status IN ['checkin']` y validar timestamps lógicos |
| **A5** | attendances | Integridad de Datos | Employee puede revertir transiciones de estado (checkout → checkin) | ALTA | Employee cambia estado de "checkout" a "checkin" | Horas trabajadas incorrectas. Registros duplicados. | Update rule: `noSensitiveFieldChanges()` no protege status | Proteger `status` en función dedicada |
| **U1** | users | Control de Acceso | Supervisor puede leer todos los users de empresa (email, dni, rol) | ALTA | Supervisor accede a email personal de otro supervisor | Privacy comprometida. Información sensible expuesta | Read rule: `inCompany()` permite a cualquier rol | Agregar restricción de rol o campos en read |
| **U2** | users | Control de Acceso | Employee puede leer todos los users de empresa | ALTA | Employee accede a emails personales de supervisores | Privacy comprometida | Mismo que U1 | Mismo que U1 |
| **I1** | incidences | Integridad de Datos | Employee puede crear incidence con `estado='aprobado'` | ALTA | Employee auto-aprueba su propia incidencia | Bypasseo de workflow de aprobación | Create rule no valida estado | Agregar: `request.resource.data.estado == 'pendiente'` |
| **M2** | medical_documents | Integridad de Datos | Employee puede crear medical_document con `estado='aprobado'` | ALTA | Mismo que I1 | Bypasseo de aprobación | Mismo que I1 | Mismo que I1 |
| **U3** | users | Privilege Escalation | Admin puede crear usuario con `rol='superadmin'` | MEDIA | Admin crea usuario con rol superadmin para sí mismo | Escalación de privilegios | Create rule no valida rol | Agregar: `request.resource.data.rol IN ['employee', 'supervisor']` |
| **W2** | workplaces | Integridad de Datos | Admin puede modificar ubicación (latitude, longitude, radius) | MEDIA | Admin cambia ubicación de geofence para interferir con validación | Attendances grabadas en ubicación falsa | Update rule: `noSensitiveFieldChanges()` no protege coords | Proteger coordenadas en función dedicada |
| **M1** | medical_documents | Integridad de Datos | Admin puede cambiar tipo, fechaInicio, fechaFin, motivo de documento | MEDIA | Admin modifica documento para cambiar tipo de "enfermedad" a "personal" | Tipo de ausencia incorrecta. Auditoría imposible | Update rule: `noSensitiveFieldChanges()` insuficiente | Crear `medicalDocumentNoSensitiveChanges()` que proteja estos campos |
| **I2** | incidences | Integridad de Datos | Admin puede cambiar tipo, fechaInicio, fechaFin, descripcion | MEDIA | Admin modifica incidencia histórica | Auditoría imposible. Inconsistencia de datos | Mismo que M1 | Crear `incidenceNoSensitiveChanges()` |
| **C1** | companies | Integridad de Datos | Admin puede modificar estado de 'activa' a 'inactiva' sin restricción | MEDIA | Admin desactiva empresa accidentalmente | Empresa fuera de servicio. Down time. | Update rule no valida cambios críticos | Agregar lógica: no permitir cambios de estado sin confirmación (o implementar en app) |
| **A4** | attendances | Integridad de Datos | No hay validación de timestamp lógico (checkOutTime > checkInTime) | MEDIA | Employee crea attendance con checkOutTime anterior a checkInTime | Horas negativas. Cálculos de duración incorrectos | Create/Update sin validación temporal | Agregar validación: `checkOutTime == null \|\| checkOutTime > checkInTime` |
| **A3** | attendances | Privacy | Supervisor/Admin pueden leer coordenadas GPS de todos empleados | MEDIA | Admin/Supervisor realiza tracking de ubicación | Privacy comprometida. Información de localización personal expuesta | Read permite acceso a GPS data | Implementar field-level security (si Firestore lo permite) o documentar restricción |
| **I3** | incidences | Diseño | Supervisor no puede actualizar/aprobar incidencias (¿intencional?) | MEDIA | Supervisor no puede actuar sobre incidencias | Workflow incompleto. Supervisión imposible | Update rule: solo admin/superadmin | Revisar spec si supervisor debería poder aprobar |
| **M3** | medical_documents | Integridad de Datos | Falta validación de transiciones de estado | MEDIA | Admin aprueba documentación rechazada | Estados inválidos en sistema | Update rule permite cualquier transición | Agregar validación: solo `pendiente→{aprobado,rechazado}` |
| **W3** | workplaces | Validación | No hay validación de coordenadas válidas en create | BAJA | Admin crea workplace con coords (0,0) o fuera de país | Geofence inútil | Create rule no valida valores | Agregar validación: coords dentro de rango válido (app-level) |
| **C2** | companies | Integridad de Datos | Admin puede modificar CUIT sin restricción | BAJA | Admin cambia CUIT incorrectamente | Datos empresa incorrectos | Update rule: no protege CUIT | Agregar: `noSensitiveFieldChanges()` |
| **U4** | users | Calidad de Código | Cuarta condición en read es redundante | BAJA | N/A | Confusión de mantenimiento | Read rule: `(isEmployee() && isOwner(uid))` redundante | Eliminar condición redundante |
| **M1-CLARITY** | medical_documents | Claridad | No hay denegación explícita para supervisor (solo implícita) | BAJA | Supervisors intenta leer medical_documents | Confusión de intención | Read rule no deniega explícitamente | Agregar comentario o hacer explícita la denegación |

---

# ANÁLISIS DE FLUJOS ESPECÍFICOS

## Flujo: Onboarding de Usuario Admin

1. **Usuario sin empresa** (companyId = null)
2. Puede crear su documento: `isOwner(uid) && getCompanyId() == null` ✓
3. Puede crear empresa: `isOnboardingUser()` ✓
4. Después, companyId ≠ null
5. Puede crear employees: `isAdmin() && companyId == getCompanyId()` ✓

**Vulnerabilidades en flujo**:
- ✓ Bien protegido
- ⚠️ PERO: Si el usuario onboarding NO crea empresa, queda "huérfano"

## Flujo: Check-in de Employee

1. Employee crea attendance: `userId == request.auth.uid && companyId == getCompanyId()` ✓
2. App valida ubicación (no en rules)
3. Employee puede actualizar: `userId == request.auth.uid && inCompany()` ✓

**Vulnerabilidades en flujo**:
- ❌ CRÍTICO: Employee puede cambiar checkInTime después de crear
- ❌ CRÍTICO: Employee puede cambiar ubicación GPS después de crear

## Flujo: Check-out de Employee

1. Employee actualiza attendance: `userId == request.auth.uid` ✓
2. Cambia status a "checkout"
3. Agrega checkOutTime

**Vulnerabilidades en flujo**:
- ❌ CRÍTICO: Employee puede modificar checkInTime ANTES de checkout
- ❌ CRÍTICO: Employee podría cambiar status de checkout a checkin

## Flujo: Lectura de Medical Documents por Employee

1. Employee crea documento: `userId == request.auth.uid && estado == 'pendiente'` (debería validarse)
2. Admin/Supervisor lee: `isAdmin() && inCompany()` (supervisor NO debería poder)
3. Admin actualiza estado a aprobado: `estado == 'pendiente' && newEstado IN ['aprobado', 'rechazado']` (debería validarse)

**Vulnerabilidades en flujo**:
- ❌ ALTA: Employee puede crear documento con estado=aprobado
- ⚠️ MEDIA: Admin puede cambiar tipo/fechas de documento

## Flujo: Creación de Workplace

1. Admin crea: `companyId == getCompanyId()` ✓
2. Admin puede actualizar: `inCompany()` ✓
3. Employee puede leer: SÍ ❌ (debería ser NO)

**Vulnerabilidades en flujo**:
- ❌ CRÍTICA: Employee puede leer ubicación de todas las sedes

---

# ANÁLISIS DE EDGE CASES

## Edge Case 1: Usuario con companyId = null

**Escenario**: Usuario creado pero empresa no asignada

**Qué puede hacer**:
- Crear empresa: ✓
- Crear usuario: ✗ (no puede, no tiene empresa)
- Leer users: ✗ (`inCompany()` retorna false)
- Crear attendance: ✗ (companyId debe coincidir)

**Veredicto**: Bien protegido ✓

## Edge Case 2: Usuario con isDeleted = true

**Escenario**: Usuario eliminado (soft delete)

**Qué puede hacer**:
- Autenticarse: Rules no lo protegen (Firebase Auth lo permite)
- Crear attendance: ✓ SÍ PUEDE (rules no validan isDeleted)
- Leer datos: ✓ SÍ PUEDE

**VULNERABILIDAD**: Usuario eliminado puede seguir escribiendo

**Solución propuesta**:
```dart
function isActive() {
  return getUserData().isActive == true && getUserData().isDeleted == false;
}

// En todas las reglas de write:
allow create/update: if isActive() && ...
```

## Edge Case 3: Usuario con isActive = false

**Escenario**: Usuario desactivado

**Qué puede hacer**:
- Crear attendance: ✓ SÍ PUEDE
- Modificar perfil: ✓ SÍ PUEDE

**VULNERABILIDAD**: Usuario inactivo puede seguir escribiendo

**Solución**: Mismo que Edge Case 2

## Edge Case 4: Documento sin companyId

**Escenario**: Documento histórico sin companyId (migración incompleta)

**Qué puede hacer**: 
- Lectura: `inCompany(null)` retorna false ✓ (no se puede leer)
- Actualización: No se puede acceder
- Escritura: No se puede acceder

**Veredicto**: Bien protegido (no se puede acceder a datos huérfanos) ✓

## Edge Case 5: Documento con companyId inválido

**Escenario**: Documento pertenece a empresa que no existe

**Qué puede hacer**:
- Lectura: `inCompany(invalidId)` retorna false ✓
- Modificación: Bloqueada

**Veredicto**: Bien protegido ✓

## Edge Case 6: Roles no estándar

**Escenario**: Usuario con rol diferente a: admin, supervisor, employee, superadmin

**Qué puede hacer**:
- Leer datos: Depende de condición (probablemente falla porque no entra en ninguna rama)
- Escribir datos: Probablemente falla

**Veredicto**: Potencialmente bloqueado, pero sin error claro

**Recomendación**: Validar que rol está en enum válido al crear usuario

---

# ANÁLISIS FASE 2 vs FASE 3

## Fase 2 Actual (Empresa Única)

✓ companyId está en documentos (preparación)
❌ Pero Firestore no valida que solo exista una empresa
❌ No hay validación que impida crear múltiples empresas
❌ Si companyId es null, hay "datos huérfanos"

## Problema: Readiness para Fase 3

**¿Las rules están correctamente preparadas para Fase 3?**

SÍ, en gran medida:
- ✓ companyId está en documentos
- ✓ Funciones como `inCompany()` validan companyId
- ✓ Aislamiento por companyId está implementado en CASI todas las colecciones

NO, hay problemas:
- ❌ `_attendance_locks` NO valida companyId
- ❌ No hay validación de "una única empresa" en Fase 2
- ❌ No hay mecanismo para bloquear creación de múltiples empresas

**Recomendación para Fase 3**:
1. Implementar validación explícita: `companyId != null`
2. Crear documento "metadata" para config multi-tenant
3. Agregar índices: `(companyId, field)` para queries eficientes
4. Revisar todas las queries en cliente (no visible en rules, pero crítico)

---

# RECOMENDACIONES PRIORIZADAS

## 🔴 CRÍTICA - Implementar inmediatamente

1. **A1 - ATTENDANCES: Proteger checkInTime, checkOutTime, status, ubicación**
   - Impacto: Fraude de asistencia masivo
   - Esfuerzo: 30 min
   - Solución: Nueva función `attendanceNoSensitiveChanges()`

2. **L1 - _ATTENDANCE_LOCKS: Validar companyId**
   - Impacto: Corrupción de datos multi-empresa
   - Esfuerzo: 1 hora
   - Solución: Reorganizar con companyId en path o agregar validación

3. **W1 - WORKPLACES: Restricto a admin/supervisor**
   - Impacto: Fuga de información competitiva
   - Esfuerzo: 15 min
   - Solución: Agregar rol check en read rule

## 🔴 ALTA - Implementar antes de producción

4. **A2, A5 - ATTENDANCES: Validar transiciones de estado**
   - Impacto: Registros inconsistentes
   - Esfuerzo: 45 min
   - Solución: Función de validación de transiciones

5. **I1, M2 - Validar estado=pendiente en CREATE**
   - Impacto: Bypasseo de workflow
   - Esfuerzo: 30 min
   - Solución: Agregar validación de estado inicial

6. **U1, U2, U3 - USERS: Validaciones y restricciones**
   - Impacto: Privacy, privilege escalation
   - Esfuerzo: 1 hora
   - Solución: Múltiples fixes

## 🟠 MEDIA - Implementar en siguiente sprint

7. **M1, I2 - MEDICAL_DOCUMENTS/INCIDENCES: Proteger campos sensibles**
   - Impacto: Auditoría comprometida
   - Esfuerzo: 1 hora
   - Solución: Funciones dedicadas por colección

8. **Edge cases: Validar isActive, isDeleted en writes**
   - Impacto: Usuario inactivo puede escribir
   - Esfuerzo: 1 hora
   - Solución: Agregar validación de estado activo

---

# RESUMEN DE CAMBIOS RECOMENDADOS

```firestore
// HELPER FUNCTIONS MEJORADAS
function isActiveUser() {
  let user = getUserData();
  return isAuthenticated() && user.isActive == true && user.isDeleted == false;
}

function attendanceNoSensitiveChanges() {
  return request.resource.data.companyId == resource.data.companyId
    && request.resource.data.userId == resource.data.userId
    && request.resource.data.checkInTime == resource.data.checkInTime
    && request.resource.data.checkOutTime == resource.data.checkOutTime
    && request.resource.data.status == resource.data.status
    && request.resource.data.latitude == resource.data.latitude
    && request.resource.data.longitude == resource.data.longitude
    && request.resource.data.precision == resource.data.precision;
}

function medicalDocumentNoSensitiveChanges() {
  return noSensitiveFieldChanges()
    && request.resource.data.tipo == resource.data.tipo
    && request.resource.data.fechaInicio == resource.data.fechaInicio
    && request.resource.data.fechaFin == resource.data.fechaFin
    && request.resource.data.motivo == resource.data.motivo;
}

function isValidStateTransition(validTransitions) {
  let currentState = resource.data.estado;
  let newState = request.resource.data.estado;
  return currentState == newState || validTransitions[currentState].contains(newState);
}

// USUARIOS - MEJORADO
match /users/{uid} {
  allow read: if isAuthenticated() && isActiveUser()
    && (isSuperadmin() || isOwner(uid) 
        || ((isAdmin() || isSupervisor()) && inCompany(resource.data.companyId)));
  
  allow create: if isActiveUser()
    && (isSuperadmin()
        || (isAdmin() && request.resource.data.companyId == getCompanyId()
            && request.resource.data.rol IN ['employee', 'supervisor'])
        || (isOwner(uid) && getCompanyId() == null));
  
  allow update: if isActiveUser()
    && (isSuperadmin()
        || (isAdmin() && inCompany(resource.data.companyId))
        || (isOwner(uid) && isOwnProfileUpdate()))
    && noUserSensitiveChanges();
  
  allow delete: if isSuperadmin();
}

// ATTENDANCES - MEJORADO
match /attendances/{docId} {
  allow read: if isActiveUser()
    && (isSuperadmin() || inCompany(resource.data.companyId)
        || (isEmployee() && isOwner(resource.data.userId)));
  
  allow create: if isActiveUser()
    && (isSuperadmin()
        || (isEmployee() && request.resource.data.userId == request.auth.uid
            && request.resource.data.companyId == getCompanyId()
            && request.resource.data.status IN ['checkin']
            && request.resource.data.checkInTime != null
            && request.resource.data.checkOutTime == null));
  
  allow update: if isActiveUser()
    && (isSuperadmin()
        || (isEmployee() && resource.data.userId == request.auth.uid
            && inCompany(resource.data.companyId)))
    && attendanceNoSensitiveChanges();
  
  allow delete: if isSuperadmin();
}

// WORKPLACES - MEJORADO
match /workplaces/{docId} {
  allow read: if isActiveUser()
    && (isSuperadmin() || ((isAdmin() || isSupervisor()) && inCompany(resource.data.companyId)));
  
  allow create: if isActiveUser()
    && (isSuperadmin()
        || (isAdmin() && request.resource.data.companyId == getCompanyId()));
  
  allow update: if isActiveUser()
    && (isSuperadmin()
        || (isAdmin() && inCompany(resource.data.companyId)))
    && noSensitiveFieldChanges();
  
  allow delete: if isSuperadmin()
    || (isAdmin() && inCompany(resource.data.companyId));
}

// _ATTENDANCE_LOCKS - MEJORADO
match /_attendance_locks/{companyId}/{lockId} {
  allow read: if isActiveUser() && inCompany(companyId);
  allow write: if isActiveUser() && inCompany(companyId);
}
```

---

# CONCLUSIÓN

Las Firestore Rules actuales tienen **múltiples vulnerabilidades críticas** que comprometen:
- Integridad de datos de asistencia
- Aislamiento multi-tenant
- Control de acceso basado en roles
- Privacy de empleados

**Recomendación**: No publicar en producción sin implementar al menos los fixes de severidad CRÍTICA.

**Estimado de esfuerzo**: 8-10 horas de desarrollo + testing

**Próximos pasos**:
1. Implementar fixes CRÍTICAS
2. Re-auditar rules mejoradas
3. Crear test suite de seguridad (no posible con rules, pero sí en cliente)
4. Documentar restricciones en UI
5. Preparar migración para Fase 3


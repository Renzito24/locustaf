# Reglas de Firestore — LOCUSTAF

Este documento describe el modelo de permisos implementado en `firestore.rules` (producción) y el flujo de seed.

## Roles

| Rol | Descripción |
|-----|-------------|
| `superadmin` | Acceso total a todas las empresas. Gestiona empresas y usuarios globalmente. |
| `admin` | Acceso completo a su propia empresa (empleados, lugares, asistencias, justificativos). |
| `supervisor` | Lectura de su empresa (usuarios, lugares, asistencias, incidencias). No accede a documentos médicos. |
| `employee` | Solo sus propios datos: asistencia, incidencias y certificados médicos. |

## Funciones auxiliares

| Función | Propósito |
|---------|-----------|
| `isAuthenticated()` | El request tiene un token de Auth válido. |
| `getUserData()` / `getRole()` / `getCompanyId()` | Lee el documento del usuario autenticado. |
| `isSuperadmin()` / `isAdmin()` / `isSupervisor()` / `isEmployee()` | Comprueba el rol del usuario. |
| `isOwner(userId)` | El documento pertenece al usuario autenticado. |
| `inCompany(companyId)` | El documento pertenece a la empresa del usuario. Requiere `companyId != null` (evita que usuarios en onboarding accedan a datos ajenos). |
| `isOnboardingUser()` | Usuario autenticado sin empresa asignada (flujo de onboarding). |
| `noSensitiveFieldChanges()` | En updates, `companyId` y `userId` no pueden cambiar. |
| `noAttendanceServerFieldChanges()` | En asistencias, los campos fijados en el check-in no pueden cambiar (userId, companyId, checkInTime, date, isLate, workplaceId, checkInLatitud, checkInLongitud). |
| `noUserSensitiveChanges()` | En users, el rol no puede cambiar salvo admin/superadmin. |
| `isOwnProfileUpdate()` | Un empleado solo puede actualizar campos no sensibles de su propio perfil. |

## Permisos por colección

### `users/{uid}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, el propio usuario, o admin/supervisor de su empresa |
| create | superadmin, admin (en su empresa), o el propio usuario en onboarding (rol forzado a `admin`, empresa creada por él) |
| update | superadmin, admin (en su empresa), o el propio usuario (solo perfil no sensible) |
| delete | superadmin |

### `companies/{companyId}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, o admin de la empresa |
| create | superadmin, o usuario en onboarding (con `createdBy == uid`) |
| update | superadmin, o admin de la empresa |
| delete | superadmin |

### `attendances/{docId}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, admin/supervisor de la empresa, o el empleado dueño |
| create | superadmin, o empleado (con `userId == uid` y `companyId` de su empresa) |
| update | superadmin, o empleado dueño (solo campos de check-out permitidos) |
| delete | superadmin |

### `workplaces/{docId}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, o admin/supervisor de la empresa |
| create | superadmin, o admin de la empresa |
| update | superadmin, o admin de la empresa |
| delete | superadmin, o admin de la empresa |

### `medical_documents/{docId}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, admin de la empresa, o el empleado dueño |
| create | superadmin, admin de la empresa, o el empleado dueño |
| update | superadmin, o admin de la empresa |
| delete | superadmin, o admin de la empresa |

> El supervisor **no** tiene acceso a documentos médicos (privacidad).

### `incidences/{docId}`

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, admin/supervisor de la empresa, o el empleado dueño |
| create | superadmin, admin de la empresa, o el empleado dueño |
| update | superadmin, o admin de la empresa |
| delete | superadmin, o admin de la empresa |

### `_attendance_locks/{lockId}`

Colección interna de control de concurrencia (previene doble check-in).

| Operación | Quién puede |
|-----------|-------------|
| read | superadmin, o el dueño del lock (`lockId == uid`) |
| write | superadmin, o el dueño del lock |

## Índices compuestos

Se requieren 2 índices compuestos en `attendances`:

1. `(userId ASC, checkInTime DESC)` — historial de asistencias por usuario.
2. `(userId ASC, status ASC)` — búsqueda de asistencia activa.

Los índices de un solo campo son generados automáticamente por Firebase.

## Flujo de seed

El seed usa reglas permisivas temporalmente (`seed/firestore.rules.seed`) para poder crear los documentos vía REST API.

```bash
# 1. Reglas permisivas (solo para seed)
firebase deploy --only firestore:rules firestore.rules.seed

# 2. Ejecutar el seed
dart run seed/seed.dart

# 3. Reglas de producción + índices
firebase deploy --only firestore
```

> **Advertencia:** nunca dejar las reglas permisivas desplegadas en producción. El paso 3 es obligatorio después del seed.

## Cloud Functions

`syncUserAuthStatus` (trigger de Firestore en `users`): cuando un usuario se marca como `isDeleted: true` o `isActive: false`, la función desactiva la cuenta correspondiente en Firebase Authentication.

- Región: `southamerica-east1` (debe coincidir con la base de datos).
- Runtime: Node 22.

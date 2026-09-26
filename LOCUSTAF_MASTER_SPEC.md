# LOCUSTAF MASTER SPECIFICATION

## Locus Staff — Sistema de Gestión de Personal y Control de Asistencia

### Versión 2.1 — Master Specification

> **Actualización 26/09/2026 — post Ronda 2 (Seguridad).** La especificación se actualiza
> a la arquitectura **server-authoritative** de asistencias. Nuevas secciones: 8 (roles
> del sistema: jerarquía, superadministrador, supervisor, empleado y matriz de permisos),
> 11.6 (arquitectura de asistencias server-side), 11.7 (fichadas manuales — modo estricto,
> decisión de producto) y 12 (hoja de ruta y decisiones abiertas). Cambios puntuales en
> 1, 2.2, 3, 4.2, 4.4 y 11.1–11.3. Detalle en la sección 13 (registro de cambios).

---

# 1. VISIÓN DEL SISTEMA

LOCUSTAF (Locus Staff) es una plataforma web de gestión de personal y control de asistencia laboral orientada principalmente a pequeñas y medianas empresas (PyMEs).

El sistema permitirá a una empresa administrar sus empleados y grupos de trabajo, definir jornadas laborales, controlar ingresos y egresos mediante geolocalización, gestionar ausencias, licencias y justificativos, calcular horas trabajadas y generar reportes.

La arquitectura deberá estar preparada desde el inicio para soportar múltiples empresas independientes dentro de la misma plataforma (multiempresa / multi-tenant), garantizando el aislamiento de los datos entre ellas.

La aplicación web está desarrollada con Flutter Web y se encuentra en funcionamiento. La aplicación móvil Android se genera desde el mismo código base (misma lógica de negocio y backend); el APK release está construido y pendiente de distribución.

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

- Múltiples empresas. *(Implementado: aislamiento por `companyId` verificado con tests.)*
- Notificaciones.
- Aplicación Android. *(APK release generado desde el mismo código base; distribución pendiente.)*
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
- Autoridad del servidor (server-authoritative): toda operación sensible (asistencias, locks, duración de jornadas, rate limiting) se ejecuta en Cloud Functions; el cliente nunca escribe estos datos directamente y toda validación crítica se re-ejecuta del lado del servidor.

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
- Cloud Functions (Node.js): callables para toda la lógica de asistencias y rate limiting server-side.

## 4.3 Herramientas

- Flutter.
- Dart.
- Firebase CLI.
- FlutterFire CLI.
- Git.
- GitHub.

## 4.4 Plataforma futura

La aplicación web está en producción.

Posteriormente:

- Android (APK release generado; la distribución se realiza al cerrar la mejora de UX).
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

# 8. ROLES DEL SISTEMA

El sistema define cuatro roles con jerarquía estricta. La autorización se aplica en Firestore Rules y Cloud Functions (server-side); la UI nunca es la única barrera.

## 8.1 Jerarquía y modelo comercial actual

- **Superadministrador**: dueño de la plataforma LOCUSTAF. Administra las PyMEs.
- **Administrador** (dueño de la PyME): administra su empresa.
- **Supervisor**: administración delegada, acotada a su grupo de trabajo.
- **Empleado** (usuario común): registra y consulta su propia asistencia.

Modelo comercial actual (transitorio, hasta implementar planes y suscripciones — ver 2.2):

- El administrador abona su suscripción mediante transferencia al superadministrador.
- Verificado el pago, el superadministrador habilita (activa) a la empresa y a su administrador. Una empresa sin habilitar no opera normalmente.

## 8.2 Superadministrador

Dueño de la plataforma. No pertenece a ninguna empresa: supervisa todo el sistema.

Puede:

- Dar de alta empresas (PyMEs) y crear su administrador inicial (onboarding).
- Activar e inactivar empresas (habilitación por pago).
- Leer todos los datos de todas las empresas.
- Eliminar empresas, usuarios y asistencias.
- Administrar pagos y datos de facturación (único rol con acceso a pagos).
- Escribir directamente en asistencias (único rol con escritura directa; todos los demás roles operan asistencias vía Cloud Functions).

No puede / no debe:

- Registrarse en una empresa como empleado ni operar como tal.

## 8.3 Administrador / Dueño

El administrador representa al propietario o responsable de la empresa (PyME).

Puede:

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
- Registrar el ingreso manual de un empleado (únicamente dentro del día y horario laboral de ese empleado — ver 11.7).
- Ver asistencia.
- Ver dashboard.
- Ver ausencias.
- Ver licencias.
- Revisar justificativos.
- Generar reportes.
- Exportar PDF.
- Exportar Excel.

---

## 8.4 Supervisor

Rol intermedio: puede hacer algo menos que un administrador, con alcance acotado a su grupo de trabajo.

Puede:

- Administrar el grupo de trabajo que tiene asignado.
- Administrar a los empleados de la empresa. *(Alcance exacto a confirmar: ¿dar de alta y desactivar, o solo modificar?)*
- Restablecer contraseñas de usuarios.
- Consultar asistencias de la empresa (solo lectura).
- Consultar lugares de trabajo e incidencias (solo lectura).

No puede:

- Acceder a documentos médicos.
- Administrar datos de la empresa, pagos ni facturación.
- Registrar ingresos manuales (reservado al administrador — ver 11.7).

## 8.5 Empleado (usuario común)

Puede:

- Fichar entrada y salida con validación de geolocalización (`checkInGeo` / `checkOutGeo`).
- Ver su propia asistencia e historial (exclusivamente sus registros).
- Finalizar su propia jornada huérfana, cuando su jornada activa superó la hora de fin de su lugar de trabajo (finalización sellada por el servidor — ver 11.6).
- Consultar la información de su empresa y de su lugar de trabajo.
- Consultar sus propios datos de perfil.

No puede:

- Crear, modificar ni eliminar asistencias de otros usuarios.
- Ver datos de facturación de la empresa (decisión abierta — ver 12.4).
- Acceder a documentos médicos ni a datos de otros empleados.

## 8.6 Matriz de permisos (resumen)

| Capacidad | Superadmin | Admin | Supervisor | Empleado |
|---|---|---|---|---|
| Activar / inactivar empresas | Sí | No | No | No |
| Administrar empresa, grupos y horarios | Todo visible | Sí | No | No |
| Administrar un grupo y sus empleados | Sí | Sí | Sí (asignado) | No |
| Restablecer contraseñas | Sí | A confirmar | Sí | No |
| Ingreso manual (dentro del horario — ver 11.7) | Sí | Sí | No | No |
| Fichar con geolocalización (sí mismo) | — | Sí | Sí | Sí |
| Ver asistencias de todos | Sí | Sí | Sí (lectura) | Solo las propias |
| Documentos médicos | Sí | Sí | No | No |
| Pagos y facturación | Sí | Decisión abierta (12.4) | No | No |

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
- La validación de tolerancia se ejecuta íntegramente en el servidor: tanto el check-in por geolocalización (`checkInGeo`) como el alta manual (`manualCheckIn`) comparan la hora declarada contra el reloj del servidor y rechazan lo que esté fuera de la ventana (± tolerancia). El servidor deriva `date` e `isLate`.
- *(Actualizado Ronda 2)* El cliente ya no crea asistencias directamente: la validación que antes vivía en Firestore Rules fue reemplazada por el default deny de escritura de cliente.
- Configurable desde **Configuración de empresa** (admin).

## 11.2 Días laborables (por empresa)

- `diasLaborables`: lista ISO (1=Lun ... 7=Dom), default `[1,2,3,4,5]`.
- Los reportes de ausencias del mes consideran el día laborable actual: si hoy no es laborable, las "ausencias del día" se muestran como 0.
- Configurable desde **Configuración de empresa** (admin).

## 11.3 Locks de sesión de asistencia (anti doble check-in) — ACTUALIZADO RONDA 2

- Colección interna `_attendance_locks/{userId}`: garantiza una sola asistencia activa por empleado.
- Campos de cada lock: `attendanceId`, `checkInTime`, `lockedAt`, `status`.
- **Los locks son internos del servidor:** el cliente no puede leerlos ni escribirlos (Firestore Rules: default deny).
- Se crean, reclaman y eliminan exclusivamente dentro de las Cloud Functions, dentro de transacciones.
- Reclamación de locks huérfanos en un nuevo check-in si:
  - el lock supera el TTL (24 h) desde `lockedAt`; o
  - la asistencia asociada no existe o ya está `completed`.
- *(Cambio C4, Ronda 2)* El borrado lógico de un empleado ya NO purga su lock: el lock se libera por TTL o por el estado de la asistencia asociada. Esto elimina toda escritura de locks desde rutas de cliente.

## 11.4 Timestamps y zonas horarias

- `checkInTime` / `checkOutTime` se persisten como `Timestamp` UTC de Firestore.
- El resto de la metadata (`createdAt`, `updatedAt`, `reviewedAt`) se persiste como ISO-8601 en UTC (`toUtc().toIso8601String()`).
- En la lectura de datos, se convierte a hora local (`.toLocal()`) para que la UI muestre siempre el horario local del dispositivo.

## 11.5 Historial con paginación

- El historial de asistencias se carga por páginas de 25 registros (orden `checkInTime` DESC, cursor `startAfter`), acumulando de a páginas con botón "Cargar más".
- Los totales se obtienen con `COUNT()` agregado de Firestore (sin descargar todo el historial).
- El filtrado (búsqueda y rango de fechas) se aplica client-side sobre las páginas cargadas.

## 11.6 Arquitectura server-authoritative de asistencias (implementada — Ronda 2)

- Toda escritura de asistencias pasa por Cloud Functions (callables): `checkInGeo`, `checkOutGeo`, `manualCheckIn`, `finalizeOrphaned`.
- El cliente Flutter no crea, modifica ni borra documentos de `attendances` ni `_attendance_locks` (verificado: 0 referencias en `lib/`; suite de seguridad: 120 tests).
- `durationMinutes` se deriva en el servidor (`checkOutTime - checkInTime`); el cliente no puede fijar duraciones arbitrarias.
- Una asistencia solo pasa de `active` a `completed` (nunca se reabre desde el cliente). La hora de ingreso, la fecha, el lugar y las coordenadas de check-in quedan congelados desde la creación.
- Jornada huérfana: asistencia activa que superó la hora de fin del lugar de trabajo (día local del check-in, UTC-3). Su finalización la ejecuta la callable `finalizeOrphaned`, que verifica propiedad (userId), empresa y estado, y re-verifica transaccionalmente que el reloj del servidor superó la hora de fin.
- Alta manual: la ejecuta la callable `manualCheckIn` (administrador autorizado). Recibe `targetUserId` y `checkInTime` (ISO UTC), valida la tolerancia contra el reloj del servidor y deriva `date`/`isLate` server-side.
- Rechazo de duplicados: si el empleado ya tiene una asistencia activa, la callable rechaza con mensaje claro ("Ya tenés una asistencia activa desde las... Finalizala antes de iniciar una nueva.").
- Rate limiting server-side sobre operaciones sensibles (p. ej., 6 intentos cada 10 minutos).

## 11.7 Fichadas manuales — Modo estricto (decisión de producto; implementación: Ronda 3)

Decidido por el propietario (26/09/2026):

- El sistema es estricto: no se permite dar ingreso por un empleado si no es su día ni su horario laboral.
- Si un empleado va a trabajar con otro horario por un período (p. ej., una semana), el administrador modifica su asignación (lugar de trabajo / horario, mecanismo de reasignación existente). Nunca se registra una excepción al momento de fichar.
- No existe carga retroactiva de asistencias fuera de la ventana de tolerancia. El caso "empleado presente sin teléfono" se resuelve dentro de la tolerancia; el resto se documenta como incidencia justificada.
- Implementación prevista: validación de día laborable + ventana horaria del puesto dentro de la callable `manualCheckIn`, con mensajes de error claros y tests de casos borde (día no laborable, fuera de horario, límite de tolerancia).

Pendiente de confirmación:

- Bloqueo del ingreso manual si el empleado ya tiene cualquier asistencia ese día (activa o completada). Recomendación: sí bloquear; la jornada partida (mañana/tarde) sigue siendo posible por el check-in propio del empleado con geolocalización.

---

# 12. HOJA DE RUTA Y ESTADO

## 12.1 Estado al 26/09/2026 — Ronda 2 (Seguridad) completada

- Arquitectura server-authoritative (11.6) implementada y desplegada (functions + web). Commits `aceee2b` (rules), `9d412e9` (app), `2d0516a` (functions); tag `ronda-2-seguridad` para rollback.
- Suites verificadas con declaración previa de totales: Flutter 305 passing; Functions 133 (86 pass / 47 skip); integración con emulador 133 (131 pass / 2 skip); seguridad 120 passing.
- Cerrados: ALTO-1 (falsificación de horas), ALTO-2 (borrado de locks), MEDIO-3, BUG-N1 (ingreso manual solo funcionaba para superadmin), BUG-N2 (borrado de empleados fallaba a medias).
- Verificado en campo: alta manual (happy path + rechazo de duplicado con mensaje amigable) y finalización de jornada huérfana end-to-end, con tope de acreditación server-side (jornada fuera de horario acredita 0 minutos).

## 12.2 Pendientes de la Ronda 2 (antes del cierre formal)

- Prueba de regresión: contador de ausencias del empleado de prueba (valor 24 en web — confirmar contra `flutter run`; si ambos coinciden, es el valor correcto de la fórmula).
- Distribución del APK release a los dispositivos: **decidido postergarla hasta cerrar la Ronda 3 (UX)**, para realizar una única distribución y prueba.
- Deploy de las Firestore Rules nuevas (R2-E): se ejecuta después de distribuir el APK. Orden de despliegue acordado: 1) Functions, 2) App (web/APK), 3) Firestore Rules. Mientras tanto, las rules viejas sostienen la ventana de migración.

## 12.3 Ronda 3 — UX (próxima)

- Orden acordado: primero el entorno del Empleado, luego el del Admin, por último el del Superadmin.
- Hallazgos de campo a incluir: tarjeta del empleado para jornadas cargadas por el administrador ("El administrador registró tu ingreso", sin ofrecer finalización para jornadas del mismo día), badge de "cerrada automáticamente" para huérfanas en el historial, refresco de tarjeta tras finalizar, y revisión de la presentación del contador de ausencias.

## 12.4 Decisiones abiertas

- ¿Los empleados pueden ver datos de facturación de la empresa? (aparcada)
- ¿UI para que los administradores corrijan fichadas erróneas, con auditoría? (aparcada)
- Bloqueo de jornadas múltiples por día en el alta manual (ver 11.7).

---

# 13. REGISTRO DE CAMBIOS

- **v2.1 (26/09/2026):** actualización post Ronda 2. Backend incorpora Cloud Functions (4.2). Principio server-authoritative (3). Sección 8 reestructurada como roles del sistema (jerarquía, superadmin, supervisor, empleado, matriz de permisos; alta manual con restricción de horario en habilidades del admin). 11.1 tolerancia validada server-side; 11.3 locks server-only y sin purga en soft-delete; nuevas 11.6 (arquitectura de asistencias) y 11.7 (modo estricto de fichadas manuales); nueva 12 (hoja de ruta y decisiones abiertas).
- **v2.0:** especificación master original.
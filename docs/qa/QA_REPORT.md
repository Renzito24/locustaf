# Informe de QA — LOCUSTAF

**Fecha:** 2026-08-30
**Alcance:** Revisión de código, pruebas y preparación de despliegue.
**Estado del código:** `main` @ `ab5a5b8` — 107/107 tests pasando.

---

## 1. Resumen ejecutivo

La aplicación está en buen estado general: la suite de tests (107) pasa completa, el flujo de asistencia con locks transaccionales es sólido frente a concurrencia, y las reglas de Firestore cubren correctamente los vectores de escalada de privilegios (VUL-1 a VUL-4b) y la auto-aprobación de justificativos.

Se corrigieron los **2 hallazgos de severidad media** (robustez ante datos corruptos en `AttendanceModel.fromJson` y el cuello de botella de `orphanedAttendancesProvider`). Restan **4 riesgos de severidad baja** (no bloqueantes). No se encontraron vulnerabilidades de seguridad explotables de severidad alta. El mecanismo de locks es correcto frente a doble check-in simultáneo.

---

## 2. Bugs encontrados

**Estado: BUG-1 y BUG-2 RESUELTOS en commit `ab5a5b8`.**

### BUG-1 — Severidad MEDIA: `AttendanceModel.fromJson` rompe el stream ante datos corruptos
**Archivo:** `lib/features/attendance/data/models/attendance_model.dart:111-113`

`checkInTime: _parseTimestamp(json['checkInTime'])` lanza `TypeError` si el campo es `null` (o un tipo inesperado). De forma similar, `AttendanceStatusExtension.fromString` (línea 30) lanza `ArgumentError` si `status` tiene un valor desconocido.

**Impacto:** Un único documento corrupto en `attendances` (campo `checkInTime` nulo o `status` inválido) hace fallar **todo el stream** de la consulta, rompiendo el historial, el dashboard y los reportes para todos los usuarios de la empresa. Es exactamente el escenario de "datos corruptos en Firestore" que se pidió probar.

**Traza esperada:** `TypeError: type 'Null' is not a subtype of type 'Timestamp'` (o `ArgumentError: Invalid AttendanceStatus`).

**Sugerencia:** Hacer `_parseTimestamp` tolerante a `null` (devolver `DateTime.now()` o `null` con manejo aguas abajo) y que `fromString` devuelva un valor por defecto (`active`) en vez de lanzar. Alternativamente, filtrar/omitir el documento corrupto en el `fromJson` del stream.

**Resolución:** `_parseTimestamp` ahora devuelve fallback predecible ante `null`/inválido; `_parseStatus` degrada a `AttendanceStatus.active` en vez de lanzar. 11 tests del modelo, `flutter analyze` 0, `flutter test` 107/107.

### BUG-2 — Severidad MEDIA: `orphanedAttendancesProvider` descarga todas las asistencias y lugares
**Archivo:** `lib/features/attendance/presentation/providers/attendance_notifier.dart:44-70`

El provider observa `allAttendancesStreamProvider` y `allWorkplacesStreamProvider` (todas las asistencias y lugares de la empresa) y filtra en memoria. Con miles de asistencias, cada cambio re-descarga todo.

**Impacto:** Cuello de botella de consulta y de memoria en empresas con volumen alto. El dashboard de "jornadas huérfanas" se vuelve lento.

**Sugerencia:** Consultar solo `status == 'active'` a nivel de base de datos (índice `(companyId, status)`), y filtrar por `horaFin` en memoria solo sobre ese subconjunto.

**Resolución:** Nuevo `getAllActiveAttendances()` en el repositorio + `allActiveAttendancesStreamProvider` consultan solo `status == 'active'` a nivel Firestore; `orphanedAttendancesProvider` usa ese stream acotado. La query de igualdad simple no requiere índice compuesto. Test de repositorio agregado.

---

## 3. Riesgos identificados

### R1 — Severidad BAJA: `checkOutTime` arbitrario en el pasado
**Archivo:** `firestore.rules` (`noAttendanceServerFieldChanges`)

Las reglas permiten al empleado fijar `checkOutTime` a cualquier valor (no se valida que sea posterior a `checkInTime`). `durationMinutes` se calcula en el repositorio, pero un cliente malicioso podría escribir un `checkOutTime` falso. No es escalada de privilegios, pero corrompe la integridad de los reportes.

**Sugerencia:** En las reglas, exigir `request.resource.data.checkOutTime >= resource.data.checkInTime` cuando se modifica `checkOutTime`.

### R2 — Severidad BAJA: `validAttendanceCreate` permite `checkInTime` en el futuro
**Archivo:** `firestore.rules` (`validAttendanceCreate`)

`diff <= toleranceMillis` admite una hora de entrada hasta la tolerancia en el futuro. Es intencional para tolerar desfase de reloj, pero un cliente podría adelantar levemente la hora de entrada.

### R3 — Severidad BAJA: lógica duplicada en `checkIn`/`checkOut`
**Archivo:** `attendance_notifier.dart`

Las validaciones de usuario activo, lugar de trabajo y geocerca están duplicadas entre `checkIn` y `checkOut`. Riesgo de divergencia futura. Sugerencia: extraer a un helper compartido.

### R4 — Severidad BAJA: `getAllAttendances` sin paginación
**Archivo:** `attendance_repository_impl.dart:44-52`

El stream de todas las asistencias de la empresa no está paginado (a diferencia de `getAttendancePage`). Usado por reportes/dashboard. Con volumen alto, coste de lectura creciente.

---

## 4. Verificaciones positivas (concurrencia y seguridad)

- **Doble check-in simultáneo (2 dispositivos):** correcto. El lock por usuario (`_attendance_locks/{userId}`) se lee/escribe dentro de una transacción Firestore serializable. El segundo dispositivo re-lee el lock tras el retry y recibe "Ya tenés una asistencia activa". No hay race condition.
- **Lock huérfano / TTL:** correcto. `_isLockStale` (24h) + verificación de que la asistencia asociada esté `completed` o no exista permite reclamar locks abandonados sin romper la integridad.
- **GPS apagado / baja precisión:** correcto. `LocationService` devuelve estados `disabled`/`denied`/`lowAccuracy` con mensajes claros; el notifier aborta el check-in/out sin escribir datos.
- **Reglas de seguridad:** VUL-1 (rol forzado a admin + empresa creada por el usuario), VUL-3 (campos server-only), VUL-4/4b (lectura por rol), M1 (sin auto-aprobación) y VUL-2 (locks con ownership) están correctamente implementadas.
- **Manejo de Timestamp:** `_parseTimestamp` y `_parseLockTime` toleran `Timestamp`/`String`/`DateTime`, y el check-out usa `Timestamp.fromDate(now.toUtc())`. El bug de Timestamp reportado previamente está resuelto.

---

## 5. Sugerencias de mejora (priorizadas)

1. **Alta:** Endurecer `AttendanceModel.fromJson` ante datos corruptos (BUG-1). Es el riesgo más probable en producción.
2. **Media:** Acotar `orphanedAttendancesProvider` a asistencias activas a nivel de DB (BUG-2).
3. **Baja:** Validar `checkOutTime >= checkInTime` en reglas (R1).
4. **Baja:** Extraer validaciones duplicadas del notifier (R3).
5. **Baja:** Paginar `getAllAttendances` (R4).

---

## 6. Estado de pruebas

| Suite | Resultado |
|-------|-----------|
| `flutter test` | 107/107 pasando |
| `flutter analyze` | 0 issues |
| Cobertura de flujo de asistencia (E2E) | Presente (`attendance_notifier_test.dart`) |
| Tests de reglas de seguridad (emulador) | 27/27 pasando |

---

## 7. Tests de seguridad con emulador

La suite `test/security/rules.test.js` (mocha + @firebase/rules-unit-testing) se ejecutó contra el emulador de Firestore en `localhost:8081`: **27/27 tests pasando**, cubriendo VUL-1 a VUL-4b (escalada de rol, campos server-only, lectura por rol, locks con ownership), la auto-aprobación de justificativos, tolerancias de `checkInTime`, falsificación de `userId`/`companyId` e IDOR con `companyId` nulo. Comando: `cd test/security && npm test`.

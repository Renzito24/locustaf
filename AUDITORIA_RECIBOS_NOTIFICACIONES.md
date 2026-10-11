# Auditoría — Recibos (Paystubs) y Notificaciones (Comunicados)

- **Proyecto:** Locustaf (`app_locustaf`) — Flutter 3.47.1 / Dart 3.13.1, Riverpod 3.3.2, GoRouter 17.3.0
- **Versión auditada:** `2.1.0+10`
- **Alcance:** pestañas **Recibos** y **Notificaciones/Comunicados**, más los ejes transversales que las afectan (navegación/roles, reglas Firestore/Storage, índices, tests y deuda técnica).
- **Modalidad:** auditoría de solo lectura (ver §7 con la remediación posterior aplicada). No se modificaron `firestore.rules` ni `storage.rules`.
- **Base de referencia:** `flutter analyze` → 0 issues; `flutter test` → 507 tests en verde.

---

## 1. Resumen ejecutivo

1. Las dos features funcionan de punta a punta y están bien cubiertas por reglas de seguridad estrictas; no se encontró ningún defecto que rompa el flujo principal ni fuga de datos entre empresas.
2. El hallazgo más serio es de **ciclo de vida de archivos**: al borrar un comunicado se elimina el documento de Firestore pero **no el PDF de Storage**, dejando archivos huérfanos (Recibos sí limpia Storage, así que es una asimetría puntual).
3. El segundo hallazgo relevante es una **consulta con probabilidad alta de ser denegada** por reglas ("rules are not filters") en la pantalla "Leído por" de comunicados: falta verificación en emulador.
4. Hay deuda de robustez transversal: errores crudos mostrados en la UI, validaciones de rol hechas por comparación de strings, provider que lanza excepción en vez de degradar a estado vacío, y ausencia de tests de seguridad/widgets para ambas features.
5. No hay hallazgos CRÍTICOS. El sistema es seguro por reglas (servidor manda); la mayoría de las correcciones son de consistencia, manejo de errores y limpieza.

**Veredicto:** **APTO con observaciones.** No hay bloqueantes. Recomendado priorizar la limpieza de Storage en el borrado de comunicados, verificar la query de lecturas y unificar el manejo de errores antes de la próxima iteración funcional.

---

## 2. Tabla de hallazgos

Severidad: **CRÍTICO > ALTO > MEDIO > BAJO > DUDA**. "NO VERIFICADO" = requiere emulador/dispositivo/credenciales.

| ID | Sev. | Archivo:línea | Descripción | Evidencia | Recomendación |
|----|------|---------------|-------------|-----------|---------------|
| **NOT-01** | **ALTO** | `comunicado_repository_impl.dart:53`, `comunicados_components.dart:244` | Al eliminar un comunicado se borra solo el doc de Firestore; el PDF en Storage queda huérfano. | Recibos sí borra Storage (`paystubs_provider.dart:250-262`); comunicados no. Las rules permiten `delete` al admin en `storage.rules`. | Borrar `storagePath` desde Storage antes/después de borrar el doc (best-effort, sin romper si falla). |
| **NOT-02** | **ALTO / DUDA** | `comunicado_repository_impl.dart:~150` (`streamReadersForComunicado`) | La consulta a `communicationReads` filtra **solo** por `comunicadoId`; la regla de lectura exige `companyId == getCompanyId()`. Firestore no permite leer con una query que no restrinja por el campo de la regla → probable `permission-denied`. La pantalla "Leído por" no mostraría lectores a admins. | `firestore.rules` (read de `communicationReads`): admin requiere `inCompany(resource.data.companyId)`. Contraste: `streamReadComunicadoIds` sí filtra `userId == uid` y matchea `isOwner`. No cubierto por tests de seguridad. | Añadir filtro `.where('companyId', isEqualTo: companyId)` (requiere índice `companyId + comunicadoId`) o cambiar la regla a `isOwner`-based. **Verificar en emulador.** |
| **REC-01** | **MEDIO** | `create_paystub_screen.dart:151` | El dropdown de empleados usa `usersStreamProvider` (todos los usuarios de la empresa) **sin filtrar por rol**, por lo que permite adjuntar un recibo a un admin/superadmin. Inconsistente con la vista de listado que sí filtra. | `users_provider.dart:16` no filtra rol; `filteredEmployeesProvider` (que sí excluye admins) no se usa aquí. | Reusar `filteredEmployeesProvider` o filtrar `rol != admin`. |
| **REC-02** | **MEDIO** | `paystubs_provider.dart:182` (`createPaystub`) | No hay control de duplicados por `(userId, periodo)`. Un admin puede subir dos recibos del mismo período; luego `firstOrNull` hace que el resumen/tarjeta sea no determinista. | `paystubs_screen.dart:74` y `paystubs_components.dart:124` usan `.firstOrNull`; no hay `where(periodo)` + verificación en el alta. | Antes de crear, consultar existencia por `userId + periodo` y bloquear/avisar. |
| **NOT-03** | **MEDIO** | `comunicados_provider.dart:15` | `comunicadoRepositoryProvider` **lanza `Exception`** si `user`/`companyId` es null, rompiendo el árbol (estado error) en vez de degradar a lista vacía. Afecta a superadmin (sin `companyId`). | Patrón correcto en `usersStreamProvider` (`users_provider.dart:18`) que devuelve `Stream.value(<UserModel>[])`. | Devolver un repositorio "no-op"/stream vacío cuando falte `companyId`. |
| **NOT-04** | **MEDIO** | `comunicados_provider.dart:61` | La invariante "PDF **o** contenido, nunca ambos" se valida con `assert`, que se elimina en release. | La pantalla valida, pero el provider no protege en producción. | Validar en runtime y lanzar/retornar error controlado. |
| **NOT-05** | **MEDIO** | `comunicados_components.dart:~414`, `comunicado_repository_impl.dart:~150` | "Leído por" carga **todos** los lectores sin paginación. | `StreamProvider` sobre la colección completa por comunicado. | Paginar/limitar (`limit`/`startAfter`) si el histórico crece. |
| **NAV-01** | **MEDIO** | `route_guard.dart` | Rutas de creación y de empresas (`/comunicados/create`, `/paystubs/create`, `/companies`, `/companies/create`, `/companies/edit`) no están en las listas de restricción por rol; un supervisor/admin podría navegar directo. Las pantallas no re-verifican rol. | Mitigado en servidor: la regla de `create` de comunicados exige admin → el upload se deniega (sin huérfano). El resto es solo UX de acceso. | Añadir guard de rol en `route_guard.dart` y/o chequear rol dentro de las pantallas. |
| **NAV-02** | **MEDIO** | `auth_provider.dart:143` (`isAdminProvider`) | Devuelve `true` **solo** para `UserRole.admin`; **no** para superadmin. Efectos: superadmin ve UI de empleado en Recibos, no ve "Nuevo Comunicado"/borrado, y dispara `NOT-03` (provider lanza). La rama superadmin de `comunicado_repository_impl.dart:59` queda muerta. | `isSuperadminProvider` existe aparte (`company_providers.dart:34`) y no se combina en `isAdminProvider`. | Definir si superadmin debe gestionar comunicados; si sí, ajustar `isAdminProvider` o gates de UI. |
| **REC-03** | **MEDIO** | `paystubs_provider.dart:286`, `:310`, `paystub_detail_dialog.dart:43` | `approve`/`reject`/alta no verifican `estado == pendiente` en cliente. La regla sí lo exige (defensa en servidor), pero un doble submit cambiaría `respondedAt`. | `firestore.rules` update de paystubs exige `estado` previo `pendiente`. UI oculta botones. | Guard temprano en notifier para UX y evitar carreras. |
| **REC-04** | **MEDIO** | `paystubs_screen.dart:103/107/117`, `create_paystub_screen.dart:177`, `employee_paystubs_screen.dart:55` | Errores crudos de excepción mostrados al usuario (`error.toString()` / `Error: $e`). Muestra detalles internos y mala UX. | `_ErrorWidget(error: error.toString())`; `Text('Error: $e')`. | Mapear a mensajes amigables en español. |
| **NOT-06** | **MEDIO** | `comunicados_provider.dart:113`, `create_comunicado_screen.dart:456/507` | Igual que REC-04 en comunicados: `e.toString()` / `Error: $e` a la UI. | idem. | Mensajes amigables y logging interno. |
| **REC-05** | **BAJO** | `paystubs_screen.dart:61`, `paystubs_components.dart:158-164` | Comparaciones de rol por string: `.rol.name == 'employee'` en vez del enum `UserRole`. | Duplicación y fragilidad ante renombres. | Usar el enum directamente. |
| **REC-06** | **BAJO** | `paystubs_screen.dart:20`, `employee_paystubs_screen.dart` | Para empleados se computa/observa `filteredPaystubsProvider` (y se invalidan providers que no aplican) sin usarse. | Trabajo y reconstrucciones innecesarias. | Ajustar qué se observa según el rol. |
| **REC-07** | **BAJO** | `paystubs_components.dart:323` | `getNormalizedPeriod(p)` envuelve `PaystubModel.normalizedPeriod`, duplicando lógica de normalización. | Usado en `paystubs_screen.dart:66` y `paystubs_components.dart:124`. | Usar `p.normalizedPeriod` y eliminar el wrapper. |
| **NOT-07** | **BAJO** | `comunicado_repository_impl.dart:28`, `:54` | Usa `FirebaseFirestore.instance` directo en lugar del `FirestoreService` inyectado. | `_firestoreService` se inyecta pero no se usa en create/delete. | Usar el servicio inyectado por consistencia y testabilidad. |
| **NOT-08** | **BAJO** | `comunicados_provider.dart:71`, `comunicado_repository_impl.dart:29` | Se genera un `docId` en el provider (usado para el `storagePath`) y **otro** `docRef.id` en el repo (id real del doc). Funciona, pero es confuso. | `storagePath` = `companies/{c}/comunicados/{providerDocId}/{providerDocId}.pdf`; el doc se guarda con `repoDocId`. | Generar un único id y pasarlo a ambos. |
| **NOT-09** | **BAJO** | `comunicados_provider.dart:75` | Sanitización de nombre de archivo **inline** en vez de reusar `FileUtils.sanitizeFileName`. | `file_utils.dart` ya expone sanitize + mimeType. | Reusar la utilidad. |
| **NOT-10** | **BAJO** | `comunicados_components.dart:41` | Para comunicados PDF, `markAsRead` solo se dispara en `onPdfLoaded`; si la carga del PDF falla (p. ej. CORS), nunca queda marcado como leído. | El detalle de texto sí marca en carga. | Marcar leído al abrir, independientemente del resultado de la carga. |
| **NOT-11** | **BAJO** | `create_comunicado_screen.dart:146/210` | Título y contenido sin `maxLength`. Un contenido enorme se acerca al límite de 1 MB por documento de Firestore. | Sin validación de longitud en UI ni provider. | `maxLength` en los campos. |
| **NOT-12** | **BAJO** | `comunicados_components.dart:104` | `ref.watch` de `comunicadosReadIdsProvider` dentro del `itemBuilder` (por ítem). | Riverpod desduplica, pero es un code smell. | Observar una vez fuera del builder. |
| **NOT-13** | **BAJO** | `comunicado_model.dart` (`toJson`) | `toJson()` incluye `'id'` (redundante con el id del doc) y `copyWith` no puede anular `content`/`fileName`/`storagePath` (no hay patrón de "clear"). | — | Omitir `id` del payload o documentar; `copyWith` con centinelas si se necesita limpiar. |
| **SEC-01** | **BAJO** | `firestore.rules` (paystubs.create, ~459) | La regla valida `companyId` y `estado=='pendiente'`, pero no que `userId` pertenezca a la empresa del creador. | — | Endurecer si se considera necesario (requiere `get()` del user). |
| **SEC-02** | **BAJO** | `firestore.rules`, `storage.rules` | Sin enforcement de **App Check**. | — | Evaluar activar App Check. |
| **SEC-03 / TST-01** | **MEDIO** | `test/security/*.js`, `test/features/paystubs`, `test/features/comunicados` | Sin tests de seguridad para `paystubs`/`comunicados`/`communicationReads`; sin tests de widget para `CreatePaystubScreen`/`CreateComunicadoScreen` ni de providers (create/delete/approve). El test de comunicados **mockea** `comunicadoReadersProvider` (no ejercita la query real → NOT-02 pasa desapercibido). | `test/security/` solo cubre invitations/rqg1/rules/storage/users_superadmin. | Añadir tests de rules para las 3 colecciones y de widgets/providers para las pantallas de alta. |
| **DEU-01** | **BAJO** | `auth_repository.dart:1` | TODO obsoleto ("Define AuthRepository interface") cuando la interfaz ya está definida. | — | Eliminar el comentario. |
| **DEU-02** | **BAJO** | `create_comunicado_screen.dart:108`, `create_paystub_screen.dart:93` | En `ref.listen` de éxito se usa `ScaffoldMessenger.of(context)` + `context.pop()` sin chequear `mounted`. | El listener se desregistra al desmontar, por lo que el riesgo real es bajo; aun así conviene el guard. | Añadir `if (!mounted) return;`. |
| **DEU-03** | **BAJO** | `create_paystub_screen.dart:21`, `paystubs_components.dart:535`, `paystubs_screen.dart:311` | Duplicación de la lista de meses/formateo de período en varios lugares. | — | Extraer a una única utilidad. |

---

## 3. Lo que funciona bien

- **Seguridad por reglas sólida y comentada** (`VUL-XX`): aislamiento multiempresa en todas las lecturas; `paystubs.update` de empleado/supervisor limitado a su propio doc `pendiente` con `affectedKeys` y `respondedAt == request.time`; `communicationReads.create` fuerza `docId == comunicadoId + '_' + uid` y `inCompany`.
- **Recibos limpia Storage** al borrar (`paystubs_provider.dart:250-262`) con manejo de errores; el alta hace rollback del archivo si falla el guardado del doc.
- **Visualizador de PDF maduro** (`pdf_viewer_dialog.dart`): `mounted`, reintento, fallback "abrir en pestaña nueva" en web, mensaje amable ante CORS, sin fugas.
- **Datos server-side correctos:** timestamps derivados como `Timestamp` (el `toDate()` de `cloud_firestore` ya devuelve hora **local**; no hay bug de zona horaria).
- **Streams resilientes** con `retryOnError` (backoff) en asistencias/incidencias/lugares/empleados.
- **Índices declarados** para los `where` de comunicados; `firestore_index_coverage_test.dart` los protege.
- **Tests de responsive** para comunicados a 320/375/768/1024/1440 px, sin desbordes.
- **`analyze` limpio** (0 issues) y 507 tests verdes.

---

## 4. Dudas

- **NOT-02:** ¿`streamReadersForComunicado` es realmente denegado? Depende del comportamiento exacto de evaluación de reglas para `list` con campo de recurso. Requiere reproducir en emulador con un admin real.
- **NAV-02:** ¿Es intencional que el superadmin **no** gestione comunicados? La rama superadmin en `comunicado_repository_impl.dart:59` sugiere que sí se pensó, pero `isAdminProvider` la deja inalcanzable.
- **REC-02:** ¿Se espera un recibo por período, o varios (p. ej. correcciones)? Define si el control de duplicados debe bloquear o solo advertir.
- **Storage rules + token:** no se pudo validar el camino real de `storage.rules` con token de usuario en runtime (solo lectura estática).

---

## 5. NO VERIFICADO (requiere emulador / dispositivo / credenciales)

- Denegación real de la query **"Leído por"** en emulador (NOT-02).
- Comportamiento real de **CORS** en Web para el visor de PDF y descarga de recibos.
- Layout en **dispositivo físico** a 320/360 px (los tests de widget cubren 320 px de comunicados; faltan recibos y físico).
- Efectividad del **App Check** deshabilitado (SEC-02).
- Suite completa de **seguridad** corriendo con `--project locustaf-test` (obligatorio para el caso de Storage).

---

## 6. Top 5 a arreglar

1. **NOT-01 (ALTO):** borrar el PDF de Storage al eliminar un comunicado (evitar huérfanos). — Cambio pequeño, impacto claro.
2. **NOT-02 (ALTO/DUDA):** verificar y corregir la query de "Leído por" (`communicationReads` por `companyId` o regla por `isOwner`). — Funcionalidad probablemente rota para admins.
3. **NOT-03 + NAV-02 (MEDIO):** no lanzar excepción en `comunicadoRepositoryProvider` y decidir el acceso del superadmin (evita pantallas rotas / rama muerta).
4. **REC-01 + REC-02 (MEDIO):** filtrar el dropdown de recibos por rol y bloquear recibos duplicados por período.
5. **REC-04 / NOT-06 + SEC-03/TST-01 (MEDIO):** dejar de exponer errores crudos en la UI y añadir tests de rules + widgets para ambas features (hoy la regresión de NOT-02 pasa inadvertida).

---

## 7. Remediación aplicada (post-auditoría)

Se implementaron las correcciones de Fase 1 (robustez) y Fase 2 (UI/consistencia) sin tocar `firestore.rules` ni `storage.rules`. `flutter analyze` → **0 issues**; `flutter test` → **519 tests** en verde (eran 507; +12 nuevos).

| ID | Estado | Cambio |
|----|--------|-------|
| **NOT-01** | ✅ Corregido | `comunicados_components.dart` (`_confirmDelete`): tras borrar el doc se borra el PDF de Storage (`storageServiceProvider.deleteFile`) con `try/catch` + `LoggingService` best-effort. |
| **NOT-02** | ✅ Corregido | `comunicado_repository_impl.dart` (`streamReadersForComunicado`): ahora usa `queryStreamWithFilters` con `{companyId, comunicadoId}` (solo igualdades → index merge, sin índice nuevo). La denegación real sigue pendiente de verificación en emulador. |
| **NOT-03** | ✅ Corregido | `comunicados_provider.dart`: `comunicadoRepositoryProvider` ya no lanza; usa `user?.companyId ?? ''` y el repo emite listas vacías cuando no hay empresa. |
| **NOT-04** | ✅ Corregido | `createComunicado`: guard en runtime (PDF XOR contenido) con `AsyncActionState.failure` en vez de `assert`. |
| **NOT-06 / REC-04** | ✅ Corregido | Mensajes de error de UI vía `ErrorHandler.parse(e).message` en comunicados y recibos (provider, pantallas de alta/listado y widgets). |
| **NOT-07 / NOT-08** | ✅ Corregido | `createComunicado`/`deleteComunicado` usan `_firestoreService`; el `id` pre-generado por el provider se reutiliza como `docId` (coincide con el `storagePath`). |
| **NOT-09** | ✅ Corregido | Nombre de archivo sanitizado con `FileUtils.sanitizeFileName`. |
| **NOT-10** | ✅ Corregido | El comunicado PDF se marca como leído al abrirlo (ya no depende de `onPdfLoaded`). |
| **NOT-11** | ✅ Corregido | `maxLength` 120 (título) y 5000 (contenido). |
| **REC-01** | ✅ Corregido | Dropdown de alta de recibo filtrado a `employee`/`supervisor` (activos, no borrados). |
| **REC-02** | ✅ Corregido | Nuevo `PaystubRepository.getPaystubsForUser` + `FirestoreService.queryGetWithFilters`; `createPaystub` bloquea duplicado por `(userId, periodo)` con mensaje amigable. |
| **REC-05 / REC-07** | ✅ Corregido | Comparaciones por `UserRole` (y `rol.label`) y eliminación del wrapper `getNormalizedPeriod` (se usa `p.normalizedPeriod`). |
| **DEU-02** | ✅ Corregido | Guard `if (!mounted) return;` en los `ref.listen` de las pantallas de alta. |
| **SEC-03 / TST-01** | 🟡 Parcial | Añadidos tests de repositorio (recibos, comunicados) y de provider (validación runtime) contra `fake_cloud_firestore`. Pendiente: tests de **widgets** de las pantallas de alta y tests de **rules** JS para las 3 colecciones. |

**Veredicto final: APTO.** No hay bloqueantes; las correcciones de robustez y consistencia quedaron aplicadas y cubiertas por tests. Los pendientes son mejoras de cobertura (rules JS / widgets de alta), la decisión de producto sobre superadmin (NAV-02) y verificaciones que requieren emulador/dispositivo (NOT-02, CORS, layout físico).

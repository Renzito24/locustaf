## TASK-024 – Gestión completa de Documentación Médica (Firebase Storage)

### Objetivo

Completar definitivamente el módulo de Documentación Médica, integrando Firebase Storage con Firestore para permitir la gestión real de archivos, garantizando seguridad, consistencia de datos y una experiencia de usuario robusta.

---

### Alcance

La tarea comprende la auditoría, corrección y finalización completa del módulo Medical Documents.

No deben quedar funcionalidades simuladas ni campos sin uso.

---

### Funcionalidades obligatorias

#### 1. Firebase Storage

- Integrar Firebase Storage.
- Crear servicio específico para almacenamiento de archivos.
- Mantener separación de responsabilidades (StorageService independiente).

---

#### 2. Subida de archivos

Permitir subir:

- PDF
- JPG
- JPEG
- PNG

Validar:

- tipo MIME
- extensión
- tamaño máximo configurable
- nombre seguro del archivo

Mostrar progreso durante la carga.

---

#### 3. Descarga y visualización

Permitir:

- visualizar documentos cuando sea posible
- descargar archivos
- abrir PDF e imágenes desde la aplicación

---

#### 4. Reemplazo de archivos

Cuando un documento sea editado:

- permitir reemplazar el archivo existente
- eliminar el archivo anterior de Firebase Storage
- actualizar Firestore únicamente cuando la operación sea exitosa

Evitar archivos huérfanos.

---

#### 5. Eliminación

Al eliminar un documento:

- eliminar primero el archivo físico
- luego eliminar o desactivar el documento según la estrategia Soft Delete existente

Nunca dejar referencias rotas.

---

#### 6. Validaciones

Validar:

- usuario existente
- usuario activo
- archivo seleccionado
- tipo permitido
- tamaño permitido
- errores de red
- cancelación de carga
- permisos insuficientes
- errores de Firebase Storage

---

#### 7. Manejo de errores

Todos los errores deben tener mensajes claros para el usuario.

No utilizar Exception genérica.

Crear excepciones específicas del dominio cuando corresponda.

---

#### 8. Optimización

Evitar:

- cargas duplicadas
- archivos temporales innecesarios
- operaciones redundantes sobre Firestore

---

#### 9. Arquitectura

Mantener Feature-First + Clean Architecture.

Toda la lógica de Storage debe vivir fuera de la UI.

La UI únicamente debe consumir Providers y Notifiers.

---

#### 10. Auditoría del módulo

Revisar:

- Models
- Repository
- RepositoryImpl
- Providers
- Notifiers
- Screens
- Widgets
- Firestore
- Firebase Storage

Corregir deuda técnica encontrada si pertenece al módulo.

---

### Criterios de aceptación

El módulo se considera terminado únicamente si:

- Firebase Storage funciona correctamente.
- Firestore mantiene consistencia.
- No existen archivos huérfanos.
- No existen referencias rotas.
- La subida muestra progreso.
- La descarga funciona.
- La visualización funciona.
- La edición reemplaza correctamente archivos.
- La eliminación mantiene consistencia.
- flutter analyze continúa sin errores en lib/.

---

### Entregables

- Resumen técnico.
- Archivos creados.
- Archivos modificados.
- Reglas de negocio implementadas.
- Problemas encontrados.
- Problemas resueltos.
- Commit sugerido.
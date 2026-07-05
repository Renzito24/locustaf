# TASK-014 – ESTABILIZACIÓN Y CONSISTENCIA DE LA ARQUITECTURA

## Objetivo

Corregir los hallazgos críticos detectados durante la auditoría técnica del proyecto sin agregar nuevas funcionalidades.

Este TASK tiene como objetivo mejorar la consistencia entre módulos, reforzar la seguridad y reducir deuda técnica antes de continuar con nuevas implementaciones.

No deben modificarse pantallas, navegación ni comportamiento funcional visible para el usuario.

---

# Alcance

## 1. Consistencia de updatedAt

### Medical Documents

Actualmente las operaciones de actualización no garantizan la actualización del campo `updatedAt`.

Debe modificarse el repositorio para que toda operación de actualización escriba:

- updatedAt = DateTime.now()

---

### Incidences

Aplicar exactamente el mismo criterio.

Toda modificación de una incidencia debe actualizar automáticamente:

- updatedAt = DateTime.now()

Debe mantenerse el mismo comportamiento utilizado en:

- Users
- Workplaces

---

## 2. Firestore Security Rules

Crear el archivo oficial de reglas de Firestore para el proyecto.

Debe incluir, como mínimo:

- autenticación obligatoria
- administradores con acceso completo
- supervisores con permisos limitados
- empleados únicamente sobre su propia información
- negar acceso anónimo

No modificar todavía Storage Rules.

No implementar reglas extremadamente complejas.

El objetivo es disponer de una base segura para producción.

---

## 3. Refactor de FirestoreService

Actualmente existen consultas con `orderBy()` hardcodeado.

Refactorizar el servicio para permitir consultas reutilizables.

El servicio debe aceptar el campo de ordenamiento como parámetro.

No romper compatibilidad con los módulos existentes.

Si es necesario, crear sobrecargas o métodos auxiliares manteniendo compatibilidad hacia atrás.

---

## 4. Manejo uniforme de excepciones

Revisar los repositorios existentes para unificar el manejo de errores.

Criterios:

- conservar stack trace (`rethrow`)
- evitar `throw e`
- mantener mensajes consistentes
- evitar lógica duplicada

No modificar la UI.

Solo mejorar la consistencia de la capa Data.

---

# Fuera de alcance

Este TASK NO debe implementar:

- nuevas pantallas
- nuevos providers
- nuevos modelos
- nuevas rutas
- cambios visuales
- optimizaciones de rendimiento
- refactorizaciones grandes
- exportación PDF
- exportación Excel

---

# Arquitectura

Debe respetarse completamente la arquitectura existente:

- Feature-First
- Clean Architecture adaptada al MVP
- Riverpod
- GoRouter
- Firebase
- Equatable

No introducir nuevas dependencias.

No utilizar build_runner.

No utilizar freezed.

---

# Criterios de aceptación

- updatedAt se actualiza correctamente en Medical Documents.
- updatedAt se actualiza correctamente en Incidences.
- Existe un archivo de Firestore Rules listo para producción básica.
- FirestoreService elimina orderBy hardcodeado sin romper compatibilidad.
- El manejo de excepciones es consistente en todos los repositorios revisados.
- flutter analyze devuelve 0 issues.
- No se modifica el comportamiento funcional del sistema.
- No se rompe ninguna funcionalidad implementada en TASK-001 a TASK-013.
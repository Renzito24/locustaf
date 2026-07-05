# TASK-014 – ETAPA 3: REFACTORIZACIÓN DE FirestoreService

## Objetivo

Eliminar la dependencia de `orderBy()` hardcodeado en `FirestoreService`, mejorando la reutilización del servicio sin modificar el comportamiento funcional actual del sistema.

Esta etapa forma parte del proceso de estabilización técnica del proyecto.

No incorpora nuevas funcionalidades.

---

# Contexto

La auditoría técnica detectó que `FirestoreService.queryStream()` contiene un criterio de ordenamiento fijo, reduciendo su reutilización y obligando a adaptar distintos módulos a una implementación específica.

El objetivo es convertir el servicio en una pieza más genérica, manteniendo la compatibilidad con el código existente.

---

# Alcance

## 1. Refactorizar `FirestoreService.queryStream()`

Eliminar el `orderBy()` hardcodeado.

El campo de ordenamiento deberá recibirse como parámetro.

El orden descendente/ascendente también deberá poder configurarse mediante parámetros.

---

## 2. Compatibilidad

El refactor NO debe romper el código existente.

Si es necesario:

- utilizar parámetros opcionales;
- mantener sobrecargas;
- crear métodos auxiliares.

La prioridad es mantener compatibilidad con los módulos actuales.

---

## 3. Reutilización

El servicio deberá poder utilizarse con cualquier colección del proyecto.

No deberá quedar acoplado a Attendance ni a ningún otro módulo específico.

---

# Restricciones

No modificar:

- UI
- Screens
- Widgets
- Providers
- Router
- Models
- Repositories (salvo ajustes mínimos indispensables para mantener compatibilidad)
- Firestore Rules
- Arquitectura

No cambiar consultas que actualmente funcionan correctamente salvo que sea estrictamente necesario para adaptar la nueva firma del método.

No optimizar consultas.

No modificar filtros.

No modificar Streams existentes.

---

# Fuera de alcance

Esta etapa NO debe:

- mejorar rendimiento;
- cambiar consultas;
- agregar paginación;
- implementar caché;
- modificar índices;
- cambiar lógica de negocio.

El único objetivo es desacoplar el criterio de ordenamiento del servicio.

---

# Criterios de aceptación

- `FirestoreService` deja de depender de un `orderBy()` fijo.
- El campo de ordenamiento es configurable.
- El orden ascendente/descendente es configurable.
- Los módulos existentes continúan funcionando sin cambios funcionales.
- `flutter analyze` devuelve 0 issues.
- No se introducen regresiones.

---

# Resultado esperado

`FirestoreService` queda preparado para reutilizarse en cualquier módulo del proyecto, manteniendo la compatibilidad con la arquitectura existente y reduciendo el acoplamiento detectado durante la auditoría.
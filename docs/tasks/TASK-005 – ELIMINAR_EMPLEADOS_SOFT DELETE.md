TASK-005 – ELIMINAR EMPLEADOS (SOFT DELETE)

Contexto obligatorio:
Leer y respetar completamente:
- lib/core/docs/PROJECT_CONTEXT.md
- docs/tasks/TASK-005-DELETE-EMPLOYEES.md (este archivo)

No modificar arquitectura.
No crear nuevas capas innecesarias.
No tocar Firebase Auth.

---

## 🎯 OBJETIVO

Implementar eliminación lógica de empleados mediante soft delete en Firestore.

El empleado NO se elimina físicamente.
Se marca como eliminado con isDeleted = true.

---

## ⚙️ CAMBIOS OBLIGATORIOS

---

### 1. REPOSITORY

Archivo:
lib/features/employees/data/repositories/users_repository_impl.dart

Agregar:

Future<void> deleteUser(String uid)

Implementación:
- actualizar documento Firestore del usuario
- set isDeleted = true
- set updatedAt = DateTime.now()

NO borrar documento.
NO tocar Auth.

---

### 2. DOMAIN

Archivo:
lib/features/employees/domain/repositories/users_repository.dart

Agregar:

Future<void> deleteUser(String uid)

---

### 3. PROVIDER

Crear archivo:

lib/features/employees/presentation/providers/delete_employee_notifier.dart

Responsabilidad:
- AsyncNotifier
- estados loading / error / success
- llamar repository.deleteUser(uid)

---

### 4. UI – EMPLOYEE CARD

Archivo:
lib/features/employees/presentation/widgets/employee_card.dart

Cambios:
- usar callback existente onToggleActive o agregar onDelete si es necesario
- mostrar confirm dialog ANTES de eliminar

Confirmación obligatoria:

"¿Seguro que deseas eliminar este empleado?"

---

### 5. LISTA DE EMPLEADOS

Archivo donde se usa usersStreamProvider:

Filtrar:

- excluir usuarios con isDeleted == true

---

## 🚫 RESTRICCIONES

- NO eliminar usuarios en Firebase Auth
- NO borrar documentos Firestore físicamente
- NO modificar arquitectura del proyecto
- NO crear nuevas features fuera de employees
- NO duplicar lógica existente

---

## 🧠 DECISIÓN ARQUITECTÓNICA

Se implementa SOFT DELETE por seguridad de datos laborales.
Los registros deben conservarse para historial y trazabilidad.

---

## 🧪 CRITERIOS DE ACEPTACIÓN

- Empleado desaparece de la lista tras eliminar
- Documento Firestore queda con isDeleted = true
- No hay errores en flutter analyze
- UI muestra confirmación antes de eliminar
- Stream actualiza automáticamente

---

FIN DEL TASKTASK-005 – ELIMINAR EMPLEADOS (SOFT DELETE)

Contexto obligatorio:
Leer y respetar completamente:
- lib/core/docs/PROJECT_CONTEXT.md
- docs/tasks/TASK-005-DELETE-EMPLOYEES.md (este archivo)

No modificar arquitectura.
No crear nuevas capas innecesarias.
No tocar Firebase Auth.

---

## 🎯 OBJETIVO

Implementar eliminación lógica de empleados mediante soft delete en Firestore.

El empleado NO se elimina físicamente.
Se marca como eliminado con isDeleted = true.

---

## ⚙️ CAMBIOS OBLIGATORIOS

---

### 1. REPOSITORY

Archivo:
lib/features/employees/data/repositories/users_repository_impl.dart

Agregar:

Future<void> deleteUser(String uid)

Implementación:
- actualizar documento Firestore del usuario
- set isDeleted = true
- set updatedAt = DateTime.now()

NO borrar documento.
NO tocar Auth.

---

### 2. DOMAIN

Archivo:
lib/features/employees/domain/repositories/users_repository.dart

Agregar:

Future<void> deleteUser(String uid)

---

### 3. PROVIDER

Crear archivo:

lib/features/employees/presentation/providers/delete_employee_notifier.dart

Responsabilidad:
- AsyncNotifier
- estados loading / error / success
- llamar repository.deleteUser(uid)

---

### 4. UI – EMPLOYEE CARD

Archivo:
lib/features/employees/presentation/widgets/employee_card.dart

Cambios:
- usar callback existente onToggleActive o agregar onDelete si es necesario
- mostrar confirm dialog ANTES de eliminar

Confirmación obligatoria:

"¿Seguro que deseas eliminar este empleado?"

---

### 5. LISTA DE EMPLEADOS

Archivo donde se usa usersStreamProvider:

Filtrar:

- excluir usuarios con isDeleted == true

---

## 🚫 RESTRICCIONES

- NO eliminar usuarios en Firebase Auth
- NO borrar documentos Firestore físicamente
- NO modificar arquitectura del proyecto
- NO crear nuevas features fuera de employees
- NO duplicar lógica existente

---

## 🧠 DECISIÓN ARQUITECTÓNICA

Se implementa SOFT DELETE por seguridad de datos laborales.
Los registros deben conservarse para historial y trazabilidad.

---

## 🧪 CRITERIOS DE ACEPTACIÓN

- Empleado desaparece de la lista tras eliminar
- Documento Firestore queda con isDeleted = true
- No hay errores en flutter analyze
- UI muestra confirmación antes de eliminar
- Stream actualiza automáticamente

---

FIN DEL TASK
# TASK-004 – EDITAR EMPLEADOS

## 🎯 Objetivo

Implementar la edición de empleados existentes en LOCUSTAF, permitiendo modificar datos almacenados en Firestore manteniendo consistencia con la arquitectura actual.

---

## 🧱 Contexto

El sistema ya cuenta con:

- TASK-001: Listado de empleados
- TASK-002: Creación de empleados
- TASK-003: Hardening del módulo de empleados

El siguiente paso es habilitar UPDATE de empleados.

---

## ⚙️ Alcance

Este task incluye:

- Edición de empleados existentes
- Actualización en Firestore
- Reutilización del formulario existente
- Navegación desde lista → edición
- Precarga de datos del empleado

---

## 🚫 Fuera de alcance

- No se modifica Firebase Auth
- No se permite cambio de email en Auth
- No se implementa eliminación de empleados
- No se agregan roles dinámicos aún

---

## 🔄 Flujo esperado

Employee List  
→ Click "Editar"  
→ EditEmployeeScreen  
→ EmployeeForm precargado  
→ Validación  
→ Update en Firestore  
→ Stream actualiza lista automáticamente  

---

## 📁 Archivos a crear

### 1. Edit screen

lib/features/employees/presentation/screens/edit_employee_screen.dart

Responsabilidad:
- Recibir UserModel
- Mostrar EmployeeForm en modo edición
- Precargar datos

---

### 2. Provider de actualización

lib/features/employees/presentation/providers/update_employee_notifier.dart

Responsabilidad:
- Manejar estado AsyncLoading / AsyncError
- Llamar repository.updateUser()

---

## ✏️ Archivos a modificar

### 1. EmployeeCard

lib/features/employees/presentation/widgets/employee_card.dart

Cambio:
- Conectar onEdit callback (NO cambiar UI)

---

### 2. Router

lib/core/router/app_router.dart

Agregar ruta:

/employees/edit

---

### 3. Repository

lib/features/employees/data/repositories/users_repository_impl.dart

Agregar:

Future<void> updateUser(UserModel user)

Solo Firestore update por UID.

---

### 4. EmployeeForm

lib/features/employees/presentation/widgets/employee_form.dart

Cambios:
- Agregar modo edición
- Precargar datos si isEditing == true
- Cambiar botón de “Crear” a “Guardar”

---

## 🧠 Reglas importantes

- No modificar Auth
- No crear nuevas capas
- No duplicar formularios
- Reutilizar EmployeeForm
- Usar Validators core

---

## 🧪 Criterios de aceptación

- Se puede abrir pantalla de edición
- Datos se muestran correctamente precargados
- Se puede modificar y guardar
- Firestore se actualiza correctamente
- Lista se actualiza automáticamente
- flutter analyze = 0 issues

---

## 🚀 Resultado esperado

CRUD de empleados pasa a estado:

- CREATE ✔
- READ ✔
- UPDATE ✔

---

## 📌 Nota arquitectónica

Este task consolida el módulo de empleados como un sistema CRUD completo sobre Firestore con sincronización en tiempo real.
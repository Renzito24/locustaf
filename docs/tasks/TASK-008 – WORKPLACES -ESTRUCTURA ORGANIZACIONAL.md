# TASK-008 – WORKPLACES (GESTIÓN DE LUGARES DE TRABAJO)

## 🎯 OBJETIVO

Implementar la gestión de lugares de trabajo (Workplaces) para LOCUSTAF.

Esto permite asignar empleados a ubicaciones físicas o unidades organizativas.

Es la base de la estructura empresarial del sistema.

---

## 🧱 CONTEXTO

Actualmente:

- Los empleados existen
- La asistencia funciona
- Pero NO existe estructura organizacional

Este task introduce la capa de organización.

---

## 🏢 ENTIDAD WORKPLACE

### WorkplaceModel

Campos:

- id (string)
- name (string)
- description (string?)
- address (string?)
- isActive (bool)
- createdAt (DateTime)
- updatedAt (DateTime?)

---

## 🔗 RELACIÓN CON EMPLEADOS

Se agrega campo en UserModel:

- workplaceId (string?)

Relación:
- 1 workplace → muchos empleados
- un empleado → 1 workplace (opcional por ahora)

---

## ⚙️ FUNCIONALIDADES

---

### 1. CREAR WORKPLACE

- nombre obligatorio
- descripción opcional
- dirección opcional
- activo por defecto = true

---

### 2. LISTAR WORKPLACES

- lista completa
- filtro activos/inactivos

---

### 3. ASIGNAR EMPLEADO A WORKPLACE

- desde creación de empleado (TASK-002/004)
- desde edición de empleado (TASK-004)

---

### 4. FILTRAR EMPLEADOS POR WORKPLACE

- en EmployeesScreen agregar filtro opcional

---

## 📁 ESTRUCTURA A CREAR

---

### 1. MODEL

lib/features/workplaces/data/models/workplace_model.dart

---

### 2. DOMAIN REPOSITORY

lib/features/workplaces/domain/repositories/workplace_repository.dart

---

### 3. DATA REPOSITORY

lib/features/workplaces/data/repositories/workplace_repository_impl.dart

---

### 4. PROVIDER

lib/features/workplaces/presentation/providers/workplace_notifier.dart

---

### 5. UI

lib/features/workplaces/presentation/screens/workplaces_screen.dart

---

### 6. CREATE/EDIT (UI SIMPLE)

- formulario básico
- reutilizar patrón de EmployeeForm (sin duplicar arquitectura)

---

## 🔐 REGLAS DE NEGOCIO

- workplace puede estar inactivo
- empleados solo pueden asignarse a workplaces activos
- si workplace se desactiva → no elimina empleados

---

## 🚫 RESTRICCIONES

- NO modificar Auth
- NO tocar Attendance
- NO romper Employees module
- NO crear backend
- SOLO Firestore + Riverpod
- mantener Feature-First

---

## 🧪 CRITERIOS DE ACEPTACIÓN

- se pueden crear workplaces
- se pueden listar workplaces
- empleados pueden tener workplace asignado
- filtro por workplace funciona
- UI no rompe Employees ni Attendance
- flutter analyze = 0 issues

---

## 🧠 NOTA ARQUITECTÓNICA

Workplaces es la capa organizacional del sistema.

Conecta:
- Employees
- Attendance
- Reports (futuro)

FIN DEL TASK
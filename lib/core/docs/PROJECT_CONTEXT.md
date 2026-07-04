# PROJECT CONTEXT – LOCUSTAF

## 🧭 Objetivo del sistema

LOCUSTAF (Locus Staff) es un sistema web de control de asistencia laboral.

El objetivo es construir un sistema profesional, escalable y mantenible desde el inicio, evitando deuda técnica.

---

## 🏗️ Arquitectura general

El proyecto utiliza una arquitectura híbrida:

### 1. Feature-First (nivel global)

Todo el código está organizado por funcionalidad:

lib/features/

---

### 2. Clean Architecture (nivel interno)

Cada feature contiene:

- data/
- domain/
- presentation/

---

## ⚙️ Stack tecnológico

- Flutter Web
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Riverpod (state management)
- GoRouter (routing)
- Equatable (modelos)
- Sin build_runner
- Sin freezed

---

## 📁 Estructura base

lib/
  app/
  core/
    constants/
    router/
    services/
    utils/
    docs/
  features/
    authentication/
    dashboard/
    employees/
    attendance/
    history/
    medical_documents/
    reports/
    workplaces/

---

## 👥 Feature actual: Employees

### TASK-001
✔ Lista de empleados
✔ Stream en tiempo real
✔ filtros y búsqueda

### TASK-002
✔ Alta de empleados
✔ Firebase Auth integration
✔ Firestore sync con UID

### TASK-003 (en curso)
- Hardening del módulo de empleados
- rollback Auth ↔ Firestore
- centralización de validaciones
- mejora UX de errores

---

## 🔧 Reglas de desarrollo

- No mezclar UI con lógica de datos
- Repositories solo acceso a datos
- Riverpod para estado
- AsyncNotifier para operaciones async
- FirestoreService como capa de acceso a datos
- No usar freezed ni code generation

---

## 🔄 Flujo de trabajo

1. Definir TASK
2. Implementación (OpenCode)
3. Code review (ChatGPT)
4. flutter analyze
5. commit
6. siguiente TASK

---

## ⚠️ Reglas para IA (IMPORTANTE)

Cualquier IA (OpenCode, ChatGPT u otra) debe:

- Leer este archivo antes de modificar código
- No asumir estructura del proyecto
- No inventar carpetas o features
- Respetar arquitectura existente
- No refactorizar sin tarea explícita

---

## 📌 Estado del sistema

- Auth: ✔ estable
- Employees: ✔ en desarrollo avanzado
- Firestore: ✔ integrado
- Routing: ✔ estable
- Dashboard: ✔ estable
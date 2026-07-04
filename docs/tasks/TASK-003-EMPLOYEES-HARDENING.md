# TASK-003 – Hardening del módulo de Empleados

## 🎯 Objetivo

Transformar el módulo de empleados en un sistema robusto, consistente y escalable, eliminando riesgos de inconsistencia entre Auth y Firestore, mejorando UX de errores y centralizando validaciones.

---

## 🧱 Estado actual

El módulo de empleados ya cuenta con:

- TASK-001: Listado de empleados con Stream en tiempo real
- TASK-002: Alta de empleados completa
- Firebase Authentication integrado
- Firestore sincronizado con UID como document ID
- Riverpod (AsyncNotifier + Providers)
- GoRouter configurado

---

## ⚠️ Problemas detectados

- Posible inconsistencia entre Firebase Auth y Firestore (usuario huérfano si falla Firestore)
- Validaciones duplicadas en UI
- Manejo de errores limitado en UX
- FirestoreService puede crecer sin control claro
- Campos “Rol” y “Workplace” sin funcionalidad real (placeholders)

---

## 🔧 Implementaciones de TASK-003

### 1. Consistencia Auth ↔ Firestore (CRÍTICO)

Modificar:

lib/features/employees/presentation/providers/create_employee_notifier.dart

Flujo nuevo:

1. Crear usuario en Firebase Auth
2. Si falla → abortar proceso
3. Crear documento en Firestore
4. Si falla:
   - eliminar usuario de Firebase Auth (rollback)
   - lanzar error controlado

---

### 2. Manejo de errores UX

Modificar:

lib/features/employees/presentation/screens/create_employee_screen.dart

Mejoras:

- Mostrar errores específicos en UI:
  - email ya en uso
  - error de red
  - error Firestore
- Mejor manejo de AsyncLoading / AsyncError
- Feedback claro al usuario (no solo SnackBar genérico)

---

### 3. Centralización de validaciones

Crear archivo nuevo:

lib/core/utils/validators.dart

Contenido:

- email validation
- password validation
- dni validation
- required field validation

Ejemplo de estructura:

class Validators {
  static String? email(String value) {}
  static String? password(String value) {}
  static String? dni(String value) {}
  static String? required(String value, String fieldName) {}
}

---

Migrar validaciones desde:

lib/features/employees/presentation/widgets/employee_form.dart

---

### 4. Revisión FirestoreService

Archivo:

lib/core/services/firestore_service.dart

Acción:

- Verificar consistencia de métodos CRUD
- NO refactor profundo en este task
- Solo asegurar estabilidad actual

---

### 5. Revisión UsersRepositoryImpl

Archivo:

lib/features/employees/data/repositories/users_repository_impl.dart

Validar:

- Mantener responsabilidad exclusiva de acceso a datos
- No mezclar lógica de UI ni validaciones
- Evitar crecimiento como “god repository”

---

### 6. UX de campos deshabilitados

Archivo:

lib/features/employees/presentation/widgets/employee_form.dart

Cambios:

- Campo Rol:
  "Empleado (próximamente)"
- Campo Workplace:
  "Lugar de trabajo (próximamente)"

Alternativa válida: ocultarlos completamente si no aportan valor

---

### 7. Mejora de AsyncNotifier

Archivo:

create_employee_notifier.dart

Requerido:

- Manejo correcto de AsyncLoading
- Manejo de AsyncError con mensajes reales
- Estados claros para UI

---

## 🧪 Criterios de aceptación

- No existen usuarios huérfanos sin manejo de error
- Validaciones centralizadas en core/utils
- UX de error clara y entendible
- Flujo create employee robusto
- Flutter analyze = 0 issues
- Sistema estable para escalar features futuras

---

## 🧠 Resultado esperado

El módulo de empleados queda como:

- Sistema estable de identidad de usuarios
- Base sólida para roles, workplaces y attendance
- Arquitectura consistente Feature-First + Clean per feature
- Backend Firebase correctamente encapsulado

---

## 🚀 Estado final

TASK-003 finaliza cuando:

- Consistencia Auth ↔ Firestore está garantizada
- Validaciones centralizadas
- UX de errores mejorada
- Código sin issues en análisis
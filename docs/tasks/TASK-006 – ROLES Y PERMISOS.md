# TASK-006 – ROLES Y PERMISOS

## 🎯 OBJETIVO

Implementar un sistema básico de roles y permisos en LOCUSTAF para controlar el acceso a funcionalidades del sistema.

Este es el núcleo de seguridad del proyecto.

---

## 🧱 CONTEXTO

Actualmente el sistema permite autenticación con Firebase Auth, pero:

- Todos los usuarios tienen el mismo nivel de acceso
- No existe control de permisos
- No hay diferenciación entre admin / empleado / supervisor

Este task introduce el modelo de autorización.

---

## 👥 ROLES DEFINIDOS

Se implementan 3 roles iniciales:

- admin → acceso total al sistema
- supervisor → acceso a empleados + asistencia + reportes
- employee → acceso limitado a su propia información

---

## 🧠 MODELO DE DATOS

Se agrega campo en UserModel:

```dart
String role;
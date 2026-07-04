# TASK-002 — Alta de Empleados

**Estado:** Pendiente  
**Prioridad:** Alta  
**Versión:** 1.0  
**Fecha:** 04/07/2026

---

# Objetivo

Implementar el módulo completo de alta de empleados para LOCUSTAF.

El sistema deberá permitir que un administrador registre un nuevo empleado mediante un formulario web, creando automáticamente el usuario en Firebase Authentication y almacenando su información en Cloud Firestore.

La implementación deberá respetar completamente la arquitectura actual del proyecto y reutilizar los componentes existentes siempre que sea posible.

---

# Contexto

Actualmente el proyecto cuenta con:

- Autenticación mediante Firebase Authentication.
- Dashboard funcional.
- GoRouter configurado.
- Riverpod para gestión de estado.
- UsersRepositoryImpl implementado.
- usersStreamProvider implementado.
- Lista de empleados (TASK-001) completamente funcional.
- Arquitectura Clean Architecture organizada mediante Feature-First.

Esta tarea representa la primera funcionalidad completa de escritura sobre Firebase.

---

# Alcance

Esta tarea incluye únicamente la funcionalidad de creación de empleados.

Debe contemplar:

- pantalla de creación
- formulario
- validaciones
- provider
- integración con Firebase Authentication
- integración con Cloud Firestore
- actualización automática de la lista de empleados

---

# Fuera del alcance

Esta tarea NO debe implementar:

- edición de empleados
- eliminación de empleados
- cambio de contraseña
- recuperación de contraseña
- subida de fotografías
- asignación de múltiples lugares de trabajo
- permisos avanzados
- gestión de roles
- auditoría
- historial de cambios

Todo lo anterior será implementado en tareas posteriores.

---

# Arquitectura

La implementación debe respetar obligatoriamente la arquitectura existente.

Organización general:

- Feature-First

Capas internas:

- presentation
- domain
- data

No deben modificarse decisiones arquitectónicas existentes.

---

# Componentes a implementar

## Pantalla

Crear:

lib/features/employees/presentation/screens/create_employee_screen.dart

Debe integrarse con DashboardLayout existente.

---

## Widget reutilizable

Crear:

lib/features/employees/presentation/widgets/employee_form.dart

El formulario deberá mantenerse separado de la pantalla.

---

## Provider

Implementar un provider específico para la creación de empleados.

Debe encargarse de toda la lógica de negocio.

La pantalla no deberá contener lógica de creación.

---

## Repositorio

Reutilizar:

UsersRepositoryImpl

No crear un repositorio paralelo.

---

# Campos requeridos

El formulario deberá contener:

- Nombre
- Apellido
- Email
- DNI
- Teléfono (opcional)
- Contraseña
- Lugar de trabajo (placeholder si aún no existe la funcionalidad)
- Rol (empleado por defecto)

---

# Validaciones

Validar como mínimo:

Nombre:
- obligatorio

Apellido:
- obligatorio

Email:
- formato válido

DNI:
- obligatorio

Contraseña:
- mínimo 6 caracteres

Mostrar mensajes claros al usuario.

---

# Flujo funcional

El flujo esperado será:

Formulario

↓

Validación

↓

Provider

↓

UsersRepositoryImpl

↓

Firebase Authentication

↓

Cloud Firestore

↓

Actualización automática mediante usersStreamProvider

↓

Regreso o confirmación visual

---

# Firebase Authentication

Debe crear un usuario nuevo.

El UID generado será el identificador oficial del empleado.

No generar identificadores propios.

---

# Cloud Firestore

Crear documento dentro de:

users

El documento deberá utilizar el UID generado por Firebase Authentication.

Debe almacenarse toda la información necesaria para construir un UserModel válido.

---

# Integración

Debe reutilizar:

- usersStreamProvider

No crear:

- employeeStreamProvider
- createUsersRepository
- servicios duplicados
- streams paralelos

---

# Navegación

Agregar la ruta correspondiente para acceder a la pantalla de creación.

No modificar la arquitectura de GoRouter.

No romper DashboardLayout.

---

# Interfaz

La interfaz debe mantener coherencia con el resto del proyecto.

Utilizar:

- Cards
- Padding consistente
- Espaciados uniformes
- Componentes reutilizables
- Material 3

Evitar lógica visual duplicada.

---

# Archivos permitidos

Se permite crear o modificar únicamente los archivos necesarios para implementar esta funcionalidad.

Preferentemente dentro de:

features/employees/

y únicamente realizar modificaciones mínimas fuera de esa feature cuando sean estrictamente necesarias (por ejemplo, registro de rutas o providers).

---

# Restricciones

NO crear:

- nuevos repositorios innecesarios
- nuevos servicios innecesarios
- nuevos StreamProvider duplicados

NO modificar:

- DashboardLayout
- autenticación existente
- arquitectura general
- estructura del proyecto

NO mover archivos existentes.

---

# Calidad del código

Mantener:

- nombres descriptivos
- responsabilidades separadas
- widgets reutilizables
- providers livianos
- código legible

Evitar archivos excesivamente grandes.

---

# Criterios de aceptación

La tarea se considerará completada únicamente si:

- El formulario funciona correctamente.
- Se crea un usuario en Firebase Authentication.
- Se crea el documento correspondiente en Firestore.
- El UID coincide con el documento almacenado.
- El nuevo empleado aparece automáticamente en la lista existente.
- No existen errores de compilación.
- flutter analyze devuelve 0 issues.
- La arquitectura permanece consistente.

---

# Riesgos

Debe evitarse especialmente:

- duplicar lectura de Firestore
- romper usersStreamProvider
- modificar DashboardLayout
- alterar el flujo de autenticación
- introducir deuda técnica

---

# Entregables

Al finalizar la implementación deberá entregarse un informe con:

## Archivos creados

Listado completo.

## Archivos modificados

Listado completo.

## Decisiones técnicas

Justificación breve de cualquier decisión tomada.

## Resultado de flutter analyze

Debe indicarse el resultado completo.

## Observaciones

Cualquier limitación detectada durante la implementación.

---

# Definición de terminado (Definition of Done)

La tarea estará finalizada cuando:

- Cumpla todos los criterios de aceptación.
- Pase flutter analyze sin errores.
- Sea aprobada mediante revisión técnica.
- Se encuentre lista para realizar commit.
# TASK-014 – ETAPA 2: FIRESTORE SECURITY RULES

## Objetivo

Implementar las reglas de seguridad de Cloud Firestore para establecer una base segura para producción, respetando la arquitectura actual de LOCUSTAF y sin modificar el comportamiento funcional de la aplicación.

Este TASK forma parte de la estabilización técnica del proyecto y no incorpora nuevas funcionalidades.

---

# Contexto

La Etapa 1 del TASK-014 ya fue completada, incorporando la consistencia del campo `updatedAt` en los repositorios.

En esta etapa se abordará exclusivamente la seguridad de Firestore.

---

# Alcance

## 1. Crear o actualizar `firestore.rules`

Implementar un conjunto de reglas que protejan todas las colecciones utilizadas actualmente por el proyecto.

Las reglas deben ser compatibles con la estructura existente de Firestore.

---

## 2. Autenticación

Toda operación deberá requerir un usuario autenticado.

Debe denegarse cualquier acceso anónimo.

---

## 3. Roles

Las reglas deberán contemplar los roles implementados actualmente por el sistema.

### Administrador

Debe disponer de acceso completo a todas las colecciones utilizadas por la aplicación.

Podrá:

- leer
- crear
- actualizar
- realizar bajas lógicas

---

### Supervisor

Debe poder operar únicamente sobre los módulos permitidos por la aplicación.

No debe disponer de privilegios administrativos.

Las reglas deberán respetar exactamente las restricciones existentes en la aplicación.

---

### Empleado

Debe acceder únicamente a la información correspondiente a su propio usuario cuando la aplicación lo requiera.

No debe poder modificar información administrativa ni acceder a datos pertenecientes a otros empleados.

---

## 4. Funciones auxiliares

Siempre que sea posible utilizar funciones auxiliares para evitar duplicación.

Ejemplos:

- isAuthenticated()
- isAdmin()
- isSupervisor()
- isEmployee()
- isOwner()

El objetivo es mejorar la legibilidad y facilitar el mantenimiento.

---

## 5. Compatibilidad

Las reglas no deben romper el funcionamiento actual de:

- Authentication
- Employees
- Attendance
- History
- Reports
- Workplaces
- Medical Documents
- Incidences

---

# Restricciones

No modificar:

- Código Dart
- Providers
- Router
- Repositories
- Models
- UI
- Firebase Storage Rules
- Cloud Functions

No crear nuevas colecciones.

No modificar la estructura de Firestore.

---

# Criterios de aceptación

- Existe un archivo `firestore.rules` preparado para producción básica.
- Todo acceso requiere autenticación.
- Los permisos se encuentran separados por rol.
- Los empleados no pueden acceder a información que no les corresponde.
- La estructura de reglas es clara y mantenible.
- No se modifica el comportamiento funcional del sistema.

---

# Resultado esperado

LOCUSTAF contará con reglas de seguridad de Firestore consistentes con la arquitectura actual, proporcionando una base sólida para continuar con las siguientes etapas del proyecto.
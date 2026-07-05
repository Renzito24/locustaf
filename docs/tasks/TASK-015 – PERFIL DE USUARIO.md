# TASK-015 – PERFIL DE USUARIO

## Objetivo

Incorporar un módulo de Perfil de Usuario que permita al usuario autenticado consultar su información personal desde la aplicación.

El objetivo es ofrecer una vista centralizada de los datos del usuario sin modificar la lógica existente de autenticación ni de administración.

Esta funcionalidad deberá integrarse respetando completamente la arquitectura Feature-First utilizada por LOCUSTAF.

---

# Contexto

Actualmente la aplicación identifica correctamente al usuario autenticado y dispone de toda la información necesaria en Firestore.

Sin embargo, el usuario no posee una pantalla donde visualizar sus propios datos.

Este módulo será la base para futuras funcionalidades como:

- cambio de contraseña;
- cambio de fotografía;
- preferencias;
- auditoría personal.

---

# Alcance

## Nueva Feature

Crear una nueva feature:

profile

siguiendo exactamente la estructura arquitectónica del resto del proyecto.

---

## Pantalla Perfil

Crear una pantalla que muestre únicamente información del usuario autenticado.

Como mínimo deberá visualizar:

- Foto de perfil (placeholder si no existe).
- Nombre completo.
- Correo electrónico.
- Rol.
- Lugar de trabajo.
- Estado (Activo/Inactivo).
- Fecha de creación de la cuenta.
- Última actualización (si existe).

La información deberá presentarse de forma limpia y consistente con el diseño actual de LOCUSTAF.

---

## Obtención de datos

Los datos deberán obtenerse utilizando la infraestructura existente.

No duplicar lógica.

Reutilizar Providers, Repositories y Services siempre que sea posible.

---

## Navegación

Agregar la nueva opción:

Perfil

en el Sidebar.

La navegación deberá realizarse mediante GoRouter siguiendo el patrón utilizado por el resto del proyecto.

---

## Arquitectura

Respetar completamente:

- Feature-First.
- Clean Architecture adaptada al proyecto.
- Riverpod.
- GoRouter.
- Firebase.
- Material Design.

No introducir nuevas dependencias.

---

# Restricciones

No implementar todavía:

- edición de datos;
- cambio de contraseña;
- carga de fotografía;
- cambio de correo;
- preferencias;
- configuración.

Esta etapa es únicamente de visualización.

---

# Fuera de alcance

No modificar:

- Authentication.
- Users.
- Attendance.
- Reports.
- Workplaces.
- Medical Documents.
- Incidences.
- Firestore Rules.

No realizar cambios en la lógica existente.

---

# Criterios de aceptación

- Existe una nueva feature Profile.
- El Sidebar permite acceder al Perfil.
- Se muestran correctamente los datos del usuario autenticado.
- No existe duplicación de lógica.
- La arquitectura del proyecto permanece consistente.
- flutter analyze devuelve 0 issues.
- No se rompe ninguna funcionalidad existente.

---

# Resultado esperado

LOCUSTAF incorpora un módulo de Perfil de Usuario totalmente integrado con la arquitectura existente, preparado para futuras ampliaciones sin introducir deuda técnica.
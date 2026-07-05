# TASK-015 – ETAPA 2: DISEÑO DE LA PANTALLA DE PERFIL

## Objetivo

Diseñar la interfaz visual del módulo Perfil de Usuario respetando la identidad visual de LOCUSTAF y reutilizando los componentes existentes del proyecto.

Esta etapa modifica únicamente la presentación de la información.

No incorpora funcionalidades nuevas.

---

# Contexto

La estructura del módulo ya fue implementada durante la Etapa 1.

La navegación funciona correctamente y los datos del usuario autenticado ya se obtienen mediante la infraestructura existente.

En esta etapa se mejorará exclusivamente la experiencia visual.

---

# Alcance

## Encabezado

Mostrar un encabezado compuesto por:

- Avatar circular.
- Si el usuario no posee fotografía, mostrar sus iniciales.
- Nombre completo.
- Correo electrónico.
- Badge indicando el rol.

---

## Información

Organizar la información utilizando tarjetas (Card).

Cada dato deberá mostrarse acompañado por un icono representativo.

Como mínimo visualizar:

- Nombre completo.
- Correo electrónico.
- Rol.
- Lugar de trabajo.
- Estado.
- Fecha de creación.
- Última actualización (si existe).

---

## Estado

Mostrar el estado mediante un Chip o Badge.

Activo → color de éxito.

Inactivo → color de advertencia.

No utilizar texto plano.

---

## Diseño

Mantener:

- Material Design.
- Espaciados uniformes.
- Bordes redondeados.
- Diseño responsive.
- Scroll vertical.
- Consistencia con el resto de LOCUSTAF.

---

## Arquitectura

No mover lógica de negocio a la UI.

Continuar reutilizando los Providers existentes.

No crear nuevos Providers.

No crear nuevos Repositories.

No duplicar código.

---

# Restricciones

No implementar:

- edición;
- cambio de contraseña;
- cambio de foto;
- carga de imágenes;
- preferencias;
- configuración.

No modificar otras features.

---

# Criterios de aceptación

- La pantalla posee una apariencia profesional.
- Toda la información se encuentra organizada mediante Cards.
- El estado utiliza un Chip o Badge.
- El rol utiliza un Badge visual.
- El Avatar muestra iniciales cuando no existe fotografía.
- flutter analyze devuelve 0 issues.
- No cambia el comportamiento funcional de la aplicación.

---

# Resultado esperado

El Perfil de Usuario presenta una interfaz moderna, consistente con el resto del sistema y preparada para futuras funcionalidades como edición, fotografía y configuración personal.
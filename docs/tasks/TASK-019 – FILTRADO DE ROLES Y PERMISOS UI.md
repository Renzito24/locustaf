# TASK-019 – FILTRADO DE ROLES Y PERMISOS UI

## Objetivo
Implementar control de visibilidad en la interfaz de LOCUSTAF según el rol del usuario autenticado.

Cada usuario debe ver únicamente las secciones y acciones permitidas según su UserRole.

---

## Roles del sistema

- admin
- supervisor
- employee

---

## Alcance

### Sidebar / Navegación

Filtrar opciones del menú según rol:

#### Admin:
- Dashboard
- Empleados
- Sucursales
- Historial
- Incidencias
- Reportes
- Perfil

#### Supervisor:
- Dashboard
- Empleados (limitado o solo lectura si aplica)
- Historial
- Incidencias
- Perfil

#### Employee:
- Dashboard
- Perfil
- (opcional) Asistencia propia

---

### Reglas de UI

- Ocultar opciones no permitidas (no solo deshabilitar)
- No modificar backend ni Auth system
- No crear nuevos roles
- Mantener diseño actual del sidebar

---

### Navegación segura

- Si un usuario intenta acceder a una ruta no permitida:
  - redirigir a Dashboard o pantalla segura

---

## Reglas técnicas

- Usar UserRole existente
- Mantener arquitectura Feature-First
- No duplicar lógica de permisos
- No modificar backend ni Firestore rules
- No crear providers nuevos

---

## Criterios de aceptación

- Sidebar cambia según rol
- Usuarios solo ven opciones permitidas
- Navegación protegida visualmente
- No errores de rutas
- UI consistente con el resto del sistema
- flutter analyze = 0 issues

---

## Resultado esperado

LOCUSTAF implementa control de acceso visual real por roles, mejorando seguridad UX y coherencia del sistema sin modificar backend.
# TASK-028 — Portal del Empleado

## Contexto

LOCUSTAF ya implementa un sistema de roles (Administrador, Supervisor y Empleado).

Actualmente el rol **Empleado** visualiza el Dashboard (Inicio), el cual muestra información global del sistema (empleados presentes, ausentes, sucursales, etc.), incumpliendo el principio de mínimo privilegio definido en el STD-001.

El objetivo de esta tarea es implementar un **Portal del Empleado** completamente independiente del Portal Administrativo, permitiendo únicamente el acceso a su propia información.

Esta tarea NO debe modificar el comportamiento de Administradores ni Supervisores.

---

# Objetivos

Implementar una experiencia específica para el rol Empleado manteniendo:

- Feature First
- Clean Architecture
- Riverpod
- GoRouter
- Firebase
- Design System Dark + Gold
- Responsive Design

No introducir deuda técnica.

Mantener:

flutter analyze

con:

0 errors
0 warnings

(Los info del script seed.dart no cuentan.)

---

# 1. Navegación del Empleado

Modificar el menú lateral del rol Empleado.

Debe quedar exactamente así:

• Asistencia

• Reportes

• Perfil

──────────────

• Cerrar sesión

Eliminar completamente:

- Inicio
- Empleados
- Lugares
- Historial
- Documentación
- Incidencias

El empleado nunca debe visualizar dichas opciones.

---

# 2. Dashboard

El Dashboard deja de existir para el Empleado.

Al iniciar sesión:

Administrador → Dashboard

Supervisor → Dashboard

Empleado → Asistencia

Modificar GoRouter para que el redirect inicial del empleado sea:

/attendance

Si intenta ingresar manualmente al Dashboard mediante la URL deberá ser redirigido automáticamente a Asistencia.

---

# 3. Seguridad de navegación

Revisar todas las rutas protegidas.

El empleado NO podrá acceder mediante URL a:

- Dashboard
- Employees
- Workplaces
- History
- Medical Documents
- Incidences
- Reportes Administrativos

Toda validación debe realizarse tanto en la interfaz como en GoRouter.

---

# 4. Perfil

La pantalla de Perfil deja de ser únicamente de lectura.

Debe implementarse un modo edición.

Campos editables:

- Nombre
- Apellido
- Teléfono
- Dirección (si existe)
- Avatar/Foto (si ya existe soporte)

Campos solo lectura:

- DNI
- Email
- Rol
- Estado
- Lugar de trabajo
- Turno asignado
- Fecha de ingreso

Los campos bloqueados deberán visualizarse claramente como información administrativa.

---

# 5. Cambio de contraseña

Agregar una nueva sección denominada:

Seguridad

Implementar:

- Contraseña actual
- Nueva contraseña
- Confirmar contraseña

Validaciones:

- obligatorias
- longitud mínima
- ambas contraseñas coinciden

Utilizar Firebase Authentication.

Si Firebase requiere reautenticación deberá implementarse correctamente.

Utilizar los componentes visuales del Design System.

---

# 6. Reportes Personales

Crear una vista específica para el empleado.

No reutilizar el módulo administrativo.

Mostrar únicamente información del usuario autenticado.

Indicadores:

- Días trabajados
- Horas trabajadas
- Horas extra (cuando exista la funcionalidad)
- Llegadas tarde
- Ausencias
- Justificativos
- Incidencias propias

Debajo mostrar:

Historial personal.

Filtros:

- Mes
- Año

Nunca mostrar información de otros empleados.

---

# 7. Responsive

Mantener el comportamiento responsive implementado anteriormente.

Desktop:

- Sidebar fija

Tablet:

- Sidebar colapsable

Mobile:

- Drawer

Todas las pantallas nuevas deberán visualizarse correctamente desde 360 px de ancho.

No deben existir overflows.

---

# 8. UI

Mantener el Design System oficial.

No modificar:

- Colores
- Tipografías
- Botones
- Cards
- Inputs
- Espaciados
- Gradientes
- Sombras

Toda la nueva interfaz debe respetar la identidad visual Dark + Gold implementada en TASK-027.

---

# 9. Calidad

Al finalizar ejecutar:

flutter analyze

Resultado esperado:

0 errors

0 warnings

(No considerar los info del script seed.dart.)

---

# 10. Entregable

Al finalizar entregar un informe indicando:

- Archivos creados
- Archivos modificados
- Funcionalidades implementadas
- Cambios en navegación
- Cambios de seguridad
- Cambios realizados en Perfil
- Cambios realizados en Reportes
- Resultado de flutter analyze
- Riesgos detectados
- Mensaje de commit sugerido en español
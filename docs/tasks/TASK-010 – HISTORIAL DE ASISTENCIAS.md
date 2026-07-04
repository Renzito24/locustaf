# TASK-010 – HISTORIAL DE ASISTENCIAS

## 🎯 OBJETIVO

Implementar el módulo completo de Historial de Asistencias.

Este módulo permitirá consultar todas las jornadas laborales registradas en el sistema mediante filtros avanzados y visualización detallada.

No modifica información existente; es un módulo de consulta.

---

# CONTEXTO

Actualmente LOCUSTAF ya dispone de:

- Autenticación
- Empleados
- Roles y permisos
- Attendance (Check-In / Check-Out)
- Workplaces
- Reportes

Este TASK aprovecha toda esa información para ofrecer una consulta histórica completa.

---

# FUNCIONALIDADES

## 1. Listado de asistencias

Mostrar todas las asistencias registradas.

Orden:

- Más recientes primero.

Cada registro deberá mostrar:

- Empleado
- Workplace
- Fecha
- Hora de ingreso
- Hora de egreso
- Duración
- Estado

---

## 2. Filtros

Implementar filtros combinables.

### Empleado

Dropdown.

Debe permitir:

- Todos
- Empleado específico

---

### Workplace

Dropdown.

Debe permitir:

- Todos
- Workplace específico

---

### Fecha desde

DatePicker.

---

### Fecha hasta

DatePicker.

---

### Estado

Opciones:

- Todos
- Activa
- Finalizada

---

Los filtros deben funcionar simultáneamente.

---

## 3. Búsqueda

Agregar búsqueda por:

- Nombre
- Apellido

No debe romper los filtros.

---

## 4. Vista detalle

Al seleccionar una asistencia se abrirá una pantalla (o diálogo) mostrando:

- Nombre completo
- Email
- Workplace
- Fecha
- Hora ingreso
- Hora egreso
- Duración
- Estado

Solo lectura.

---

## 5. Indicadores rápidos

Encima de la tabla mostrar:

- Total de registros
- Jornadas activas
- Jornadas finalizadas

---

# ARQUITECTURA

Mantener la arquitectura existente.

Feature-First.

Clean Architecture.

Riverpod.

---

# ARCHIVOS

## Presentation

history/

presentation/

screens/

history_screen.dart

widgets/

history_filter_bar.dart

history_card.dart

history_detail_dialog.dart

providers/

history_provider.dart

---

## Data

Reutilizar AttendanceRepository.

No duplicar consultas existentes.

Si falta algún método de consulta, agregarlo en AttendanceRepository.

---

## Domain

Solo agregar interfaces si realmente son necesarias.

---

# REGLAS

- No modificar Employees.
- No modificar Auth.
- No modificar Workplaces.
- No modificar Reports.
- No modificar Dashboard.

Toda la lógica pertenece al módulo History.

---

# UI

Mantener el mismo estilo utilizado en:

- Employees
- Reports

Utilizar:

- Cards
- DataTable
- Chips
- Badges
- Dialogs

Mantener consistencia visual.

---

# CRITERIOS DE ACEPTACIÓN

✓ Se listan todas las asistencias.

✓ Orden descendente por fecha.

✓ Filtro por empleado.

✓ Filtro por workplace.

✓ Filtro por estado.

✓ Filtro por rango de fechas.

✓ Búsqueda por nombre.

✓ Vista detalle funcional.

✓ Indicadores superiores correctos.

✓ flutter analyze = 0 issues.

---

# RESTRICCIONES

- No agregar dependencias nuevas.
- No romper la arquitectura existente.
- Reutilizar repositorios y providers cuando sea posible.
- No duplicar lógica de Attendance.
- Mantener la consistencia con TASK-001 al TASK-009.

FIN DEL TASK.
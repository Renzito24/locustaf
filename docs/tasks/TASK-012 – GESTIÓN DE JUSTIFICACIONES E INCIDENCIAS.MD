# TASK-012 – GESTIÓN DE JUSTIFICACIONES E INCIDENCIAS

## 🎯 OBJETIVO

Implementar el módulo completo de Justificaciones e Incidencias.

Este módulo permitirá registrar cualquier situación que afecte la asistencia de un empleado y que no corresponda a una jornada laboral normal.

El módulo será independiente de Attendance, pero estará relacionado con Employees y Reports.

---

# CONTEXTO

Actualmente LOCUSTAF ya dispone de:

- Autenticación
- Empleados
- Roles y permisos
- Attendance
- History
- Workplaces
- Reports
- Medical Documents

Este TASK incorpora la gestión de incidencias laborales.

---

# TIPOS DE INCIDENCIAS

Crear un enum IncidenceType con al menos los siguientes valores:

- Vacaciones
- Licencia médica
- Enfermedad
- Accidente laboral
- Llegada tarde
- Salida anticipada
- Home Office
- Comisión de servicio
- Franco
- Ausencia justificada
- Otro

El enum debe tener métodos para conversión desde/hacia Firestore y una etiqueta legible para la UI.

---

# FUNCIONALIDADES

## 1. Listado

Mostrar todas las incidencias registradas.

Cada registro debe mostrar:

- Empleado
- Tipo
- Fecha inicio
- Fecha fin
- Estado
- Observaciones

Orden:

Más recientes primero.

---

## 2. Alta

Permitir registrar una incidencia.

Campos:

- Empleado (obligatorio)
- Tipo (obligatorio)
- Fecha inicio
- Fecha fin
- Observaciones
- Documento relacionado (opcional)

---

## 3. Edición

Permitir modificar la incidencia utilizando el mismo formulario.

No duplicar formularios.

---

## 4. Baja lógica

Implementar soft delete mediante:

isActive

No eliminar documentos de Firestore.

---

## 5. Estados

Calcular automáticamente:

- Programada
- En curso
- Finalizada

El estado debe calcularse dinámicamente según las fechas.

No guardar este estado en Firestore.

---

## 6. Filtros

Implementar filtros combinables:

- empleado
- tipo
- estado

Agregar búsqueda por:

- nombre
- apellido
- tipo

---

## 7. Vista detalle

Crear una vista de solo lectura.

Mostrar:

- empleado
- tipo
- período
- estado
- observaciones
- documento relacionado (si existe)

---

# MODELO

Crear IncidenceModel siguiendo exactamente el estándar del proyecto:

- Equatable
- copyWith()
- fromJson()
- toJson()
- props

---

# REPOSITORY

Crear:

IncidenceRepository

Implementar:

- getIncidences()
- createIncidence()
- updateIncidence()
- softDeleteIncidence()

---

# PROVIDERS

Crear providers para:

- listado
- filtros
- creación
- edición
- eliminación lógica

Toda la lógica debe vivir en Riverpod.

---

# UI

Mantener la misma línea visual del resto del proyecto.

Utilizar:

- Cards
- DataTable
- Chips
- Badges
- Dialogs

---

# INTEGRACIÓN

Este módulo debe integrarse con:

- Employees
- Reports (en futuras métricas)

No modificar Attendance.

---

# RESTRICCIONES

- No modificar Auth.
- No modificar Attendance.
- No modificar History.
- No modificar Medical Documents.
- No modificar Workplaces.
- No agregar dependencias nuevas.
- Mantener la arquitectura existente.

---

# CRITERIOS DE ACEPTACIÓN

✓ Alta de incidencias.

✓ Edición.

✓ Baja lógica.

✓ Listado completo.

✓ Estados calculados automáticamente.

✓ Filtros combinables.

✓ Vista detalle.

✓ Reutilización de Employees.

✓ flutter analyze = 0 issues.

---

# RESULTADO ESPERADO

LOCUSTAF permitirá gestionar todas las situaciones excepcionales que afectan la asistencia del personal, dejando preparado el sistema para futuras métricas, reportes y exportaciones.

FIN DEL TASK.
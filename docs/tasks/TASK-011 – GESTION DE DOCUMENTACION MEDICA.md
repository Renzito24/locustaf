# TASK-011 – GESTIÓN DE DOCUMENTACIÓN MÉDICA

## 🎯 OBJETIVO

Implementar el módulo completo de Gestión de Documentación Médica de los empleados.

Este módulo permitirá registrar, consultar, editar y controlar el vencimiento de la documentación médica asociada a cada empleado.

No reemplaza Attendance ni History.

Es un módulo independiente relacionado con Employees.

---

# CONTEXTO

Actualmente LOCUSTAF dispone de:

- Autenticación
- Empleados
- Roles y Permisos
- Attendance
- History
- Workplaces
- Reports

Este TASK completa la feature `medical_documents`.

---

# FUNCIONALIDADES

## 1. Listado

Mostrar todos los documentos médicos registrados.

Cada registro mostrará:

- Empleado
- Tipo de documento
- Fecha de emisión
- Fecha de vencimiento
- Estado
- Observaciones (si existen)

Orden:

Vencimiento más próximo primero.

---

## 2. Alta

Permitir registrar un documento médico.

Campos:

- Empleado (obligatorio)
- Tipo de documento (obligatorio)
- Fecha de emisión
- Fecha de vencimiento
- Observaciones
- Archivo adjunto (opcional)

---

## 3. Edición

Permitir modificar todos los datos del documento.

No crear un formulario distinto.

Reutilizar el mismo formulario utilizado para alta.

---

## 4. Baja lógica

No eliminar documentos.

Agregar:

isActive

Si un documento deja de ser válido podrá desactivarse.

---

## 5. Estados

Mostrar visualmente:

🟢 Vigente

🟡 Próximo a vencer
(30 días o menos)

🔴 Vencido

El estado debe calcularse automáticamente.

No guardar el estado en Firestore.

---

## 6. Filtros

Agregar filtros por:

- empleado
- tipo
- estado
- vigentes
- vencidos
- próximos a vencer

Todos combinables.

---

## 7. Búsqueda

Buscar por:

- nombre
- apellido
- tipo de documento

---

## 8. Vista detalle

Pantalla o diálogo de solo lectura.

Mostrar:

- empleado
- tipo
- emisión
- vencimiento
- estado
- observaciones
- archivo adjunto (si existe)

---

# MODELO

Revisar MedicalDocumentModel.

Debe mantener:

- Equatable
- copyWith()
- fromJson()
- toJson()

Agregar únicamente los campos faltantes si fueran necesarios.

No romper compatibilidad.

---

# STORAGE

Si ya existe Firebase Storage configurado:

Permitir subir el archivo y guardar únicamente la URL en Firestore.

Si Storage todavía no está listo:

Dejar preparado el campo:

documentUrl

sin romper la arquitectura.

---

# UI

Mantener la misma línea visual del proyecto.

Utilizar:

- Cards
- DataTable
- Chips
- Badges
- Dialogs

Mantener consistencia con Employees e History.

---

# ARQUITECTURA

Mantener:

Feature-First

Clean Architecture

Riverpod

Toda la lógica de negocio debe vivir en providers y repositories.

La UI únicamente consume estado.

---

# RESTRICCIONES

No modificar:

- Attendance
- History
- Reports
- Employees
- Auth

No agregar dependencias nuevas.

No romper la arquitectura.

---

# CRITERIOS DE ACEPTACIÓN

✓ Alta de documentos.

✓ Edición.

✓ Baja lógica.

✓ Listado completo.

✓ Estados calculados automáticamente.

✓ Filtros combinables.

✓ Búsqueda.

✓ Vista detalle.

✓ Integración con Employees.

✓ flutter analyze = 0 issues.

---

# RESULTADO ESPERADO

LOCUSTAF contará con un módulo completo para administrar la documentación médica del personal, con control automático de vencimientos y preparado para futuras notificaciones.

FIN DEL TASK.
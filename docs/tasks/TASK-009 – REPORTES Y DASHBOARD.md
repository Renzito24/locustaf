# TASK-009 – REPORTES Y DASHBOARD

## 🎯 OBJETIVO

Implementar el primer módulo de reportes de LOCUSTAF.

El objetivo es visualizar información útil del sistema utilizando los datos existentes de:

- Employees
- Attendance
- Workplaces

No se implementarán exportaciones (PDF/Excel) en esta tarea.

---

## CONTEXTO

Actualmente el sistema ya permite:

- administrar empleados
- administrar lugares de trabajo
- registrar asistencias
- controlar acceso mediante roles

Este task agrega la capa de análisis de información.

---

## DASHBOARD DE REPORTES

La pantalla Reports mostrará tarjetas (cards) con métricas generales.

---

### CARD 1

Total de empleados

Obtiene:

Cantidad total de empleados activos.

---

### CARD 2

Empleados presentes hoy

Cantidad de empleados con asistencia activa o completada en la fecha actual.

---

### CARD 3

Empleados ausentes hoy

Total empleados activos
menos
empleados presentes.

---

### CARD 4

Workplaces activos

Cantidad de lugares de trabajo activos.

---

## REPORTE DE ASISTENCIA

Mostrar una tabla simple con:

- empleado
- workplace
- hora ingreso
- hora egreso
- duración

Orden descendente por fecha.

---

## FILTROS

Agregar:

- fecha
- workplace

Los filtros deben convivir correctamente.

---

## PROVIDERS

Crear providers específicos para reportes.

No reutilizar providers de UI de Employees.

Los cálculos deben vivir en providers.

La pantalla solo consume estado.

---

## REPOSITORY

Si es necesario, agregar métodos de consulta.

No duplicar lógica existente.

Reutilizar FirestoreService.

---

## UI

Mantener el estilo visual existente del Dashboard.

Usar Cards.

Usar tablas para reportes.

Mantener consistencia con Employees.

---

## RESTRICCIONES

- NO modificar Employees
- NO modificar Attendance
- NO modificar Auth
- NO modificar Roles
- NO crear backend
- Mantener Feature-First
- Mantener Clean Architecture

---

## CRITERIOS DE ACEPTACIÓN

- dashboard muestra métricas reales
- presentes calculados correctamente
- ausentes calculados correctamente
- workplaces activos calculados correctamente
- tabla de asistencia funcional
- filtros funcionan correctamente
- flutter analyze = 0 issues

---

## RESULTADO ESPERADO

LOCUSTAF contará con su primer módulo de inteligencia operativa mostrando información consolidada del sistema.
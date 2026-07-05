# TASK-013 – AUDITORÍA TÉCNICA Y FUNCIONAL DEL SISTEMA

## Objetivo

Realizar una revisión completa de LOCUSTAF para detectar problemas de arquitectura, código, rendimiento, UX o funcionalidades antes de continuar con nuevos módulos.

Este TASK NO debe agregar nuevas funcionalidades.

El objetivo es conocer el estado real del proyecto.

---

# Alcance

Revisar absolutamente todo el proyecto.

No implementar cambios salvo que sean indispensables para corregir errores críticos encontrados durante el análisis.

---

# Revisar

## Arquitectura

Verificar:

- Organización Feature-First
- Clean Architecture
- Separación Presentation / Domain / Data
- Dependencias entre capas
- Reutilización de componentes
- Código duplicado
- Clases demasiado grandes
- Widgets demasiado grandes
- Providers demasiado grandes
- Repositories demasiado grandes

---

## Routing

Verificar:

- rutas existentes
- rutas sin uso
- rutas duplicadas
- navegación
- guards
- permisos

---

## Riverpod

Revisar:

- providers duplicados
- providers innecesarios
- providers muy grandes
- fugas de estado
- listeners incorrectos

---

## Firestore

Revisar:

- consultas duplicadas
- streams innecesarios
- posibles problemas de rendimiento
- colecciones inconsistentes
- nombres de colecciones
- uso correcto de FirestoreService

---

## Firebase Authentication

Revisar:

- login
- logout
- rollback
- creación
- permisos

---

## UI

Revisar:

- Dashboard
- Sidebar
- Employees
- Attendance
- History
- Reports
- Medical Documents
- Incidences
- Workplaces

Buscar:

- botones sin implementar
- pantallas incompletas
- acciones sin callback
- mensajes inconsistentes
- errores visuales

---

## Responsive

Comprobar comportamiento en:

- Desktop
- Tablet
- Mobile

---

## Roles

Verificar:

Administrador

Supervisor

Empleado

Comprobar que cada uno solo vea lo permitido.

---

## Modelos

Verificar que todos tengan:

- Equatable
- copyWith()
- fromJson()
- toJson()
- props

---

## Repositories

Verificar consistencia entre todos los repositorios.

---

## Providers

Comprobar consistencia de nomenclatura y responsabilidades.

---

## Código

Buscar:

- TODO olvidados
- FIXME
- dead code
- imports sin usar
- archivos sin utilizar
- widgets nunca llamados

---

## flutter analyze

Debe finalizar con:

No issues found

---

# Resultado esperado

NO implementar nuevas funcionalidades.

Entregar un informe técnico con:

## Hallazgos

Para cada hallazgo indicar:

- Descripción
- Archivo
- Severidad

(Alta / Media / Baja)

- Recomendación

---

## Mejoras sugeridas

Separar entre:

- Críticas
- Recomendadas
- Opcionales

---

## Conclusión

Responder:

¿LOCUSTAF está listo para continuar con nuevas funcionalidades?

Justificar técnicamente la respuesta.

FIN DEL TASK.
# TASK-016 – DASHBOARD (HomeScreen funcional)

## Objetivo
Implementar el dashboard principal de LOCUSTAF reemplazando el HomeScreen actual (placeholder) por una pantalla funcional que muestre un resumen real del estado del sistema utilizando datos existentes.

## Alcance funcional
El dashboard debe mostrar KPIs reales del sistema:

- Empleados activos
- Presentes hoy
- Ausentes hoy
- Sucursales activas

## Fuente de datos
- Utilizar exclusivamente reports_provider.dart
- No crear nuevos providers
- No duplicar lógica existente

## Diseño UI

### Estructura general:
- Header superior con:
  - Título: “Dashboard”
  - Fecha actual
  - Subtítulo descriptivo del sistema

### Sección KPIs:
Mostrar Cards con:
- Icono representativo
- Título del KPI
- Valor principal destacado
- Color semántico según tipo de dato

### Paleta de colores:
- Verde → presentes
- Rojo → ausentes
- Azul → empleados activos
- Naranja → sucursales

## Reglas técnicas

### Prohibido:
- Crear nuevos providers
- Modificar Auth
- Modificar backend o Firestore rules
- Duplicar lógica de reports_provider
- Agregar funcionalidades fuera del alcance del dashboard

### Obligatorio:
- Reutilizar reports_provider.dart
- Manejar estados: loading, error, data
- Mantener consistencia visual con Profile
- UI responsive básica (mobile + desktop simple)
- Mantener arquitectura Feature-First

## UX esperada
El dashboard debe responder:
“¿Cómo está el sistema hoy?”

No debe mostrar datos aislados, sino un resumen global del estado de la aplicación.

## Estructura sugerida
HomeScreen
 ├── DashboardHeader
 ├── KpiGrid
 │     ├── KpiCard (reutilizable)
 │     ├── KpiCard
 └── (opcional) SummarySection

## Criterios de aceptación
- HomeScreen deja de ser placeholder
- KPIs se muestran correctamente
- Datos provienen de reports_provider
- Manejo de loading/error implementado
- UI consistente con Profile
- No se rompe arquitectura existente
- flutter analyze = 0 issues

## Resultado esperado
El sistema cuenta con un dashboard funcional que muestra el estado general de LOCUSTAF en tiempo real, reutilizando la lógica existente sin duplicaciones y manteniendo consistencia visual con el resto de la aplicación.
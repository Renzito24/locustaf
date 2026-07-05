# TASK-020 – Corrección del Layout del Dashboard (RenderFlex Overflow)

## Estado

🔄 Pendiente

---

## Objetivo

Corregir definitivamente el error visual:

```
BOTTOM OVERFLOWED BY 2.1 PIXELS
```

que aparece al ingresar al Dashboard luego del Login.

El objetivo es eliminar la causa del overflow, manteniendo el diseño actual, la arquitectura Feature-First y la reutilización de componentes ya implementados.

---

## Contexto

Durante el TASK-016 se implementó el Dashboard reutilizando completamente la lógica existente en `reports_provider`, evitando duplicación de código y manteniendo una arquitectura limpia.

El Dashboard muestra correctamente los siguientes indicadores:

- Empleados activos
- Presentes hoy
- Ausentes hoy
- Sucursales activas

La lógica funciona correctamente y no requiere modificaciones.

Sin embargo, al renderizar las KPI Cards, Flutter informa:

```
BOTTOM OVERFLOWED BY 2.1 PIXELS
```

Este problema es exclusivamente visual y no afecta la lógica de negocio.

---

## Alcance

Este TASK debe enfocarse únicamente en el layout del Dashboard.

Se permite modificar únicamente aquello que sea necesario para eliminar el overflow.

Puede incluir ajustes en:

- GridView
- childAspectRatio
- LayoutBuilder
- Column
- Row
- Padding
- SizedBox
- Expanded
- Flexible
- Constraints
- Altura de las KPI Cards

Siempre respetando el diseño original.

---

## Restricciones

No modificar:

- Providers
- Riverpod
- Firestore
- Repositories
- Models
- Servicios
- Navegación
- Router
- Roles
- Autenticación

No agregar lógica nueva.

No crear providers nuevos.

No modificar funcionalidades existentes.

No ocultar el overflow mediante hacks como:

- ClipRect
- OverflowBox
- IgnorePointer
- Widgets que simplemente oculten el problema

Debe corregirse la causa del layout.

---

## Archivos involucrados

Principalmente:

```
lib/features/dashboard/presentation/screens/home_screen.dart
```

Y cualquier widget interno relacionado con las KPI Cards si fuera necesario.

---

## Criterios de aceptación

Al finalizar este TASK deberá cumplirse lo siguiente:

- El Dashboard continúa funcionando correctamente.
- Las cuatro KPI Cards mantienen su apariencia.
- No aparece ningún RenderFlex Overflow.
- No aparecen nuevos warnings.
- `flutter analyze` continúa mostrando:

```
No issues found.
```

- El Dashboard continúa siendo responsive.

---

## Resultado esperado

Se espera una solución limpia, mantenible y consistente con la arquitectura del proyecto, eliminando completamente el problema de layout sin afectar el comportamiento funcional del Dashboard.
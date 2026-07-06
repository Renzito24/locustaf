IMPLEMENTAR COMPLETAMENTE EL TASK-022.

No analizar el TASK.

No resumir el TASK.

No explicar cómo lo implementarías.

Modificar directamente el código del proyecto hasta dejar completamente terminado el módulo "Gestión de Lugares de Trabajo".

No implementar únicamente una parte.

No dejar funcionalidades para un futuro TASK.

La prioridad absoluta es dejar este módulo completamente terminado, funcional y listo para producción.

====================================================
CONTEXTO
====================================================

LOCUSTAF utiliza:

- Flutter
- Riverpod
- Firebase Authentication
- Cloud Firestore
- Arquitectura Feature-First

Debe respetarse toda la arquitectura existente.

No duplicar código.

Reutilizar providers, repositorios, servicios y modelos existentes siempre que sea posible.

====================================================
OBJETIVO
====================================================

Completar al 100% el módulo "Lugares de Trabajo".

Al finalizar el administrador deberá poder gestionar completamente todos los lugares de trabajo desde la aplicación.

====================================================
PERMISOS
====================================================

Administrador

- Acceso total.

Supervisor

- Solo lectura.

Empleado

- Sin acceso.

====================================================
FUNCIONALIDADES
====================================================

Implementar completamente:

✓ Crear lugar de trabajo.

✓ Editar lugar de trabajo.

✓ Activar.

✓ Desactivar.

✓ Baja lógica (no eliminar físicamente).

✓ Listado completo.

✓ Búsqueda.

✓ Filtros.

✓ Responsive.

====================================================
DATOS DEL LUGAR DE TRABAJO
====================================================

Campos obligatorios:

- Nombre
- Dirección
- Descripción
- Latitud
- Longitud

No solicitar al usuario que escriba manualmente la latitud y longitud.

Las coordenadas deberán obtenerse automáticamente.

====================================================
SELECCIÓN DE UBICACIÓN
====================================================

Implementar un mapa interactivo utilizando OpenStreetMap.

Utilizar librerías open source compatibles con Flutter.

No utilizar Google Maps.

El administrador deberá poder establecer la ubicación mediante cualquiera de estas opciones:

1)

Buscar una dirección.

Al seleccionar el resultado:

- completar automáticamente la dirección.
- obtener latitud.
- obtener longitud.
- mover el marcador.

2)

Seleccionar directamente un punto sobre el mapa.

Al hacer clic:

- mover el marcador.
- actualizar automáticamente las coordenadas.

3)

Botón:

"Usar mi ubicación actual"

Solicitar permisos.

Obtener GPS.

Centrar el mapa.

Mover el marcador.

Actualizar automáticamente:

- dirección (si es posible)
- latitud
- longitud

====================================================
EDICIÓN
====================================================

Durante la edición deberá poder modificarse:

- nombre
- dirección
- descripción
- ubicación
- estado

El mapa deberá abrir mostrando el marcador en la ubicación guardada.

====================================================
ESTADOS
====================================================

Implementar:

Activo

Inactivo

No eliminar documentos de Firestore.

Implementar baja lógica.

====================================================
REGLAS DE NEGOCIO
====================================================

Un lugar de trabajo puede editarse aunque tenga empleados asignados.

Un lugar de trabajo puede desactivarse aunque tenga empleados asignados.

Nunca eliminar físicamente un lugar de trabajo.

====================================================
LISTADO
====================================================

Mostrar:

Nombre

Dirección

Descripción

Estado

Cantidad de empleados asignados (si la información ya existe o puede obtenerse sin romper la arquitectura).

====================================================
FILTROS
====================================================

Implementar:

Buscar por nombre.

Buscar por dirección.

Filtrar por:

- Activos
- Inactivos
- Todos

====================================================
INTERFAZ
====================================================

Mejorar visualmente el módulo.

Mantener el estilo general de LOCUSTAF.

Mejorar:

- espaciados
- botones
- formularios
- tarjetas
- estados vacíos
- mensajes
- responsive

No romper el diseño existente.

====================================================
RESTRICCIONES
====================================================

No modificar:

- Dashboard
- Usuarios
- Asistencias
- Reportes
- Perfil

excepto si es estrictamente necesario para integrar correctamente el módulo.

====================================================
CRITERIOS DE ACEPTACIÓN
====================================================

Al finalizar:

✓ Crear lugares de trabajo.

✓ Editarlos.

✓ Activarlos.

✓ Desactivarlos.

✓ Baja lógica.

✓ Buscar.

✓ Filtrar.

✓ Responsive.

✓ OpenStreetMap funcionando.

✓ Selección por mapa.

✓ Selección por búsqueda.

✓ Selección por GPS.

✓ Coordenadas automáticas.

✓ Flutter Analyze con 0 issues.

====================================================
ENTREGA
====================================================

Al finalizar informar:

1. Archivos modificados.

2. Librerías incorporadas.

3. Arquitectura utilizada.

4. Flujo implementado.

5. Resultado de flutter analyze.

6. Confirmar que el módulo "Lugares de Trabajo" quedó completamente terminado.
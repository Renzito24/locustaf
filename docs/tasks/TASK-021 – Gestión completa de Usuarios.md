TASK-021 – Gestión completa de Usuarios

Implementar completamente el módulo "Gestión de Usuarios".

No realizar únicamente un análisis.

Modificar el código del proyecto hasta dejar el módulo completamente funcional.

IMPORTANTE

Implementar la totalidad del módulo "Gestión de Usuarios".

No implementar solo una parte.

No dejar funcionalidades para futuros TASK.

El módulo deberá quedar completamente terminado, funcional y listo para ser utilizado por un administrador.

Antes de comenzar:

- Analizar la arquitectura completa del proyecto.
- Analizar la feature Employees.
- Identificar todos los servicios, providers, repositorios y modelos existentes.
- Reutilizar la infraestructura existente siempre que sea posible.

Durante la implementación:

- Resolver todos los problemas técnicos necesarios para completar el módulo.
- Si es necesario refactorizar código existente para obtener una solución correcta, hacerlo respetando la arquitectura del proyecto.
- No implementar soluciones temporales ni hacks.

Al finalizar, el módulo deberá quedar completamente funcional incluyendo:

✓ Alta de usuarios.
✓ Edición de usuarios.
✓ Activación y desactivación.
✓ Restablecimiento de contraseña.
✓ Búsqueda.
✓ Filtros.
✓ Validaciones.
✓ Integración completa con Firebase Authentication.
✓ Integración completa con Firestore.
✓ Interfaz de usuario completa y consistente.

No detener la implementación porque una funcionalidad requiera modificaciones adicionales. Resolverlas como parte del TASK.

Solo detenerse si existe una limitación técnica real que impida completar el módulo. En ese caso explicar exactamente cuál es la limitación, por qué ocurre y cuál sería la solución profesional.

Antes de finalizar:

- Ejecutar flutter analyze.
- Corregir cualquier error o warning introducido.
- Verificar que el flujo completo funcione correctamente.

La entrega debe corresponder a un módulo terminado, no a una implementación parcial.

Arquitectura

El proyecto utiliza:

- Flutter
- Riverpod
- Firebase Authentication
- Cloud Firestore
- Arquitectura Feature-First

Debe mantenerse la arquitectura existente.

No duplicar código.

Reutilizar servicios, providers y repositorios existentes siempre que sea posible.

Objetivo

Dejar completamente operativo el módulo de administración de usuarios.

El Administrador debe ser el único usuario autorizado para gestionar cuentas.

IMPORTANTE

La implementación NO debe utilizar FirebaseAuth.createUserWithEmailAndPassword() directamente desde la sesión del administrador, ya que eso provoca el cambio automático de sesión.

Implementar una solución profesional que permita al administrador crear usuarios sin perder su sesión.

Puede utilizar:

- Firebase Cloud Functions + Firebase Admin SDK (preferido)

o cualquier otra solución equivalente que mantenga la sesión del administrador.

No implementar soluciones temporales o hacks.

Funcionalidades requeridas

====================================================

021.1 Crear usuario

====================================================

Permitir crear:

- Supervisor
- Empleado

Campos mínimos:

- Nombre
- Apellido
- Email
- Contraseña
- Confirmar contraseña
- Rol
- Lugar de trabajo
- Teléfono (si el modelo ya lo contempla)

Validaciones:

- Email válido.
- Email único.
- Password mínima 6 caracteres.
- Confirmación correcta.
- Lugar de trabajo obligatorio.
- Rol obligatorio.

Crear correctamente:

- Firebase Authentication
- Firestore

Nunca guardar la contraseña en Firestore.

====================================================

021.2 Editar usuario

====================================================

Permitir modificar:

- Nombre
- Apellido
- Teléfono
- Lugar de trabajo
- Rol

No permitir editar el UID.

Actualizar Firestore correctamente.

====================================================

021.3 Activar / Desactivar usuario

====================================================

Implementar baja lógica.

No eliminar documentos.

Agregar un campo de estado.

Los usuarios desactivados:

- no deben poder iniciar sesión
  (si la arquitectura actual lo permite)

o al menos

- deben quedar claramente marcados como inactivos.

La lista debe permitir filtrar activos e inactivos.

====================================================

021.4 Restablecer contraseña

====================================================

Implementar la opción:

"Restablecer contraseña"

Utilizar el mecanismo oficial de Firebase.

No almacenar contraseñas.

====================================================

021.5 Búsqueda y filtros

====================================================

Agregar:

- búsqueda por nombre
- búsqueda por email
- filtro por rol
- filtro por lugar de trabajo
- filtro por estado

====================================================

021.6 Mejoras visuales

====================================================

Mejorar el módulo visualmente.

No modificar el diseño general del proyecto.

Mejorar:

- espaciados
- alineaciones
- botones
- formularios
- tablas
- estados vacíos
- mensajes de éxito
- mensajes de error

Mantener Material Design.

====================================================

Permisos

====================================================

Administrador

- acceso total

Supervisor

- solo lectura

Empleado

- sin acceso

====================================================

Restricciones

====================================================

NO modificar:

- Dashboard
- Asistencia
- Reportes
- Sidebar
- Login
- Seed

excepto que sea absolutamente necesario para implementar correctamente la creación segura de usuarios.

====================================================

Criterios de aceptación

====================================================

Al finalizar:

✓ El Administrador puede crear usuarios.

✓ Puede editar usuarios.

✓ Puede activar/desactivar usuarios.

✓ Puede restablecer contraseñas.

✓ Puede buscar y filtrar.

✓ No pierde su sesión al crear usuarios.

✓ Los usuarios aparecen correctamente en Firestore.

✓ Los usuarios aparecen correctamente en Firebase Authentication.

✓ flutter analyze devuelve 0 issues.

====================================================

Entrega esperada

====================================================

Al finalizar informar:

1. Archivos modificados.

2. Arquitectura utilizada.

3. Justificación técnica de la creación segura de usuarios.

4. Flujo completo implementado.

5. Resultado de flutter analyze.

6. Confirmación de que el módulo Gestión de Usuarios quedó completamente terminado.
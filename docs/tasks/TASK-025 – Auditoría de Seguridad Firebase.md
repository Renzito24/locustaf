# TASK-025 – Auditoría de Seguridad Firebase

## Objetivo

Realizar una auditoría completa de la seguridad del proyecto LOCUSTAF para verificar que las reglas de Firebase Firestore y Firebase Storage protejan correctamente la información del sistema.

---

## Alcance

### Firestore

Revisar todas las colecciones existentes.

Verificar:

- Permisos de lectura.
- Permisos de escritura.
- Permisos de actualización.
- Permisos de eliminación.
- Acceso únicamente para usuarios autenticados.
- Restricciones según el rol del usuario (Administrador / Empleado).

---

### Firebase Storage

Revisar las reglas de almacenamiento.

Verificar especialmente la carpeta de documentos médicos.

Comprobar:

- Permisos de carga de archivos.
- Permisos de descarga.
- Permisos de eliminación.
- Acceso únicamente al propietario del documento cuando corresponda.

---

### Seguridad de la aplicación

Revisar el código Flutter para detectar posibles problemas de autorización.

Validar que:

- No existan operaciones que dependan únicamente del cliente.
- Los permisos sean controlados por Firebase.
- No existan rutas o consultas que permitan acceder a información de otros usuarios.

---

### Pruebas

Verificar el comportamiento utilizando distintos perfiles:

- Usuario no autenticado.
- Empleado.
- Administrador.

Intentar:

- Leer información.
- Crear registros.
- Actualizar registros.
- Eliminar registros.

Documentar cualquier comportamiento incorrecto.

---

## Entregables

- Auditoría completa de Firestore Security Rules.
- Auditoría completa de Storage Rules.
- Riesgos encontrados.
- Correcciones implementadas (si fueran necesarias).
- Resumen técnico.
- Lista de archivos modificados.
- Resultado de `flutter analyze`.

---

## Criterios de aceptación

- No existen reglas inseguras.
- Los permisos respetan el modelo de roles del sistema.
- Los documentos médicos permanecen protegidos.
- Ningún usuario puede acceder a información que no le corresponda.
- El proyecto continúa compilando sin errores.
# LOCUSTAF AI DEVELOPMENT RULES

## Versión

1.0

## Proyecto

LOCUSTAF — Locus Staff

Sistema de gestión de personal y control de asistencia laboral para pequeñas y medianas empresas.

---

# 1. PROPÓSITO

Este documento establece las reglas generales que deben respetar todas las inteligencias artificiales, agentes, skills y herramientas automatizadas que participen en el desarrollo de LOCUSTAF.

Estas reglas tienen prioridad sobre cualquier decisión improvisada durante el desarrollo.

El objetivo es mantener:

- seguridad;
- estabilidad;
- arquitectura limpia;
- código mantenible;
- buenas prácticas;
- aislamiento de datos entre empresas;
- trazabilidad de cambios;
- pruebas automatizadas;
- cambios pequeños y controlados.

---

# 2. DOCUMENTO PRINCIPAL DEL PROYECTO

Antes de realizar cualquier modificación importante, la IA DEBE consultar:

LOCUSTAF_MASTER_SPEC.md

Este archivo define los requisitos funcionales y técnicos principales del sistema.

La IA NO debe contradecir los requisitos establecidos en dicho documento.

Si existe una contradicción entre una tarea y el MASTER SPEC:

1. detener la implementación;
2. informar la contradicción;
3. solicitar una decisión antes de modificar código.

---

# 3. REGLA FUNDAMENTAL: CAMBIOS CONTROLADOS

La IA NO debe modificar todo el proyecto para resolver una tarea pequeña.

Cada tarea debe tener un alcance claramente definido.

Ejemplo:

TASK: agregar tolerancia de llegada tarde.

La IA puede modificar únicamente los archivos necesarios para implementar esa funcionalidad.

No debe modificar simultáneamente:

- autenticación;
- navegación;
- usuarios;
- almacenamiento;
- reglas de Firestore;
- diseño global;

salvo que sea estrictamente necesario y lo justifique.

---

# 4. PROHIBIDO REALIZAR CAMBIOS SILENCIOSOS

La IA nunca debe:

- eliminar funcionalidades existentes sin autorización;
- eliminar archivos sin autorización;
- cambiar dependencias sin informar;
- cambiar arquitectura sin informar;
- modificar Firestore Rules silenciosamente;
- modificar Storage Rules silenciosamente;
- modificar autenticación silenciosamente;
- cambiar el modelo de datos sin informar;
- realizar migraciones destructivas sin autorización.

Todo cambio importante debe ser informado.

---

# 5. FLUJO OBLIGATORIO DE TRABAJO

Todas las tareas deben seguir este flujo:

PLAN
↓
IMPLEMENTACIÓN
↓
ANÁLISIS
↓
TESTS
↓
REVISIÓN DE SEGURIDAD
↓
REVISIÓN DE CÓDIGO
↓
APROBACIÓN HUMANA
↓
COMMIT

La IA no debe considerar una tarea terminada simplemente porque el código compila.

---

# 6. TRABAJO POR TAREAS

Cada modificación significativa debe identificarse mediante una tarea.

Ejemplo:

TASK-001 — Modelo multiempresa

TASK-002 — Grupos de trabajo

TASK-003 — Horarios

TASK-004 — Días laborables

TASK-005 — Feriados

TASK-006 — Tolerancia de llegada

TASK-007 — Cálculo de horas

TASK-008 — Dashboard de presencia

Las tareas deben ser pequeñas y comprobables.

---

# 7. NO TRABAJAR SOBRE MÚLTIPLES FUNCIONALIDADES A LA VEZ

Siempre que sea posible:

UNA TAREA
↓
UNA IMPLEMENTACIÓN
↓
UNA PRUEBA
↓
UNA REVISIÓN
↓
APROBACIÓN

No implementar múltiples módulos simultáneamente sin necesidad.

---

# 8. ARQUITECTURA

LOCUSTAF debe mantener una arquitectura organizada por funcionalidades.

Las funcionalidades deben mantenerse dentro de:

lib/features/

Cada feature debe separar sus responsabilidades.

Estructura recomendada:

presentation/
domain/
data/

No colocar lógica de negocio compleja directamente dentro de widgets.

---

# 9. RESPONSABILIDAD ÚNICA

Cada clase debe tener una responsabilidad clara.

Evitar:

- clases gigantes;
- widgets gigantes;
- repositories con lógica de UI;
- servicios con responsabilidades mezcladas;
- providers que hagan todo;
- acceso directo a Firebase desde widgets.

---

# 10. FIREBASE

Firebase es parte de la infraestructura de LOCUSTAF.

El acceso a:

- Firestore;
- Firebase Storage;
- Firebase Authentication;

debe mantenerse separado de la lógica de presentación.

Utilizar los servicios y repositories establecidos por la arquitectura.

No crear instancias duplicadas de servicios cuando ya exista un servicio centralizado.

---

# 11. FIRESTORE SERVICE

FirestoreService debe mantenerse centralizado.

Antes de crear otro servicio para Firestore:

1. revisar FirestoreService existente;
2. comprobar si la funcionalidad puede incorporarse correctamente;
3. evitar duplicación.

No crear múltiples implementaciones equivalentes sin justificación.

---

# 12. RIVERPOD

Riverpod es el mecanismo principal para:

- providers;
- dependencias;
- estado;
- comunicación entre capas.

No crear mecanismos alternativos de estado sin justificación.

---

# 13. MULTIEMPRESA

LOCUSTAF debe diseñarse como sistema multiempresa.

Cada empresa debe tener aislamiento lógico de datos.

Una empresa NO puede:

- leer empleados de otra empresa;
- leer asistencias de otra empresa;
- modificar grupos de otra empresa;
- acceder a documentos de otra empresa;
- acceder a información administrativa de otra empresa.

El aislamiento debe implementarse principalmente mediante reglas de seguridad de Firebase y validaciones apropiadas.

Nunca confiar únicamente en filtros de la interfaz.

---

# 14. SEGURIDAD

La seguridad es una prioridad.

Nunca asumir:

"Si el botón no aparece, el usuario no puede acceder."

La seguridad debe existir también en:

- Firestore Rules;
- Storage Rules;
- Authentication;
- validaciones;
- autorización;
- modelo de datos.

Las interfaces solamente representan las restricciones.

---

# 15. ROLES

LOCUSTAF contempla diferentes roles.

Como mínimo:

- Administrador;
- Empleado.

Podrán existir otros roles si el MASTER SPEC los establece.

Cada rol debe tener permisos explícitos.

No otorgar permisos administrativos por defecto.

---

# 16. EMPLEADOS

Un empleado solamente debe poder acceder a la información que le corresponde.

Debe poder:

- iniciar sesión;
- registrar entrada;
- registrar salida;
- consultar sus propios registros;
- consultar sus horas;
- descargar sus reportes.

No debe poder acceder a:

- empleados de otras empresas;
- información administrativa;
- configuraciones de la empresa;
- datos privados de otros empleados.

---

# 17. ASISTENCIA

El sistema debe considerar:

- entrada;
- salida;
- fecha;
- horas trabajadas;
- llegada tarde;
- tolerancia;
- salida anticipada;
- jornada completada;
- jornada pendiente;
- ausencia;
- días no laborables;
- feriados.

Las reglas exactas deben respetar el MASTER SPEC.

---

# 18. GEOLOCALIZACIÓN

La geolocalización se utiliza para validar la asistencia.

El empleado podrá registrar asistencia solamente cuando se encuentre dentro del radio configurado.

Debe contemplarse:

- latitud;
- longitud;
- radio;
- ubicación actual;
- distancia calculada;
- error de ubicación;
- ubicación no disponible.

Nunca confiar solamente en coordenadas enviadas por el cliente sin validación.

---

# 19. HORARIOS

Los horarios deben permitir determinar:

- hora esperada de entrada;
- hora esperada de salida;
- tolerancia;
- llegada tarde;
- salida anticipada;
- horas trabajadas.

La lógica debe estar centralizada y ser testeable.

No duplicar cálculos de horarios en múltiples pantallas.

---

# 20. DÍAS LABORABLES

El administrador debe poder establecer qué días son laborables.

Un día configurado como no laborable:

NO debe generar automáticamente una ausencia.

---

# 21. FERIADOS

Los feriados deben poder registrarse.

Un feriado no debe generar automáticamente una ausencia.

Los feriados deben formar parte de la lógica de cálculo de asistencia y reportes.

---

# 22. CÁLCULO DE HORAS

El sistema debe calcular las horas trabajadas.

Debe poder obtener:

- horas del día;
- minutos del día;
- total semanal cuando corresponda;
- total mensual;
- horas esperadas;
- diferencias cuando corresponda.

Los cálculos deben ser consistentes entre:

- dashboard;
- historial;
- reportes;
- exportaciones.

---

# 23. DASHBOARD

El administrador debe poder visualizar el estado actual de su empresa.

Entre otros estados:

- presentes;
- ausentes;
- llegadas tarde;
- turnos pendientes;
- registros en proceso;
- jornadas completadas.

La información debe representar el estado real de los registros.

---

# 24. EXPORTACIONES

Los reportes podrán exportarse a:

- Excel;
- PDF.

Los datos exportados deben utilizar la misma lógica de cálculo que la aplicación.

No implementar cálculos diferentes exclusivamente para exportaciones.

---

# 25. TESTING

Toda funcionalidad importante debe tener pruebas.

Como mínimo deben considerarse:

- casos normales;
- casos límite;
- errores;
- permisos;
- seguridad;
- datos inválidos.

Ejemplo:

Tolerancia = 15 minutos.

Entrada esperada = 08:00.

Entrada = 08:14.

Resultado:

NO llegada tarde.

Entrada = 08:15.

Resultado:

Debe respetar la regla definida por el MASTER SPEC.

Entrada = 08:16.

Resultado:

Llegada tarde.

Los límites deben estar explícitamente definidos y testeados.

---

# 26. FLUTTER ANALYZE

Después de modificaciones relevantes debe ejecutarse:

flutter analyze

No considerar una tarea correctamente terminada si existen errores nuevos introducidos por la modificación.

---

# 27. TESTS AUTOMATIZADOS

Cuando corresponda ejecutar:

flutter test

Los tests existentes no deben eliminarse simplemente porque fallen después de una modificación.

Primero investigar la causa.

---

# 28. REGRESIONES

Una modificación no debe romper funcionalidades existentes.

Antes de aprobar una tarea se debe comprobar:

- compilación;
- análisis;
- tests;
- funcionalidad modificada;
- funcionalidades relacionadas.

---

# 29. MANEJO DE ERRORES

No ocultar excepciones silenciosamente.

Los errores deben:

- manejarse;
- registrarse cuando corresponda;
- mostrar mensajes apropiados al usuario;
- evitar revelar información sensible.

No mostrar errores internos de Firebase directamente al usuario cuando puedan traducirse a un mensaje apropiado.

---

# 30. DATOS SENSIBLES

Nunca incluir en el código fuente:

- contraseñas;
- claves privadas;
- tokens;
- secretos;
- credenciales;
- API keys privadas.

Nunca subir secretos al repositorio.

---

# 31. DEPENDENCIAS

Antes de agregar una dependencia:

1. comprobar si ya existe una solución interna;
2. evaluar compatibilidad con Flutter;
3. evaluar compatibilidad con Web;
4. evaluar mantenimiento;
5. evaluar seguridad;
6. informar el motivo.

No agregar paquetes innecesarios.

---

# 32. CAMBIOS DE ARQUITECTURA

La IA no debe cambiar:

- patrón arquitectónico;
- estructura general;
- mecanismo de estado;
- autenticación;
- modelo multiempresa;

sin autorización.

---

# 33. BASE DE DATOS

Nunca realizar:

- borrados masivos;
- migraciones destructivas;
- cambios irreversibles;

sin autorización explícita.

Antes de una migración:

1. identificar datos afectados;
2. realizar respaldo cuando corresponda;
3. probar migración;
4. verificar resultado.

---

# 34. GIT

Cada tarea significativa debe poder identificarse mediante Git.

Se recomienda:

main
↓
feature/TASK-XXX-nombre

No realizar cambios experimentales directamente sobre main cuando exista riesgo.

Antes de realizar cambios importantes:

git status

Después:

git diff

Y antes de commit:

flutter analyze
flutter test

cuando corresponda.

---

# 35. APROBACIÓN HUMANA

La IA puede:

- analizar;
- proponer;
- implementar;
- ejecutar pruebas;
- revisar.

Pero la aprobación final de cambios importantes corresponde al desarrollador.

Especialmente:

- seguridad;
- Firestore Rules;
- Storage Rules;
- autenticación;
- modelo multiempresa;
- migraciones;
- eliminación de datos;
- cambios arquitectónicos.

---

# 36. LÍMITE DEL LOOP AUTOMÁTICO

Los agentes pueden intentar corregir errores automáticamente.

Pero deben tener un límite.

Si una tarea falla repetidamente:

1. detener el proceso;
2. informar el error;
3. indicar qué se intentó;
4. indicar qué archivos fueron modificados;
5. no continuar modificando arbitrariamente el proyecto.

Nunca ejecutar un loop infinito de modificaciones.

---

# 37. ARCHIVOS PROTEGIDOS

Los siguientes archivos requieren especial cuidado:

LOCUSTAF_MASTER_SPEC.md
firestore.rules
storage.rules
firebase_options.dart
pubspec.yaml
pubspec.lock

No modificarlos sin necesidad.

Los cambios en:

firestore.rules
storage.rules

requieren revisión de seguridad.

---

# 38. REGLA DE CONTEXTO

Antes de modificar una feature, la IA debe revisar:

1. MASTER SPEC;
2. archivos relacionados;
3. modelos;
4. repositories;
5. providers;
6. rutas;
7. reglas de seguridad relacionadas;
8. tests existentes.

No modificar basándose únicamente en un archivo aislado.

---

# 39. REGLA DE CAMBIOS MÍNIMOS

Preferir:

CAMBIO PEQUEÑO + TEST + REVISIÓN

sobre:

CAMBIO MASIVO + MUCHAS FUNCIONALIDADES.

La estabilidad tiene prioridad sobre la velocidad.

---

# 40. CUANDO EXISTAN DUDAS

Si la IA no puede determinar con seguridad:

- qué comportamiento se espera;
- qué permiso corresponde;
- qué dato debe guardarse;
- qué arquitectura utilizar;
- si un cambio rompe otra funcionalidad;

debe detenerse y preguntar.

No inventar requisitos.

---

# 41. PRINCIPIO FINAL

LOCUSTAF debe evolucionar de forma:

SEGURA
+
CONTROLADA
+
TESTEABLE
+
MANTENIBLE
+
ESCALABLE

La IA es una herramienta de desarrollo.

No reemplaza la decisión del desarrollador.

---

# FIN DE LOCUSTAF AI DEVELOPMENT RULES
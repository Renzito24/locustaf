\# LOCUSTAF SAFE DEVELOPMENT SKILL



\## Propósito



Esta skill define cómo una IA debe trabajar sobre LOCUSTAF de forma segura,

controlada, testeable y mantenible.



Debe utilizarse antes de realizar modificaciones de código.



\## Regla principal



La IA debe consultar siempre:



.ai/rules/LOCUSTAF\_AI\_RULES.md



y:



LOCUSTAF\_MASTER\_SPEC.md



Las reglas del proyecto tienen prioridad sobre decisiones improvisadas.



\---



\# 1. FLUJO OBLIGATORIO



Toda tarea debe seguir:



PLAN

↓

INSPECCIÓN

↓

IMPLEMENTACIÓN

↓

ANÁLISIS

↓

TESTS

↓

REVISIÓN DE SEGURIDAD

↓

REVISIÓN DE REGRESIONES

↓

INFORME

↓

APROBACIÓN HUMANA



La IA no debe considerar una tarea terminada solamente porque compila.



\---



\# 2. TRABAJO INCREMENTAL



Trabajar siempre sobre una funcionalidad pequeña.



Ejemplo:



TASK-XXX

↓

analizar archivos relacionados

↓

modificar lo mínimo necesario

↓

flutter analyze

↓

flutter test

↓

revisar cambios

↓

informar resultado



No modificar múltiples funcionalidades sin necesidad.



\---



\# 3. INSPECCIÓN ANTES DE MODIFICAR



Antes de modificar código la IA debe identificar:



\- feature afectada;

\- pantalla;

\- provider;

\- repository;

\- model;

\- services;

\- rutas relacionadas;

\- reglas Firebase relacionadas;

\- tests existentes.



No asumir cómo funciona una parte del sistema sin revisar su implementación actual.



\---



\# 4. CAMBIOS MÍNIMOS



Prioridad:



CAMBIO MÍNIMO

\+

PRUEBA

\+

REVISIÓN



Evitar refactorizaciones innecesarias durante una tarea funcional.



No modificar archivos no relacionados solamente para "mejorar" el proyecto.



\---



\# 5. ARQUITECTURA



Mantener:



lib/features/

&#x20;   presentation/

&#x20;   domain/

&#x20;   data/



Mantener separación de responsabilidades.



No colocar lógica compleja de negocio dentro de widgets.



No acceder directamente a Firebase desde la interfaz cuando exista

repository/service correspondiente.



Utilizar Riverpod para dependencias y estado.



\---



\# 6. FIREBASE



Antes de modificar Firebase:



revisar:



\- firestore.rules

\- storage.rules

\- repositories

\- services

\- modelos relacionados



Los cambios de seguridad requieren revisión explícita.



Nunca debilitar reglas para solucionar rápidamente un error de interfaz.



\---



\# 7. SEGURIDAD



Nunca confiar exclusivamente en:



\- botones ocultos;

\- rutas protegidas;

\- validaciones de UI;

\- filtros visuales.



La autorización debe existir también en backend/Firebase cuando corresponda.



Nunca introducir:



\- contraseñas;

\- tokens;

\- secretos;

\- credenciales;

\- claves privadas.



\---



\# 8. TESTING



Cuando una funcionalidad tenga lógica de negocio:



crear o actualizar tests apropiados.



Los tests deben considerar:



\- caso normal;

\- caso límite;

\- datos inválidos;

\- errores;

\- permisos;

\- regresiones.



Nunca eliminar tests para conseguir una ejecución exitosa.



\---



\# 9. VALIDACIÓN



Después de cambios relevantes ejecutar:



flutter analyze



y cuando corresponda:



flutter test



También revisar:



git diff



La IA debe identificar errores nuevos introducidos por su modificación.



\---



\# 10. LOOP CONTROLADO



La IA puede intentar corregir automáticamente errores.



Pero cada iteración debe ser controlada.



Máximo recomendado:



1\. implementar;

2\. analizar;

3\. corregir;

4\. volver a analizar;

5\. ejecutar tests;

6\. revisar.



Si el problema persiste después de varios intentos razonables:



DETENER.



Informar:



\- error;

\- causa probable;

\- archivos modificados;

\- pruebas ejecutadas;

\- resultado;

\- siguiente decisión necesaria.



Nunca ejecutar modificaciones indefinidamente.



\---



\# 11. ARCHIVOS PROTEGIDOS



Requieren especial cuidado:



LOCUSTAF\_MASTER\_SPEC.md

.ai/rules/LOCUSTAF\_AI\_RULES.md

firestore.rules

storage.rules

firebase\_options.dart

pubspec.yaml

pubspec.lock



No modificarlos sin necesidad.



\---



\# 12. APROBACIÓN HUMANA



La IA puede:



\- analizar;

\- proponer;

\- implementar;

\- ejecutar pruebas;

\- corregir errores;

\- revisar.



La aprobación final corresponde al desarrollador.



Requieren especial aprobación:



\- seguridad;

\- autenticación;

\- Firestore Rules;

\- Storage Rules;

\- modelo multiempresa;

\- migraciones;

\- eliminación de datos;

\- cambios arquitectónicos.



\---



\# 13. INFORME FINAL



Al terminar una tarea, informar:



TASK:

Qué se implementó.



ARCHIVOS MODIFICADOS:

Lista exacta.



ARCHIVOS CREADOS:

Lista exacta.



PRUEBAS:

Resultados de flutter analyze y flutter test.



SEGURIDAD:

Qué se revisó.



REGRESIONES:

Qué funcionalidades relacionadas fueron verificadas.



ESTADO:

LISTO PARA APROBACIÓN

o

REQUIERE REVISIÓN.



Nunca afirmar que una tarea está aprobada automáticamente.


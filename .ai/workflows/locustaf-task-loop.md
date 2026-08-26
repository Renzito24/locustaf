\# LOCUSTAF TASK LOOP WORKFLOW



\## Propósito



Este workflow define el proceso estándar para implementar tareas en LOCUSTAF.



Debe utilizarse para cambios funcionales o técnicos significativos.



El objetivo es realizar cambios pequeños, verificables y seguros.



\---



\# 1. DOCUMENTOS OBLIGATORIOS



Antes de comenzar, consultar:



.ai/rules/LOCUSTAF\_AI\_RULES.md



.ai/skills/locustaf-safe-development/SKILL.md



LOCUSTAF\_MASTER\_SPEC.md



También debe utilizarse:



.ai/agents/locustaf-reviewer.md



\---



\# 2. IDENTIFICACIÓN DE LA TAREA



Toda modificación significativa debe tener una identificación:



TASK-XXX



Ejemplo:



TASK-031 — Validación de horarios



La tarea debe tener un objetivo concreto.



\---



\# 3. INSPECCIÓN



Antes de modificar código:



1\. ejecutar git status;

2\. identificar archivos relacionados;

3\. revisar modelos;

4\. revisar repositories;

5\. revisar providers;

6\. revisar services;

7\. revisar pantallas;

8\. revisar rutas;

9\. revisar reglas Firebase relacionadas;

10\. revisar tests existentes.



No modificar código todavía.



\---



\# 4. PLAN



La IA debe explicar:



OBJETIVO



Qué se quiere conseguir.



ARCHIVOS A MODIFICAR



Lista de archivos previstos.



ARCHIVOS A CREAR



Lista de archivos previstos.



ARCHIVOS QUE NO SE DEBEN MODIFICAR



Archivos protegidos o fuera de alcance.



TESTS



Qué pruebas serán necesarias.



RIESGOS



Posibles efectos secundarios.



\---



\# 5. APROBACIÓN DEL PLAN



Antes de realizar cambios importantes:



esperar aprobación humana.



No implementar cambios arquitectónicos,

migraciones, cambios de seguridad o cambios

de modelo de datos sin autorización.



\---



\# 6. IMPLEMENTACIÓN



Realizar únicamente los cambios necesarios.



No modificar funcionalidades no relacionadas.



No realizar refactorizaciones masivas.



No cambiar dependencias sin informar.



No modificar Firebase Rules silenciosamente.



\---



\# 7. ANÁLISIS



Después de implementar:



ejecutar:



flutter analyze



Si aparecen errores:



1\. identificar causa;

2\. corregir únicamente lo necesario;

3\. volver a ejecutar flutter analyze.



\---



\# 8. TESTS



Ejecutar:



flutter test



cuando corresponda.



Si existen errores:



1\. identificar causa;

2\. corregir;

3\. ejecutar nuevamente.



Nunca eliminar tests para conseguir un resultado exitoso.



\---



\# 9. LÍMITE DEL LOOP



La IA puede realizar como máximo:



3 ciclos automáticos de corrección.



CICLO:



IMPLEMENTAR

↓

ANALIZAR

↓

TEST

↓

CORREGIR



Si después de 3 ciclos continúan los errores:



DETENER.



Informar:



\- error;

\- causa probable;

\- archivos modificados;

\- intentos realizados;

\- resultados;

\- decisión necesaria.



Nunca continuar indefinidamente.



\---



\# 10. REVISIÓN DEL AGENT



Después de que los tests sean satisfactorios:



ejecutar la revisión conceptual mediante:



.ai/agents/locustaf-reviewer.md



El reviewer debe comprobar:



\- alcance;

\- arquitectura;

\- seguridad;

\- Firebase;

\- permisos;

\- tests;

\- regresiones;

\- cambios innecesarios.



\---



\# 11. SEGURIDAD



Si la tarea modifica:



firestore.rules



storage.rules



authentication



autorización



modelo multiempresa



o datos sensibles:



la tarea requiere revisión humana explícita.



No aprobar automáticamente.



\---



\# 12. REVISIÓN DE GIT



Ejecutar:



git status



y:



git diff



Comprobar:



\- archivos modificados;

\- archivos creados;

\- archivos eliminados;

\- cambios inesperados.



\---



\# 13. RESULTADO



El workflow debe terminar en uno de estos estados:



READY\_FOR\_HUMAN\_APPROVAL



REQUIRES\_CORRECTION



BLOCKED



\---



\# 14. APROBACIÓN HUMANA



La IA NO debe realizar commit automáticamente.



Debe esperar la aprobación del desarrollador.



Cuando el desarrollador apruebe:



se puede preparar el commit correspondiente.



\---



\# 15. INFORME FINAL



El informe debe incluir:



TASK:



OBJETIVO:



CAMBIOS REALIZADOS:



ARCHIVOS CREADOS:



ARCHIVOS MODIFICADOS:



TESTS:



FLUTTER ANALYZE:



SEGURIDAD:



REVISIÓN DEL AGENT:



REGRESIONES:



ESTADO:



\---



\# 16. PRINCIPIO



Una tarea pequeña debe producir:



CAMBIO PEQUEÑO

\+

TEST

\+

REVISIÓN

\+

APROBACIÓN



Nunca:



CAMBIO MASIVO

\+

MUCHAS FUNCIONALIDADES

\+

SIN TESTS

\+

SIN REVISIÓN



\---



\# FIN DEL WORKFLOW


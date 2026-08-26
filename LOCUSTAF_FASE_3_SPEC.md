# LOCUSTAF — FASE 3 SPECIFICATION

## Fase 3 — Multiempresa y evolución SaaS

Estado: Propuesta
Prerequisito: Fase 2 completada y aprobada

---

# 1. OBJETIVO

Transformar LOCUSTAF, construido y estabilizado inicialmente para una empresa, en una plataforma capaz de administrar múltiples empresas independientes.

Cada empresa deberá operar como un espacio aislado, con sus propios:

- Administradores
- Supervisores
- Empleados
- Grupos de trabajo
- Jornadas
- Asistencias
- Justificativos
- Incidencias
- Reportes
- Configuraciones

Ningún usuario podrá acceder a información perteneciente a otra empresa.

---

# 2. OBJETIVO TÉCNICO

Incorporar multi-tenancy mediante `companyId`.

La arquitectura deberá permitir:

Usuario
↓
Empresa
↓
Recursos de la empresa

Ejemplo:

Usuario → companyId
Empleado → companyId
Workplace → companyId
Attendance → companyId
Incidence → companyId
MedicalDocument → companyId

Todas las consultas y reglas de seguridad deberán respetar esta relación.

---

# 3. ALCANCE

## 3.1 Empresa

Crear entidad `CompanyModel`.

Datos:

- id
- nombreComercial
- razonSocial
- cuit
- direccion
- telefono
- email
- estado
- createdAt
- updatedAt

Estados:

- activa
- inactiva

---

## 3.2 Usuarios

Agregar `companyId` a `UserModel`.

Cada usuario deberá pertenecer a una empresa.

El sistema deberá impedir:

- cambiar de empresa arbitrariamente;
- modificar `companyId` desde el cliente;
- acceder a usuarios de otra empresa.

---

## 3.3 Recursos

Agregar `companyId` progresivamente a:

- users
- workplaces
- attendances
- incidences
- medical_documents
- reports
- configuraciones futuras

Todas las consultas deberán utilizar filtros de empresa.

---

# 4. ROLES MULTIEMPRESA

## Administrador

Puede administrar únicamente su empresa.

Puede:

- administrar empleados;
- administrar supervisores;
- administrar lugares;
- configurar jornadas;
- consultar asistencia;
- revisar justificativos;
- consultar incidencias;
- generar reportes;
- administrar configuración de empresa.

No puede acceder a otra empresa.

---

## Supervisor

Pertenece a una empresa.

Puede acceder únicamente a información autorizada de su empresa.

No puede:

- crear empresas;
- modificar roles críticos;
- modificar `companyId`;
- acceder a otra empresa.

---

## Empleado

Pertenece a una empresa.

Solo puede consultar y modificar la información propia permitida.

Nunca puede consultar información global de otras empresas.

---

# 5. AISLAMIENTO DE DATOS

Las Firestore Security Rules deberán comprobar:

- usuario autenticado;
- empresa del usuario;
- `companyId` del documento;
- rol;
- ownership cuando corresponda.

Las Rules serán la barrera definitiva de seguridad.

El frontend nunca será considerado mecanismo de seguridad.

Las consultas deberán estar diseñadas para cumplir las mismas restricciones que las Rules, ya que Firestore no utiliza las Rules como filtros de resultados. :contentReference[oaicite:1]{index=1}

---

# 6. FIRESTORE RULES

Revisar y adaptar todas las Rules existentes.

Objetivo:

Usuario A
→ Empresa A
→ acceso permitido

Usuario A
→ Empresa B
→ acceso denegado

Usuario B
→ Empresa B
→ acceso permitido

Se deberán impedir modificaciones no autorizadas de:

- companyId
- userId
- role
- estado administrativo
- ownership

Las Rules deberán validar cambios de campos sensibles cuando corresponda. Firebase permite aplicar controles específicos a campos individuales. :contentReference[oaicite:2]{index=2}

---

# 7. STORAGE

La estructura de Storage deberá incorporar empresa.

Ejemplo:

companies/{companyId}/medical_documents/{userId}/{fileName}

Las Rules deberán validar:

- autenticación;
- companyId;
- userId;
- rol;
- ownership.

Un usuario de Empresa A nunca podrá acceder a documentos de Empresa B.

---

# 8. CREACIÓN DE EMPRESAS

Crear flujo administrativo para:

- crear empresa;
- activar empresa;
- desactivar empresa;
- editar información.

Al crear una empresa deberá poder crearse su administrador inicial.

---

# 9. INVITACIÓN / ALTA DE USUARIOS

Diseñar mecanismo para incorporar usuarios a una empresa.

Opciones:

- creación administrativa;
- invitación por email;
- generación de usuario inicial.

El usuario deberá quedar asociado a una única empresa al momento de su alta.

No se permitirá seleccionar arbitrariamente otra empresa desde el frontend.

---

# 10. CONTEXTO DE EMPRESA

Implementar un `CompanyProvider` o equivalente.

Debe proporcionar:

- empresa actual;
- companyId;
- estado;
- permisos relacionados.

Toda feature que necesite información empresarial deberá consumir este contexto.

---

# 11. REPOSITORIOS

Todos los repositories deberán recibir o resolver el contexto empresarial.

Ejemplo conceptual:

AttendanceRepository
→ companyId
→ consulta únicamente asistencias de esa empresa.

No deberán existir nuevos repositories que consulten colecciones globales sin filtro empresarial.

---

# 12. DASHBOARD

El Dashboard deberá convertirse en completamente multiempresa.

Administrador:

- KPIs de su empresa.

Supervisor:

- KPIs de su ámbito autorizado.

Empleado:

- información personal.

Nunca deberá existir un KPI global de todas las empresas para un usuario normal.

---

# 13. REPORTES

Todos los reportes deberán filtrarse por:

- companyId;
- usuario cuando corresponda;
- período;
- lugar;
- estado.

La exportación deberá respetar exactamente los mismos permisos de la pantalla.

---

# 14. JUSTIFICATIVOS

Los justificativos deberán incorporar companyId.

Flujo:

Empleado Empresa A
↓
Justificativo Empresa A
↓
Administrador Empresa A
↓
Aprobación/Rechazo

Nunca deberá existir posibilidad de revisión cruzada entre empresas.

---

# 15. ASISTENCIA

Las asistencias deberán incorporar companyId.

El check-in deberá validar:

1. usuario;
2. empresa;
3. lugar;
4. pertenencia del lugar a la empresa;
5. geolocalización;
6. reglas laborales.

Un empleado no podrá registrar asistencia en un lugar perteneciente a otra empresa.

---

# 16. LUGARES DE TRABAJO

Cada lugar deberá pertenecer a una empresa.

No podrá:

- utilizarse desde otra empresa;
- editarse desde otra empresa;
- eliminarse desde otra empresa.

---

# 17. CONFIGURACIONES LABORALES

Incorporar configuraciones por empresa:

- tolerancias;
- días laborables;
- horarios;
- reglas de asistencia;
- feriados;
- parámetros de reportes.

Las configuraciones deberán poder evolucionar posteriormente hacia turnos avanzados.

---

# 18. TURNOS AVANZADOS

Preparar arquitectura para:

- turnos;
- horarios variables;
- turnos rotativos;
- múltiples jornadas;
- horas extra;
- tolerancias específicas.

No necesariamente implementar toda esta funcionalidad en la primera iteración de Fase 3.

---

# 19. AUSENCIAS

Completar sistema de ausencias utilizando:

- jornadas;
- días laborables;
- justificativos aprobados;
- feriados;
- configuración empresarial.

Las ausencias deberán pertenecer a una empresa.

---

# 20. PLANIFICACIÓN FUTURA SaaS

Preparar la arquitectura para:

- planes;
- límites por empresa;
- cantidad de empleados;
- almacenamiento;
- funcionalidades premium;
- suscripciones.

No implementar facturación si no forma parte del alcance aprobado.

---

# 21. OBSERVABILIDAD

Preparar mecanismos para identificar:

- empresa;
- usuario;
- operación;
- errores;
- eventos importantes.

Los logs nunca deberán exponer información sensible innecesaria.

---

# 22. TESTING

Crear pruebas específicas de aislamiento.

Casos mínimos:

- Empresa A no puede leer Empresa B.
- Empresa A no puede modificar Empresa B.
- Empleado A no puede acceder a empleado B.
- Supervisor A no puede acceder a Empresa B.
- Admin A no puede acceder a Empresa B.
- Storage A no puede acceder a archivos B.
- Asistencia A no puede utilizar workplace B.
- Justificativo A no puede ser aprobado desde Empresa B.

También deberán mantenerse todos los tests de Fase 2.

---

# 23. MIGRACIÓN

Si existen datos creados durante Fase 2:

1. realizar backup;
2. asignar empresa inicial;
3. incorporar companyId;
4. validar integridad;
5. actualizar Rules;
6. ejecutar pruebas;
7. verificar funcionamiento;
8. recién después habilitar multiempresa.

La migración deberá ser no destructiva.

---

# 24. SEGURIDAD

La seguridad deberá implementarse mediante:

- Firebase Authentication;
- Firestore Security Rules;
- Storage Security Rules;
- ownership;
- companyId;
- roles.

Nunca confiar únicamente en:

- Flutter;
- GoRouter;
- providers;
- ocultar botones;
- filtros visuales.

Firebase establece que las Security Rules son una capa independiente de seguridad y deben proteger directamente los datos. :contentReference[oaicite:3]{index=3}

---

# 25. RESPONSIVE

Mantener el Design System consolidado durante Fase 2.

No realizar un nuevo rediseño.

Validar:

- 360px
- 768px
- 1024px
- 1200px+
- desktop amplio

---

# 26. PERFORMANCE

Mantener:

- consultas filtradas;
- paginación;
- índices;
- providers eficientes;
- ausencia de streams globales.

Agregar:

- índices necesarios para consultas por companyId;
- paginación empresarial;
- cache cuando resulte conveniente.

---

# 27. CRITERIOS DE ACEPTACIÓN

Fase 3 será aceptada cuando:

- existan múltiples empresas funcionales;
- cada usuario pertenezca correctamente a una empresa;
- no existan accesos cruzados;
- Firestore Rules estén verificadas;
- Storage Rules estén verificadas;
- asistencia respete empresa;
- justificativos respeten empresa;
- reportes respeten empresa;
- dashboard respete empresa;
- tests de aislamiento estén en verde;
- no existan consultas globales indebidas;
- `flutter analyze` = 0 issues;
- `flutter test` = verde;
- migración de datos validada;
- documentación actualizada.

---

# 28. ORDEN DE IMPLEMENTACIÓN

E1 — Modelo Company

E2 — Migración de UserModel

E3 — companyId en modelos

E4 — Repositories y queries

E5 — Firestore Rules

E6 — Storage Rules

E7 — Contexto empresarial

E8 — Administración de empresas

E9 — Alta/invitación de usuarios

E10 — Asistencia multiempresa

E11 — Justificativos multiempresa

E12 — Historial y reportes

E13 — Dashboard

E14 — Configuración laboral

E15 — Ausencias y turnos

E16 — Testing de aislamiento

E17 — Migración/validación final

E18 — Auditoría de seguridad

E19 — Optimización

E20 — Documentación

---

# 29. DEFINITION OF DONE

Una tarea de Fase 3 estará terminada cuando:

- código implementado;
- arquitectura respetada;
- companyId correctamente aplicado;
- Rules revisadas;
- Storage revisado;
- tests correspondientes creados;
- sin regresiones de Fase 2;
- responsive validado;
- documentación actualizada;
- `flutter analyze` sin issues;
- tests en verde.

---

# 30. RESULTADO FINAL

Al finalizar Fase 3 LOCUSTAF deberá funcionar como:

Empresa A
├── Administradores
├── Supervisores
├── Empleados
├── Lugares
├── Asistencias
├── Justificativos
└── Reportes

Empresa B
├── Administradores
├── Supervisores
├── Empleados
├── Lugares
├── Asistencias
├── Justificativos
└── Reportes

Empresa C
├── ...

Cada empresa funcionará como un entorno independiente dentro de la misma plataforma.

La implementación deberá mantener la arquitectura preparada para una futura evolución hacia un producto SaaS.
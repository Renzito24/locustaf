# LOCUSTAF — Objetivo y Roadmap de Producto

## Objetivo general

Convertir LOCUSTAF, inicialmente desarrollado como proyecto académico, en un producto tecnológico real orientado al control de asistencia de pequeñas y medianas empresas.

El objetivo final es disponer de una plataforma SaaS profesional, segura, escalable y preparada para múltiples empresas, disponible inicialmente mediante Web y Android, con un modelo de negocio basado principalmente en suscripciones y, de forma complementaria, publicidad para usuarios del plan gratuito.

---

## Visión

LOCUSTAF busca simplificar la gestión de asistencia de empleados mediante:

* Registro de entrada y salida.
* Validación de ubicación mediante GPS.
* Geofencing.
* Historial de asistencia.
* Gestión de empleados.
* Supervisores y administradores.
* Justificaciones e incidencias.
* Documentación.
* Reportes.
* Exportación de información.
* Administración de lugares de trabajo.
* Arquitectura preparada para múltiples empresas.

La visión a largo plazo es que una empresa pueda registrarse, crear su organización, incorporar empleados y comenzar a controlar su asistencia sin necesidad de instalar infraestructura propia.

---

# Roadmap

## Fase 0 — Estabilización

Objetivo:

Dejar la versión Web actual completamente estable y auditada.

Criterios:

* Código sin errores de análisis.
* Tests funcionando.
* Firebase correctamente configurado.
* Firestore Rules auditadas.
* Storage Rules auditadas.
* Cloud Functions verificadas.
* Autenticación validada.
* Roles correctamente implementados.
* Git limpio.
* Deploy de producción controlado.

---

## Fase 1 — Android

Objetivo:

Adaptar LOCUSTAF para funcionar como aplicación Android.

Tareas:

* Configurar proyecto Android.
* Configurar Application ID.
* Configurar Firebase Android.
* Configurar Google Sign-In.
* Revisar permisos.
* Revisar GPS.
* Configurar icono.
* Configurar nombre de aplicación.
* Configurar versión.
* Revisar comportamiento responsive.
* Revisar funcionalidades específicas de Android.

Resultado esperado:

LOCUSTAF funcionando correctamente en un dispositivo Android real.

---

## Fase 2 — APK

Objetivo:

Generar una versión instalable de LOCUSTAF sin utilizar Google Play Store.

Tareas:

* Configurar firma de aplicación.
* Configurar release build.
* Generar APK.
* Instalar APK manualmente.
* Probar actualización de versiones.
* Documentar procedimiento de distribución.

Resultado esperado:

Un archivo APK oficial de LOCUSTAF que pueda instalarse manualmente en dispositivos Android.

---

## Fase 3 — QA Android

Objetivo:

Garantizar que la aplicación funcione correctamente en teléfonos reales.

Se probarán:

* Login.
* Google Login.
* Recuperación de contraseña.
* Sesiones.
* Roles.
* GPS.
* Permisos.
* Geofence.
* Check-in.
* Check-out.
* Historial.
* Incidencias.
* Justificaciones.
* Documentos.
* Reportes.
* Conectividad.
* Errores.
* Seguridad.

Resultado esperado:

Versión Android estable para pruebas con usuarios reales.

---

## Fase 4 — Beta privada

Objetivo:

Obtener usuarios reales sin realizar todavía una comercialización masiva.

Proceso:

Usuarios beta
→ utilizan LOCUSTAF
→ reportan problemas
→ se analizan métricas
→ se corrigen problemas
→ se publica nueva versión.

Resultado esperado:

Producto validado técnicamente y con feedback real.

---

## Fase 5 — Profesionalización del producto

Objetivo:

Pasar de una aplicación funcional a un producto profesional.

Se trabajará en:

* UX.
* UI.
* navegación.
* onboarding.
* mensajes de error.
* accesibilidad.
* responsive.
* identidad visual.
* documentación.
* soporte.
* experiencia del administrador.
* experiencia del supervisor.
* experiencia del empleado.

Resultado esperado:

LOCUSTAF debe poder ser utilizado por una empresa real sin depender constantemente del desarrollador.

---

## Fase 6 — Arquitectura Multiempresa

Objetivo:

Preparar LOCUSTAF para funcionar como SaaS.

Conceptualmente:

Empresa A
→ usuarios
→ empleados
→ lugares
→ asistencias

Empresa B
→ usuarios
→ empleados
→ lugares
→ asistencias

Cada recurso deberá estar correctamente asociado a una empresa mediante companyId.

Resultado esperado:

La arquitectura permitirá alojar múltiples empresas dentro del mismo sistema.

---

## Fase 7 — Seguridad Multiempresa

Objetivo:

Garantizar aislamiento total entre empresas.

Se deberán revisar:

* Firestore Rules.
* Storage Rules.
* Cloud Functions.
* Consultas.
* Servicios.
* Autorización.
* Roles.
* companyId.
* Validaciones del lado servidor.

Regla fundamental:

Un usuario perteneciente a una empresa nunca debe poder acceder, modificar o eliminar información perteneciente a otra empresa.

Resultado esperado:

Arquitectura SaaS segura y preparada para múltiples organizaciones.

---

## Fase 8 — Modelo FREE

Objetivo:

Permitir que una empresa pueda probar LOCUSTAF sin pagar.

Posibles características:

* Una empresa.
* Cantidad limitada de empleados.
* Control de asistencia.
* GPS.
* Historial básico.
* Funciones principales.

Podrá incluir publicidad moderada.

Resultado esperado:

Una puerta de entrada gratuita para captar usuarios.

---

## Fase 9 — Modelo PRO

Objetivo:

Crear una versión de pago destinada a pequeñas empresas.

Posibles características:

* Mayor cantidad de empleados.
* Reportes avanzados.
* Exportaciones.
* Mayor cantidad de lugares.
* Funciones avanzadas.
* Sin publicidad.
* Mayor capacidad de almacenamiento.
* Funciones administrativas adicionales.

Resultado esperado:

Primera fuente de ingresos recurrentes.

---

## Fase 10 — Modelo BUSINESS

Objetivo:

Atender empresas con necesidades mayores.

Posibles características:

* Mayor cantidad de empleados.
* Múltiples lugares.
* Múltiples supervisores.
* Reportes avanzados.
* Administración avanzada.
* Mayor capacidad.
* Soporte prioritario.
* Funcionalidades empresariales.

Resultado esperado:

Plan de mayor valor económico.

---

## Fase 11 — Publicidad

Objetivo:

Monetizar usuarios gratuitos sin perjudicar la experiencia.

Se evaluará integración con Google AdMob.

La publicidad deberá:

* Ser moderada.
* No interferir con el registro de asistencia.
* No bloquear funciones importantes.
* No perjudicar la experiencia.
* Desaparecer en planes pagos.

Resultado esperado:

Fuente secundaria de ingresos para usuarios FREE.

---

## Fase 12 — Suscripciones

Objetivo:

Permitir que empresas paguen por utilizar funcionalidades premium.

Modelo conceptual:

FREE
→ $0

PRO
→ suscripción mensual

BUSINESS
→ suscripción mensual

Los precios serán definidos posteriormente mediante análisis de costos, competencia, mercado y disposición real de los usuarios a pagar.

Resultado esperado:

Modelo de ingresos recurrentes.

---

## Fase 13 — Primeros clientes

Objetivo:

Conseguir las primeras empresas que utilicen LOCUSTAF de manera real.

Prioridad:

No buscar miles de usuarios inicialmente.

Buscar primero entre 3 y 5 empresas reales.

Objetivos:

* Obtener feedback.
* Detectar necesidades.
* Identificar funcionalidades importantes.
* Conocer objeciones.
* Validar precios.
* Detectar problemas operativos.
* Confirmar disposición a pagar.

Resultado esperado:

Primeros clientes reales y validación comercial.

---

## Fase 14 — Métricas

Objetivo:

Medir el comportamiento real del producto.

Métricas principales:

* Empresas registradas.
* Empresas activas.
* Usuarios activos.
* Empleados por empresa.
* Asistencias registradas.
* Retención.
* Conversión FREE → PRO.
* Conversión FREE → BUSINESS.
* Cancelaciones.
* Ingresos.
* Costos de infraestructura.
* Uso de almacenamiento.
* Uso de Firestore.
* Uso de Functions.

Resultado esperado:

Tomar decisiones basadas en datos y no solamente en intuición.

---

## Fase 15 — Google Play Store

Objetivo:

Publicar oficialmente LOCUSTAF en Google Play.

Se deberá preparar:

* Cuenta de desarrollador.
* AAB.
* Firma.
* Ficha de aplicación.
* Capturas.
* Descripción.
* Política de privacidad.
* Términos.
* Información de soporte.
* Clasificación.
* Declaraciones correspondientes.
* Sistema de actualizaciones.

Resultado esperado:

LOCUSTAF disponible oficialmente en Google Play.

---

## Fase 16 — Escalamiento

Objetivo:

Convertir LOCUSTAF en un producto comercial sostenible.

Posibles líneas futuras:

* Más países.
* Más monedas.
* Internacionalización.
* Más funcionalidades.
* Integraciones.
* API.
* Notificaciones.
* Turnos.
* Horas extras.
* Vacaciones.
* Estadísticas avanzadas.
* Automatizaciones.
* Funcionalidades premium.
* Nuevos planes empresariales.

---

# Modelo de negocio objetivo

El modelo principal será:

Suscripciones SaaS
+
Publicidad en usuarios FREE
+
Funcionalidades premium
+
Servicios empresariales opcionales.

La publicidad será considerada una fuente secundaria.

El objetivo principal será conseguir ingresos recurrentes mediante empresas que paguen por utilizar LOCUSTAF.

---

# Principio de desarrollo

LOCUSTAF no incorporará funcionalidades únicamente por agregar características.

Cada funcionalidad deberá justificar:

1. Qué problema resuelve.
2. Qué usuario la necesita.
3. Qué valor aporta.
4. Qué impacto tiene en seguridad.
5. Qué impacto tiene en arquitectura.
6. Qué impacto tiene en costos.
7. Qué pruebas necesita.
8. Si corresponde al plan FREE, PRO o BUSINESS.

Cada fase deberá completarse mediante:

Planificación
→ Implementación
→ Tests
→ Auditoría
→ flutter analyze
→ flutter test
→ Git commit
→ Deploy controlado
→ Validación.

---

# Objetivo final

Convertir LOCUSTAF desde un proyecto académico en un producto SaaS real, profesional y sostenible económicamente.

La prioridad será:

1. Calidad.
2. Seguridad.
3. Estabilidad.
4. Experiencia de usuario.
5. Validación real.
6. Modelo de negocio.
7. Monetización.
8. Escalamiento.

Nunca se priorizará la monetización por encima de la seguridad, estabilidad o confianza de los usuarios.

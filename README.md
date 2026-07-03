# LOCUSTAF

Sistema Web de Control de Asistencia Laboral desarrollado con Flutter y Firebase.

## Descripción

LOCUSTAF (Locus Staff) es una aplicación web orientada a la administración del personal de una organización.

El sistema permite gestionar empleados, lugares de trabajo, asistencia, historial de movimientos, justificativos, reportes y perfiles de usuario desde una única plataforma.

El proyecto fue desarrollado desde cero utilizando una arquitectura limpia y escalable para facilitar su mantenimiento y evolución.

---

# Estado del proyecto

**Versión:** En desarrollo

Actualmente se encuentran implementados:

* Arquitectura base del proyecto
* Integración con Firebase
* Autenticación mediante Firebase Authentication
* Login funcional
* Logout funcional
* Protección de rutas (Auth Guard)
* Dashboard administrativo inicial
* Riverpod para gestión de estado
* GoRouter para navegación

---

# Tecnologías utilizadas

## Frontend

* Flutter Web
* Material Design 3

## Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

## Arquitectura

* Clean Architecture
* Feature First
* Repository Pattern

## Gestión de estado

* Flutter Riverpod

## Navegación

* GoRouter

---

# Estructura del proyecto

```text
lib/
│
├── app/
├── core/
│   ├── constants/
│   ├── router/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── authentication/
│   ├── dashboard/
│   ├── employees/
│   ├── attendance/
│   ├── workplaces/
│   ├── history/
│   ├── medical_documents/
│   ├── reports/
│   └── splash/
│
└── shared/
```

---

# Funcionalidades planificadas

* Gestión de empleados
* Gestión de lugares de trabajo
* Registro de asistencia
* Historial de movimientos
* Justificativos médicos
* Reportes
* Gestión de perfiles
* Roles de usuario
* Panel administrativo
* Dashboard con estadísticas
* Geolocalización
* Notificaciones
* Carga de documentación

---

# Instalación

## Clonar el proyecto

```bash
git clone https://github.com/Renzito24/locustaf.git
```

## Instalar dependencias

```bash
flutter pub get
```

## Configurar Firebase

```bash
flutterfire configure
```

## Ejecutar el proyecto

```bash
flutter run -d chrome
```

---

# Documentación

El proyecto cuenta con documentación adicional:

* `LOCUSTAF_DESARROLLO.md`
* `LOCUSTAF_CONTEXTO.md` (bitácora técnica)
* Documentación futura dentro de `docs/`

---

# Objetivo del proyecto

Construir un sistema moderno, escalable y mantenible para la administración del presentismo laboral, aplicando buenas prácticas de arquitectura de software y desarrollo con Flutter.

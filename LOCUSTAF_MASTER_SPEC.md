# LOCUSTAF MASTER SPECIFICATION
## Locus Staff - Sistema de Control de Asistencia Laboral
### Versión MVP 1.0

---

## 1. VISIÓN DEL SISTEMA

LOCUSTAF (Locus Staff) es una plataforma de control de asistencia laboral diseñada para pequeños y medianos empleadores.

Permite registrar:
- Ingresos y egresos
- Control de horas trabajadas
- Validación por geolocalización
- Historial laboral
- Justificativos médicos
- Reportes básicos

---

## 2. PRINCIPIOS DEL SISTEMA

El sistema debe cumplir con:

- Simplicidad de uso
- Validación de ubicación obligatoria
- Registro confiable de asistencia
- Separación clara de roles
- Escalabilidad futura (multiempresa)

---

## 3. ARQUITECTURA TECNOLÓGICA

### Frontend
- Flutter Web

### Backend
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Hosting

### Estado de la aplicación
- Riverpod (gestión de estado)

---

## 4. ROLES DEL SISTEMA

### 4.1 Administrador
Puede:
- Gestionar empleados
- Crear lugares de trabajo
- Ver asistencias
- Generar reportes
- Ver dashboard general
- Gestionar justificativos

---

### 4.2 Trabajador
Puede:
- Iniciar sesión
- Registrar ingreso
- Registrar egreso
- Ver historial personal
- Subir justificativos médicos
- Cambiar contraseña

---

## 5. MODELO DE NEGOCIO

### Empleados
- Creación por administrador
- Datos obligatorios:
  - Nombre
  - Apellido
  - DNI
  - Email
  - Teléfono
  - Dirección
  - Categoría laboral
  - Lugar asignado

---

### Lugares de trabajo
Cada lugar contiene:
- Nombre
- Dirección
- Latitud
- Longitud
- Radio permitido (metros)

---

## 6. REGLA DE GEOLOCALIZACIÓN

El sistema debe validar asistencia mediante GPS:

1. Obtener ubicación actual del trabajador
2. Calcular distancia al lugar asignado
3. Validar contra radio permitido

Si cumple:
→ Registrar asistencia

Si no cumple:
→ Rechazar registro

---

## 7. ASISTENCIA

Reglas:
- Un ingreso por día
- No duplicar registros
- Egreso solo si existe ingreso

Datos:
- Fecha
- Hora ingreso
- Hora egreso
- Ubicación GPS
- Distancia calculada

---

## 8. JUSTIFICATIVOS MÉDICOS

- Formatos: PDF, JPG, PNG
- Almacenamiento: Firebase Storage
- Asociado a empleado y fecha

---

## 9. DASHBOARD ADMIN

Indicadores:
- Total empleados
- Presentes
- Ausentes
- Con justificativo
- Actividad diaria
- Lugares activos

---

## 10. REQUISITOS FUNCIONALES

RF01 Login
RF02 Gestión empleados
RF03 Gestión lugares
RF04 Registro ingreso
RF05 Registro egreso
RF06 Validación GPS
RF07 Historial
RF08 Dashboard
RF09 Justificativos
RF10 Reportes
RF11 Cambio de contraseña

---

## 11. REQUISITOS NO FUNCIONALES

RNF01 UI intuitiva
RNF02 Seguridad
RNF03 Performance
RNF04 Responsive
RNF05 Escalable

---

## 12. ROADMAP FUTURO

- Multiempresa
- Notificaciones
- QR attendance
- Exportación PDF
- Analítica avanzada
- Turnos laborales
# LOCUSTAF DEVELOPMENT LOG
## Estado del proyecto (MVP 1.0)

---

## 1. ESTADO ACTUAL

### Fase actual:
🔵 Fase 1 - Configuración inicial Flutter

---

## 2. LO QUE YA ESTÁ HECHO

- Proyecto Flutter inicial creado
- Estructura base definida
- Separación de `main.dart` y `app.dart`
- Clase `LocustafApp` creada
- ProviderScope configurado (Riverpod preparado)
- MaterialApp configurado
- SplashScreen definido (placeholder)
- Dashboard layout creado con sidebar fijo, AppBar y área de contenido
- Modelo `UserModel` completo con Equatable, copyWith, fromJson/toJson

---

## 3. ESTRUCTURA BASE ACTUAL

lib/
 ├── main.dart
 ├── app/
 │    └── app.dart
 ├── core/ (pendiente)
 ├── features/ (pendiente)

---

## 4. DECISIONES TÉCNICAS TOMADAS

- Flutter Web como frontend principal
- Firebase como backend
- Riverpod como state management
- Arquitectura escalable tipo feature-first
- MVP enfocado en asistencia laboral con GPS
- Modelos con Equatable + copyWith + fromJson/toJson manual (sin freezed ni build_runner)
- UserModel con UserRole enum (admin/empleado), createdAt/updatedAt preparados para Firestore

---

## 5. ESTADO FUNCIONAL

✔ App inicia correctamente
✔ MaterialApp configurado
✔ SplashScreen conectado
✔ ProviderScope activo

---

## 6. PENDIENTE INMEDIATO

### Fase 2 - UI base
- Crear SplashScreen real
- Crear estructura de navegación
- Implementar GoRouter (NO aún activado)
- Definir layout base del sistema
- Crear Dashboard layout (sidebar + AppBar + contenido) ✔

---

## 7. PRÓXIMO PASO SUGERIDO

Implementar:

- SplashScreen UI real
- Pantalla Login (mock) ✔
- Estructura de rutas base
- Core theme refinado
- Modelo UserModel completo ✔

---

## 8. NOTAS

El sistema está en fase temprana pero correctamente estructurado para escalar a MVP completo con Firebase + geolocalización.
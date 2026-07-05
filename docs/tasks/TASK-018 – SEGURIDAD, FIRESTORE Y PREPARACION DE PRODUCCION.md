# TASK-018 – SEGURIDAD, FIRESTORE Y PREPARACIÓN DE PRODUCCIÓN

## 🎯 Objetivo

Preparar LOCUSTAF para un entorno real de producción implementando seguridad en Firestore, datos iniciales (seed data), validación de estructura y estabilidad del backend.

---

## 🧱 Alcance

### 1. Firestore Rules

- Revisar reglas actuales
- Asegurar control por autenticación
- Restringir acceso por colección según usuario autenticado
- Validar permisos básicos por rol si aplica

Ejemplo esperado:
- usuarios solo pueden leer su perfil
- empleados no pueden modificar datos globales
- solo admin puede escribir en colecciones críticas

---

### 2. Seed Data (datos iniciales)

Crear datos mínimos necesarios para que la app funcione en primer arranque:

- Admin user base
- Al menos 1 workplace
- Estructura inicial de usuarios
- Datos mínimos para reports (si aplica)

---

### 3. Indexes de Firestore

- Verificar errores de composite indexes en consola
- Crear indexes necesarios para queries existentes
- Asegurar que no haya queries sin soporte de indexación

---

### 4. Validación de entorno

- Confirmar que la app puede iniciar desde cero
- Sincronicidad entre Auth y Firestore
- No errores por colecciones vacías
- No null crashes en providers

---

### 5. Limpieza final

- Eliminar reglas de test mode
- Evitar acceso abierto a Firestore
- Asegurar estructura segura por defecto

---

## ⚙️ Reglas técnicas

- NO cambiar arquitectura del frontend
- NO modificar UI
- NO crear features nuevas
- SOLO backend + configuración Firebase
- Mantener compatibilidad con providers actuales

---

## 🔐 Reglas de seguridad mínimas esperadas

- Deny by default en Firestore
- Acceso solo con auth
- Validación de ownership cuando corresponda
- Separación clara de roles si aplica en backend

---

## 📌 Criterios de aceptación

- Firestore rules seguras (no modo test)
- App funciona con datos iniciales
- No errores de indexación
- No crashes con base vacía
- Auth + Firestore sincronizados
- flutter analyze = 0 issues

---

## 🚀 Resultado esperado

LOCUSTAF queda lista para entorno real:

- segura en backend
- estable desde arranque limpio
- sin dependencias de datos manuales
- preparada para demo o despliegue
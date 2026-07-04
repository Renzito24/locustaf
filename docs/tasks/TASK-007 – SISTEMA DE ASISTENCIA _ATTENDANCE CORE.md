# TASK-007 – SISTEMA DE ASISTENCIA (ATTENDANCE CORE)

## 🎯 OBJETIVO

Implementar el sistema base de asistencia laboral en LOCUSTAF:

- check-in (inicio de jornada)
- check-out (fin de jornada)
- cálculo de duración
- historial de asistencia
- persistencia en Firestore
- actualización en tiempo real

Este es el núcleo funcional del sistema.

---

## 🧱 MODELO DE DATOS

### AttendanceModel

Campos:

- uid (string)
- userId (string)
- checkInTime (DateTime)
- checkOutTime (DateTime?)
- durationMinutes (int?)
- date (String YYYY-MM-DD)
- status (active | completed)

---

## ⚙️ FLUJO PRINCIPAL

```text id="flow007"
Check-In
→ crear registro en Firestore (status: active)

Check-Out
→ actualizar registro existente
→ set checkOutTime
→ calcular durationMinutes
→ status: completed
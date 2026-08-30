# Plan de Monitoreo — LOCUSTAF

**Objetivo:** detectar errores de check-in/check-out, latencia alta y fallos de autenticación en producción.

---

## 1. Logs

### Cloud Functions
Las funciones ya registran eventos vía `console.log`/`console.error`. Se recomienda estructurar los logs con campos clave para filtrarlos en Cloud Logging:

```js
// En cada función (ej. syncUserAuthStatus)
console.log(JSON.stringify({
  severity: 'INFO',
  event: 'user_sync',
  uid: userId,
  action: 'disable',
  timestamp: new Date().toISOString(),
}));
```

**Filtros útiles en Cloud Logging (Logs Explorer):**
- Errores de check-in/out: `severity>=ERROR AND jsonPayload.event="attendance"`
- Errores de auth: `severity>=ERROR AND jsonPayload.event="auth"`

### App (Flutter)
`LoggingService` ya emite logs con tags (`attendance`, `incidences`, `medical_documents`). En producción se recomienda conectar un servicio de reporte de errores (Sentry) en `LoggingService._log` sin cambiar los call sites.

---

## 2. Métricas

### Cloud Monitoring
- **Firestore:** latencia de lectura/escritura, operaciones por segundo, errores de reglas (`firestore.googleapis.com/firestore/rule_evaluation`).
- **Functions:** invocaciones, duración, errores (`cloudfunctions.googleapis.com/function/execution_count`, `/execution_times`, `/execution_errors`).
- **Hosting:** requests, bytes servidos, errores 4xx/5xx.

### Métricas de negocio (vía Cloud Functions + BigQuery o Firestore)
- Nº de check-ins/outs por día.
- Tasa de llegadas tarde.
- Nº de jornadas huérfanas.

---

## 3. Alertas

### Alertas recomendadas (Cloud Monitoring)

| Alerta | Condición | Severidad | Acción |
|--------|-----------|-----------|--------|
| Errores de check-in/out | `severity>=ERROR` con `event="attendance"` > 5 en 5 min | Alta | Revisar logs de la función/repo |
| Latencia de check-in/out | Duración de función > 3 s (p95) | Media | Revisar consultas Firestore e índices |
| Fallos de autenticación | `firebase_auth` errores de login > umbral | Media | Revisar intentos de fuerza bruta |
| Errores de reglas Firestore | `rule_evaluation` denegadas inesperadas | Media | Revisar reglas y queries |
| Errores 5xx en Hosting | `http_request/request_count` con status 5xx | Alta | Revisar build y hosting |

### Canales de notificación
- Email (obligatorio).
- Slack/Webhook (recomendado) para alertas de severidad alta.

---

## 4. Configuración de alertas (ejemplo)

```bash
# Crear una alerta de errores de check-in/out (vía gcloud)
gcloud alpha monitoring policies create \
  --project=locustaf-31ed2 \
  --display-name="Errores check-in/out" \
  --condition-filter='logName:"cloudfunctions.googleapis.com" AND severity>=ERROR AND jsonPayload.event="attendance"' \
  --condition-threshold-value=5 \
  --condition-threshold-duration=300s \
  --notification-channels="<CHANNEL_ID>"
```

---

## 5. Checklist post-deploy

- [ ] Verificar que las reglas de producción están activas (no las de seed).
- [ ] Confirmar que los índices compuestos se crearon (`firebase deploy --only firestore:indexes`).
- [ ] Probar login, check-in y check-out en el entorno desplegado.
- [ ] Confirmar que la Cloud Function `syncUserAuthStatus` aparece en Functions.
- [ ] Activar las alertas de Cloud Monitoring.
- [ ] Conectar Sentry (o equivalente) al `LoggingService` en producción.

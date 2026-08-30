#!/usr/bin/env bash
# ============================================================================
# LOCUSTAF — Script de despliegue automatizado
#
# Uso:
#   ./deploy.sh staging     # despliega al entorno STAGING
#   ./deploy.sh production  # despliega al entorno PRODUCCIÓN
#
# Requisitos:
#   - firebase-tools instalado y logueado (firebase login)
#   - flutter en el PATH
#   - Proyectos Firebase creados y configurados con flutterfire
#
# Orden de despliegue (según especificación):
#   1. Reglas de Firestore (firestore.rules)
#   2. Índices compuestos (firestore.indexes.json)
#   3. Cloud Functions
#   4. Hosting (app Flutter compilada en web)
# ============================================================================

set -euo pipefail

# --- Configuración por entorno ---------------------------------------------
# Mapea el nombre del entorno al ID del proyecto Firebase.
# Ajustá estos IDs a los proyectos reales de STAGING y PRODUCCIÓN.
declare -A PROJECTS=(
  [staging]="locustaf-staging"
  [production]="locustaf-31ed2"
)

ENV_NAME="${1:-}"
if [[ -z "$ENV_NAME" ]]; then
  echo "ERROR: indicá el entorno: ./deploy.sh staging|production"
  exit 1
fi

PROJECT_ID="${PROJECTS[$ENV_NAME]:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: entorno desconocido '$ENV_NAME'. Válidos: staging, production"
  exit 1
fi

# --- Guardas de seguridad ---------------------------------------------------
if [[ "$ENV_NAME" == "production" ]]; then
  echo "⚠  VAS A DESPLEGAR A PRODUCCIÓN ($PROJECT_ID)."
  read -r -p "Escribí 'PROD' para confirmar: " CONFIRM
  if [[ "$CONFIRM" != "PROD" ]]; then
    echo "Despliegue cancelado."
    exit 1
  fi
fi

echo "=============================================="
echo "  LOCUSTAF → $ENV_NAME ($PROJECT_ID)"
echo "=============================================="

# --- 0. Verificación de código ---------------------------------------------
echo "[0/5] flutter analyze..."
flutter analyze

echo "[0/5] flutter test..."
flutter test

# --- 1. Reglas de Firestore -------------------------------------------------
echo "[1/5] Desplegando reglas de Firestore..."
firebase use "$PROJECT_ID"
firebase deploy --only firestore:rules

# --- 2. Índices compuestos --------------------------------------------------
echo "[2/5] Desplegando índices de Firestore..."
firebase deploy --only firestore:indexes

# --- 3. Cloud Functions -----------------------------------------------------
echo "[3/5] Desplegando Cloud Functions..."
firebase deploy --only functions

# --- 4. Hosting (app Flutter web) -------------------------------------------
echo "[4/5] Compilando app Flutter web..."
flutter build web --release

echo "[5/5] Desplegando Hosting..."
firebase deploy --only hosting

echo "=============================================="
echo "  Despliegue a $ENV_NAME completado."
echo "=============================================="

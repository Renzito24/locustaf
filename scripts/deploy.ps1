# ============================================================================
# LOCUSTAF — Script de despliegue
# Uso:  powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  LOCUSTAF - Despliegue a Firebase" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Verificación de código
Write-Host "`n[1/5] flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "flutter analyze falló. Abortando." -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/5] flutter test..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "flutter test falló. Abortando." -ForegroundColor Red
    exit 1
}

# 2. Reglas de Firestore
Write-Host "`n[3/5] Desplegando reglas de Firestore..." -ForegroundColor Yellow
firebase deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deploy de reglas falló. Abortando." -ForegroundColor Red
    exit 1
}

# 3. Índices de Firestore
Write-Host "`n[4/5] Desplegando índices de Firestore..." -ForegroundColor Yellow
firebase deploy --only firestore:indexes
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deploy de índices falló. Abortando." -ForegroundColor Red
    exit 1
}

# 4. Storage + Functions
Write-Host "`n[5/5] Desplegando Storage y Cloud Functions..." -ForegroundColor Yellow
firebase deploy --only storage,functions
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deploy de Storage/Functions falló." -ForegroundColor Red
    exit 1
}

Write-Host "`n==============================================" -ForegroundColor Green
Write-Host "  Despliegue completado correctamente" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

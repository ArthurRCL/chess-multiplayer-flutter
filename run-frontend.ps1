# ============================================================
#  run-frontend.ps1 — Roda o app Flutter no Chrome
#  Uso: .\run-frontend.ps1
# ============================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# URL da API backend (ajuste se rodar em porta diferente)
$API_BASE_URL = "http://localhost:8080"
$WS_BASE_URL  = "http://localhost:8080/ws"

# 1. Verificar se Flutter está disponível ──────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Flutter não encontrado. Instale o Flutter SDK e adicione ao PATH."
    exit 1
}
$flutterVersion = (flutter --version 2>&1 | Select-String 'Flutter (\S+)').Matches[0].Groups[1].Value
Write-Host "🐦 Flutter detectado: $flutterVersion" -ForegroundColor Green

# 2. Garantir dependências instaladas ──────────────────────
Write-Host ""
Write-Host "📦 Verificando dependências (flutter pub get)..." -ForegroundColor Cyan
Set-Location $scriptDir
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Falha ao instalar dependências."
    exit 1
}

# 3. Rodar no Chrome ───────────────────────────────────────
Write-Host ""
Write-Host "🚀 Iniciando app no Chrome..." -ForegroundColor Yellow
Write-Host "   Backend esperado em: $API_BASE_URL" -ForegroundColor Cyan
Write-Host ""

flutter run -d chrome --web-port=3001 `
  --dart-define=API_BASE_URL=$API_BASE_URL `
  --dart-define=WS_BASE_URL=$WS_BASE_URL

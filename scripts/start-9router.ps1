# 9Router Launcher per Improvy Flutter (Windows)
# Esegui con: powershell -ExecutionPolicy Bypass -File .\scripts\start-9router.ps1

Write-Host "🚀 Avvio 9Router..." -ForegroundColor Green
Write-Host "📊 Dashboard: http://localhost:20128/dashboard" -ForegroundColor Cyan
Write-Host "🔌 API Endpoint: http://localhost:20128/v1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Premere Ctrl+C per fermare" -ForegroundColor Yellow
Write-Host ""

# Controlla se 9router è installato
$check = npm list -g 9router 2>$null
if (-not $check) {
    Write-Host "❌ 9Router non trovato!" -ForegroundColor Red
    Write-Host "Installa con: npm install -g 9router" -ForegroundColor Yellow
    exit 1
}

# Avvia 9router
Write-Host "⏳ Connessione in corso..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

9router

Write-Host "✅ 9Router è in esecuzione!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prossimi step:" -ForegroundColor Cyan
Write-Host "1. Apri http://localhost:20128/dashboard"
Write-Host "2. Connetti un provider gratuito (Kiro AI, OpenCode Free)"
Write-Host "3. Copia API Key dal dashboard"
Write-Host "4. Configura Claude Code con l'endpoint sopra"
Write-Host ""
Write-Host "📖 Guida completa: .\.claude\9ROUTER_SETUP.md" -ForegroundColor Green

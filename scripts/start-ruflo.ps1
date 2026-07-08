# Ruflo Launcher per Improvy Flutter (Windows)
# Esegui con: powershell -ExecutionPolicy Bypass -File .\scripts\start-ruflo.ps1

Write-Host "🚀 Avvio Ruflo (Agent Meta-Harness)..." -ForegroundColor Green
Write-Host ""
Write-Host "📊 Configurazione:" -ForegroundColor Cyan
Write-Host "  MCP Server: http://localhost:5002" -ForegroundColor White
Write-Host "  Memory: .claude-flow/memory (AgentDB + HNSW)" -ForegroundColor White
Write-Host "  Config: .claude/ruflo.config.json" -ForegroundColor White
Write-Host ""
Write-Host "Available Agents (100+):" -ForegroundColor Cyan
Write-Host "  - CodeReviewer" -ForegroundColor White
Write-Host "  - TestGenerator" -ForegroundColor White
Write-Host "  - SecurityAuditor" -ForegroundColor White
Write-Host "  - DocWriter" -ForegroundColor White
Write-Host "  - ArchitectureAnalyzer" -ForegroundColor White
Write-Host "  - PerformanceOptimizer" -ForegroundColor White
Write-Host "  - ... and 94 more" -ForegroundColor White
Write-Host ""
Write-Host "✨ Features:" -ForegroundColor Cyan
Write-Host "  • Self-learning (SONA neural patterns)" -ForegroundColor White
Write-Host "  • Vector memory (HNSW similarity search)" -ForegroundColor White
Write-Host "  • Swarm coordination" -ForegroundColor White
Write-Host "  • Goal planning (GOAP A*)" -ForegroundColor White
Write-Host "  • Background workers (audit, testgen, docs)" -ForegroundColor White
Write-Host "  • Security scanning (AIDefence, PII, CVE)" -ForegroundColor White
Write-Host "  • Federation ready (cross-machine agents)" -ForegroundColor White
Write-Host ""

# Controlla se ruflo è installato
$check = npm list -g ruflo 2>$null
if (-not $check) {
    Write-Host "❌ Ruflo non trovato!" -ForegroundColor Red
    Write-Host "Installa con: npm install -g ruflo@latest" -ForegroundColor Yellow
    exit 1
}

Write-Host "Premere Ctrl+C per fermare" -ForegroundColor Yellow
Write-Host ""
Write-Host "⏳ Connessione..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# Avvia Ruflo daemon
Write-Host "Starting Ruflo daemon..." -ForegroundColor Gray
ruflo daemon start

# Attendi che sia pronto
Start-Sleep -Seconds 3

# Mostra status
Write-Host ""
Write-Host "✅ Ruflo è in esecuzione!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prossimi step:" -ForegroundColor Cyan
Write-Host "1. Registra Ruflo come MCP:" -ForegroundColor White
Write-Host "   claude mcp add ruflo -- npx ruflo mcp start" -ForegroundColor Gray
Write-Host "2. Riavvia Claude Code" -ForegroundColor White
Write-Host "3. In Claude Code, prova:" -ForegroundColor White
Write-Host "   /spawn-agent CodeReviewer" -ForegroundColor Gray
Write-Host "   /memory-search 'flutter'" -ForegroundColor Gray
Write-Host "   /goal 'implement auth refactor'" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Guida completa: .\RUFLO_GUIDE.md" -ForegroundColor Green
Write-Host "📊 Monitoraggio: ruflo logs --follow" -ForegroundColor Green
Write-Host "🌐 Web UI: https://flo.ruv.io/" -ForegroundColor Green
Write-Host ""

# Mostra logs
Write-Host "Real-time logs:" -ForegroundColor Yellow
Write-Host "================" -ForegroundColor Yellow
ruflo logs --follow

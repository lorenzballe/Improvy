# Graphify Launcher per Improvy Flutter (Windows)
# Esegui con: powershell -ExecutionPolicy Bypass -File .\scripts\run-graphify.ps1

Write-Host "📊 Graphify Knowledge Graph Builder" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Estrae concetti e relazioni dal tuo codebase" -ForegroundColor Cyan
Write-Host "🧠 Costruisce una knowledge graph interattiva" -ForegroundColor Cyan
Write-Host "⚡ 71.5x meno token per query (su corpus grandi)" -ForegroundColor Cyan
Write-Host ""

# Controlla se graphify è installato
try {
    $version = graphify --version 2>$null
    if (-not $version) {
        throw "Not found"
    }
} catch {
    Write-Host "❌ Graphify non trovato!" -ForegroundColor Red
    Write-Host "Installa con: pip install graphifyy" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Graphify versione: $version" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Modalità disponibili:" -ForegroundColor Cyan
Write-Host "  standard  - Balanced extraction" -ForegroundColor White
Write-Host "  deep      - Aggressive (more inferred edges)" -ForegroundColor White
Write-Host "  shallow   - Fast (extracted only)" -ForegroundColor White
Write-Host ""
Write-Host "📁 Target: improvy_flutter" -ForegroundColor Cyan
Write-Host ""

# Menu interattivo
Write-Host "Scegli un'azione:" -ForegroundColor Yellow
Write-Host "1) Estrai il grafo (standard)" -ForegroundColor White
Write-Host "2) Estrai il grafo (deep)" -ForegroundColor White
Write-Host "3) Estrai il grafo (shallow - veloce)" -ForegroundColor White
Write-Host "4) Aggiorna il grafo (solo file cambiati)" -ForegroundColor White
Write-Host "5) Apri il grafo in browser" -ForegroundColor White
Write-Host "6) Leggi il report" -ForegroundColor White
Write-Host "7) Query il grafo" -ForegroundColor White
Write-Host "8) Installa git hook" -ForegroundColor White
Write-Host "9) Esci" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Seleziona (1-9)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "⏳ Estrazione standard in corso..." -ForegroundColor Yellow
        Write-Host "(Questo potrebbe richiedere 1-2 minuti)" -ForegroundColor Gray
        Write-Host ""
        graphify .
        Write-Host ""
        Write-Host "✅ Grafo creato!" -ForegroundColor Green
        Write-Host "📊 Visualizza: graphify-out/graph.html" -ForegroundColor Cyan
    }

    "2" {
        Write-Host ""
        Write-Host "⏳ Estrazione deep in corso..." -ForegroundColor Yellow
        Write-Host "(Questo potrebbe richiedere 2-3 minuti)" -ForegroundColor Gray
        Write-Host ""
        graphify . --mode deep
        Write-Host ""
        Write-Host "✅ Grafo creato (con inferred edges)!" -ForegroundColor Green
        Write-Host "📊 Visualizza: graphify-out/graph.html" -ForegroundColor Cyan
    }

    "3" {
        Write-Host ""
        Write-Host "⏳ Estrazione shallow in corso..." -ForegroundColor Yellow
        Write-Host "(Veloce - solo AST, no LLM)" -ForegroundColor Gray
        Write-Host ""
        graphify . --mode shallow
        Write-Host ""
        Write-Host "✅ Grafo creato (veloce)!" -ForegroundColor Green
        Write-Host "📊 Visualizza: graphify-out/graph.html" -ForegroundColor Cyan
    }

    "4" {
        Write-Host ""
        Write-Host "⏳ Aggiornamento in corso..." -ForegroundColor Yellow
        Write-Host "(Solo file cambiati, molto veloce)" -ForegroundColor Gray
        Write-Host ""
        graphify . --update
        Write-Host ""
        Write-Host "✅ Grafo aggiornato!" -ForegroundColor Green
    }

    "5" {
        Write-Host ""
        Write-Host "🌐 Apertura grafo nel browser..." -ForegroundColor Cyan
        if (Test-Path "graphify-out/graph.html") {
            Start-Process "graphify-out/graph.html"
            Write-Host "✅ Grafo aperto!" -ForegroundColor Green
        } else {
            Write-Host "❌ Grafo non trovato! Esegui prima l'estrazione (opzione 1)" -ForegroundColor Red
        }
    }

    "6" {
        Write-Host ""
        if (Test-Path "graphify-out/GRAPH_REPORT.md") {
            Get-Content "graphify-out/GRAPH_REPORT.md"
        } else {
            Write-Host "❌ Report non trovato! Esegui prima l'estrazione (opzione 1)" -ForegroundColor Red
        }
    }

    "7" {
        Write-Host ""
        $query = Read-Host "Digita la query"
        Write-Host ""
        Write-Host "🔍 Ricerca in corso..." -ForegroundColor Cyan
        graphify query $query
    }

    "8" {
        Write-Host ""
        Write-Host "🪝 Installazione git hook..." -ForegroundColor Yellow
        graphify hook install
        Write-Host "✅ Git hook installato!" -ForegroundColor Green
        Write-Host "Il grafo si aggiorna automaticamente dopo ogni commit" -ForegroundColor Gray
    }

    "9" {
        Write-Host "Arrivederci!" -ForegroundColor Green
        exit 0
    }

    default {
        Write-Host "❌ Scelta non valida!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "💡 Suggerimenti:" -ForegroundColor Green
Write-Host "• Apri graphify-out/graph.html nel browser per navigare" -ForegroundColor White
Write-Host "• Leggi GRAPH_REPORT.md per insights e god nodes" -ForegroundColor White
Write-Host "• Usa /graphify query 'your question' per interrogare il grafo" -ForegroundColor White
Write-Host "• Installa git hook per auto-sync su ogni commit" -ForegroundColor White
Write-Host ""

#!/bin/bash

# Graphify Launcher per Improvy Flutter (Unix/macOS/Linux)
# Usage: ./scripts/run-graphify.sh

set -e

echo "📊 Graphify Knowledge Graph Builder"
echo ""
echo "🔍 Estrae concetti e relazioni dal tuo codebase"
echo "🧠 Costruisce una knowledge graph interattiva"
echo "⚡ 71.5x meno token per query (su corpus grandi)"
echo ""

# Controlla se graphify è installato
if ! command -v graphify &> /dev/null; then
    echo "❌ Graphify non trovato!"
    echo "Installa con: pip install graphifyy"
    exit 1
fi

version=$(graphify --version 2>/dev/null || echo "unknown")
echo "✅ Graphify versione: $version"
echo ""
echo "📋 Modalità disponibili:"
echo "  standard  - Balanced extraction"
echo "  deep      - Aggressive (more inferred edges)"
echo "  shallow   - Fast (extracted only)"
echo ""
echo "📁 Target: improvy_flutter"
echo ""

# Menu interattivo
echo "Scegli un'azione:"
echo "1) Estrai il grafo (standard)"
echo "2) Estrai il grafo (deep)"
echo "3) Estrai il grafo (shallow - veloce)"
echo "4) Aggiorna il grafo (solo file cambiati)"
echo "5) Apri il grafo in browser"
echo "6) Leggi il report"
echo "7) Query il grafo"
echo "8) Installa git hook"
echo "9) Esci"
echo ""

read -p "Seleziona (1-9): " choice

case $choice in
    1)
        echo ""
        echo "⏳ Estrazione standard in corso..."
        echo "(Questo potrebbe richiedere 1-2 minuti)"
        echo ""
        graphify .
        echo ""
        echo "✅ Grafo creato!"
        echo "📊 Visualizza: graphify-out/graph.html"
        ;;

    2)
        echo ""
        echo "⏳ Estrazione deep in corso..."
        echo "(Questo potrebbe richiedere 2-3 minuti)"
        echo ""
        graphify . --mode deep
        echo ""
        echo "✅ Grafo creato (con inferred edges)!"
        echo "📊 Visualizza: graphify-out/graph.html"
        ;;

    3)
        echo ""
        echo "⏳ Estrazione shallow in corso..."
        echo "(Veloce - solo AST, no LLM)"
        echo ""
        graphify . --mode shallow
        echo ""
        echo "✅ Grafo creato (veloce)!"
        echo "📊 Visualizza: graphify-out/graph.html"
        ;;

    4)
        echo ""
        echo "⏳ Aggiornamento in corso..."
        echo "(Solo file cambiati, molto veloce)"
        echo ""
        graphify . --update
        echo ""
        echo "✅ Grafo aggiornato!"
        ;;

    5)
        echo ""
        echo "🌐 Apertura grafo nel browser..."
        if [ -f "graphify-out/graph.html" ]; then
            if command -v open &> /dev/null; then
                open "graphify-out/graph.html"
            elif command -v xdg-open &> /dev/null; then
                xdg-open "graphify-out/graph.html"
            else
                echo "Apri manualmente: graphify-out/graph.html"
            fi
            echo "✅ Grafo aperto!"
        else
            echo "❌ Grafo non trovato! Esegui prima l'estrazione (opzione 1)"
        fi
        ;;

    6)
        echo ""
        if [ -f "graphify-out/GRAPH_REPORT.md" ]; then
            cat "graphify-out/GRAPH_REPORT.md"
        else
            echo "❌ Report non trovato! Esegui prima l'estrazione (opzione 1)"
        fi
        ;;

    7)
        echo ""
        read -p "Digita la query: " query
        echo ""
        echo "🔍 Ricerca in corso..."
        graphify query "$query"
        ;;

    8)
        echo ""
        echo "🪝 Installazione git hook..."
        graphify hook install
        echo "✅ Git hook installato!"
        echo "Il grafo si aggiorna automaticamente dopo ogni commit"
        ;;

    9)
        echo "Arrivederci!"
        exit 0
        ;;

    *)
        echo "❌ Scelta non valida!"
        exit 1
        ;;
esac

echo ""
echo "💡 Suggerimenti:"
echo "• Apri graphify-out/graph.html nel browser per navigare"
echo "• Leggi GRAPH_REPORT.md per insights e god nodes"
echo "• Usa /graphify query 'your question' per interrogare il grafo"
echo "• Installa git hook per auto-sync su ogni commit"
echo ""

#!/bin/bash

# Ruflo Launcher per Improvy Flutter (Unix/macOS/Linux)
# Usage: ./scripts/start-ruflo.sh

set -e

echo "🚀 Avvio Ruflo (Agent Meta-Harness)..."
echo ""
echo "📊 Configurazione:"
echo "  MCP Server: http://localhost:5002"
echo "  Memory: .claude-flow/memory (AgentDB + HNSW)"
echo "  Config: .claude/ruflo.config.json"
echo ""
echo "Available Agents (100+):"
echo "  - CodeReviewer"
echo "  - TestGenerator"
echo "  - SecurityAuditor"
echo "  - DocWriter"
echo "  - ArchitectureAnalyzer"
echo "  - PerformanceOptimizer"
echo "  - ... and 94 more"
echo ""
echo "✨ Features:"
echo "  • Self-learning (SONA neural patterns)"
echo "  • Vector memory (HNSW similarity search)"
echo "  • Swarm coordination"
echo "  • Goal planning (GOAP A*)"
echo "  • Background workers (audit, testgen, docs)"
echo "  • Security scanning (AIDefence, PII, CVE)"
echo "  • Federation ready (cross-machine agents)"
echo ""

# Controlla se ruflo è installato
if ! command -v ruflo &> /dev/null; then
    echo "❌ Ruflo non trovato!"
    echo "Installa con: npm install -g ruflo@latest"
    exit 1
fi

echo "Premere Ctrl+C per fermare"
echo ""
echo "⏳ Connessione..."
sleep 1

# Avvia Ruflo daemon
echo "Starting Ruflo daemon..."
ruflo daemon start

# Attendi che sia pronto
sleep 3

# Mostra status
echo ""
echo "✅ Ruflo è in esecuzione!"
echo ""
echo "📋 Prossimi step:"
echo "1. Registra Ruflo come MCP:"
echo "   claude mcp add ruflo -- npx ruflo mcp start"
echo "2. Riavvia Claude Code"
echo "3. In Claude Code, prova:"
echo "   /spawn-agent CodeReviewer"
echo "   /memory-search 'flutter'"
echo "   /goal 'implement auth refactor'"
echo ""
echo "📖 Guida completa: ./RUFLO_GUIDE.md"
echo "📊 Monitoraggio: ruflo logs --follow"
echo "🌐 Web UI: https://flo.ruv.io/"
echo ""

# Mostra logs
echo "Real-time logs:"
echo "================"
ruflo logs --follow

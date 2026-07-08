#!/bin/bash

# 9Router Launcher per Improvy Flutter
# Avvia il router con output nel log

set -e

echo "🚀 Avvio 9Router..."
echo "📊 Dashboard: http://localhost:20128/dashboard"
echo "🔌 API: http://localhost:20128/v1"
echo ""
echo "Premere Ctrl+C per fermare"
echo ""

# Controlla se 9router è installato
if ! command -v 9router &> /dev/null; then
    echo "❌ 9Router non trovato!"
    echo "Installa con: npm install -g 9router"
    exit 1
fi

# Avvia 9router
9router

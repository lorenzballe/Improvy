#!/bin/bash

# Startup All AI Development Tools (9Router + Ruflo + Graphify)
# Unix/macOS/Linux
# Usage: ./scripts/startup-all.sh

set -e

echo "🚀 Improvy AI Development Toolkit - Startup"
echo "==========================================="
echo ""
echo "Starting: 9Router + Ruflo + Graphify"
echo ""

# Check if tools are installed
echo "Checking tools..."
echo ""

if ! command -v 9router &> /dev/null; then
    echo "❌ 9router not found"
    echo "Install with: npm install -g 9router"
    exit 1
fi
echo "✓ 9router installed"

if ! command -v ruflo &> /dev/null; then
    echo "❌ ruflo not found"
    echo "Install with: npm install -g ruflo@latest"
    exit 1
fi
echo "✓ ruflo installed"

if ! command -v graphify &> /dev/null; then
    echo "❌ graphify not found"
    echo "Install with: pip install graphifyy"
    exit 1
fi
echo "✓ graphify installed"

echo ""
echo "✅ All tools installed!"
echo ""
echo "Starting services..." -ForegroundColor Yellow
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down services..."
    kill $PID_9ROUTER 2>/dev/null || true
    kill $PID_RUFLO 2>/dev/null || true
    echo "✓ Services stopped"
}

trap cleanup EXIT

# Start 9Router
echo "[1/3] Starting 9Router (Token Saver)..."
9router > /tmp/9router.log 2>&1 &
PID_9ROUTER=$!
echo "  PID: $PID_9ROUTER"
sleep 2

# Start Ruflo daemon
echo "[2/3] Starting Ruflo daemon (Agent Orchestration)..."
ruflo daemon start > /tmp/ruflo.log 2>&1 &
PID_RUFLO=$!
echo "  PID: $PID_RUFLO"
sleep 2

# Graphify (ready to use, no daemon)
echo "[3/3] Graphify ready (Knowledge Graph)"
echo "  Use: /graphify . in Claude Code"

echo ""
echo "✅ All services started!"
echo ""
echo "Status:"
echo "  9Router    → http://localhost:20128/dashboard"
echo "  Ruflo      → Agent daemon running"
echo "  Graphify   → Ready via /graphify command"
echo ""
echo "Next:"
echo "  1. Open Claude Code"
echo "  2. Try: /goal 'implement feature X'"
echo "  3. Tools work transparently in background"
echo ""
echo "To stop services:"
echo "  Press Ctrl+C in this terminal"
echo ""
echo "Logs:"
echo "  9Router: tail -f /tmp/9router.log"
echo "  Ruflo:   ruflo logs --follow"
echo ""
echo "Running services (Ctrl+C to stop)..."
echo ""

# Wait for termination
wait

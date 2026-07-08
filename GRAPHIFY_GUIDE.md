# Graphify Integration Guide

## 📌 Cosa è Graphify?

**Graphify** è un Claude Code skill che costruisce una **knowledge graph interattiva** dal tuo codebase:

- 📊 **Estrae concetti e relazioni** da code, docs, PDFs, immagini
- 🔍 **Navigazione interattiva** - graph.html, Obsidian vault, wiki markdown
- ⚡ **71.5x token reduction** - su corpus grandi, riduce token vs leggere raw files
- 🧠 **Suggerisce domande** e identifica "god nodes" (concetti centrali)
- 🪝 **Auto-sync** con git hooks e watch mode
- 🎯 **Persistent graph** - query settimane dopo senza rileggere i file
- 🌳 **Multimodal** - code, text, PDFs, screenshots, diagrammi, immagini

## 🚀 Quick Start (3 minuti)

### 1. Installazione (già fatta)
```bash
pip install graphifyy
graphify install
```

### 2. Registra come Skill in Claude Code

Crea il file skill (se non esiste):

```bash
mkdir -p ~/.claude/skills/graphify
```

Oppure in Claude Code, aggiungi `/graphify` e Claude lo suggerirà.

### 3. Usa Graphify

Nel prompt di Claude Code:

```
/graphify .                           # Mappa tutta la cartella
```

Questo crea:

```
graphify-out/
├── graph.html              ← Apri nel browser! (interattivo)
├── GRAPH_REPORT.md         ← God nodes, connessioni, domande
├── graph.json              ← Grafo persistente (query in futuro)
├── obsidian/               ← Vault per Obsidian
├── wiki/                   ← Wikipedia-style articles
└── cache/                  ← SHA256 cache (incremental updates)
```

---

## 💡 Comandi Graphify

### Basic Commands

```
/graphify .                          # Map current directory
/graphify ./lib                      # Map specific folder
/graphify ./lib --mode deep          # Aggressive extraction (more inferred edges)
/graphify ./lib --update             # Re-extract only changed files
/graphify ./lib --watch              # Auto-sync as you code (background)
```

### Query the Graph

```
/graphify query "what connects auth to payment?"
/graphify path "RevenueCat" "IAP"
/graphify explain "ChromaticScale"
```

### Add External Sources

```
/graphify add https://arxiv.org/abs/1706.03762    # Fetch + extract paper
/graphify add https://github.com/path/to/repo     # Clone + graph repo
```

### Export Formats

```
/graphify ./lib --wiki               # Build agent-crawlable wiki
/graphify ./lib --svg                # Export graph.svg
/graphify ./lib --graphml            # Gephi/yEd format
/graphify ./lib --neo4j              # Generate cypher.txt for Neo4j
/graphify ./lib --mcp                # Start MCP stdio server
```

### Automation

```
graphify hook install                # Git post-commit hook
graphify hook uninstall              # Remove hook
```

---

## 📊 For improvy_flutter

### 1. Map Your Codebase

```bash
cd improvy_flutter
/graphify .
```

This creates a graph of:
- **Flutter code** (lib/*.dart)
- **iOS code** (ios/Runner/*)
- **Android code** (android/app/*)
- **Configuration** (pubspec.yaml, RevenueCat setup, etc)
- **Docs** (.claude/, README.md, 9ROUTER_GUIDE.md, RUFLO_GUIDE.md)

### 2. Explore God Nodes

Graphify will identify concepts that everything connects through:

**For improvy_flutter, likely god nodes:**
- `AudioService` (core to ear training)
- `RevenueCat` (IAP across platforms)
- `AnimationController` (UI effects)
- `Provider` (state management)
- `ChromaticScale` (music theory)
- `AppStateManager` (app lifecycle)

### 3. Discover Surprising Connections

Graphify ranks unexpected connections:

Example output:
```
Code-to-Code: MusicPlayer → RevenueCat (IAP detection)
Code-to-Docs: ChromaticCard → IMPROVY_FLUTTER_PIXEL_PERFECT.md
Code-to-Config: AudioService → ios/Runner/GeneratedPluginRegistrant.swift
```

### 4. Agent Navigation

For Ruflo agents, the wiki format makes codebase exploration easier:

```
graphify-out/wiki/index.md
├── AudioService.md        ← Agent can read & understand
├── RevenueCat.md
├── ChromaticScale.md
└── ...
```

Agents navigate by reading .md instead of parsing JSON.

---

## 🎯 Workflows

### Workflow 1: Onboarding New Dev

```bash
# New person joins project
/graphify .

# They explore:
graphify-out/graph.html          # Click around, see structure
graphify-out/GRAPH_REPORT.md     # Read suggested questions
/graphify query "what's critical to the app?"
/graphify path "AuthService" "IAP"

# Result: 30% faster onboarding
```

### Workflow 2: Feature Planning

```bash
# Planning new feature: "Playlist support"

/graphify query "how does data flow from input to storage?"
/graphify path "AudioFile" "Database"
/graphify explain "MusicPlayer"

# Graphify shows you similar patterns
# You reuse existing architecture
```

### Workflow 3: Code Review

```bash
# Before code review, update graph
/graphify . --update

# Check new connections
/graphify query "what changed since last commit?"

# Identifies accidental coupling, new dependencies
```

### Workflow 4: Debugging

```bash
# Bug: "Sound doesn't play in background"

/graphify query "what connects audio to background mode?"
/graphify path "AudioService" "PermissionManager"

# Traces dependencies: finds the missing link
```

### Workflow 5: Parallel Development (Multi-Agent)

```bash
# Ruflo agents working on different features
# Graph updates after each commit (git hook)

Agent 1: Implements auth
Agent 2: Implements payment flow
Agent 3: Optimizes animations

# After each commit, graph rebuilds (fast, AST-only for code)
# Other agents see latest structure
# No merge conflicts from invisible dependencies
```

---

## 🔧 Configuration

### graphify-out/.graphify.json

```json
{
  "mode": "standard",
  "languages": [
    "dart",
    "swift",
    "kotlin",
    "python",
    "markdown"
  ],
  "edge_modes": [
    "EXTRACTED",
    "INFERRED"
  ],
  "max_inferred": 50,
  "cache_strategy": "sha256",
  "auto_sync": false,
  "git_hook": false,
  "export_formats": [
    "html",
    "json",
    "obsidian",
    "wiki"
  ]
}
```

### Incremental Updates

```bash
# First run: full extraction
/graphify .                  # ~1-2 min for improvy_flutter

# Subsequent runs: only changed files
/graphify . --update         # ~5-10 sec (cache hit)

# Git hook: auto-update on every commit
graphify hook install
```

---

## 📈 Example Output for improvy_flutter

### GRAPH_REPORT.md

```markdown
# Knowledge Graph Report

## God Nodes (Highest Centrality)

1. AudioService (degree: 47)
   - Connects: MusicPlayer, MediaControls, PermissionManager, Recorder
   - Why: Core audio layer for ear training

2. RevenueCat (degree: 31)
   - Connects: IAP, AuthService, AppState, UIState
   - Why: Cross-platform payment handling

3. Provider (StateManagement, degree: 28)
   - Connects: All screens, AudioService, RevenueCat
   - Why: Global state propagation

## Surprising Connections

- ChromaticCard (UI) → RevenueCat (IAP)
  Reason: Card is locked until subscription active
  
- MusicPlayer (Backend) → AnimationController (UI)
  Reason: Synchronizes visual feedback with audio playback

## Suggested Questions

1. "What's the complete flow from audio input to IAP unlock?"
2. "Which components depend on both iOS and Android native code?"
3. "How does the app handle audio in background mode?"
4. "What would break if we refactored AudioService?"
5. "Which features require network connectivity?"

## Token Benchmark

Files processed: 52
Raw read tokens: 450,000
Graph query tokens: 6,300
Reduction: **71.5x**
```

### graph.html (Interactive)

- Click nodes to expand
- Search bar to find concepts
- Color-coded by community (cluster)
- Drag to rearrange
- Zoom/pan enabled

---

## 🛡️ Privacy & Cache

- **Local only** - graph builds on your machine
- **SHA256 cache** - only changed files re-extracted
- **No cloud** - NetworkX + Claude, all local
- **Persistent** - graph.json saved for future queries
- **Git hook optional** - disable if not needed

---

## 🪝 Git Integration

### Auto-update on Every Commit

```bash
graphify hook install
# Creates .git/hooks/post-commit

# After every commit:
# - Code files: fast AST-only rebuild (instant)
# - Docs/images: notify you to run --update (LLM pass)
```

Disable anytime:
```bash
graphify hook uninstall
```

---

## 🔗 Combine with Ruflo Agents

Ruflo agents can navigate the wiki:

```
Agent reads: graphify-out/wiki/index.md
Agent searches: graph.json for concepts
Agent asks: /graphify query "what needs testing?"

Result: Agents understand codebase structure automatically
```

---

## 📚 Advanced

### Export to Obsidian

```bash
/graphify . --wiki
# Creates: graphify-out/obsidian/

# Open in Obsidian:
# Obsidian → Open folder → graphify-out/obsidian
# Voilà: Your codebase as a knowledge vault
```

### Neo4j Export

```bash
/graphify . --neo4j
# Creates: graphify-out/cypher.txt

# Import to Neo4j:
# cat graphify-out/cypher.txt | neo4j-admin import
```

### MCP Server

```bash
/graphify . --mcp
# Starts: graphify MCP stdio server
# Agents can query graph via MCP tools
```

---

## 🚨 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Graphify not recognized** | Add Python Scripts to PATH: `%APPDATA%\Python\Python3xx\Scripts` |
| **Graph too large** | Run with `--mode shallow` for faster extraction |
| **Cache stale** | Delete `graphify-out/cache/` to force full rebuild |
| **Missing language** | Edit `.graphify.json` to add languages |

---

## ✨ Why Graphify for improvy_flutter?

1. **Onboard faster** - New devs see full structure instantly
2. **Reduce bugs** - Discover hidden dependencies before they break
3. **Plan features** - Find similar patterns, reuse existing solutions
4. **Debug faster** - Trace dependencies visually
5. **Scale teams** - Multiple agents see same codebase graph
6. **Document auto** - Wiki updates from code, not manually maintained

---

## 🎉 Next Steps

```bash
# 1. Run graphify
/graphify .

# 2. Open graph
open graphify-out/graph.html          # macOS
xdg-open graphify-out/graph.html       # Linux
start graphify-out/graph.html          # Windows

# 3. Read report
cat graphify-out/GRAPH_REPORT.md

# 4. Query graph
/graphify query "how do auth and IAP connect?"
/graphify path "AuthService" "RevenueCat"

# 5. Install git hook (optional)
graphify hook install

# Done! Graph updates automatically on commits.
```

**With 9Router + Ruflo + Graphify, you now have:**
- 💰 Token savings (9Router)
- 🤖 Agent orchestration + learning (Ruflo)
- 📊 Knowledge graph navigation (Graphify)

**Best toolkit for AI-powered development!** 🚀

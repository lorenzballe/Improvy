# 🚀 Complete AI Development Stack Guide

## Sistema Completo: 9Router + Ruflo + Graphify

Hai 3 tool complementari che lavorano insieme:

```
┌─────────────────────────────────────────────────────────────┐
│                   IMPROVY_FLUTTER PROJECT                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐        │
│  │   9ROUTER    │  │    RUFLO    │  │  GRAPHIFY    │        │
│  ├──────────────┤  ├─────────────┤  ├──────────────┤        │
│  │ • Token Save │  │ • Learning  │  │ • Mapping    │        │
│  │ • Free AI    │  │ • Agents    │  │ • Structure  │        │
│  │ • Fallback   │  │ • Memory    │  │ • Questions  │        │
│  └──────────────┘  └─────────────┘  └──────────────┘        │
│       ↓                  ↓                   ↓                │
│    Budget          Automation          Knowledge             │
│   Optimization     & Learning          Graph                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Cosa Fa Ognuno

### 1️⃣ 9ROUTER - Risparmio Token

**Cosa:** Middleware tra Claude Code e AI provider  
**Come:** Comprime tool output (git diff, grep, ls)  
**Beneficio:** 20-40% meno token + free models fallback

```
Claude Code
    ↓
9Router (comprime + routing)
    ↓
├─→ Claude API (subscription)
├─→ GLM 4 ($0.6/1M) ← se quota esaurita
└─→ Kiro AI (FREE unlimited) ← se budget finito
```

**Quando usare:**
- Tutti i giorni (sempre attivo, trasparente)
- Riduce costi automaticamente

---

### 2️⃣ RUFLO - Automazione & Learning

**Cosa:** Agent orchestration system  
**Come:** 100+ agenti specializzati + self-learning memory  
**Beneficio:** Task simili diventano 30-40% più veloci

```
Task 1: Implement auth
  Agents: CodeReviewer + TestGenerator + SecurityAuditor
  Memory: Salva pattern + solutions + trajectories
    ↓
Task 2: Implement payment (simile a auth)
  AgentDB search: Trova pattern da Task 1
  Agents: Riusano cached solutions
  Result: 30-40% più veloce!
```

**Quando usare:**
- Per task complessi/ricorrenti
- Multi-agenti coordination
- Feature planning con goal planning

---

### 3️⃣ GRAPHIFY - Knowledge Graph

**Cosa:** Mappa interattiva della struttura del codebase  
**Come:** Estrae concetti da code, docs, immagini  
**Beneficio:** Naviga codebase senza leggerlo tutto

```
Primo run: /graphify .
  ↓
Crea: graph.html (interattivo) + graph.json (persistente)
  ↓
Query: "what connects auth to IAP?"
  ↓
Risposta: Visualizza percorso + spiegazione
  ↓
Auto-sync: Git hook aggiorna grafo dopo ogni commit
```

**Quando usare:**
- Onboarding nuovi dev
- Planning features
- Debugging dependencies
- Scopri connessioni nascoste

---

## 📊 Workflow Completo (Esempio)

### Scenario: Implementare "Playlist Support" Feature

#### PASSO 1: Capire la struttura (GRAPHIFY)

```bash
# Apri Graphify
./scripts/run-graphify.ps1
# Scegli: 1) Estrai il grafo (standard)

# Quando finisce
open graphify-out/graph.html
# Clicca intorno, capisci:
#   - AudioService → MusicPlayer → Database
#   - RevenueCat → Playlist (feature locked?)
#   - Animation integration

# Leggi report
cat graphify-out/GRAPH_REPORT.md
# Ti dice: "Playlist feature requires AudioService refactor"
```

#### PASSO 2: Pianificare con RUFLO

```bash
# In Claude Code, digita:
/goal "Implement Playlist support with tests and PR"

# Ruflo (GOAP planner) decompone:
Preconditions:
  - AudioService refactored
  - Database schema updated
  - IAP check for premium

Actions:
  1. Create Playlist model (reuse from graph)
  2. Update AudioService (agents find similar patterns)
  3. Generate tests (testgen agent)
  4. Security audit (security agent)
  5. Update docs (docs agent)

# Ruflo assegna agenti + esegue in parallelo
```

#### PASSO 3: Eseguire con Claude Code + 9ROUTER

```bash
# Avvia dev session
# 9Router è SEMPRE attivo in background

# Digita normalmente in Claude Code
# 9Router fa:
#   ✓ Comprime output git diff (40% token savings)
#   ✓ Se esaurisce crediti Claude → Fallback a GLM
#   ✓ Se budget finito → Fallback a Kiro AI FREE
#   ✓ Tu continui a codificare senza interruzioni

# Mentre sviluppi, Ruflo background workers:
#   ✓ Generano test (testgen agent)
#   ✓ Fanno security audit (security agent)
#   ✓ Scrivono docs (docs agent)
#   ✓ Ottimizzano performance (optimizer agent)
```

#### PASSO 4: Push & Update Graph

```bash
git commit -m "feat: Add Playlist support"
# Graphify git hook runs automatically
#   ✓ Rebuilds graph.json (AST-only, fast)
#   ✓ Shows new connections
#   ✓ Updates god_nodes.md

# Ruflo agents vedono nuova struttura
#   ✓ Memory aggiornata
#   ✓ Prossimi task imparano da questo
```

---

## 💡 Workflow Giorno Dopo Giorno

### Mattina: Pianificazione

```
1. Apri Claude Code
   → 9Router è già attivo (trasparente)

2. Digita un goal
   /goal "implement next feature"
   → Ruflo decompone in steps + assegna agenti

3. Opzionale: Esplora grafo
   /graphify query "what changed?"
   → Vedi nuovi pattern da commit di ieri
```

### Durante il Giorno: Sviluppo

```
1. Scrivi normalmente
   → 9Router comprime output automaticamente
   → Token savings 20-40% transparente

2. Ruflo lavora in background
   → Agenti generano test mentre codifichi
   → Security audit mentre fai git push
   → Docs aggiornate automaticamente

3. Se task simile a uno passato
   → Ruflo trova pattern in memory
   → Suggerisce soluzione cached
   → 30-40% più veloce
```

### Fine Giorno: Review & Commit

```
1. Commit
   → Graphify git hook aggiorna grafo
   → Ruflo impara dai risultati
   → Memory si arricchisce

2. Opzionale: Controlla progress
   /memory-search "playlist implementation"
   → Vedi cosa gli agenti imparato
```

---

## 🎯 Modelli di Utilizzo

### Modello 1: Token Saver (PASSIVO)

```
Scenario: Vuoi solo risparmiare token
Setup:
  ✓ 9Router attivo (default)
  ✗ Ruflo disabled
  ✗ Graphify disabled

Risultato: 20-40% token savings, zero configurazione
```

### Modello 2: Auto-Coding (ATTIVO)

```
Scenario: Vuoi agenti che codificano mentre dormi
Setup:
  ✓ 9Router attivo (budget control)
  ✓ Ruflo attivo (autopilot mode)
  ✓ Graphify attivo (agents navigation)

In action:
  1. Digita goal
  2. Ruflo agenti lavorano in parallelo
  3. Commit automatici
  4. Graphify aggiorna grafo
  5. Tu rileggi e approvi

Risultato: 70% feature time ridotto
```

### Modello 3: Team Collaboration (SCALATO)

```
Scenario: Team di 3+ developer
Setup:
  ✓ 9Router (shared budget)
  ✓ Ruflo (agenti coordinati)
  ✓ Graphify + federation (cross-machine)

Workflow:
  Dev A: Implementa auth
    → Agenti salvano pattern + solution
  
  Dev B: Implementa payment (simile)
    → Agenti ritrovano pattern da A
    → 40% più veloce
  
  Dev C: Ottimizza performance
    → Graphify mostra bottleneck
    → Agenti suggeriscono fix

Risultato: Team sincronizzato, zero merge conflicts
```

---

## 🔧 Setup Iniziale (5 minuti)

### Step 1: Avvia 9Router

```bash
9router
# → Dashboard su http://localhost:20128
# → Connetti provider gratuito (Kiro AI)
# → Copia API Key

# Configura Claude Code
# Settings → Custom endpoint
# http://localhost:20128/v1
# API Key: [copia]
```

### Step 2: Inizializza Ruflo

```bash
npx ruflo init wizard
# → Crea .claude/, .claude-flow/, CLAUDE.md

claude mcp add ruflo -- npx ruflo mcp start
# → Registra MCP server

# Riavvia Claude Code
```

### Step 3: Prepara Graphify

```bash
pip install graphifyy  # Già fatto

./scripts/run-graphify.ps1
# Scegli: 1) Estrai il grafo

# Quando finisce:
# • graphify-out/graph.html (apri nel browser)
# • graphify-out/GRAPH_REPORT.md (leggi insights)
```

---

## 📈 Cost Breakdown Esperato

### Senza Stack
- Claude API: $10-50/month per dev
- Manuale testing: 2h/day
- Debugging: 1h/day
- **Total: $50/month + 15h/week**

### Con Stack (9Router + Ruflo + Graphify)
- 9Router: $0-10/month (fallback a free)
- Ruflo: $0 (local, uses your Claude budget)
- Graphify: $0 (local, no API calls)
- Auto testing: -80% time
- Auto debugging: -60% time
- **Total: $0-10/month + 6h/week (60% time saved)**

---

## 🚀 Comandi Rapidi

### 9Router
```bash
9router                          # Dashboard
curl localhost:20128/v1/models   # Verifica connection
```

### Ruflo
```bash
/spawn-agent CodeReviewer        # Lancia agente
/memory-search "flutter"         # Cerca in memory
/goal "ship feature X"           # GOAP planning
/swarm-init                      # Multi-agent task
/agent-list                      # Vedi agenti attivi
```

### Graphify
```bash
/graphify .                      # Estrai grafo
graphify query "what connects X to Y?"
graphify path "Node1" "Node2"
graphify hook install            # Auto-update on commit
./scripts/run-graphify.ps1       # Menu interattivo
```

---

## 🎯 Checklist Iniziale

- [ ] 9Router installato e attivo (`9router` running)
- [ ] 9Router connesso a Claude Code (custom endpoint)
- [ ] Ruflo inizializzato (`npx ruflo init wizard`)
- [ ] Ruflo registrato come MCP (`claude mcp add ruflo`)
- [ ] Claude Code riavviato
- [ ] Graphify installato (`pip install graphifyy`)
- [ ] Primo grafo estratto (`/graphify .`)
- [ ] graph.html visualizzato nel browser
- [ ] Git hook Graphify installato (`graphify hook install`)

---

## 💡 Pro Tips

### Tip 1: Usa 9Router per Research
```
Quando cerchi nuove librerie/pattern:
  → 9Router riduce token 40%
  → Accedi a multiple providers
  → Se uno lento, fallback automatico
```

### Tip 2: Ruflo Memory per Patterns
```
Primo task: Nota i pattern (slow)
Secondo task (simile): Agenti trovano pattern
  → 30-40% più veloce
  → After 10 tasks: +100% velocity
```

### Tip 3: Graphify per Onboarding
```
Nuovo dev arriva:
  1. /graphify . (estrai grafo)
  2. open graphify-out/graph.html (explorer)
  3. cat graphify-out/GRAPH_REPORT.md (read)
  4. → 2 ore → 30 minuti capire struttura!
```

### Tip 4: Git Hook Automation
```
graphify hook install
  ✓ Grafo si aggiorna ogni commit
  ✓ Ruflo agenti vedono nuova struttura
  ✓ Nessun overhead, tutto automatico
```

### Tip 5: Combine for Maximum Impact
```
Feature Complex (multi-agent, tempo critico):

1. /goal "ship this feature" (Ruflo)
2. Ruflo assegna 4 agenti in parallelo
3. 9Router comprime output (40% token save)
4. Graphify mostra progress in real-time
5. Auto-tests/docs/security check
6. Result: 70% time saved + higher quality
```

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| Claude Code non vede 9Router | Riavvia Claude Code, verifica endpoint `localhost:20128/v1` |
| Ruflo agenti non rispondono | `ruflo daemon status`, `ruflo daemon restart` |
| Graphify estrazione lenta | Usa `--mode shallow` per veloce, `--mode deep` per comprehensive |
| Memoria Ruflo non persiste | Verifica `.claude-flow/memory/` cartella esiste |
| Git hook non funziona | `graphify hook install` di nuovo, check `.git/hooks/post-commit` |

---

## 📚 Guida per Ogni Strumento

- **9Router dettagli** → [9ROUTER_GUIDE.md](9ROUTER_GUIDE.md)
- **Ruflo dettagli** → [RUFLO_GUIDE.md](RUFLO_GUIDE.md)
- **Graphify dettagli** → [GRAPHIFY_GUIDE.md](GRAPHIFY_GUIDE.md)

---

## ✨ What You've Built

```
improvy_flutter è adesso equipaggiato con:

💰 Token Savings (9Router)
  ↓
🤖 Agent Automation (Ruflo)
  ↓
📊 Knowledge Mapping (Graphify)
  ↓
🚀 AI-Powered Development
```

**Risultato:** Sviluppo 60-70% più veloce, qualità più alta, costi ridotti.

---

## 🎉 Prossimi Step

1. **Avvia i 3 tool:**
   ```bash
   # Terminal 1
   9router
   
   # Terminal 2
   ruflo daemon start
   
   # Terminal 3
   ./scripts/run-graphify.ps1 → scegli 1 (estrai)
   ```

2. **Configura Claude Code:**
   - 9Router endpoint: `localhost:20128/v1`
   - Ruflo MCP: Registrato ✓
   - Riavvia Claude Code

3. **Prova il workflow:**
   ```
   /goal "implement a small feature"
   → Ruflo decompone
   → Agenti lavorano
   → 9Router risparmia token
   → Graphify traccia struttura
   ```

4. **Monitora il progresso:**
   ```bash
   /memory-search "feature X"
   /graphify query "what's the impact?"
   ruflo logs --follow
   ```

**Tu adesso sei equipaggiato per AI-powered development!** 🚀

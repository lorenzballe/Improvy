# Ruflo Integration Guide

## 📌 Cosa è Ruflo?

**Ruflo** è un **agent meta-harness** — un sistema di orchestrazione intelligente che dà a Claude Code una "sistema nervoso" con:

- 🤖 **100+ agenti specializzati** (coding, testing, security, docs, architecture)
- 🧠 **Self-learning** - Gli agenti imparano dai tuoi pattern di coding e ricordano tra le sessioni
- 💾 **Vector memory persistente** (AgentDB + HNSW) - Ricorda soluzioni passate e le riusa
- 🐝 **Swarm coordination** - Multipli agenti collaborano come un team
- 🌐 **Agent federation** - Agenti su diverse macchine/team comunicano in sicurezza
- ⚡ **12 background workers** - Audit, testing, docs, optimization - tutto automatico
- 🎯 **Goal planner (GOAP)** - Descrivi un goal in inglese, Ruflo pianifica e lo esegue
- 💬 **Web UI** a [flo.ruv.io](https://flo.ruv.io/) - Chat multi-modello con MCP tools
- 📊 **Observatory** - Token tracking, cost alerts, metrics
- 🛡️ **Security harness** - AIDefence, PII detection, CVE scanning

## 🚀 Quick Start (5 minuti)

### 1. Installazione
```bash
npm install -g ruflo@latest
```

### 2. Inizializzazione nel tuo progetto
```bash
# Interactive wizard (recommended)
npx ruflo init wizard

# Oppure quick mode
npx ruflo init
```

Questo crea:
- `.claude/` - Configurazione per Claude Code
- `.claude-flow/` - Cache e memoria degli agenti
- `CLAUDE.md` - Guida e istruzioni per gli agenti
- Hooks per auto-routing dei task

### 3. Registra Ruflo come MCP server in Claude Code

```bash
# Aggiungi Ruflo come MCP server
claude mcp add ruflo -- npx ruflo mcp start
```

Oppure manually in `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "ruflo": {
      "command": "npx",
      "args": ["ruflo", "mcp", "start"]
    }
  }
}
```

### 4. ✅ Fatto!

Claude Code adesso ha accesso a:
- 100+ agenti specializzati
- Self-learning memory
- Swarm coordination tools
- Goal planning
- Code review automation
- Test generation
- Security scanning

---

## 💡 Come Usare Ruflo

### Opzione A: Comandi Slash (Claude Code UI)

Nel prompt di Claude Code, usa i comandi Ruflo:

```
/spawn-agent CodeReviewer
  → Avvia un agent specializzato in code review

/memory-search "routing implementation"
  → Cerca nella memoria dei task passati

/swarm-init
  → Coordina multipli agenti per un task complesso

/goal "ship the auth refactor with tests and a PR"
  → Ruflo decompone il goal in steps e assegna agli agenti
```

### Opzione B: Self-Learning Loop (Automatico)

Dopo init, Ruflo funziona **completamente in background**:

```
Mentre codifichi normalmente:
  1. Ogni task va allo scheduler
  2. I background workers:
     - Analizzano il pattern
     - Cercano soluzioni simili nella memory
     - Generano test se mancano
     - Auditano per security
  3. Gli agenti imparano dai risultati
  4. Prossimi task simili sono più veloci
```

### Opzione C: Web UI Chat

Vai a **[flo.ruv.io](https://flo.ruv.io/)** (hosted) oppure self-host:

- Chat con qualsiasi modello (Claude, GPT, Gemini, Qwen, local LLMs)
- Chiama i 210+ MCP tools di Ruflo direttamente
- Memory persistente (ricorda i tuoi preferiti)
- Esecuzione parallela di tool

Esempio:
```
User: "Find all security issues in improvy_flutter"

RuFlo (parallel):
  [Tool 1] security_audit → scans codebase
  [Tool 2] cve_scanner → checks deps
  [Tool 3] pii_detector → flags sensitive data
  [Tool 4] path_traversal_check → tests inputs

Result: Structured security report
```

### Opzione D: Goal Planner UI

Vai a **[goal.ruv.io](https://goal.ruv.io/)**:

```
Goal: "ship the auth refactor with tests and a PR"

RuFlo (A* planning):
  Preconditions:
    - Branch exists
    - Tests passing
    - Docs updated
  
  Actions:
    1. Create feature branch
    2. Refactor auth module
    3. Generate tests
    4. Run security audit
    5. Push + open PR
    6. Request review
  
  Live agent dashboard: [View progress]
```

---

## 🎯 Plugin System (35 plugins built-in)

### Core & Orchestration
- `ruflo-core` - Foundation server
- `ruflo-swarm` - Multi-agent coordination
- `ruflo-autopilot` - Autonomous loop
- `ruflo-federation` - Cross-machine agents
- `ruflo-workflows` - Reusable task templates

### Memory & Intelligence
- `ruflo-rag-memory` - Smart retrieval (hybrid search + graph)
- `ruflo-intelligence` - Self-learning from past tasks
- `ruflo-agentdb` - Vector memory with HNSW
- `ruflo-ruvector` - GPU-accelerated search

### Code Quality
- `ruflo-testgen` - Auto-generate missing tests
- `ruflo-browser` - Playwright automation
- `ruflo-jujutsu` - Git diff analysis + risk scoring
- `ruflo-docs` - Auto-generate documentation

### Security
- `ruflo-security-audit` - Vulnerability scanning
- `ruflo-aidefence` - Prompt injection blocking, PII detection

### DevOps
- `ruflo-observability` - Logs, traces, metrics
- `ruflo-cost-tracker` - Token budget tracking
- `ruflo-migrations` - Safe DB schema changes

### Domain-Specific
- `ruflo-neural-trader` - AI trading (4 agents, backtesting)
- `ruflo-goals` - Goal decomposition with GOAP

**Installa un plugin:**
```bash
ruflo plugin install ruflo-testgen
# Adesso /spawn-agent TestGenerator è disponibile
```

---

## 📊 Architecture

```
Your Claude Code
        |
        v
  [Hooks System]  ← Auto-routes tasks
        |
        v
  [Ruflo MCP Server] ← 210+ tools
        |
   +----+-----+----+-----+
   |    |     |    |     |
   v    v     v    v     v
Router Agents Memory Swarm Federation
   |    |     |    |     |
   +----+-----+----+-----+
        |
        v
  [Learning Loop]  ← Self-improves
```

### Self-Learning Flow

1. **Task comes in** → Ruflo extracts context
2. **Check memory** → Search AgentDB for similar patterns (HNSW)
3. **Route to agent** → Pick best agent (or spawn new one)
4. **Execute** → Agent runs with MCP tools
5. **Learn** → Trajectory + outcome saved to memory
6. **Next task** → Similar tasks retrieve cached solutions (20-40% faster)

---

## 🛡️ Security & Compliance

### Built-in Safeguards

| Feature | What it does |
|---------|------------|
| **AIDefence** | Blocks prompt injection, detects jailbreaks |
| **PII Detection** | 14 types: SSN, email, credit card, API keys, etc. |
| **Path traversal** | Blocks `../../../etc/passwd` attacks |
| **CVE Scanner** | Auto-checks npm dependencies |
| **Federation trust** | Zero-trust identity + mTLS + ed25519 |

### Compliance Modes

```bash
ruflo config set --compliance HIPAA
  # Auto-scrubs HIPAA-sensitive data, full audit trail

ruflo config set --compliance GDPR
  # Manages personal data, right-to-be-forgotten, consent logs
```

---

## 🔧 Configuration

### `.claude/ruflo.config.json`

```json
{
  "server": {
    "port": 5002,
    "host": "127.0.0.1"
  },
  "learning": {
    "enabled": true,
    "memory_backend": "agentdb",
    "similarity_threshold": 0.85
  },
  "background_workers": {
    "audit": true,
    "testgen": true,
    "docs": true,
    "optimize": true
  },
  "federation": {
    "enabled": false,
    "trust_mode": "zero-trust",
    "pii_policy": "redact"
  },
  "security": {
    "aidefence": true,
    "pii_detection": true,
    "cve_scanning": true
  },
  "cost_tracking": {
    "enabled": true,
    "budget_monthly": 100,
    "alert_threshold_percent": 80
  }
}
```

---

## 📚 Common Workflows

### 1️⃣ Code Review + Tests + Docs (Auto)

```
Normal: code → manual review → write tests → update docs
Ruflo:  code → [4 parallel agents]
          1. CodeReviewer (agent-code-review)
          2. TestGenerator (testgen)
          3. DocWriter (ruflo-docs)
          4. SecurityAuditor (security-audit)
        → All done simultaneously
```

### 2️⃣ Multi-Agent Bug Hunt

```
/spawn-swarm BugHunt
  agent-static-analysis   → Find code smells
  agent-dependency-check  → Check for CVEs
  agent-performance       → Profile hotspots
  agent-security          → Scan for vulns
  
→ Report merged, deduped, prioritized
```

### 3️⃣ Self-Improving Feature Development

```
Task 1: Implement auth refactor
  Agents: ArchitectureAgent, CodeAgent, TestAgent
  Learn: Patterns, tradeoffs, test coverage %
  
Task 2: Implement payment flow
  AgentDB search: "refactor patterns" (from task 1)
  Agents: Start with cached solutions
  Result: 30% faster, same quality
```

### 4️⃣ Goal-Based Planning

```
/goal "Ship the mobile app v1.0 with real user auth and IAP"

GOAP planner decomposes into:
  Phase 1: Architecture
    → Set up RevenueCat IAP
    → Design auth flow
  
  Phase 2: Implementation
    → Implement auth (agents reuse from memory)
    → Integrate IAP (agents find best patterns)
  
  Phase 3: Testing & Deployment
    → Generate tests
    → Security audit
    → Build & sign app
    → Upload to TestFlight
  
→ Each phase runs agents in parallel
```

---

## 🚨 Troubleshooting

| Problem | Solution |
|---------|----------|
| **MCP server not connecting** | `claude mcp add ruflo -- npx ruflo mcp start` puis restart Claude Code |
| **Memory not persisting** | Check `.claude-flow/` folder exists, AgentDB running |
| **Agents not learning** | Verify `ruflo config get --learning.enabled` = true |
| **Background workers silent** | Check logs: `ruflo logs --follow` |
| **Federation auth fails** | Re-run: `ruflo federation init` |

**Debug mode:**
```bash
ruflo config set --debug true
ruflo logs --follow
# → See detailed agent decisions, memory searches, etc
```

---

## 🌐 Resources

| Resource | URL |
|----------|-----|
| GitHub | https://github.com/ruvnet/ruflo |
| Website | https://flo.ruv.io (Web UI) |
| Goal Planner | https://goal.ruv.io |
| Docs | https://github.com/ruvnet/ruflo/tree/main/docs |
| Plugin Marketplace | https://github.com/ruvnet/ruflo/tree/main/plugins |
| Benchmark | `scripts/benchmark-intelligence.mjs` |

---

## ✨ Why Ruflo for improvy_flutter?

1. **Self-learning coding** - Agents learn your Flutter patterns and reuse solutions
2. **Async automation** - Background workers handle boring stuff (tests, docs, audits)
3. **Quality gates** - Every commit runs through security + performance checks
4. **Faster iterations** - Memory makes similar tasks 30-40% faster
5. **Scalable coordination** - If you hire team members, federation lets their agents collaborate
6. **Built-in compliance** - HIPAA/GDPR modes for app with sensitive user data (auth, payments)

---

## 🎉 Next Steps

```bash
# 1. Init Ruflo
npx ruflo init wizard

# 2. Register MCP
claude mcp add ruflo -- npx ruflo mcp start

# 3. Restart Claude Code

# 4. Try a command
/spawn-agent CodeReviewer
# → Reviews your current changes

# 5. Check memory
/memory-search "flutter widget"
# → Recalls similar patterns from past tasks

# 6. Plan a goal
/goal "implement chromatic card v1.0"
# → Ruflo creates A* plan + assigns agents
```

Tutto è **automatico** dopo questo punto. Continua a codificare normalmente. Ruflo migliora in background. 🚀

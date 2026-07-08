# Claude Code Configuration for Improvy Flutter

## 🚀 Quick Start

This project is equipped with **AI development toolkit** (9Router + Ruflo + Graphify).

### ⚡ First Time Setup (5 minutes)

1. **9Router** (Token Saver)
   ```bash
   9router
   # → Opens http://localhost:20128/dashboard
   # → Connect Kiro AI (FREE, no signup needed)
   # → Copy API Key
   ```

2. **Configure Claude Code Endpoint**
   - Settings → Search "Custom Provider"
   - Endpoint: `http://localhost:20128/v1`
   - API Key: [paste from 9Router dashboard]
   - Model: `kr/claude-sonnet-4.5`

3. **Ruflo** (Agent Orchestration)
   ```bash
   npx ruflo init wizard  # Already done, but run to verify
   claude mcp add ruflo -- npx ruflo mcp start
   # → Restart Claude Code
   ```

4. **Graphify** (Knowledge Graph)
   ```bash
   pip install graphifyy  # Already done
   /graphify .           # Use in Claude Code to map codebase
   ```

### ✅ Verify Setup
```
/memory-search "test"     # Ruflo memory working
/graphify query "test"    # Graphify working
curl localhost:20128/v1/models  # 9Router working
```

---

## 🎯 Available Commands

### In Claude Code Prompt

**Ruflo Commands**:
```
/goal "implement feature X"
/spawn-agent CodeReviewer
/spawn-swarm TaskName
/memory-search "pattern"
/agent-list
```

**Graphify Commands**:
```
/graphify .                              # Map codebase
/graphify query "what connects A to B?"
/graphify path "NodeA" "NodeB"
```

---

## 🔄 Startup Sequence

### Option A: Manual (Recommended First Time)

**Terminal 1** - 9Router (Token Saver):
```bash
9router
# Keep this running - it's your API gateway
```

**Terminal 2** - Ruflo (Agent Orchestration):
```bash
ruflo daemon start
# Runs in background, auto-manages agents
```

**Terminal 3** - Claude Code:
```bash
# Just use Claude Code normally
# 9Router + Ruflo work transparently in background
```

### Option B: Automated Startup (All Platforms)

#### **Windows PowerShell**
```powershell
# Run all 3 tools simultaneously
.\scripts\startup-all.ps1
```

#### **macOS/Linux**
```bash
# Run all 3 tools simultaneously
./scripts/startup-all.sh
```

#### **Individual Tool Startup**

Windows:
```powershell
.\scripts\start-9router.ps1
.\scripts\start-ruflo.ps1
.\scripts\run-graphify.ps1
```

Unix:
```bash
./scripts/start-9router.sh
./scripts/start-ruflo.sh
./scripts/run-graphify.sh
```

---

## 📊 Tool Reference

### 9Router (localhost:20128)
- **Purpose**: Token compression + multi-provider routing
- **Status**: Global install, run with `9router`
- **Dashboard**: http://localhost:20128/dashboard
- **API**: http://localhost:20128/v1 (for Claude Code)
- **Benefits**: 20-40% token savings, free model fallback
- **Guide**: See `9ROUTER_GUIDE.md`

### Ruflo (Local MCP Server)
- **Purpose**: Agent orchestration + self-learning
- **Status**: Installed, MCP registered with Claude Code
- **Daemon**: `ruflo daemon start/stop`
- **Commands**: `/goal`, `/spawn-agent`, `/memory-search`
- **Benefits**: 30-70% speed improvement, self-learning memory
- **Guide**: See `RUFLO_GUIDE.md`

### Graphify (Local CLI)
- **Purpose**: Knowledge graph mapping
- **Status**: Installed locally
- **Command**: `/graphify .` in Claude Code
- **Output**: `graphify-out/` (graph.html, graph.json, GRAPH_REPORT.md)
- **Benefits**: 71.5x token reduction on large corpus
- **Guide**: See `GRAPHIFY_GUIDE.md`

---

## 🔧 Configuration Files

### 9Router
- **Settings**: Not needed (cloud-based dashboard)
- **API Key**: Configure in Claude Code settings
- **Endpoint**: `http://localhost:20128/v1`

### Ruflo
- **Config**: `.claude/ruflo.config.json`
- **Memory**: `.claude-flow/memory/` (AgentDB)
- **MCP**: Registered in Claude Code

### Graphify
- **Config**: `.graphify.json` (optional)
- **Output**: `graphify-out/` (auto-created)
- **Cache**: `graphify-out/cache/` (SHA256)

---

## 📈 Daily Workflow

### Morning (5 min setup)
```bash
# Terminal 1: Start 9Router (keep running)
9router

# Terminal 2: Start Ruflo daemon (keep running)
ruflo daemon start

# Terminal 3: Open Claude Code
# → Tools ready automatically!
```

### During Work (Transparent)
```
# In Claude Code, use normally:
/goal "implement feature X"
→ Ruflo plans + assigns agents
→ 9Router compresses output (-40% token)
→ You write code, agents help in background
```

### Before Commit
```bash
# Optional: Update knowledge graph
/graphify . --update
# → Graphify learns new patterns
# → Agents see updated structure
```

---

## ⚠️ Troubleshooting

### 9Router Not Responding
```bash
# Check if running
curl http://localhost:20128/v1/models

# Restart
pkill -f 9router
9router
```

### Ruflo Agents Not Responding
```bash
# Check daemon status
ruflo daemon status

# Restart
ruflo daemon stop
ruflo daemon start

# View logs
ruflo logs --follow
```

### Graphify Not Found
```bash
# Reinstall
pip install --upgrade graphifyy

# Verify
graphify --version
```

### Claude Code Not Seeing 9Router
```bash
# Restart Claude Code completely (close + reopen)
# Verify endpoint in settings: http://localhost:20128/v1
# Check API key from 9Router dashboard
```

---

## 🚀 Quick Command Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `9router` | Start token saver | `9router` |
| `ruflo daemon start` | Start agent system | `ruflo daemon start` |
| `/goal "..."` | Plan with agents | `/goal "implement auth"` |
| `/spawn-agent Name` | Launch specific agent | `/spawn-agent CodeReviewer` |
| `/memory-search "..."` | Query learned patterns | `/memory-search "flutter"` |
| `/graphify .` | Map codebase | `/graphify .` |
| `/graphify query "..."` | Query knowledge graph | `/graphify query "what connects X to Y?"` |
| `./scripts/startup-all.sh` | Auto-start all tools | `./scripts/startup-all.sh` |

---

## 📚 Documentation

- **Quick Start**: This file (CLAUDE.md)
- **Complete Guide**: `COMPLETE_STACK_GUIDE.md` (workflows + examples)
- **9Router Details**: `9ROUTER_GUIDE.md`
- **Ruflo Details**: `RUFLO_GUIDE.md`
- **Graphify Details**: `GRAPHIFY_GUIDE.md`
- **App Status**: `DEPLOYMENT_READY.md`
- **Final Summary**: `FINAL_STATUS.md`

---

## 🔐 Environment Variables (Optional)

Create `.env` file in project root:
```bash
# Ruflo
RUFLO_DEBUG=false
RUFLO_LOG_LEVEL=info

# Graphify
GRAPHIFY_MODE=standard
GRAPHIFY_CACHE=true

# 9Router (not needed - cloud dashboard)
```

---

## ✨ Pro Tips

1. **Keep 9Router running 24/7** - It's lightweight and makes everything faster
2. **Use `/goal` instead of asking** - Ruflo plans automatically
3. **Run `/graphify . --update` before big refactors** - Graph learns new patterns
4. **Check `/memory-search` for past solutions** - Agents reuse what worked
5. **Monitor `ruflo logs --follow`** - See agents working in background

---

## 🎯 Next Steps

1. ✅ Install all tools (already done)
2. ✅ Configure Claude Code (done)
3. ✅ Verify setup (run verification commands above)
4. 🚀 **Start coding!** - Tools work transparently

---

**Status**: ✅ Ready to use  
**Last Updated**: July 8, 2026  
**Owner**: Lorenzo Ballestrazzi

**Everything is configured. Just run the startup scripts and start using Claude Code normally!** 🚀

# Ruflo Technical Setup Guide

## Prerequisites

- Node.js 18+ (already installed)
- Claude Code (for MCP integration)
- npm (for global install)

## Installation

### Global Install
```bash
npm install -g ruflo@latest
```

### Project-Level Init

Run in your project directory (`improvy_flutter`):

```bash
# Option 1: Interactive wizard (recommended)
npx ruflo init wizard

# Option 2: Quick mode
npx ruflo init

# Option 3: Specific init paths
npx ruflo init --preset full    # Everything enabled
npx ruflo init --preset minimal # Minimal setup
npx ruflo init --preset security # Focus on security
```

### What Gets Created

After `ruflo init`, you'll have:

```
improvy_flutter/
├── .claude/
│   ├── ruflo.config.json       ← Main config
│   ├── agents.json             ← Agent definitions
│   ├── hooks.json              ← Auto-routing rules
│   └── skills/                 ← Agent skills
├── .claude-flow/
│   ├── memory/                 ← AgentDB storage
│   ├── cache/                  ← Trajectory cache
│   └── federation/             ← Trust data
├── CLAUDE.md                   ← Agent guidelines
└── ruflo.log                   ← Activity log
```

## MCP Server Registration

### In Claude Code

**Method 1: CLI**
```bash
claude mcp add ruflo -- npx ruflo mcp start
```

**Method 2: Manual (edit `~/.claude/settings.json`)**
```json
{
  "mcpServers": {
    "ruflo": {
      "command": "npx",
      "args": ["ruflo", "mcp", "start"],
      "disabled": false
    }
  }
}
```

**Verify connection:**
```bash
# In Claude Code, try:
/memory-search "test"
# Should return some results (or "no matches" if first run)
```

## Configuration

### Basic Config

Edit `.claude/ruflo.config.json`:

```json
{
  "app": {
    "name": "improvy_flutter",
    "type": "flutter_mobile",
    "repo": "https://github.com/lorenzobdev/improvy_flutter"
  },
  "server": {
    "port": 5002,
    "host": "127.0.0.1",
    "ssl": false
  },
  "memory": {
    "backend": "agentdb",
    "persist": true,
    "sync_interval_ms": 5000
  },
  "learning": {
    "enabled": true,
    "self_optimize": true,
    "pattern_detection": true,
    "trajectory_storage": "all"
  },
  "agents": {
    "auto_spawn": true,
    "concurrency": 4,
    "timeout_ms": 300000,
    "memory_per_agent_mb": 256
  },
  "background_workers": {
    "audit": true,
    "testgen": true,
    "docs": true,
    "optimize": true,
    "schedule": "interval",
    "interval_minutes": 15
  },
  "hooks": {
    "enabled": true,
    "auto_route": true,
    "events": ["code.change", "test.run", "commit.push"]
  },
  "federation": {
    "enabled": false,
    "peer_discovery": false,
    "trust_mode": "local"
  },
  "security": {
    "aidefence": true,
    "pii_detection": true,
    "pii_policy": "redact",
    "cve_scanning": true,
    "path_validation": true
  },
  "compliance": {
    "mode": "standard",
    "audit_log": true,
    "consent_required": false
  },
  "observability": {
    "logging": "standard",
    "metrics": true,
    "traces": false,
    "debug": false
  },
  "cost_tracking": {
    "enabled": true,
    "backend": "local",
    "budget_monthly_usd": 50,
    "alert_threshold_percent": 80
  }
}
```

### Plugins

Enable/disable plugins:

```bash
# List installed
ruflo plugin list

# Install
ruflo plugin install ruflo-testgen
ruflo plugin install ruflo-security-audit
ruflo plugin install ruflo-docs
ruflo plugin install ruflo-jujutsu

# Uninstall
ruflo plugin uninstall ruflo-testgen
```

### Environment Variables

```bash
# .env.ruflo (optional)
RUFLO_DEBUG=false
RUFLO_LOG_LEVEL=info
RUFLO_MEMORY_SYNC_MS=5000
RUFLO_AGENT_TIMEOUT_MS=300000
RUFLO_DISABLE_FEDERATION=true
```

## Startup

### Development

```bash
# Terminal 1: Start MCP server
npx ruflo mcp start

# Terminal 2: In Claude Code, use normally
# Ruflo works in background via MCP hooks
```

### Daemon Mode (Background)

```bash
# Start Ruflo as background service
ruflo daemon start

# Check status
ruflo daemon status

# View logs
ruflo logs --follow

# Stop
ruflo daemon stop
```

### Docker (Optional)

```bash
# Build Docker image
docker build -t improvy-ruflo -f Dockerfile.ruflo .

# Run
docker run -d \
  -p 5002:5002 \
  -v $(pwd)/.claude-flow:/app/.claude-flow \
  improvy-ruflo

# Logs
docker logs -f <container-id>
```

## Verification

### Health Check

```bash
# Test MCP connection
ruflo health check

# Expected output:
# ✓ MCP server running (port 5002)
# ✓ AgentDB initialized
# ✓ Memory backend online
# ✓ Federation disabled
# ✓ Security scanning active
```

### First Task

In Claude Code:

```
/memory-search "widget"
# Should show: "No matches in memory (new project)"

/spawn-agent CodeReviewer
# Should show: "Agent spawned with ID: agent_12345"

/agent-list
# Should show: List of available agents
```

## Troubleshooting

### MCP Server Not Connecting

```bash
# Check if Ruflo is running
ruflo daemon status

# Restart
ruflo daemon stop
ruflo daemon start

# Verify port
netstat -an | findstr 5002
# Should show: LISTENING 127.0.0.1:5002

# In Claude Code settings, verify:
# "ruflo" MCP server is enabled (not disabled: true)
```

### Memory Not Working

```bash
# Check AgentDB
ruflo memory health

# Rebuild memory index
ruflo memory rebuild

# Check stored items
ruflo memory list --all

# Clear memory (careful!)
ruflo memory clear
```

### Agents Not Running

```bash
# Check agent logs
ruflo agent logs --agent CodeReviewer

# Manually spawn (debug)
ruflo agent spawn --type CodeReviewer --debug

# Check concurrency limit
ruflo config get --agents.concurrency
# If too low (e.g., 1), increase:
ruflo config set --agents.concurrency 4
```

### High CPU/Memory Usage

```bash
# Check active agents
ruflo agent ps

# Kill specific agent
ruflo agent kill agent_12345

# Reduce concurrency
ruflo config set --agents.concurrency 2

# Reduce background workers
ruflo config set --background_workers.audit false
ruflo config set --background_workers.testgen false
```

### Daemon Won't Start

```bash
# Check logs
ruflo logs --error

# Try verbose mode
ruflo daemon start --verbose

# Reset
ruflo daemon reset
ruflo daemon start
```

## Security Hardening

### For Production/Team Use

```bash
# Enable all security
ruflo config set --security.aidefence true
ruflo config set --security.pii_detection true
ruflo config set --security.pii_policy redact
ruflo config set --security.cve_scanning true
ruflo config set --security.path_validation true

# Enable compliance
ruflo config set --compliance.mode HIPAA
# Or
ruflo config set --compliance.mode GDPR
# Or
ruflo config set --compliance.mode SOC2

# Enable audit logging
ruflo config set --compliance.audit_log true

# Disable federation (unless needed)
ruflo config set --federation.enabled false
```

### Monitoring

```bash
# Real-time metrics
ruflo metrics --live

# Token usage
ruflo cost-tracker show

# Agent performance
ruflo agent metrics

# Security incidents
ruflo security log --tail 50
```

## Uninstall

```bash
# Stop daemon
ruflo daemon stop

# Remove from npm
npm uninstall -g ruflo

# Clean local cache
rm -rf ~/.ruflo
rm -rf .claude-flow/

# Remove MCP registration
# Edit ~/.claude/settings.json and remove "ruflo" from mcpServers
```

## Next Steps

1. ✅ Install: `npm install -g ruflo@latest`
2. ✅ Init: `npx ruflo init wizard`
3. ✅ Register MCP: `claude mcp add ruflo -- npx ruflo mcp start`
4. ✅ Restart Claude Code
5. 🎯 Use: Try `/spawn-agent CodeReviewer`
6. 📚 Read: `RUFLO_GUIDE.md` for workflows

---

## Support

- GitHub Issues: https://github.com/ruvnet/ruflo/issues
- Documentation: https://github.com/ruvnet/ruflo/tree/main/docs
- Discord: Community server links in README

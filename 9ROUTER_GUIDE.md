# 9Router Integration Guide

## 📌 Cosa è 9Router?

**9Router** è uno smart router per LLM che:

- 💰 **Risparmia 20-40% di token** comprimendo automaticamente tool output (git diff, grep, ls, ecc)
- 🔀 **Instrada tra 40+ provider AI** (Claude, OpenAI, Gemini, GLM, MiniMax, ecc)
- ⚡ **Auto-fallback**: Subscription → Cheap → Free (zero downtime)
- 🎯 **Works with any AI code tool**: Claude Code, Cursor, Cline, Copilot, ecc
- 📊 **Dashboard web** per gestire provider, quota, API key

## 🚀 Quick Start (2 minuti)

### 1. Installa 9Router
```bash
npm install -g 9router
```

### 2. Avvia il Server
```bash
# Windows (PowerShell)
.\scripts\start-9router.ps1

# Mac/Linux
./scripts/start-9router.sh

# O semplicemente
9router
```

Apre automaticamente: **http://localhost:20128/dashboard**

### 3. Connetti un Provider GRATIS
Nel Dashboard → Providers:
- **Kiro AI** ✅ Unlimited Claude Sonnet/Opus (NO SIGNUP)
- **OpenCode Free** ✅ Modelli vari (NO SIGNUP)
- **Vertex AI** ✅ $300/mese Google credits

### 4. Configura Claude Code
Copia API Key dal Dashboard → API Keys, poi:

**`.claude/settings.local.json`** (o UI Settings):
```json
{
  "modelOptions": {
    "provider": "custom",
    "endpoint": "http://localhost:20128/v1",
    "apiKey": "[COPIA DA DASHBOARD]",
    "model": "kr/claude-sonnet-4.5"
  }
}
```

### 5. ✅ Fatto!
Claude Code usa ora 9Router con token saver automatico.

---

## 💡 Esempi di Modelli Gratuiti

```
Kiro AI (Unlimited, No Signup):
  kr/claude-sonnet-4.5      ⚡ Veloce, accurate
  kr/claude-opus-4.5        🔥 Più potente
  kr/claude-haiku-4.5       🚀 Velocissimo

OpenCode Free:
  [modelli vari]            ✅ No rate limits

Google Vertex ($300 credits/month):
  gemini-2.0-flash          🎯 Multimodal, veloce
  gemini-1.5-pro            💪 Più potente
```

---

## 🎯 Quando usare 9Router?

✅ **USA 9Router SE:**
- Usi Claude Code frequentemente e vuoi risparmiare
- Hai multiple AI code tools (Cursor, Cline, Copilot)
- Vuoi fallback automatico se esaurisci quota
- Stai lavorando con repo grandi (molto git diff/grep)

❌ **NON serve se:**
- Usi solo gli altri editor (non Claude Code)
- Hai budget illimitato per AI API
- Lavori offline

---

## 📊 Token Savings Example

**Senza 9Router (RTK disabled):**
```
git diff HEAD~5:
  Raw tokens: 1500

claude grep pattern:
  Raw tokens: 2000

Total: 3500 tokens/request
```

**Con 9Router (RTK auto-compression):**
```
git diff HEAD~5 (compresso):
  Tokens: 900 (40% saved)

claude grep pattern (compresso):
  Tokens: 1200 (40% saved)

Total: 2100 tokens/request
→ Saved: 40% per request ✅
```

Moltiplicato per 100+ requests = **GRANDI RISPARMI** 💰

---

## 🛠️ Troubleshooting

| Problema | Soluzione |
|----------|-----------|
| **Dashboard non si apre** | Verifica porta 20128: `netstat -an \| findstr 20128` |
| **Claude Code non connette** | Controlla API Key e endpoint: `curl http://localhost:20128/v1/models` |
| **Provider disconnesso** | Dashboard → Providers → Re-autentica |
| **RTK non comprime** | Settings → Enable RTK Token Compression |

---

## 📚 Configurazioni Avanzate

### Multi-Provider Fallback
```json
{
  "providers": [
    { "tier": 1, "provider": "claude-code-api", "budget": "$10/month" },
    { "tier": 2, "provider": "glm-4", "budget": "$5/month" },
    { "tier": 3, "provider": "kiro-ai", "budget": "unlimited" }
  ]
}
```
9Router passa automaticamente quando esaurisce il budget.

### Rate Limit Protection
```json
{
  "rateLimits": {
    "rpm": 60,              // Requests per minute
    "tpm": 100000,          // Tokens per minute
    "auto_throttle": true   // Rallenta se supera limite
  }
}
```

### Token Analyzer
Dashboard → Metrics → Vedi:
- Tokens risparmiati per request
- Quali tool comprimono più
- Storico utilizzo per provider

---

## 🌐 Links Utili

| Risorsa | URL |
|---------|-----|
| Website | https://9router.com |
| Dashboard | http://localhost:20128/dashboard |
| GitHub | https://github.com/decolua/9router |
| Docs | https://9router.com/docs |
| Community | Discord della comunità |

---

## 💬 Domande Frequenti

**Q: Funciona offline?**
A: No, ha bisogno di internet per connettere ai provider. Il routing locale funziona offline, ma senza AI.

**Q: Dati privati sul server 9Router?**
A: 9Router gira localmente sul tuo PC. I dati vanno ai provider che hai connesso (es. Claude API). Leggi la privacy di ogni provider.

**Q: Quanti account posso aggiungere?**
A: Illimitati. Utile per round-robin e multi-account fallback.

**Q: Compatibilità con IDE?**
A: **Claude Code** ✅, **Cursor** ✅, **Cline** ✅, **GitHub Copilot** ✅, **JetBrains** ✅, **VS Code Extensions** ✅

---

## 🎉 Pronto?

```bash
9router        # Avvia
# → Apri http://localhost:20128/dashboard
# → Connetti un provider gratuito
# → Copia API Key
# → Configura Claude Code (vedi sopra)
# → Profit! 🚀
```

Per aiuto dettagliato: Vedi `.claude/9ROUTER_SETUP.md`

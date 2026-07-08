# 🚀 9Router Setup Guide per Improvy Flutter

9Router è un **smart AI router** che riduce i costi di sviluppo con Claude Code, risparmiando **20-40% di token** e fornendo fallback automatico tra provider AI.

## ✅ Installazione

```bash
npm install -g 9router
```

## 🎯 Uso Rapido

### 1️⃣ Avvia 9Router
```bash
9router
```

Apre automaticamente: **http://localhost:20128/dashboard**

### 2️⃣ Connetti un Provider GRATIS (no signup)

Nel Dashboard:
1. Vai a **Providers**
2. Clicca **Connect** su uno dei provider gratuiti:
   - **Kiro AI** (Claude Sonnet unlimited, no auth)
   - **OpenCode Free** (modelli vari, no signup)
   - **Vertex AI** ($300 monthly credits)

### 3️⃣ Configura Claude Code

Nel tuo **Claude Code Settings** (in `.claude/settings.json` o UI):

```json
{
  "modelOptions": {
    "provider": "custom",
    "endpoint": "http://localhost:20128/v1",
    "apiKey": "[copia da 9Router Dashboard → API Keys]",
    "model": "kr/claude-sonnet-4.5"
  }
}
```

**Modelli disponibili via 9Router:**
- `kr/claude-sonnet-4.5` (Kiro AI - FREE)
- `kr/claude-opus-4.5` (Kiro AI - FREE)
- `kr/claude-haiku-4.5` (Kiro AI - FREE)
- `openai/gpt-4o` (se connesso)
- `gemini/gemini-2.0-flash` (se connesso)

### 4️⃣ RTK Token Saver (AUTOMATICO)

9Router comprime automaticamente i `tool_result` (output di git, grep, ls, ecc) riducendo i token:
- **Senza**: 1000 tokens per tool output
- **Con RTK**: 600-700 tokens (20-40% risparmio)

## 🔄 Fallback automatico

Se configuri più provider, 9Router passa automaticamente:

```
Tier 1 (Subscription): Claude Code API → esaurisce quota
    ↓
Tier 2 (Cheap): GLM 4 ($0.6/1M) → budget limit
    ↓
Tier 3 (Free): Kiro AI unlimited → sempre disponibile
```

## 📊 Dashboard Features

- **Quota Tracker**: Monitora crediti e rate limits per provider
- **Token Analyzer**: Vedi come RTK ha compresso i tuoi tool_result
- **API Keys**: Genera/revoca chiavi per Claude Code e altre tool
- **Multi-account**: Configura round-robin tra account dello stesso provider

## 🛠️ Troubleshooting

**Dashboard non si apre?**
```bash
# Verifica porta 20128
lsof -i :20128

# Restart
pkill -f 9router
9router
```

**Claude Code non connette?**
1. Verifica endpoint: `http://localhost:20128/v1` (deve essere raggiungibile)
2. Verifica API Key nel Dashboard → API Keys
3. Prova con `curl`:
   ```bash
   curl http://localhost:20128/v1/models
   ```

**Provider disconnesso?**
- Dashboard → Providers → Rivedi credenziali
- Alcuni provider gratuiti richiedono token di refresh mensili

## 💡 Pro Tips

- **Multi-tool Setup**: Usa 9Router per Claude Code, Cursor, Cline contemporaneamente (tutti risparmiano token)
- **Budget Control**: Imposta limiti di budget nel Dashboard per provider paid
- **Monitor Tab**: Guarda quali modelli usi più frequentemente e rimuovi quelli costosi

## 🌐 Risorse

- Website: https://9router.com
- Dashboard: http://localhost:20128/dashboard
- API Docs: http://localhost:20128/api/docs
- GitHub: https://github.com/decolua/9router

---

**Pronto a iniziare?** Esegui `9router` e poi configura Claude Code come sopra! 🎉

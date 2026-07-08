# 🚀 Auto-Startup Guide - AI Toolkit

## Cosa Succede

Una volta configurato, i 3 tool **partono automaticamente** al riavvio del PC:
- ✅ 9Router (Token Saver)
- ✅ Ruflo (Agent Orchestration)  
- ✅ Graphify (Knowledge Graph - on demand)

**Zero configurazione necessaria** - tutto funziona quando serve!

---

## ⚡ Quick Setup (Una sola volta)

### Windows
```powershell
.\scripts\install-autostart.ps1
```

### macOS
```bash
./scripts/install-autostart.sh
```

### Linux
```bash
./scripts/install-autostart.sh
```

---

## 📋 Cosa Fa Ogni Sistema

### **Windows (Task Scheduler)**

✅ **Installazione**:
```powershell
.\scripts\install-autostart.ps1
# → Crea un Windows Scheduled Task
# → Runs at system startup (admin level)
```

✅ **Automaticamente**:
- Al riavvio del PC, il task si avvia
- Esegue health-check.py
- Se i tool non sono running, li avvia
- Se sono già running, controlla e basta

✅ **Verificare**:
```powershell
# Vai a: Task Scheduler → Task Scheduler Library
# Cerca: "ImproveAIToolkitAutoStart"

# O da PowerShell:
Get-ScheduledTask -TaskName "ImproveAIToolkitAutoStart"
```

✅ **Rimuovere**:
```powershell
Unregister-ScheduledTask -TaskName "ImproveAIToolkitAutoStart" -Confirm:$false
```

---

### **macOS (Launchd)**

✅ **Installazione**:
```bash
./scripts/install-autostart.sh
# → Crea launchd agent in ~/Library/LaunchAgents/
# → Auto-loads at login
```

✅ **Automaticamente**:
- Al login, launchd avvia il servizio
- Controlla ogni 5 minuti se i tool sono running
- Se non sono running, li avvia
- Log salvati in ~/.improvy-ai-toolkit.log

✅ **Verificare**:
```bash
launchctl list | grep ai-toolkit
# Oppure:
tail -f ~/.improvy-ai-toolkit.log
```

✅ **Rimuovere**:
```bash
launchctl unload ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
rm ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
```

---

### **Linux (Systemd)**

✅ **Installazione**:
```bash
./scripts/install-autostart.sh
# → Crea systemd timer in ~/.config/systemd/user/
# → Auto-enables at boot
```

✅ **Automaticamente**:
- Al boot, systemd timer si avvia (30s delay)
- Controlla ogni 5 minuti se i tool sono running
- Se non sono running, li avvia
- Log in journalctl

✅ **Verificare**:
```bash
systemctl --user status improvy-ai-toolkit.timer
# Oppure:
journalctl --user -u improvy-ai-toolkit.service
```

✅ **Rimuovere**:
```bash
systemctl --user disable improvy-ai-toolkit.timer
```

---

## 🔧 Come Funziona

### 1. **Health Check Script** (`health-check.py`)

```python
# Fa questo ogni volta che gira:
1. ✓ Controlla se 9Router è running (porta 20128)
2. ✓ Controlla se Ruflo daemon è active
3. ✓ Controlla se Graphify è installato
4. ✓ Se qualcosa non è running, lo avvia
5. ✓ Esce silenziosamente
```

### 2. **Avvio Automatico**

**Windows (Task Scheduler)**:
```
Ogni volta che il PC si accende
  → Task Scheduler esegue health-check.py
  → Se i tool non sono running, li avvia
  → Fine
```

**macOS (Launchd)**:
```
Al login dell'utente
  → Launchd esegue health-check.py
  → Ogni 5 minuti la controlla di nuovo
  → Se i tool non sono running, li avvia
```

**Linux (Systemd)**:
```
30 secondi dopo il boot
  → Systemd esegue health-check.py
  → Ogni 5 minuti la controlla di nuovo
  → Se i tool non sono running, li avvia
```

### 3. **Risultato**

✅ I tool sono **SEMPRE** running quando ne hai bisogno
- Senza bisogno di fare nulla
- Senza bisogno di digitare comandi
- Silenziosamente in background

---

## 📊 Workflow Finale

### Dopo l'installazione:

**Mattina**:
```
1. Accendi il PC
   → Auto-startup triggers
   → 9Router, Ruflo si avviano automaticamente
   
2. Apri Claude Code
   → Tools già pronti!
   
3. Inizia a codificare
   /goal "implement feature"
   → Tutto funziona automaticamente
```

**Giorno**:
```
Continua a usare Claude Code normalmente
/goal "..." 
/spawn-agent ...
/graphify ...

I tool rimangono in background sempre pronti
```

**Sera**:
```
Chiudi Claude Code
I tool rimangono running in background

Domani mattina, tutto è già pronto quando accendi il PC
```

---

## ⚠️ Troubleshooting

### I tool non si avviano?

**Windows**:
```powershell
# Controlla il task
Get-ScheduledTask -TaskName "ImproveAIToolkitAutoStart" | Select-Object State

# Esegui manualmente
.\scripts\health-check.py

# Se fallisce, controlla i logs di Windows Event Viewer
```

**macOS/Linux**:
```bash
# Esegui manualmente
python3 ./scripts/health-check.py

# Controlla i logs
tail -f ~/.improvy-ai-toolkit.log      # macOS
journalctl --user -u improvy-ai-toolkit.service  # Linux
```

### Voglio disabilitare temporaneamente?

**Windows**:
```powershell
Disable-ScheduledTask -TaskName "ImproveAIToolkitAutoStart"
# Per riabilitare:
Enable-ScheduledTask -TaskName "ImproveAIToolkitAutoStart"
```

**macOS**:
```bash
launchctl unload ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
# Per riabilitare:
launchctl load ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
```

**Linux**:
```bash
systemctl --user disable improvy-ai-toolkit.timer
# Per riabilitare:
systemctl --user enable improvy-ai-toolkit.timer
```

### Voglio rimuovere completamente?

**Windows**:
```powershell
Unregister-ScheduledTask -TaskName "ImproveAIToolkitAutoStart" -Confirm:$false
```

**macOS**:
```bash
launchctl unload ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
rm ~/Library/LaunchAgents/com.improvy.ai-toolkit.plist
```

**Linux**:
```bash
systemctl --user disable improvy-ai-toolkit.timer
rm ~/.config/systemd/user/improvy-ai-toolkit.*
systemctl --user daemon-reload
```

---

## 🎯 Verificare che Funziona

Dopo l'installazione, **riavvia il PC**.

Poi verifica:

```bash
# Check 9Router
curl http://localhost:20128/v1/models

# Check Ruflo
ruflo daemon status

# Check Graphify
graphify --version
```

Se tutti rispondono = ✅ **Tutto funziona!**

---

## 📝 Log Files

### Windows
```
Task Scheduler Logs:
  Windows Event Viewer → Windows Logs → System
  Filtra per "ImproveAIToolkitAutoStart"
```

### macOS
```bash
tail -f ~/.improvy-ai-toolkit.log
tail -f ~/.improvy-ai-toolkit-error.log
```

### Linux
```bash
journalctl --user -u improvy-ai-toolkit.service -f
```

---

## ✨ Bonus: Manual Trigger

Puoi anche eseguire manualmente il health check in qualsiasi momento:

**Windows**:
```powershell
python.exe .\scripts\health-check.py
```

**macOS/Linux**:
```bash
python3 ./scripts/health-check.py
```

Utile se vuoi verificare che tutto è running senza aspettare il prossimo ciclo.

---

## 🎉 Conclusione

Adesso:

✅ **Auto-startup è configurato**
- Partono automaticamente al riavvio
- Rimangono sempre pronti
- Zero intervento necessario
- Tutto funziona trasparentemente

✅ **Prossima volta**:
1. Accendi il PC
2. Apri Claude Code
3. I tool sono già pronti!

**That's it! Fully automated.** 🚀

---

**Last Updated**: July 8, 2026  
**Status**: ✅ Auto-startup ready

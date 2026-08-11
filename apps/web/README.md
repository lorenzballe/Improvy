# Improvy AI — sito + backend

Sito web con login Google e chat AI multi-agente. Next.js 15 (frontend **e**
backend nello stesso progetto), Supabase (autenticazione + database Postgres),
Claude via API Anthropic.

---

## Cosa c'è già

| Pezzo | Stato |
|---|---|
| Homepage pubblica | ✅ |
| Login "Accedi con Google" | ✅ (serve la configurazione qui sotto) |
| Onboarding in 3 passaggi | ✅ |
| Chat in streaming (il testo appare mentre viene scritto) | ✅ |
| 5 agenti selezionabili, ognuno col suo modello | ✅ |
| Storico conversazioni: salvataggio, elenco, eliminazione | ✅ |
| Database con isolamento per utente (RLS) | ✅ |
| Protezione delle pagine private | ✅ |
| Layer multi-provider (Anthropic + OpenAI) | ✅ |
| Conteggio token per stimare i costi | ✅ (salvato a DB; manca la dashboard) |

---

## Setup — circa 20 minuti

### 1. Supabase (login + database)

1. Vai su [supabase.com](https://supabase.com), crea un progetto (piano gratuito).
2. **SQL Editor** → incolla tutto il contenuto di
   `supabase/migrations/0001_init.sql` → **Run**. Crea le tabelle, i trigger e
   le regole di sicurezza.
3. **Project Settings → API**: copia `Project URL` e la chiave `anon public`.

### 2. Google OAuth

Serve dire a Google che il nostro sito può chiedere il login.

1. [Google Cloud Console](https://console.cloud.google.com) → crea un progetto.
2. **API e servizi → Schermata consenso OAuth**: tipo *Esterno*, compila nome
   app ed email di assistenza.
3. **Credenziali → Crea credenziali → ID client OAuth → Applicazione web**.
4. In **URI di reindirizzamento autorizzati** incolla *esattamente* questo,
   sostituendo la parte iniziale con l'URL del tuo progetto Supabase:
   ```
   https://TUO-PROGETTO.supabase.co/auth/v1/callback
   ```
   ⚠️ È l'errore più comune: va messo l'URL **di Supabase**, non quello del sito.
5. Copia `Client ID` e `Client Secret`.
6. Torna su Supabase → **Authentication → Sign In / Providers → Google**:
   attiva, incolla i due valori, salva.
7. Sempre in Supabase → **Authentication → URL Configuration**:
   - *Site URL*: `http://localhost:3000` (in produzione: il tuo dominio)
   - *Redirect URLs*: aggiungi `http://localhost:3000/auth/callback`

### 3. Chiave Anthropic

1. [console.anthropic.com](https://console.anthropic.com) → **API Keys** →
   crea una chiave.
2. Carica qualche dollaro di credito (**Billing**), altrimenti le richieste
   vengono rifiutate.

### 4. Avvia in locale

```bash
cd apps/web
cp .env.example .env.local     # poi riempi i valori
npm install
npm run dev
```

Apri http://localhost:3000.

---

## Struttura del progetto

```
apps/web/
├── middleware.ts                 blocca le pagine private, rinnova la sessione
├── supabase/migrations/          schema SQL del database
└── src/
    ├── app/
    │   ├── page.tsx              homepage pubblica
    │   ├── login/                accedi con Google
    │   ├── onboarding/           3 domande al primo accesso
    │   ├── chat/                 la chat (elenco + singola conversazione)
    │   ├── auth/callback/        ritorno da Google → crea la sessione
    │   └── api/chat/             ⬅ il backend della chat, in streaming
    ├── components/chat/          interfaccia della chat
    └── lib/
        ├── ai/                   ⬅ il layer degli agenti
        │   ├── agents.ts         REGISTRO AGENTI — si modifica qui
        │   ├── models.ts         modelli disponibili + prezzi
        │   └── providers/        anthropic.ts, openai.ts
        ├── db/queries.ts         query al database
        └── supabase/             client per browser / server / middleware
```

---

## Aggiungere un agente

Una voce in `src/lib/ai/agents.ts` e compare subito nel selettore:

```ts
{
  id: "traduttore",
  name: "Traduttore",
  tagline: "Traduzioni naturali",
  emoji: "🌍",
  model: "claude-sonnet-5",
  maxTokens: 8000,
  effort: "medium",
  system: "Sei un traduttore professionista. Restituisci solo la traduzione.",
}
```

## Aggiungere un provider (OpenAI, Gemini, un agente tuo)

1. Crea `src/lib/ai/providers/tuo-provider.ts` implementando l'interfaccia
   `ChatProvider` (tre metodi, vedi `types.ts`).
2. Registralo nella mappa `PROVIDERS` in `src/lib/ai/index.ts`.
3. Aggiungi i suoi modelli in `models.ts`.

Non serve toccare né la chat né le route API: parlano solo con l'interfaccia.

---

## Costi

Prezzi Anthropic per milione di token (input / output):

| Modello | Input | Output | Usato da |
|---|---|---|---|
| Claude Opus 5 | $5 | $25 | Improvy, Analista, Penna |
| Claude Sonnet 5 | $3 | $15 | Dev |
| Claude Haiku 4.5 | $1 | $5 | Lampo |

Ogni risposta salva `input_tokens` e `output_tokens` nella tabella `messages`,
quindi il costo reale è calcolabile con `estimateCost()` in `lib/ai/models.ts`.

Supabase e Vercel hanno piani gratuiti che bastano ampiamente per iniziare.

---

## Deploy (quando siamo pronti)

1. Push su GitHub.
2. [vercel.com](https://vercel.com) → importa il repo → *Root Directory*:
   `apps/web`.
3. Incolla le stesse variabili di `.env.local` nelle *Environment Variables*
   (`NEXT_PUBLIC_SITE_URL` = il dominio di produzione).
4. Aggiungi il dominio di produzione in Supabase → *URL Configuration*
   (sia *Site URL* che *Redirect URLs*).

---

## Sicurezza — cosa è già coperto

- `.env.local` è in `.gitignore`: le chiavi non finiscono su GitHub.
- `ANTHROPIC_API_KEY` è usata **solo** lato server: il browser non la vede mai.
- Row Level Security sul database: ogni riga è legata a `auth.uid()`. Anche con
  la chiave pubblica in mano, nessuno può leggere le conversazioni di altri.
- Il middleware rimanda a `/login` chiunque non sia autenticato.
- Il markdown della chat è renderizzato come nodi React, non come HTML: il
  modello non può iniettare script.

---

## Cosa manca (ordine consigliato)

1. **Limite di richieste per utente** — senza, un utente può bruciare credito.
2. **Rinominare le conversazioni** (ora il titolo è la prima frase, tagliata).
3. **Dashboard costi** — i dati ci sono già a database.
4. **Caricamento file** (PDF, immagini) nella chat.
5. **Ricerca web** per gli agenti.
6. **Abbonamenti/pagamenti** (Stripe) se diventa un prodotto a pagamento.
7. **App mobile** — può usare lo stesso backend e lo stesso database.

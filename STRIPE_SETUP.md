# Improvy Pro sul sito — configurazione Stripe

Sul sito, alla pagina `#pro`, una persona accede con lo stesso account
dell'app, paga 19,99 € con Stripe, e la licenza compare sul suo account:
l'app la trova al primo accesso, su qualsiasi telefono. Nessuno store in
mezzo, nessuna commissione del 15 o 30%.

Il codice è tutto nel repo. Quello che resta da fare è fuori dal codice, e
si fa una volta sola. Tempo stimato: un'ora, quasi tutto dal browser.

## Cosa resta da fare

- [ ] **Stripe**: account, prodotto, webhook (punto 1)
- [ ] **Firebase sul piano Blaze** (punto 2)
- [ ] **Chiave del service account** per il deploy (punto 3)
- [ ] **Quattro segreti su GitHub** (punto 4)
- [ ] **Dominio del sito autorizzato** in Firebase Auth (punto 5)
- [ ] Lanciare il workflow, incollare l'indirizzo del webhook in Stripe (punto 6)
- [ ] *(facoltativo)* Stripe Tax per l'IVA, Apple Pay sul sito (punto 7)

## Come funziona, in due righe

```
sito  ──accedi──▶  Firebase Auth (stesso progetto dell'app)
sito  ──"apri il checkout"──▶  createCheckoutSession  ──▶  Stripe Checkout
Stripe  ──"pagato"──▶  stripeWebhook  ──scrive──▶  entitlements/{uid}
app   ──accedi──▶  legge entitlements/{uid}  ──▶  Pro
```

Le tre funzioni stanno in `functions/`. Le regole in `firestore.rules`
permettono a chiunque di **leggere** la propria licenza e a **nessuno** di
scriverla: la scrive solo il webhook, e solo dopo aver verificato la firma di
Stripe. Il sito non tocca soldi e non concede niente.

## 1. Stripe

1. [dashboard.stripe.com](https://dashboard.stripe.com) → crea l'account
   (come privato o come attività: Stripe chiede i dati per pagarti).
2. **Catalogo prodotti** → **Aggiungi prodotto**: nome `Improvy Pro`,
   descrizione "Licenza a vita", prezzo **19,99 €**, **una tantum**. Salva.
   Apri il prezzo e copia il suo ID, che inizia con `price_`.
3. **Sviluppatori** → **Chiavi API** → copia la **chiave segreta**, che
   inizia con `sk_live_` (o `sk_test_` finché sei in modalità test — vedi
   sotto).
4. **Sviluppatori** → **Webhook** → **Aggiungi endpoint**:
   - URL: `https://europe-west1-improvy-f470f.cloudfunctions.net/stripeWebhook`
   - Eventi da inviare, questi quattro:
     `checkout.session.completed`,
     `checkout.session.async_payment_succeeded`,
     `charge.refunded`,
     `charge.dispute.created`
   - Salva, poi apri l'endpoint e copia la **chiave segreta del webhook**,
     che inizia con `whsec_`.
5. **Impostazioni** → **Dettagli pubblici**: metti nome, sito e email di
   assistenza. È quello che compare sulla ricevuta e sull'estratto conto.

**Modalità test.** Stripe ha un interruttore "Modalità test" in alto. Tutto
quello sopra esiste due volte, una per modalità, con chiavi diverse. Per
provare senza soldi veri: fai i punti 2–4 in modalità test, metti su GitHub le
chiavi `sk_test_` e `whsec_` di test, paga con la carta `4242 4242 4242 4242`,
qualsiasi data futura e CVC. Quando funziona, rifai 2–4 in modalità live e
sostituisci le tre chiavi su GitHub.

## 2. Firebase sul piano Blaze

Le funzioni girano solo sul piano a consumo. Firebase → in basso a sinistra
**Upgrade** → **Blaze** → carta. A questi volumi il costo è zero: le prime
due milioni di chiamate al mese sono gratis.

## 3. La chiave per il deploy

Il workflow di GitHub fa il deploy al posto tuo. Gli serve una chiave:

Firebase → ⚙️ **Impostazioni progetto** → **Account di servizio** →
**Genera nuova chiave privata** → scarica il file `.json`. Aprilo con un
editor di testo: il contenuto intero è il valore del segreto
`FIREBASE_SERVICE_ACCOUNT` al punto 4. Poi cancella il file dal computer.

## 4. I segreti su GitHub

GitHub → repo **Improvy** → **Settings** → **Secrets and variables** →
**Actions** → **New repository secret**, quattro volte:

| Nome | Valore |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | tutto il contenuto del `.json` del punto 3 |
| `STRIPE_SECRET_KEY` | `sk_live_…` (o `sk_test_…`) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` |
| `STRIPE_PRICE_ID` | `price_…` |

Il workflow li copia dentro Secret Manager a ogni esecuzione: per ruotare una
chiave cambi il segreto su GitHub e rilanci il workflow. Non passano mai dal
codice.

## 5. Il sito può fare accedere

Firebase → **Authentication** → **Impostazioni** → **Domini autorizzati** →
**Aggiungi dominio**: `lorenzballe.github.io`. Senza, Google e Apple sul sito
rispondono "dominio non autorizzato".

Google sul sito funziona con quello che hai già attivato per l'app. Apple sul
sito richiede lo stesso Services ID che serve ad Apple su Android (vedi
`FIREBASE_SETUP.md`, punto 2): finché non c'è, il pulsante Apple sul sito
risponde con un errore chiaro e restano Google ed email, che bastano.

## 6. Il primo deploy

GitHub → repo **Improvy** → **Actions** → **Firebase** → **Run workflow**.
Ci mettono tre o quattro minuti. Da lì in poi riparte da solo a ogni modifica
di `functions/` o delle regole su `main`.

Se il punto 4 di Stripe l'hai fatto prima del deploy, l'indirizzo del
webhook è lo stesso già scritto sopra e non c'è altro. Il workflow lo
stampa comunque alla fine.

**Prova.** Apri il sito, `#pro`, accedi, paga con la carta di test. La pagina
deve dire "Pro is on your account" entro qualche secondo. Poi apri l'app,
accedi con lo stesso account: Pro. Su Stripe, **Sviluppatori → Webhook →
l'endpoint** mostra ogni evento e la risposta della funzione, che è dove
guardare se qualcosa non torna.

## 7. Facoltativi

**IVA.** Quando vendi tramite Apple, l'IVA la gestisce Apple. Con Stripe è
tua. **Stripe Tax** la calcola, la aggiunge al checkout secondo il paese di
chi compra e ti prepara i report per la dichiarazione OSS. Si attiva in
**Impostazioni → Tax**; poi in `functions/.env` metti
`STRIPE_AUTOMATIC_TAX=true` e committa. Costa una piccola percentuale sulle
transazioni. Finché è spento, il prezzo è 19,99 € tutto compreso e l'IVA la
dichiari tu.

**Apple Pay sul sito.** Stripe → **Impostazioni → Metodi di pagamento →
Apple Pay** → aggiungi il dominio `lorenzballe.github.io`. Stripe ti dà un
file da mettere in `public/.well-known/` del sito. Senza, su iPhone resta la
carta, che va benissimo.

## Rimborsi e revoche

Un rimborso totale o una contestazione fatti su Stripe tolgono la licenza da
soli: il webhook lo vede e scrive `pro: false` sul documento. Un rimborso
parziale la lascia. Per togliere Pro a mano a una persona, Firestore →
`entitlements` → il suo documento → `pro` a `false`.

## Cosa NON fare nell'app

Nell'app non deve comparire nessun riferimento all'acquisto sul sito: niente
link, niente "costa meno sul sito", niente accenno nel paywall. È la
condizione perché Apple e Google accettino che l'app riconosca una licenza
comprata altrove. Il sito invece può dire tutto.

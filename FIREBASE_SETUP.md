# Account e codici promozionali — configurazione Firebase

L'app ha un'area **Account** (Google, Apple, email) e una **Codici
promozionali** nelle Impostazioni. Entrambe girano su Firebase, piano
gratuito, senza server da scrivere. Finché `lib/firebase_options.dart`
contiene i segnaposto `REPLACE_ME`, le due card dicono "non disponibile in
questa versione" e tutto il resto dell'app è identico a prima: la build passa,
i test passano, niente si rompe.

Tempo stimato: 40 minuti, tutto dal browser. Serve un solo giro.

## 1. Progetto Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Crea progetto** → nome `Improvy` → Analytics: **disattiva** (PostHog
   fa già quel lavoro) → Crea.
2. Nella pagina del progetto, **Aggiungi app** → icona **Android** →
   package `com.improvy.app` → Registra.
3. **Aggiungi app** → icona **iOS** → bundle `com.improvy.app` → Registra.

   Sì, **lo stesso identificativo su entrambe**: è `applicationId` in
   `android/app/build.gradle.kts` e `PRODUCT_BUNDLE_IDENTIFIER` in Xcode.
   `com.improvy.improvy` che vedi nelle cartelle Kotlin è solo il namespace
   interno del codice Android e non va mai usato qui: Firebase confronta il
   package con `applicationId`, e se non coincide l'accesso con Google non
   parte.

   Scarica i due file di configurazione (`google-services.json` e
   `GoogleService-Info.plist`): non vanno messi nel repo, ma contengono i
   valori del punto 5.

## 2. Authentication

**Build** → **Authentication** → **Inizia** → scheda **Metodo di accesso**:

- **Email/password** → Attiva (solo la prima levetta, non "link email").
- **Google** → Attiva → email di assistenza: la tua → Salva. Poi riapri
  Google → **Configurazione SDK web** → copia il **ID client web**
  (finisce in `.apps.googleusercontent.com`). Ti serve al punto 5.
- **Apple** → Attiva. Su iPhone basta questo. Per far funzionare "Continua
  con Apple" **anche su Android** servono tre cose dal portale Apple,
  altrimenti lascia vuoto e su Android resterà Google + email:
  - un **Services ID** (Identifiers → + → Services IDs, es.
    `com.improvy.app.signin`), con "Sign in with Apple" attivo, dominio
    `<project-id>.firebaseapp.com` e return URL
    `https://<project-id>.firebaseapp.com/__/auth/handler`;
  - una **chiave** (Keys → + → Sign in with Apple) → scarica il `.p8`;
  - in Firebase, nella scheda Apple: Services ID, Team ID, Key ID e il
    contenuto del `.p8`.

### Impronta SHA-1 (solo Android, obbligatoria per Google)

Google su Android accetta solo app firmate con un certificato registrato.

1. Play Console → la tua app → **Configurazione** → **Integrità dell'app**
   → **Firma dell'app** → copia **SHA-1** del *certificato di firma
   dell'app* (quello che Google usa quando distribuisce).
2. Firebase → ⚙️ **Impostazioni progetto** → app Android → **Aggiungi
   impronta** → incolla → Salva.
3. Ripeti con la SHA-1 del keystore con cui firmi localmente (per provare
   sul tuo telefono): `keytool -list -v -keystore <il tuo .jks>`.

## 3. Firestore

**Build** → **Firestore Database** → **Crea database** → posizione
`eur3 (europe-west)` → **modalità produzione** → Crea.

Le regole sono nel repo (`firestore.rules`) e sono la vera sicurezza: un
codice si può solo cercare per nome, mai elencare, e si può spendere solo
scrivendo insieme il +1 sul contatore e la propria riscossione. Caricale:
scheda **Regole** → incolla il contenuto di `firestore.rules` → **Pubblica**.

Sono testate contro l'emulatore in `tool/firestore_rules` (`npm install &&
npm test`, serve Java).

## 4. Capability "Sign in with Apple" (iOS)

Come per gli App Group dei widget:

1. developer.apple.com → Identifiers → **com.improvy.app** → spunta
   **Sign In with Apple** → Save.
2. Profiles → elimina il profilo di `com.improvy.app` (Codemagic ne crea uno
   nuovo che porta la capability). Quello del widget non va toccato.

Codemagic aggiunge l'entitlement all'app da solo, e solo quando il punto 5 è
fatto: prima di allora la build resta com'è. Il controllo firma in
`codemagic.yaml` ti dice in chiaro se manca la capability.

## 5. I valori nell'app

Firebase → ⚙️ **Impostazioni progetto** → in basso le due app. Per ciascuna
c'è un blocco di valori. Riempi `lib/firebase_options.dart`:

| Campo Dart | Dove sta in Firebase |
|---|---|
| `projectId` | ID progetto (in alto nella pagina) |
| `messagingSenderId` | Numero progetto |
| `storageBucket` | `<project-id>.firebasestorage.app` |
| `android.apiKey` / `android.appId` | app Android → chiave API / ID app |
| `ios.apiKey` / `ios.appId` | app iOS → chiave API / ID app |
| `ios.iosClientId` | app iOS → `GoogleService-Info.plist` → `CLIENT_ID` (scarica il plist solo per leggerlo) |

Poi in `lib/config/firebase_config.dart` metti in `googleWebClientId` l'ID
client web copiato al punto 2.

In alternativa, sul PC con Flutter: `dart pub global activate flutterfire_cli`
e `flutterfire configure --project=<project-id>
--platforms=android,ios --android-package-name=com.improvy.app
--ios-bundle-id=com.improvy.app`. Riscrive `firebase_options.dart` da solo;
`googleWebClientId` va comunque messo a mano.

Infine, una volta: `dart run tool/sync_firebase_ios.dart` (Codemagic lo fa
comunque ad ogni build). Committa tutto: nessuno di questi valori è
segreto, identificano il progetto e basta.

## 6. Creare i codici

Firestore → **Dati** → collezione `codes` → **Aggiungi documento**:

- **ID documento**: il codice, MAIUSCOLO, lettere, cifre e trattini
  (es. `LANCIO2026`, `AMICI-10`). L'app normalizza quello che scrive
  l'utente allo stesso modo.
- Campi:

| Campo | Tipo | Esempio | Note |
|---|---|---|---|
| `active` | boolean | `true` | metti `false` per ritirarlo |
| `maxUses` | number | `50` | quanti account possono usarlo |
| `uses` | number | `0` | lo incrementa l'app |
| `expiresAt` | timestamp | 31/12/2026 | facoltativo |
| `note` | string | "giornalisti" | per te |

Si fa dall'app Firebase sul telefono, in tempo reale, senza release.

Ogni account può usare **un** codice. Chi lo riscatta ha Pro finché la sua
riga in `redemptions` esiste: per toglierlo a una persona, elimina quella
riga (l'ID è il suo UID, visibile in Authentication → Utenti).

Un codice non passa dagli store: è Pro concesso dall'app, e segue l'account
su qualunque telefono, iPhone o Android.

## 7. Cose da aggiornare negli store

- **App Store Connect** → Privacy dell'app: ora raccogli *Indirizzo email* e
  *ID utente*, finalità "Funzionalità dell'app", collegati all'utente.
- **Play Console** → Sicurezza dei dati: idem (email, ID utente; raccolti,
  non condivisi; l'utente può chiederne la cancellazione — sì, dall'app).
- Entrambi richiedono che chi crea un account possa **eliminarlo
  dall'app**: c'è, nella card Account.

## Come funziona, in due righe

- **Pro** = acquisto (RevenueCat) **oppure** codice riscattato (Firestore).
  I due non si annullano a vicenda: un rimborso non toglie il codice, uscire
  dall'account non toglie l'acquisto.
- Al login l'account viene passato a RevenueCat (`Purchases.logIn`), così
  anche l'acquisto segue la persona tra iPhone e Android. All'uscita si
  torna anonimi e si ripristina subito dallo store, così chi ha comprato su
  quel telefono non resta chiuso fuori.

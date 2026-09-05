// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Avanti';

  @override
  String get skip => 'Salta';

  @override
  String get cancel => 'Annulla';

  @override
  String get done => 'Fatto';

  @override
  String get close => 'Chiudi';

  @override
  String get gotIt => 'Capito';

  @override
  String get notNow => 'Non ora';

  @override
  String get retry => 'RIPROVA';

  @override
  String get home => 'HOME';

  @override
  String get start => 'INIZIA';

  @override
  String get startTraining => 'INIZIA AD ALLENARTI';

  @override
  String get proOnly => 'SOLO PRO';

  @override
  String get free => 'GRATIS';

  @override
  String get modeDiatonic => 'Diatonic';

  @override
  String get modeChromatic => 'Chromatic';

  @override
  String get modeCustom => 'Custom';

  @override
  String get modeNoteToNumber => 'Note to Number';

  @override
  String get modeOfWhat => '…Of What?';

  @override
  String get modePocket => 'Pocket Mode';

  @override
  String get modeNormal => 'Normal';

  @override
  String get tierApprentice => 'Apprendista';

  @override
  String get tierVirtuoso => 'Virtuoso';

  @override
  String get tierMaster => 'Maestro';

  @override
  String get onboardingTag => 'Allenamento mentale';

  @override
  String get onboardingHeadline => 'Ogni nota\nè un\nnumero.';

  @override
  String get onboardingPromise =>
      'Vedi all\'istante il numero sotto qualsiasi nota, in tutte e dodici le tonalità — senza contare, senza libro di teoria.';

  @override
  String get onboardingStart => 'Inizia ad allenarti';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get explainerEyebrow => 'COME FUNZIONA';

  @override
  String explainerStep(int n) {
    return '$n DI 3';
  }

  @override
  String get explainer1Title => 'Ogni tasto\nha un numero.';

  @override
  String get explainer1Body =>
      'Queste sono le sette note di Do maggiore. I musicisti le chiamano col loro numero — il grado — perché il numero dice cosa sta facendo la nota, e funziona uguale in ogni tonalità.';

  @override
  String get explainer2Title => 'Cambia tonalità.\nI numeri restano.';

  @override
  String get explainer2Body =>
      'Tocca una tonalità e guarda. Le note si spostano, i numeri no: il 5 è sempre il 5. Impari i numeri una volta e hai tutte e dodici le tonalità.';

  @override
  String get explainer3Title => 'Prova.';

  @override
  String get explainer3Body =>
      'Il gioco è tutto qui. Abbastanza veloce, abbastanza spesso, e smette di essere aritmetica e diventa istinto — due minuti al giorno bastano.';

  @override
  String get letsGo => 'Andiamo';

  @override
  String get summaryTitle => 'SESSIONE COMPLETATA';

  @override
  String get summaryPerfect => 'PUNTEGGIO PERFETTO';

  @override
  String get summaryPassed => 'LIVELLO SUPERATO';

  @override
  String get summaryCompleted => 'COMPLETATA';

  @override
  String get summaryNotYet => 'NON ANCORA — CONTINUA';

  @override
  String get summaryCorrect => 'GIUSTE';

  @override
  String get summaryErrors => 'ERRORI';

  @override
  String get summaryTime => 'TEMPO';

  @override
  String get summaryAccuracy => 'PRECISIONE %';

  @override
  String get summaryModeMastery => 'PADRONANZA MODALITÀ';

  @override
  String get summaryNextDifficulty => 'PROSSIMA DIFFICOLTÀ';

  @override
  String summaryUpsellTitle(String key) {
    return 'Questa era la metà gratuita di $key';
  }

  @override
  String get summaryUpsellBody =>
      'Chromatic aggiunge i cinque gradi alterati — il resto della tonalità.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Licenza a vita';

  @override
  String get paywallTagline => 'Ogni tonalità. Ogni modalità. Per sempre.';

  @override
  String get paywallEvery => 'Ogni ';

  @override
  String get paywallForever => 'Per sempre.';

  @override
  String get paywallWhatYouGet => 'Cosa ottieni, da musicista a musicista';

  @override
  String get paywallCta => 'Sblocca l\'accesso a vita';

  @override
  String paywallPrice(String price) {
    return '$price · pagamento unico';
  }

  @override
  String get paywallRestore => 'Ripristina';

  @override
  String get paywallNoPurchase => 'Nessun acquisto precedente trovato';

  @override
  String get featChromatic => 'Chromatic Mode';

  @override
  String get featChromaticMeta => 'tutte e 12 le tonalità';

  @override
  String get featNtn => 'Note to Number';

  @override
  String get featNtnMeta => 'cromatico';

  @override
  String get featOfWhat => '…Of What?';

  @override
  String get featOfWhatMeta => 'tutti i 15 gradi';

  @override
  String get featPocket => 'Pocket Mode';

  @override
  String get featPocketMeta => 'tutti i 12 gradi';

  @override
  String get featCustom => 'Custom Mode';

  @override
  String get featCustomMeta => 'qualsiasi grado';

  @override
  String get featAdaptive => 'Difficoltà adattiva';

  @override
  String get featAdaptiveMeta => 'automatica';

  @override
  String get featAnalytics => 'Analisi approfondite';

  @override
  String get featAnalyticsMeta => 'per tonalità';

  @override
  String get storeNotReadyTitle => 'Store non pronto';

  @override
  String get storeNotReadyBody =>
      'Nessun prodotto è disponibile per l\'acquisto in questo momento. Riprova tra poco.';

  @override
  String get almostThereTitle => 'Ci siamo quasi';

  @override
  String get almostThereBody =>
      'Il pagamento è andato a buon fine ma PRO non si è attivato automaticamente. Tocca Ripristina acquisti tra un istante — non ti verrà addebitato due volte.';

  @override
  String get billingUnavailableTitle => 'Acquisti non disponibili';

  @override
  String get billingUnavailableBody =>
      'Gli acquisti in-app non sono disponibili su questo dispositivo.';

  @override
  String get purchaseFailedTitle => 'Acquisto non riuscito';

  @override
  String get purchaseFailedBody =>
      'Qualcosa è andato storto contattando lo store. Riprova.';

  @override
  String get notifPromptTitle => 'Falla restare';

  @override
  String get notifPromptBody =>
      'Un quiz veloce al giorno tiene ogni nota affilata e la tua serie viva. Si spegne quando vuoi.';

  @override
  String get notifPromptYes => 'Sì, ricordamelo';

  @override
  String get homeAllKeys => 'PADRONANZA DI TUTTE LE TONALITÀ';

  @override
  String get homeSpecialModes => 'MODALITÀ SPECIALI';

  @override
  String get homePickUp => 'RIPRENDI DA DOVE ERI';

  @override
  String get homeTotalSessions => 'SESSIONI TOTALI';

  @override
  String get homeAccuracy => 'PRECISIONE';

  @override
  String get homeTotalProgress => 'PROGRESSO TOTALE';

  @override
  String get homeNextMilestone => 'PROSSIMO TRAGUARDO';

  @override
  String get homeMaxLevel => 'LIVELLO MASSIMO!';

  @override
  String homeLevelShort(int n) {
    return 'LIV $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% a $animal';
  }

  @override
  String get homeNtnDesc => 'Data una nota, riconosci il suo grado numerico.';

  @override
  String get homeOfWhatDesc =>
      'Una nota è un certo grado — di\' la tonica. Armonizza qualsiasi melodia.';

  @override
  String get homePocketDesc =>
      'Esercizio audio a mani libere: una voce chiede, aspetta, poi dice la nota. Funziona a schermo spento.';

  @override
  String get homeCustomDesc =>
      'Scegli tonalità, direzione e i gradi specifici su cui allenarti.';

  @override
  String homeLastSession(String when) {
    return 'ULTIMA SESSIONE • $when';
  }

  @override
  String get homeResume => 'Riprendi la sessione';

  @override
  String get homeReadyTitle => 'Pronto a iniziare?';

  @override
  String get homeReadyBody => 'Seleziona una tonalità qui sopra';

  @override
  String get homeGamesPlayed => 'PARTITE GIOCATE';

  @override
  String get homeChooseMode => 'Scegli la modalità';

  @override
  String get homeChooseModeSub => 'Scegli come allenarti oggi';

  @override
  String get homeDiatonicDesc => 'Padroneggia le 7 note della scala.';

  @override
  String get homeChromaticDesc => 'Mettiti alla prova con tutti i 12 semitoni.';

  @override
  String homeLockedTier(String prev) {
    return 'Continua ad allenarti in modalità $prev per sbloccare questa difficoltà.';
  }

  @override
  String get homeYourProgress => 'I TUOI PROGRESSI';

  @override
  String get homeKeepTraining => 'CONTINUA COSÌ';

  @override
  String get homeHandsFree => 'Audio a mani libere';

  @override
  String get homeJustNow => 'Adesso';

  @override
  String homeMinutesAgo(int n) {
    return '$n min fa';
  }

  @override
  String homeHoursAgo(int n) {
    return '$n h fa';
  }

  @override
  String homeDaysAgo(int n) {
    return '$n g fa';
  }

  @override
  String get homeQuote1 =>
      'Ogni maestro è stato un principiante. Visualizziamo quelle prime note!';

  @override
  String get homeQuote2 =>
      'A metà strada — i tuoi istinti si stanno affinando. Continua!';

  @override
  String get homeQuote3 =>
      'La vera padronanza vive nei dettagli. Fidati dell\'istinto e suona!';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Tonalità di $key, $pct per cento';
  }

  @override
  String get setupTrainingSetup => 'IMPOSTAZIONE ALLENAMENTO';

  @override
  String get setupHarmonizeSetup => 'IMPOSTAZIONE ARMONIZZAZIONE';

  @override
  String get setupPersonalized =>
      'PRATICA LIBERA · NON CONTA PER LA PADRONANZA';

  @override
  String get setupHandsFree => 'MANI LIBERE · AUDIO';

  @override
  String get setupSelectRootKey => 'Scegli la tonalità';

  @override
  String get setupSelectRootKeySub => 'Scegli la base del tuo allenamento.';

  @override
  String get setupSelectNote => 'Scegli la nota';

  @override
  String get setupSelectNoteSub =>
      'La nota della melodia tenuta per tutta la sessione.';

  @override
  String get setupIntensity => 'Intensità';

  @override
  String get setupIntensityChromatic =>
      'Padroneggia tutte le 12 note cromatiche in questa tonalità.';

  @override
  String get setupIntensityDiatonic =>
      'Concentrati sulle 7 note della scala maggiore.';

  @override
  String get setupDifficulty => 'Difficoltà';

  @override
  String get setupDifficultySub =>
      'Più difficoltà significa meno tempo per rispondere.';

  @override
  String get setupMode => 'Modalità';

  @override
  String get setupModeNormalSub =>
      'Di\' la nota di un grado, in questa tonalità.';

  @override
  String get setupModeNtnSub =>
      'Di\' il grado di una nota, in questa tonalità.';

  @override
  String get setupModeOfWhatSub =>
      'Una nota tenuta per tutto il tempo — di\' a quale tonalità appartiene.';

  @override
  String get setupSelectDegrees => 'Scegli i gradi';

  @override
  String get setupDegreesToAsk => 'Gradi da chiedere';

  @override
  String get setupDegreesAll => 'Tutti i gradi, estensioni comprese.';

  @override
  String get setupDegreesChord => 'Le quattro note dell\'accordo: 1, 3, 5, 7.';

  @override
  String get setupChord => 'Accordo';

  @override
  String get setupAll => 'Tutti';

  @override
  String get setupQuickChord => 'ACCORDO';

  @override
  String get setupQuickAll => 'TUTTI';

  @override
  String get setupQuickDiatonic => 'DIATONICO';

  @override
  String get setupQuestions => 'Numero di domande';

  @override
  String get setupQuestionsSub => 'Quante domande per questa sessione?';

  @override
  String get setupKeys => 'Tonalità';

  @override
  String get setupKeysSub => 'Allena una tonalità, o mescolale tutte e 12.';

  @override
  String get setupShuffleAll => 'Mescola tutte';

  @override
  String get setupOneKey => 'Una tonalità';

  @override
  String get setupDegrees => 'Gradi';

  @override
  String get setupAnswerDelay => 'Pausa prima della risposta';

  @override
  String get setupLength => 'Durata';

  @override
  String get setupLengthSub => 'Numero di domande (∞ = finché non ti fermi).';

  @override
  String setupTierLocked(String tier) {
    return '$tier è bloccato';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Prima arriva a $need giuste in $prev. Sei a $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap RECORD';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct per cento';
  }

  @override
  String get trainerCorrect => 'GIUSTO';

  @override
  String get trainerWrong => 'SBAGLIATO';

  @override
  String get trainerCorrectAnswer => 'RISPOSTA GIUSTA';

  @override
  String get trainerNote => 'NOTA';

  @override
  String get trainerKey => 'TONALITÀ';

  @override
  String get trainerDegree => 'GRADO';

  @override
  String get trainerProgress => 'PROGRESSO';

  @override
  String get trainerStreak => 'SERIE';

  @override
  String get trainerPianoKeyboard => 'TASTIERA';

  @override
  String get trainerExitTitle => 'Terminare la sessione?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'Un tentativo al giorno e il tempo continua a scorrere — se esci ora, $done/$total è il tuo punteggio fino a domani.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'Sei a $done domande — uscendo la sessione finisce e il punteggio resta.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'Sei a $done/$total — se esci la sessione finisce qui.';
  }

  @override
  String get trainerKeepPlaying => 'CONTINUA';

  @override
  String get trainerQuit => 'ESCI';

  @override
  String get paywallLine1 => 'Ogni tonalità.';

  @override
  String get paywallLine2 => 'Ogni modalità.';

  @override
  String get paywallLine3 => 'Per sempre.';

  @override
  String get paywallRestoring => 'Ripristino…';

  @override
  String get paywallTerms => 'Termini';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get animalSnail => 'Lumaca';

  @override
  String get animalTurtle => 'Tartaruga';

  @override
  String get animalPenguin => 'Pinguino';

  @override
  String get animalRabbit => 'Coniglio';

  @override
  String get animalFox => 'Volpe';

  @override
  String get animalHorse => 'Cavallo';

  @override
  String get animalFalcon => 'Falco';

  @override
  String get animalCheetah => 'Ghepardo';

  @override
  String get homeShuffleHandsFree => 'Mescolate · mani libere';

  @override
  String homeTierDifficulty(String tier) {
    return 'Difficoltà $tier';
  }

  @override
  String get trainerGridView => 'GRIGLIA';

  @override
  String get trainerAccuracy => 'PRECISIONE';

  @override
  String get settingsTitle => 'IMPOSTAZIONI';

  @override
  String get settingsAccountStatus => 'STATO ACCOUNT';

  @override
  String get settingsFreePlan => 'Piano gratuito';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub => 'Ogni modalità e tonalità, sbloccate.';

  @override
  String get settingsFreeSub => 'Tocca per sbloccare ogni modalità e tonalità.';

  @override
  String get settingsActive => 'ATTIVO';

  @override
  String get settingsTraining => 'ALLENAMENTO';

  @override
  String get settingsAdaptive => 'Difficoltà adattiva';

  @override
  String get settingsAdaptiveTag => 'ALLENAMENTO INTELLIGENTE';

  @override
  String get settingsAdaptiveBody =>
      'I gradi a cui rispondi lentamente o sbagli compaiono molto più spesso di quelli che sai — giusto ma lento conta ancora come non imparato. Il tempo si stringe quando sei in forma e si allenta quando inizi a sbagliare.';

  @override
  String get settingsAdaptiveLocked =>
      'Funzione PRO — passa a Pro per sbloccare l\'allenamento intelligente che si adatta ai tuoi punti deboli.';

  @override
  String get settingsSimpleNotes => 'Nomi semplici delle note';

  @override
  String get settingsSimpleNotesTag => 'ORTOGRAFIA DELLE NOTE';

  @override
  String get settingsSimpleNotesBody =>
      'Un solo nome per nota ovunque — niente barre, niente doppi nomi. Do  Re♭  Re  Mi♭  Mi  Fa  Fa♯  Sol  La♭  La  Si♭  Si.';

  @override
  String get settingsKeyboardTonic => 'Tastiera dalla tonica';

  @override
  String get settingsKeyboardTonicTag => 'INPUT PIANOFORTE';

  @override
  String get settingsKeyboardTonicBody =>
      'Il pianoforte in gioco parte dalla tonica della tua tonalità invece che dal Do.';

  @override
  String get settingsNotation => 'SISTEMA DI NOTAZIONE';

  @override
  String get settingsFreeMode => 'MODALITÀ LIBERA';

  @override
  String get settingsFreeModeTitle => 'Modalità libera';

  @override
  String get settingsFreeModeSub =>
      'Numeri al tuo ritmo. Niente timer, niente punteggio.';

  @override
  String get settingsNotifications => 'NOTIFICHE';

  @override
  String get settingsReminders => 'Promemoria giornalieri';

  @override
  String get settingsRemindersTag => 'QUIZ + SALVA-SERIE';

  @override
  String get settingsRemindersBody =>
      'Un quiz veloce al giorno, più un avviso prima che la tua serie si interrompa.';

  @override
  String get settingsNews => 'NOVITÀ E AGGIORNAMENTI';

  @override
  String get settingsWhatsNew => 'Novità';

  @override
  String get settingsStore => 'STORE';

  @override
  String get settingsUpgrade => 'PASSA A PRO';

  @override
  String get settingsRestorePurchases => 'RIPRISTINA ACQUISTI';

  @override
  String get settingsProRestored => 'PRO ripristinato';

  @override
  String get settingsHomeScreen => 'SCHERMATA HOME';

  @override
  String get settingsWidgets => 'Widget';

  @override
  String get settingsWidgetsSub =>
      'Una domanda all\'ora, direttamente sulla schermata Home';

  @override
  String get settingsSupport => 'SUPPORTO';

  @override
  String get settingsRate => 'Valuta Improvy';

  @override
  String get settingsRateSub =>
      'Una recensione è come gli altri musicisti la trovano';

  @override
  String get settingsFeedback => 'Invia un feedback';

  @override
  String get settingsFeedbackSub =>
      'Direttamente a noi, senza uscire dall\'app';

  @override
  String get settingsFeedbackSent => 'Inviato. Li leggiamo tutti.';

  @override
  String get settingsContact => 'Contatta il supporto';

  @override
  String settingsWriteTo(String email) {
    return 'Scrivi a $email';
  }

  @override
  String get settingsFollow => 'Segui lo sviluppatore';

  @override
  String settingsInstagram(String handle) {
    return 'Trovaci su Instagram: @$handle';
  }

  @override
  String get settingsLegal => 'LEGALE';

  @override
  String get settingsClearTitle => 'Cancellare tutti i dati?';

  @override
  String get settingsClearBody =>
      'Eliminerà per sempre tutti i tuoi progressi e le statistiche.';

  @override
  String get settingsWidgetsTwo => 'DUE WIDGET';

  @override
  String get settingsWidgetQuestion => 'Domanda';

  @override
  String get settingsWidgetQuestionBody =>
      'Un grado della scala in attesa di risposta, uno nuovo ogni ora. Toccalo per vedere la risposta.';

  @override
  String get settingsWidgetDaily => 'Sfida giornaliera';

  @override
  String get settingsWidgetDailyBody =>
      'La tonalità del giorno, il tuo punteggio dopo aver giocato, e la tua serie.';

  @override
  String get settingsWidgetHow => 'COME AGGIUNGERNE UNO';

  @override
  String get settingsWidgetIos1 =>
      'Tieni premuto uno spazio vuoto della schermata Home';

  @override
  String get settingsWidgetIos2 => 'Tocca il + nell\'angolo in alto';

  @override
  String get settingsWidgetIos3 => 'Cerca Improvy e scegli un widget';

  @override
  String get settingsWidgetAndroid2 => 'Tocca Widget';

  @override
  String get settingsWidgetAndroid3 =>
      'Trova Improvy e trascina fuori un widget';

  @override
  String statsLevel(int n) {
    return 'LIVELLO $n';
  }

  @override
  String get statsOverall => 'PADRONANZA\nGENERALE';

  @override
  String get statsNotes => 'NOTE';

  @override
  String get statsStreak => 'SERIE';

  @override
  String get statsNothingYet => 'ANCORA NIENTE DA MOSTRARE';

  @override
  String get statsLast30 => 'STATISTICHE SULLE ULTIME 30 PARTITE';

  @override
  String get statsSkillMastery => 'Padronanza';

  @override
  String get statsLatestGame => 'ULTIMA PARTITA';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n PARTITE FA',
      one: '1 PARTITA FA',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'Nessun dato • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Tempo di risposta • $when';
  }

  @override
  String get statsResponseTime => 'Tempo di risposta';

  @override
  String get statsLatest => 'ULTIMA';

  @override
  String get statsSpeedTitle => 'La tua velocità vive qui';

  @override
  String get statsSpeedBody =>
      'Gioca una sessione e guarda ogni risposta diventare più veloce.';

  @override
  String get statsDegreeAccuracy => 'Precisione per grado';

  @override
  String get statsPlays => 'GIOCATE';

  @override
  String get statsAccuracy => 'PRECISIONE';

  @override
  String get statsGamesPlayed => 'Partite giocate';

  @override
  String get statsHeatmap => 'Mappa della tastiera';

  @override
  String get statsByNote => 'PRESTAZIONI PER NOTA';

  @override
  String get statsSlow => 'LENTO';

  @override
  String get statsFast => 'VELOCE';

  @override
  String get statsRank => 'RANK';

  @override
  String get statsFirstRunTitle => 'Gioca una sessione';

  @override
  String get statsFirstRunBody =>
      'Trenta domande in una tonalità e ogni grafico di questa pagina si riempie — la tua velocità, i gradi che sbagli, le note che ti rallentano.';

  @override
  String get kaTitle => 'ANALISI TONALITÀ';

  @override
  String get kaMastery => 'PADRONANZA';

  @override
  String get kaAvgResp => 'RISP. MEDIA';

  @override
  String get kaPerAnswer => 'PER RISPOSTA';

  @override
  String get kaToday => 'OGGI';

  @override
  String get kaAccuracyOverTime => 'Tempo di risposta';

  @override
  String get kaDegreeMastery => 'Padronanza dei gradi cromatici';

  @override
  String get kaModeProgress => 'Progresso per modalità';

  @override
  String get kaDegreeToNote => 'GRADO › NOTA';

  @override
  String get kaNoteToDegree => 'NOTA › GRADO';

  @override
  String get kaOfWhat => '…OF WHAT?';

  @override
  String get kaConfusions => 'Confusioni frequenti';

  @override
  String get kaNoConfusions => 'NESSUNA CONFUSIONE. OTTIMO!';

  @override
  String get kaNote => 'NOTA';

  @override
  String get kaHarmonizer => 'Harmonizer';

  @override
  String get kaHarmonizerSub => 'Padronanza di “…Of What?”';

  @override
  String get dailyTitle => 'SFIDA GIORNALIERA';

  @override
  String get dailyDone => 'SFIDA FATTA';

  @override
  String get dailyFlawless => 'IMPECCABILE';

  @override
  String get dailyOutOfTime => 'TEMPO SCADUTO';

  @override
  String get dailySharp => 'AFFILATO';

  @override
  String get dailySolid => 'SOLIDO';

  @override
  String get dailyWarmingUp => 'IN RISCALDAMENTO';

  @override
  String get dailyTomorrow => 'DOMANI È UNA NUOVA TONALITÀ';

  @override
  String get dailyCopied => 'Risultato copiato — incollalo dove vuoi';

  @override
  String dailyNewIn(String when) {
    return 'Nuova sfida tra $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Prossima sfida tra $when';
  }

  @override
  String get dailyBackHome => 'Torna alla Home';

  @override
  String get dailyTheRun => 'LA CORSA';

  @override
  String get dailyStreak => 'SERIE DI SFIDE';

  @override
  String get dailyShare => 'Condividi il risultato';

  @override
  String get pocketTitle => 'POCKET MODE';

  @override
  String get pocketDegrees => 'GRADI';

  @override
  String get pocketDelay => 'PAUSA';

  @override
  String get pocketSession => 'SESSIONE';

  @override
  String get pocketListen => 'ASCOLTA';

  @override
  String get pocketYourTurn => 'TOCCA A TE';

  @override
  String get pocketAnswer => 'RISPOSTA';

  @override
  String get pocketReady => 'PRONTO';

  @override
  String get pocketComplete => 'SESSIONE COMPLETATA';

  @override
  String get pocketPlaying => 'IN CORSO';

  @override
  String get pocketPaused => 'IN PAUSA';

  @override
  String get pocketScreenOff => 'Continua anche a schermo spento';

  @override
  String get pocketAudioSession => 'Sessione audio';

  @override
  String get feedbackTitle => 'Dicci tutto';

  @override
  String get feedbackBody =>
      'Arriva direttamente a noi. Niente app di posta, niente account, nessun nome se non lo scrivi tu.';

  @override
  String get feedbackHintBug => 'Cos\'è successo, e cosa stavi facendo?';

  @override
  String get feedbackHint => 'Quello che vuoi dirci.';

  @override
  String get feedbackEmail => 'La tua email — solo se vuoi una risposta';

  @override
  String get feedbackSend => 'INVIA';

  @override
  String get feedbackKindBug => 'Qualcosa non va';

  @override
  String get feedbackKindIdea => 'Un\'idea';

  @override
  String get feedbackKindOther => 'Altro';

  @override
  String get levelUp => 'Livello superato!';

  @override
  String get levelUpYouAreNow => 'Ora sei un ';

  @override
  String get awesome => 'Grande!';

  @override
  String whatsNewVersionHere(String v) {
    return 'La versione $v\nè qui';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSIONE $v';
  }

  @override
  String get continueLabel => 'CONTINUA';

  @override
  String get fullChangelog => 'Elenco completo delle modifiche';

  @override
  String get quizFromHome => 'DALLA TUA SCHERMATA HOME';

  @override
  String get quizTrain => 'Allena ';

  @override
  String get freeModeTitle => 'MODALITÀ LIBERA';

  @override
  String get freeModeTapNext => 'TOCCA OVUNQUE PER IL PROSSIMO';

  @override
  String get freeModeNumbersDone => 'NUMERI FATTI';

  @override
  String get freeModeSub =>
      'Niente punteggio, niente tempo — solo ripetizioni.';

  @override
  String get freeModeGoAgain => 'DI NUOVO';

  @override
  String get remTargetTitle => 'Allenamento mirato 🎯';

  @override
  String get remDailyTitle => 'Sfida giornaliera 🏆';

  @override
  String remDailyBody(String key) {
    return 'La sfida di oggi è in $key maggiore — un solo tentativo, fallo contare.';
  }

  @override
  String get remQuizTitle => 'Quiz veloce 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return 'Qual è il $degree di $key maggiore? Tocca per controllare.';
  }

  @override
  String remLevelBody(String pct) {
    return 'Ti manca il $pct% per salire di livello. Chiudi il divario?';
  }

  @override
  String get remMaxedBody => 'Al massimo — tieni quei riflessi affilati.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Ogni grado, ogni tonalità, all\'istante. Hai 3 minuti?';

  @override
  String get remEarTitle => 'Ear training 🎧';

  @override
  String get remEarBody =>
      'Il richiamo veloce batte la teoria lenta. Una sessione veloce?';

  @override
  String get remFallbackBody => 'È ora di allenarsi?';

  @override
  String get remComeback3 =>
      'I gradi si dimenticano in fretta quando ti fermi. Le tue tonalità ti aspettano.';

  @override
  String get remComeback7 =>
      'Una settimana via — il tuo richiamo immediato ha bisogno di riscaldarsi. Torni?';

  @override
  String get remStreakTitle => 'Non interrompere la serie! 🔥';

  @override
  String remStreakBody(int n) {
    return 'La tua serie di $n giorni finisce stanotte — 2 minuti per tenerla viva.';
  }

  @override
  String get clear => 'Cancella';

  @override
  String get statsSigNone => 'NESSUNA';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n DIESIS',
      one: '1 DIESIS',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n BEMOLLI',
      one: '1 BEMOLLE',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'Continui a confondere $a e $b in $key maggiore. 10 domande per sistemarlo?';
  }

  @override
  String get freeModeDone => 'FATTI';

  @override
  String get freeModeLeft => 'RIMASTI';

  @override
  String get animalQuote1 => 'Piano e costante si vince!';

  @override
  String get animalQuote2 => 'Progresso costante!';

  @override
  String get animalQuote3 => 'Scivoli che è un piacere!';

  @override
  String get animalQuote4 => 'Veloce come una lepre!';

  @override
  String get animalQuote5 => 'Astuto e rapido!';

  @override
  String get animalQuote6 => 'Al galoppo, con precisione!';

  @override
  String get animalQuote7 => 'Vola alto! Vista acuta!';

  @override
  String get animalQuote8 => 'Inarrestabile! Vero Maestro!';

  @override
  String get explainerTapKey => 'TOCCA UNA TONALITÀ';

  @override
  String explainerQuestion(String key, String degree) {
    return 'In $key, qual è il $degree?';
  }

  @override
  String get explainerRight => 'Esatto.';

  @override
  String get explainerWrong => 'Non proprio — riprova.';

  @override
  String get explainerAgain => 'Un\'altra';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key in totale';
  }

  @override
  String statsTotalGamesChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n PARTITE',
      one: '1 PARTITA',
    );
    return '$_temp0';
  }

  @override
  String homeBestOf(int score, int cap) {
    return '$score/$cap MIGLIORE';
  }

  @override
  String get dailyMajorSuffix => 'maggiore';

  @override
  String dailyStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String dailyRule(int questions, int seconds) {
    return '$questions domande · $seconds secondi';
  }

  @override
  String get dailySubjectKeyOf => 'Tonalità di ';

  @override
  String get dailySubjectOn => 'Su ';

  @override
  String get wQuestion => 'DOMANDA';

  @override
  String get wQuestionLong => 'LA DOMANDA DI OGGI';

  @override
  String get wReveal => 'Tocca per scoprire';

  @override
  String get wDaily => 'SFIDA';

  @override
  String get wDailyLong => 'SFIDA DEL GIORNO';

  @override
  String get wToday => 'oggi';

  @override
  String get wDone => 'Fatta';

  @override
  String get wTomorrow => 'La prossima domani';

  @override
  String get wLevel => 'IL TUO LIVELLO';

  @override
  String get wMastery => 'PADRONANZA TONALITÀ';

  @override
  String get wStreak => 'SERIE';

  @override
  String get wDays => 'giorni di fila';

  @override
  String get wDayStreak => 'giorni di serie';

  @override
  String get wAtRisk => 'Gioca oggi per non perderla';

  @override
  String get wNeedsWork => 'DA MIGLIORARE';

  @override
  String get wMastered => 'padroneggiata';

  @override
  String get wWeakHint => 'La tua tonalità più debole. Tocca per allenarla.';

  @override
  String get wWeakEmpty => 'Gioca prima una tonalità';

  @override
  String get wStart => 'INIZIA AD ALLENARTI';

  @override
  String get wHandsFree => 'SENZA MANI';

  @override
  String get wPocketSub => 'Allenati a schermo spento';

  @override
  String get wTheory => 'IL GRADO DEL GIORNO';

  @override
  String get wOpenApp => 'Apri Improvy per riempirla.';
}

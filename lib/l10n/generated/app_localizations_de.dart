// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Weiter';

  @override
  String get skip => 'Überspringen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get close => 'Schließen';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get retry => 'NOCHMAL';

  @override
  String get home => 'START';

  @override
  String get start => 'LOS';

  @override
  String get startTraining => 'TRAINING STARTEN';

  @override
  String get proOnly => 'NUR PRO';

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
  String get tierApprentice => 'Lehrling';

  @override
  String get tierVirtuoso => 'Virtuose';

  @override
  String get tierMaster => 'Meister';

  @override
  String get onboardingTag => 'Mentales Training';

  @override
  String get onboardingHeadline => 'Jede Note\nist eine\nZahl.';

  @override
  String get onboardingPromise =>
      'Sieh sofort die Zahl unter jeder Note, in allen zwölf Tonarten — ohne Zählen, ohne Theoriebuch.';

  @override
  String get onboardingStart => 'Training starten';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get explainerEyebrow => 'SO FUNKTIONIERT ES';

  @override
  String explainerStep(int n) {
    return '$n VON 3';
  }

  @override
  String get explainer1Title => 'Jede Taste\nhat eine Zahl.';

  @override
  String get explainer1Body =>
      'Das sind die sieben Töne von C-Dur. Musiker nennen sie bei ihrer Zahl — der Stufe — weil die Zahl sagt, was der Ton tut, und das funktioniert in jeder Tonart gleich.';

  @override
  String get explainer2Title => 'Tonart wechseln.\nDie Zahlen bleiben.';

  @override
  String get explainer2Body =>
      'Tippe eine Tonart an und schau. Die Töne wandern, die Zahlen nicht: Die 5 ist immer die 5. Lerne die Zahlen einmal und du hast alle zwölf Tonarten.';

  @override
  String get explainer3Title => 'Probier es.';

  @override
  String get explainer3Body =>
      'Das ist das ganze Spiel. Schnell genug, oft genug, und aus Rechnen wird Instinkt — zwei Minuten am Tag reichen.';

  @override
  String get letsGo => 'Los geht\'s';

  @override
  String get summaryTitle => 'SITZUNG BEENDET';

  @override
  String get summaryPerfect => 'PERFEKT';

  @override
  String get summaryPassed => 'STUFE GESCHAFFT';

  @override
  String get summaryCompleted => 'ABGESCHLOSSEN';

  @override
  String get summaryNotYet => 'NOCH NICHT — WEITER SO';

  @override
  String get summaryCorrect => 'RICHTIG';

  @override
  String get summaryErrors => 'FEHLER';

  @override
  String get summaryTime => 'ZEIT';

  @override
  String get summaryAccuracy => 'TREFFER %';

  @override
  String get summaryModeMastery => 'MODUS-BEHERRSCHUNG';

  @override
  String get summaryNextDifficulty => 'NÄCHSTE STUFE SPIELEN';

  @override
  String summaryUpsellTitle(String key) {
    return 'Das war die kostenlose Hälfte von $key';
  }

  @override
  String get summaryUpsellBody =>
      'Chromatic ergänzt die fünf alterierten Stufen — den Rest der Tonart.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Lebenslange Lizenz';

  @override
  String get paywallTagline => 'Jede Tonart. Jeder Modus. Für immer.';

  @override
  String get paywallEvery => 'Jede ';

  @override
  String get paywallForever => 'Für immer.';

  @override
  String get paywallWhatYouGet => 'Was du bekommst, von Musiker zu Musiker';

  @override
  String get paywallCta => 'Lebenslangen Zugang freischalten';

  @override
  String paywallPrice(String price) {
    return '$price · einmalige Zahlung';
  }

  @override
  String get paywallRestore => 'Wiederherstellen';

  @override
  String get paywallNoPurchase => 'Kein früherer Kauf gefunden';

  @override
  String get featChromatic => 'Chromatic Mode';

  @override
  String get featChromaticMeta => 'alle 12 Tonarten';

  @override
  String get featNtn => 'Note to Number';

  @override
  String get featNtnMeta => 'chromatisch';

  @override
  String get featOfWhat => '…Of What?';

  @override
  String get featOfWhatMeta => 'alle 15 Stufen';

  @override
  String get featPocket => 'Pocket Mode';

  @override
  String get featPocketMeta => 'alle 12 Stufen';

  @override
  String get featCustom => 'Custom Mode';

  @override
  String get featCustomMeta => 'jede Stufe';

  @override
  String get featAdaptive => 'Adaptive Schwierigkeit';

  @override
  String get featAdaptiveMeta => 'automatisch';

  @override
  String get featAnalytics => 'Tiefe Analysen';

  @override
  String get featAnalyticsMeta => 'pro Tonart';

  @override
  String get storeNotReadyTitle => 'Store nicht bereit';

  @override
  String get storeNotReadyBody =>
      'Gerade ist kein Produkt zum Kauf verfügbar. Bitte versuche es gleich noch einmal.';

  @override
  String get almostThereTitle => 'Fast geschafft';

  @override
  String get almostThereBody =>
      'Die Zahlung ist durch, aber PRO konnte nicht automatisch aktiviert werden. Tippe gleich auf Käufe wiederherstellen — du wirst nicht doppelt belastet.';

  @override
  String get billingUnavailableTitle => 'Käufe nicht verfügbar';

  @override
  String get billingUnavailableBody =>
      'In-App-Käufe sind auf diesem Gerät nicht verfügbar.';

  @override
  String get purchaseFailedTitle => 'Kauf fehlgeschlagen';

  @override
  String get purchaseFailedBody =>
      'Beim Kontakt mit dem Store ist etwas schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get notifPromptTitle => 'Damit es sitzt';

  @override
  String get notifPromptBody =>
      'Ein kurzes Quiz am Tag hält jede Note scharf und deine Serie am Leben. Jederzeit abschaltbar.';

  @override
  String get notifPromptYes => 'Ja, erinnere mich';

  @override
  String get homeAllKeys => 'BEHERRSCHUNG ALLER TONARTEN';

  @override
  String get homeSpecialModes => 'SPEZIALMODI';

  @override
  String get homePickUp => 'WEITERMACHEN';

  @override
  String get homeTotalSessions => 'SITZUNGEN';

  @override
  String get homeAccuracy => 'TREFFER';

  @override
  String get homeTotalProgress => 'GESAMTFORTSCHRITT';

  @override
  String get homeNextMilestone => 'NÄCHSTER MEILENSTEIN';

  @override
  String get homeMaxLevel => 'MAX. LEVEL!';

  @override
  String homeLevelShort(int n) {
    return 'LVL $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% bis $animal';
  }

  @override
  String get homeNtnDesc => 'Zu einer Note die Stufe finden.';

  @override
  String get homeOfWhatDesc =>
      'Eine Note ist eine gegebene Stufe — nenne den Grundton. Harmonisiere jede Melodie.';

  @override
  String get homePocketDesc =>
      'Freihändige Audio-Übung: Eine Stimme fragt, wartet, sagt die Note. Läuft bei ausgeschaltetem Bildschirm.';

  @override
  String get homeCustomDesc =>
      'Wähle Tonart, Richtung und die Stufen, die du üben willst.';

  @override
  String homeLastSession(String when) {
    return 'LETZTE SITZUNG • $when';
  }

  @override
  String get homeResume => 'Sitzung fortsetzen';

  @override
  String get homeReadyTitle => 'Bereit?';

  @override
  String get homeReadyBody => 'Wähle oben eine Tonart';

  @override
  String get homeGamesPlayed => 'GESPIELTE RUNDEN';

  @override
  String get homeChooseMode => 'Modus wählen';

  @override
  String get homeChooseModeSub => 'Wie willst du heute üben?';

  @override
  String get homeDiatonicDesc => 'Beherrsche die 7 Töne der Tonleiter.';

  @override
  String get homeChromaticDesc => 'Fordere dich mit allen 12 Halbtönen.';

  @override
  String homeLockedTier(String prev) {
    return 'Übe weiter im Modus $prev, um diese Stufe freizuschalten.';
  }

  @override
  String get homeYourProgress => 'DEIN FORTSCHRITT';

  @override
  String get homeKeepTraining => 'WEITER ÜBEN';

  @override
  String get homeHandsFree => 'Freihändiges Audio';

  @override
  String get homeJustNow => 'Gerade eben';

  @override
  String homeMinutesAgo(int n) {
    return 'vor $n Min.';
  }

  @override
  String homeHoursAgo(int n) {
    return 'vor $n Std.';
  }

  @override
  String homeDaysAgo(int n) {
    return 'vor $n T.';
  }

  @override
  String get homeQuote1 =>
      'Jeder Meister war einmal Anfänger. Stellen wir uns die ersten Noten vor!';

  @override
  String get homeQuote2 => 'Halbzeit — dein Gespür wird schärfer. Dranbleiben!';

  @override
  String get homeQuote3 =>
      'Wahre Meisterschaft steckt im Detail. Vertrau deinem Instinkt und spiel!';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Tonart $key, $pct Prozent';
  }

  @override
  String get setupTrainingSetup => 'TRAININGS-SETUP';

  @override
  String get setupHarmonizeSetup => 'HARMONISIER-SETUP';

  @override
  String get setupPersonalized => 'FREIES ÜBEN · ZÄHLT NICHT ZUR BEHERRSCHUNG';

  @override
  String get setupHandsFree => 'FREIHÄNDIG · AUDIO';

  @override
  String get setupSelectRootKey => 'Tonart wählen';

  @override
  String get setupSelectRootKeySub => 'Wähle die Grundlage deines Trainings.';

  @override
  String get setupSelectNote => 'Note wählen';

  @override
  String get setupSelectNoteSub =>
      'Die Melodienote, die die ganze Sitzung gehalten wird.';

  @override
  String get setupIntensity => 'Intensität';

  @override
  String get setupIntensityChromatic =>
      'Beherrsche alle 12 chromatischen Töne dieser Tonart.';

  @override
  String get setupIntensityDiatonic =>
      'Konzentriere dich auf die 7 Töne der Durtonleiter.';

  @override
  String get setupDifficulty => 'Schwierigkeit';

  @override
  String get setupDifficultySub =>
      'Höhere Schwierigkeit heißt weniger Zeit zum Antworten.';

  @override
  String get setupMode => 'Modus';

  @override
  String get setupModeNormalSub =>
      'Nenne zu einer Stufe die Note, in dieser Tonart.';

  @override
  String get setupModeNtnSub =>
      'Nenne zu einer Note die Stufe, in dieser Tonart.';

  @override
  String get setupModeOfWhatSub =>
      'Eine Note wird durchgehend gehalten — nenne die Tonart, zu der sie gehört.';

  @override
  String get setupSelectDegrees => 'Stufen wählen';

  @override
  String get setupDegreesToAsk => 'Gefragte Stufen';

  @override
  String get setupDegreesAll => 'Alle Stufen, inklusive Erweiterungen.';

  @override
  String get setupDegreesChord => 'Die vier Akkordtöne: 1, 3, 5, 7.';

  @override
  String get setupChord => 'Akkord';

  @override
  String get setupAll => 'Alle';

  @override
  String get setupQuickChord => 'AKKORD';

  @override
  String get setupQuickAll => 'ALLE';

  @override
  String get setupQuickDiatonic => 'DIATONISCH';

  @override
  String get setupQuestions => 'Anzahl Fragen';

  @override
  String get setupQuestionsSub => 'Wie viele Fragen in dieser Sitzung?';

  @override
  String get setupKeys => 'Tonarten';

  @override
  String get setupKeysSub => 'Übe eine Tonart oder mische alle 12.';

  @override
  String get setupShuffleAll => 'Alle mischen';

  @override
  String get setupOneKey => 'Eine Tonart';

  @override
  String get setupDegrees => 'Stufen';

  @override
  String get setupAnswerDelay => 'Pause vor der Antwort';

  @override
  String get setupLength => 'Länge';

  @override
  String get setupLengthSub => 'Anzahl Fragen (∞ = bis du aufhörst).';

  @override
  String setupTierLocked(String tier) {
    return '$tier ist gesperrt';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Erreiche zuerst $need richtige in $prev. Du bist bei $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap REKORD';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct Prozent';
  }

  @override
  String get trainerCorrect => 'RICHTIG';

  @override
  String get trainerWrong => 'FALSCH';

  @override
  String get trainerCorrectAnswer => 'RICHTIGE ANTWORT';

  @override
  String get trainerNote => 'NOTE';

  @override
  String get trainerKey => 'TONART';

  @override
  String get trainerDegree => 'STUFE';

  @override
  String get trainerProgress => 'FORTSCHRITT';

  @override
  String get trainerStreak => 'SERIE';

  @override
  String get trainerPianoKeyboard => 'KLAVIATUR';

  @override
  String get trainerExitTitle => 'Sitzung beenden?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'Ein Versuch pro Tag, und die Uhr läuft weiter — wenn du jetzt gehst, ist $done/$total bis morgen dein Ergebnis.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'Du bist bei $done Fragen — Verlassen beendet die Runde und behält das Ergebnis.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'Du bist bei $done/$total — die Runde endet hier, wenn du gehst.';
  }

  @override
  String get trainerKeepPlaying => 'WEITERSPIELEN';

  @override
  String get trainerQuit => 'BEENDEN';

  @override
  String get paywallLine1 => 'Jede Tonart.';

  @override
  String get paywallLine2 => 'Jeder Modus.';

  @override
  String get paywallLine3 => 'Für immer.';

  @override
  String get paywallRestoring => 'Wird wiederhergestellt…';

  @override
  String get paywallTerms => 'Bedingungen';

  @override
  String get paywallPrivacy => 'Datenschutz';

  @override
  String get animalSnail => 'Schnecke';

  @override
  String get animalTurtle => 'Schildkröte';

  @override
  String get animalPenguin => 'Pinguin';

  @override
  String get animalRabbit => 'Hase';

  @override
  String get animalFox => 'Fuchs';

  @override
  String get animalHorse => 'Pferd';

  @override
  String get animalFalcon => 'Falke';

  @override
  String get animalCheetah => 'Gepard';

  @override
  String get homeShuffleHandsFree => 'Gemischt · freihändig';

  @override
  String homeTierDifficulty(String tier) {
    return 'Schwierigkeit $tier';
  }

  @override
  String get trainerGridView => 'RASTER';

  @override
  String get trainerAccuracy => 'TREFFER';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get settingsAccountStatus => 'KONTOSTATUS';

  @override
  String get settingsFreePlan => 'Gratis-Version';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub => 'Jeder Modus, jede Tonart — freigeschaltet.';

  @override
  String get settingsFreeSub => 'Tippen, um alles freizuschalten.';

  @override
  String get settingsActive => 'AKTIV';

  @override
  String get settingsTraining => 'TRAINING';

  @override
  String get settingsAdaptive => 'Adaptive Schwierigkeit';

  @override
  String get settingsAdaptiveTag => 'SMARTES TRAINING';

  @override
  String get settingsAdaptiveBody =>
      'Stufen, die du langsam oder falsch beantwortest, kommen deutlich öfter dran als die, die du kannst — richtig, aber langsam zählt noch als ungelernt. Die Uhr wird enger, wenn du gut bist, und lockerer, wenn du danebenliegst.';

  @override
  String get settingsAdaptiveLocked =>
      'PRO-Funktion — hol dir Pro für smartes Training, das sich deinen Schwächen anpasst.';

  @override
  String get settingsSimpleNotes => 'Einfache Notennamen';

  @override
  String get settingsSimpleNotesTag => 'SCHREIBWEISE';

  @override
  String get settingsSimpleNotesBody =>
      'Überall nur ein Name pro Note — keine Schrägstriche, keine Doppelnamen. C  Des  D  Es  E  F  Fis  G  As  A  B  H.';

  @override
  String get settingsKeyboardTonic => 'Klaviatur ab Grundton';

  @override
  String get settingsKeyboardTonicTag => 'KLAVIER-EINGABE';

  @override
  String get settingsKeyboardTonicBody =>
      'Das Klavier im Spiel beginnt beim Grundton deiner Tonart statt bei C.';

  @override
  String get settingsNotation => 'NOTATIONSSYSTEM';

  @override
  String get settingsFreeMode => 'FREIER MODUS';

  @override
  String get settingsFreeModeTitle => 'Freier Modus';

  @override
  String get settingsFreeModeSub =>
      'Zahlen in deinem Tempo. Keine Uhr, kein Ergebnis.';

  @override
  String get settingsNotifications => 'MITTEILUNGEN';

  @override
  String get settingsReminders => 'Tägliche Erinnerungen';

  @override
  String get settingsRemindersTag => 'QUIZ + SERIEN-RETTER';

  @override
  String get settingsRemindersBody =>
      'Ein kurzes Quiz am Tag, plus ein Stups, bevor deine Serie reißt.';

  @override
  String get settingsNews => 'NEUIGKEITEN';

  @override
  String get settingsWhatsNew => 'Was ist neu';

  @override
  String get settingsStore => 'STORE';

  @override
  String get settingsUpgrade => 'AUF PRO UPGRADEN';

  @override
  String get settingsRestorePurchases => 'KÄUFE WIEDERHERSTELLEN';

  @override
  String get settingsProRestored => 'PRO wiederhergestellt';

  @override
  String get settingsHomeScreen => 'HOME-BILDSCHIRM';

  @override
  String get settingsWidgets => 'Widgets';

  @override
  String get settingsWidgetsSub =>
      'Jede Stunde eine Frage, direkt auf dem Home-Bildschirm';

  @override
  String get settingsBackup => 'BACKUP';

  @override
  String get settingsExport => 'Fortschritt exportieren';

  @override
  String get settingsExportSub =>
      'Eine Datei mit jeder Tonart, jedem Ergebnis, jeder Einstellung';

  @override
  String get settingsExportFailed => 'Export konnte nicht gestartet werden';

  @override
  String get settingsRestoreFile => 'Aus Datei wiederherstellen';

  @override
  String get settingsRestoreFileSub => 'Ersetzt, was auf diesem Telefon ist';

  @override
  String get settingsRestored => 'Wiederhergestellt. Alles ist wieder da.';

  @override
  String get settingsRestoreTitle => 'Aus einer Datei wiederherstellen?';

  @override
  String get settingsRestoreBody =>
      'Alles auf diesem Telefon — jede Tonart, jedes Ergebnis, jede Einstellung — wird durch den Inhalt der Datei ersetzt. Deine Pro-Lizenz bleibt unberührt.';

  @override
  String get settingsChooseFile => 'Datei wählen';

  @override
  String get settingsSupport => 'SUPPORT';

  @override
  String get settingsRate => 'Improvy bewerten';

  @override
  String get settingsRateSub =>
      'Über Bewertungen finden andere Musiker die App';

  @override
  String get settingsFeedback => 'Feedback senden';

  @override
  String get settingsFeedbackSub => 'Direkt an uns, ohne die App zu verlassen';

  @override
  String get settingsFeedbackSent => 'Gesendet. Wir lesen jedes davon.';

  @override
  String get settingsContact => 'Support kontaktieren';

  @override
  String settingsWriteTo(String email) {
    return 'Schreib an $email';
  }

  @override
  String get settingsFollow => 'Dem Entwickler folgen';

  @override
  String settingsInstagram(String handle) {
    return 'Auf Instagram: @$handle';
  }

  @override
  String get settingsLegal => 'RECHTLICHES';

  @override
  String get settingsClearTitle => 'Alle Daten löschen?';

  @override
  String get settingsClearBody =>
      'Das löscht deinen gesamten Fortschritt und alle Statistiken dauerhaft.';

  @override
  String get settingsWidgetsTwo => 'ZWEI WIDGETS';

  @override
  String get settingsWidgetQuestion => 'Frage';

  @override
  String get settingsWidgetQuestionBody =>
      'Eine Tonleiterstufe wartet auf ihre Antwort, jede Stunde eine neue. Antippen zeigt die Antwort.';

  @override
  String get settingsWidgetDaily => 'Tages-Challenge';

  @override
  String get settingsWidgetDailyBody =>
      'Die Tonart des Tages, dein Ergebnis nach dem Spielen, und deine Serie.';

  @override
  String get settingsWidgetHow => 'SO FÜGST DU EINS HINZU';

  @override
  String get settingsWidgetIos1 =>
      'Halte eine leere Stelle des Home-Bildschirms gedrückt';

  @override
  String get settingsWidgetIos2 => 'Tippe oben auf das +';

  @override
  String get settingsWidgetIos3 => 'Suche Improvy und wähle ein Widget';

  @override
  String get settingsWidgetAndroid2 => 'Tippe auf Widgets';

  @override
  String get settingsWidgetAndroid3 =>
      'Finde Improvy und zieh ein Widget heraus';

  @override
  String statsLevel(int n) {
    return 'LEVEL $n';
  }

  @override
  String get statsOverall => 'GESAMT-\nBEHERRSCHUNG';

  @override
  String get statsNotes => 'NOTEN';

  @override
  String get statsStreak => 'SERIE';

  @override
  String get statsNothingYet => 'NOCH NICHTS ZU ZEIGEN';

  @override
  String get statsLast30 => 'STATISTIK DER LETZTEN 30 RUNDEN';

  @override
  String get statsSkillMastery => 'Beherrschung';

  @override
  String get statsLatestGame => 'LETZTE RUNDE';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'VOR $n RUNDEN',
      one: 'VOR 1 RUNDE',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'Keine Daten • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Reaktionszeit • $when';
  }

  @override
  String get statsResponseTime => 'Reaktionszeit';

  @override
  String get statsLatest => 'ZULETZT';

  @override
  String get statsSpeedTitle => 'Hier wohnt dein Tempo';

  @override
  String get statsSpeedBody =>
      'Spiel eine Sitzung und sieh zu, wie jede Antwort schneller wird.';

  @override
  String get statsDegreeAccuracy => 'Treffer pro Stufe';

  @override
  String get statsPlays => 'GESPIELT';

  @override
  String get statsAccuracy => 'TREFFER';

  @override
  String get statsGamesPlayed => 'Gespielte Runden';

  @override
  String get statsHeatmap => 'Klaviatur-Heatmap';

  @override
  String get statsByNote => 'LEISTUNG PRO NOTE';

  @override
  String get statsSlow => 'LANGSAM';

  @override
  String get statsFast => 'SCHNELL';

  @override
  String get statsRank => 'RANK';

  @override
  String get statsFirstRunTitle => 'Spiel eine Sitzung';

  @override
  String get statsFirstRunBody =>
      'Dreißig Fragen in einer Tonart, und jedes Diagramm auf dieser Seite füllt sich — dein Tempo, die Stufen, die du verfehlst, die Noten, die dich bremsen.';

  @override
  String get kaTitle => 'TONART-ANALYSE';

  @override
  String get kaMastery => 'BEHERRSCHUNG';

  @override
  String get kaAvgResp => 'Ø ANTWORT';

  @override
  String get kaPerAnswer => 'PRO ANTWORT';

  @override
  String get kaToday => 'HEUTE';

  @override
  String get kaAccuracyOverTime => 'Reaktionszeit';

  @override
  String get kaDegreeMastery => 'Chromatische Stufen';

  @override
  String get kaModeProgress => 'Fortschritt pro Modus';

  @override
  String get kaDegreeToNote => 'STUFE › NOTE';

  @override
  String get kaNoteToDegree => 'NOTE › STUFE';

  @override
  String get kaOfWhat => '…OF WHAT?';

  @override
  String get kaConfusions => 'Häufige Verwechslungen';

  @override
  String get kaNoConfusions => 'KEINE VERWECHSLUNGEN. STARK!';

  @override
  String get kaNote => 'NOTE';

  @override
  String get kaHarmonizer => 'Harmonizer';

  @override
  String get kaHarmonizerSub => '„…Of What?“-Beherrschung';

  @override
  String get dailyTitle => 'TAGES-CHALLENGE';

  @override
  String get dailyDone => 'CHALLENGE ERLEDIGT';

  @override
  String get dailyFlawless => 'MAKELLOS';

  @override
  String get dailyOutOfTime => 'ZEIT ABGELAUFEN';

  @override
  String get dailySharp => 'SCHARF';

  @override
  String get dailySolid => 'SOLIDE';

  @override
  String get dailyWarmingUp => 'AUFWÄRMEN';

  @override
  String get dailyTomorrow => 'MORGEN GIBT ES EINE NEUE TONART';

  @override
  String get dailyCopied => 'Ergebnis kopiert — füg es ein, wo du willst';

  @override
  String dailyNewIn(String when) {
    return 'Neue Challenge in $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Nächste Challenge in $when';
  }

  @override
  String get dailyBackHome => 'Zurück zum Start';

  @override
  String get dailyTheRun => 'DER DURCHLAUF';

  @override
  String get dailyStreak => 'CHALLENGE-SERIE';

  @override
  String get dailyShare => 'Ergebnis teilen';

  @override
  String get pocketTitle => 'POCKET MODE';

  @override
  String get pocketDegrees => 'STUFEN';

  @override
  String get pocketDelay => 'PAUSE';

  @override
  String get pocketSession => 'SITZUNG';

  @override
  String get pocketListen => 'HÖR ZU';

  @override
  String get pocketYourTurn => 'DU BIST DRAN';

  @override
  String get pocketAnswer => 'ANTWORT';

  @override
  String get pocketReady => 'BEREIT';

  @override
  String get pocketComplete => 'SITZUNG BEENDET';

  @override
  String get pocketPlaying => 'LÄUFT';

  @override
  String get pocketPaused => 'PAUSIERT';

  @override
  String get pocketScreenOff => 'Läuft auch bei ausgeschaltetem Bildschirm';

  @override
  String get pocketAudioSession => 'Audiositzung';

  @override
  String get feedbackTitle => 'Sag es uns';

  @override
  String get feedbackBody =>
      'Kommt direkt bei uns an. Keine Mail-App, kein Konto, kein Name, außer du schreibst einen.';

  @override
  String get feedbackHintBug =>
      'Was ist passiert, und was hast du gerade gemacht?';

  @override
  String get feedbackHint => 'Was immer du sagen willst.';

  @override
  String get feedbackEmail => 'Deine E-Mail — nur, wenn du eine Antwort willst';

  @override
  String get feedbackSend => 'SENDEN';

  @override
  String get feedbackKindBug => 'Etwas ist kaputt';

  @override
  String get feedbackKindIdea => 'Eine Idee';

  @override
  String get feedbackKindOther => 'Etwas anderes';

  @override
  String get levelUp => 'Level-Up!';

  @override
  String get levelUpYouAreNow => 'Du bist jetzt ';

  @override
  String get awesome => 'Stark!';

  @override
  String whatsNewVersionHere(String v) {
    return 'Version $v\nist da';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSION $v';
  }

  @override
  String get continueLabel => 'WEITER';

  @override
  String get fullChangelog => 'Vollständiges Änderungsprotokoll';

  @override
  String get quizFromHome => 'VON DEINEM HOME-BILDSCHIRM';

  @override
  String get quizTrain => 'Üben: ';

  @override
  String get freeModeTitle => 'FREIER MODUS';

  @override
  String get freeModeTapNext => 'IRGENDWO TIPPEN FÜR DIE NÄCHSTE';

  @override
  String get freeModeNumbersDone => 'ZAHLEN GESCHAFFT';

  @override
  String get freeModeSub => 'Kein Ergebnis, keine Uhr — nur Wiederholungen.';

  @override
  String get freeModeGoAgain => 'NOCHMAL';

  @override
  String get remTargetTitle => 'Gezieltes Üben 🎯';

  @override
  String get remDailyTitle => 'Tages-Challenge 🏆';

  @override
  String remDailyBody(String key) {
    return 'Die Challenge heute ist in $key-Dur — ein Versuch, mach ihn zählen.';
  }

  @override
  String get remQuizTitle => 'Kurzes Quiz 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return 'Was ist die $degree von $key-Dur? Tippen zum Prüfen.';
  }

  @override
  String remLevelBody(String pct) {
    return 'Dir fehlen $pct% zum nächsten Level. Lücke schließen?';
  }

  @override
  String get remMaxedBody => 'Am Maximum — halt die Reflexe scharf.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Jede Stufe, jede Tonart, sofort. Hast du 3 Minuten?';

  @override
  String get remEarTitle => 'Gehörtraining 🎧';

  @override
  String get remEarBody =>
      'Schnelles Abrufen schlägt langsame Theorie. Kurze Sitzung?';

  @override
  String get remFallbackBody => 'Zeit zum Üben?';

  @override
  String get remComeback3 =>
      'Stufen verblassen schnell, wenn du aufhörst. Deine Tonarten vermissen dich.';

  @override
  String get remComeback7 =>
      'Eine Woche weg — dein Sofort-Abruf braucht ein Aufwärmen. Kommst du zurück?';

  @override
  String get remStreakTitle => 'Reiß deine Serie nicht ab! 🔥';

  @override
  String remStreakBody(int n) {
    return 'Deine $n-Tage-Serie endet heute Nacht — 2 Minuten, um sie zu retten.';
  }

  @override
  String get clear => 'Löschen';

  @override
  String get statsSigNone => 'KEINE';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n KREUZE',
      one: '1 KREUZ',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n B',
      one: '1 B',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'Du verwechselst immer wieder $a und $b in $key-Dur. 10 Fragen, um es festzunageln?';
  }

  @override
  String get freeModeDone => 'GESCHAFFT';

  @override
  String get freeModeLeft => 'ÜBRIG';

  @override
  String get animalQuote1 => 'Langsam, aber stetig gewinnt!';

  @override
  String get animalQuote2 => 'Stetiger Fortschritt!';

  @override
  String get animalQuote3 => 'Gleitet wie geschmiert!';

  @override
  String get animalQuote4 => 'Schnell wie ein Hase!';

  @override
  String get animalQuote5 => 'Schlau und flink!';

  @override
  String get animalQuote6 => 'Im Galopp, mit Präzision!';

  @override
  String get animalQuote7 => 'Hoch hinaus! Scharfer Blick!';

  @override
  String get animalQuote8 => 'Unaufhaltsam! Ein wahrer Maestro!';

  @override
  String get explainerTapKey => 'TONART ANTIPPEN';

  @override
  String explainerQuestion(String key, String degree) {
    return 'Welcher Ton ist in $key die $degree?';
  }

  @override
  String get explainerRight => 'Genau.';

  @override
  String get explainerWrong => 'Fast — versuch es nochmal.';

  @override
  String get explainerAgain => 'Noch eine';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key insgesamt';
  }

  @override
  String statsTotalGamesChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n RUNDEN',
      one: '1 RUNDE',
    );
    return '$_temp0';
  }

  @override
  String homeBestOf(int score, int cap) {
    return '$score/$cap BESTE';
  }

  @override
  String get dailyMajorSuffix => 'Dur';

  @override
  String dailyStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dailyRule(int questions, int seconds) {
    return '$questions Fragen · $seconds Sekunden';
  }

  @override
  String get dailySubjectKeyOf => 'Tonart ';

  @override
  String get dailySubjectOn => 'Auf ';

  @override
  String get wQuestion => 'FRAGE';

  @override
  String get wQuestionLong => 'DIE FRAGE DES TAGES';

  @override
  String get wReveal => 'Zum Auflösen tippen';

  @override
  String get wDaily => 'CHALLENGE';

  @override
  String get wDailyLong => 'TAGES-CHALLENGE';

  @override
  String get wToday => 'heute';

  @override
  String get wDone => 'Erledigt';

  @override
  String get wTomorrow => 'Die nächste morgen';

  @override
  String get wLevel => 'DEIN LEVEL';

  @override
  String get wMastery => 'TONART-BEHERRSCHUNG';

  @override
  String get wStreak => 'SERIE';

  @override
  String get wDays => 'Tage in Folge';

  @override
  String get wDayStreak => 'Tage Serie';

  @override
  String get wAtRisk => 'Heute spielen, sonst ist sie weg';

  @override
  String get wNeedsWork => 'ZU ÜBEN';

  @override
  String get wMastered => 'beherrscht';

  @override
  String get wWeakHint => 'Deine schwächste Tonart. Zum Üben tippen.';

  @override
  String get wWeakEmpty => 'Spiel zuerst eine Tonart';

  @override
  String get wStart => 'TRAINING STARTEN';

  @override
  String get wHandsFree => 'FREIHÄNDIG';

  @override
  String get wPocketSub => 'Üben mit ausgeschaltetem Display';

  @override
  String get wTheory => 'DIE STUFE DES TAGES';

  @override
  String get wOpenApp => 'Öffne Improvy, um sie zu füllen.';

  @override
  String get statsSkillMasterySub =>
      'Je Tonart: Stufe › Ton, Ton › Stufe, …Of What?';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get cancel => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get close => 'Fermer';

  @override
  String get gotIt => 'Compris';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get retry => 'REJOUER';

  @override
  String get home => 'ACCUEIL';

  @override
  String get start => 'COMMENCER';

  @override
  String get startTraining => 'COMMENCER L\'ENTRAÎNEMENT';

  @override
  String get proOnly => 'PRO UNIQUEMENT';

  @override
  String get free => 'GRATUIT';

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
  String get tierApprentice => 'Apprenti';

  @override
  String get tierVirtuoso => 'Virtuose';

  @override
  String get tierMaster => 'Maître';

  @override
  String get onboardingTag => 'Entraînement mental';

  @override
  String get onboardingHeadline => 'Chaque note\nest un\nnombre.';

  @override
  String get onboardingPromise =>
      'Voyez instantanément le nombre sous n\'importe quelle note, dans les douze tonalités — sans compter, sans livre de théorie.';

  @override
  String get onboardingStart => 'Commencer l\'entraînement';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get explainerEyebrow => 'COMMENT ÇA MARCHE';

  @override
  String explainerStep(int n) {
    return '$n SUR 3';
  }

  @override
  String get explainer1Title => 'Chaque touche\na un numéro.';

  @override
  String get explainer1Body =>
      'Voici les sept notes de Do majeur. Les musiciens les appellent par leur numéro — le degré — parce que le numéro dit ce que fait la note, et ça marche pareil dans toutes les tonalités.';

  @override
  String get explainer2Title => 'Changez de tonalité.\nLes numéros restent.';

  @override
  String get explainer2Body =>
      'Touchez une tonalité et regardez. Les notes bougent, pas les numéros : le 5 est toujours le 5. Apprenez les numéros une fois et vous avez les douze tonalités.';

  @override
  String get explainer3Title => 'Essayez.';

  @override
  String get explainer3Body =>
      'C\'est tout le jeu. Assez vite, assez souvent, et ce n\'est plus de l\'arithmétique mais de l\'instinct — deux minutes par jour suffisent.';

  @override
  String get letsGo => 'C\'est parti';

  @override
  String get summaryTitle => 'SESSION TERMINÉE';

  @override
  String get summaryPerfect => 'SCORE PARFAIT';

  @override
  String get summaryPassed => 'NIVEAU RÉUSSI';

  @override
  String get summaryCompleted => 'TERMINÉE';

  @override
  String get summaryNotYet => 'PAS ENCORE — CONTINUEZ';

  @override
  String get summaryCorrect => 'JUSTES';

  @override
  String get summaryErrors => 'ERREURS';

  @override
  String get summaryTime => 'TEMPS';

  @override
  String get summaryAccuracy => 'PRÉCISION %';

  @override
  String get summaryModeMastery => 'MAÎTRISE DU MODE';

  @override
  String get summaryNextDifficulty => 'DIFFICULTÉ SUIVANTE';

  @override
  String summaryUpsellTitle(String key) {
    return 'C\'était la moitié gratuite de $key';
  }

  @override
  String get summaryUpsellBody =>
      'Chromatic ajoute les cinq degrés altérés — le reste de la tonalité.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Licence à vie';

  @override
  String get paywallTagline => 'Chaque tonalité. Chaque mode. Pour toujours.';

  @override
  String get paywallEvery => 'Chaque ';

  @override
  String get paywallForever => 'Pour toujours.';

  @override
  String get paywallWhatYouGet => 'Ce que vous obtenez, de musicien à musicien';

  @override
  String get paywallCta => 'Débloquer l\'accès à vie';

  @override
  String paywallPrice(String price) {
    return '$price · paiement unique';
  }

  @override
  String get paywallRestore => 'Restaurer';

  @override
  String get paywallNoPurchase => 'Aucun achat précédent trouvé';

  @override
  String get featChromatic => 'Chromatic Mode';

  @override
  String get featChromaticMeta => 'les 12 tonalités';

  @override
  String get featNtn => 'Note to Number';

  @override
  String get featNtnMeta => 'chromatique';

  @override
  String get featOfWhat => '…Of What?';

  @override
  String get featOfWhatMeta => 'les 15 degrés';

  @override
  String get featPocket => 'Pocket Mode';

  @override
  String get featPocketMeta => 'les 12 degrés';

  @override
  String get featCustom => 'Custom Mode';

  @override
  String get featCustomMeta => 'n\'importe quel degré';

  @override
  String get featAdaptive => 'Difficulté adaptative';

  @override
  String get featAdaptiveMeta => 'auto';

  @override
  String get featAnalytics => 'Analyses approfondies';

  @override
  String get featAnalyticsMeta => 'par tonalité';

  @override
  String get storeNotReadyTitle => 'Boutique indisponible';

  @override
  String get storeNotReadyBody =>
      'Aucun produit n\'est disponible à l\'achat pour le moment. Réessayez dans un instant.';

  @override
  String get almostThereTitle => 'Presque';

  @override
  String get almostThereBody =>
      'Le paiement est passé mais PRO n\'a pas pu être activé automatiquement. Touchez Restaurer les achats dans un instant — vous ne serez pas facturé deux fois.';

  @override
  String get billingUnavailableTitle => 'Achats indisponibles';

  @override
  String get billingUnavailableBody =>
      'Les achats intégrés ne sont pas disponibles sur cet appareil.';

  @override
  String get purchaseFailedTitle => 'Achat échoué';

  @override
  String get purchaseFailedBody =>
      'Un problème est survenu en contactant la boutique. Réessayez.';

  @override
  String get notifPromptTitle => 'Pour que ça reste';

  @override
  String get notifPromptBody =>
      'Un quiz rapide par jour garde chaque note affûtée et votre série en vie. Désactivable quand vous voulez.';

  @override
  String get notifPromptYes => 'Oui, rappelez-le-moi';

  @override
  String get homeAllKeys => 'MAÎTRISE DE TOUTES LES TONALITÉS';

  @override
  String get homeSpecialModes => 'MODES SPÉCIAUX';

  @override
  String get homePickUp => 'REPRENDRE OÙ VOUS EN ÉTIEZ';

  @override
  String get homeTotalSessions => 'SESSIONS TOTALES';

  @override
  String get homeAccuracy => 'PRÉCISION';

  @override
  String get homeTotalProgress => 'PROGRESSION TOTALE';

  @override
  String get homeNextMilestone => 'PROCHAIN PALIER';

  @override
  String get homeMaxLevel => 'NIVEAU MAX !';

  @override
  String homeLevelShort(int n) {
    return 'NIV $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% avant $animal';
  }

  @override
  String get homeNtnDesc => 'À partir d\'une note, identifiez son degré.';

  @override
  String get homeOfWhatDesc =>
      'Une note est un degré donné — nommez la tonique. Harmonisez n\'importe quelle mélodie.';

  @override
  String get homePocketDesc =>
      'Exercice audio mains libres : une voix demande, attend, puis dit la note. Fonctionne écran éteint.';

  @override
  String get homeCustomDesc =>
      'Choisissez la tonalité, le sens et les degrés précis à travailler.';

  @override
  String homeLastSession(String when) {
    return 'DERNIÈRE SESSION • $when';
  }

  @override
  String get homeResume => 'Reprendre la session';

  @override
  String get homeReadyTitle => 'Prêt à commencer ?';

  @override
  String get homeReadyBody => 'Choisissez une tonalité ci-dessus';

  @override
  String get homeGamesPlayed => 'PARTIES JOUÉES';

  @override
  String get homeChooseMode => 'Choisir le mode';

  @override
  String get homeChooseModeSub =>
      'Choisissez comment vous entraîner aujourd\'hui';

  @override
  String get homeDiatonicDesc => 'Maîtrisez les 7 notes de la gamme.';

  @override
  String get homeChromaticDesc => 'Défiez-vous sur les 12 demi-tons.';

  @override
  String homeLockedTier(String prev) {
    return 'Continuez en mode $prev pour débloquer cette difficulté.';
  }

  @override
  String get homeYourProgress => 'VOTRE PROGRESSION';

  @override
  String get homeKeepTraining => 'CONTINUEZ';

  @override
  String get homeHandsFree => 'Audio mains libres';

  @override
  String get homeJustNow => 'À l\'instant';

  @override
  String homeMinutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String homeHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String homeDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String get homeQuote1 =>
      'Tout maître a été débutant. Visualisons ces premières notes !';

  @override
  String get homeQuote2 =>
      'À mi-chemin — vos réflexes s\'affûtent. Continuez !';

  @override
  String get homeQuote3 =>
      'La vraie maîtrise est dans les détails. Faites confiance à votre instinct et jouez !';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Tonalité de $key, $pct pour cent';
  }

  @override
  String get setupTrainingSetup => 'RÉGLAGES DE L\'ENTRAÎNEMENT';

  @override
  String get setupHarmonizeSetup => 'RÉGLAGES D\'HARMONISATION';

  @override
  String get setupPersonalized =>
      'PRATIQUE LIBRE · NE COMPTE PAS POUR LA MAÎTRISE';

  @override
  String get setupHandsFree => 'MAINS LIBRES · AUDIO';

  @override
  String get setupSelectRootKey => 'Choisir la tonalité';

  @override
  String get setupSelectRootKeySub =>
      'Choisissez la base de votre entraînement.';

  @override
  String get setupSelectNote => 'Choisir la note';

  @override
  String get setupSelectNoteSub =>
      'La note de mélodie tenue pendant toute la session.';

  @override
  String get setupIntensity => 'Intensité';

  @override
  String get setupIntensityChromatic =>
      'Maîtrisez les 12 notes chromatiques de cette tonalité.';

  @override
  String get setupIntensityDiatonic =>
      'Concentrez-vous sur les 7 notes de la gamme majeure.';

  @override
  String get setupDifficulty => 'Difficulté';

  @override
  String get setupDifficultySub =>
      'Plus de difficulté, moins de temps pour répondre.';

  @override
  String get setupMode => 'Mode';

  @override
  String get setupModeNormalSub =>
      'Nommez la note d\'un degré, dans cette tonalité.';

  @override
  String get setupModeNtnSub =>
      'Nommez le degré d\'une note, dans cette tonalité.';

  @override
  String get setupModeOfWhatSub =>
      'Une note tenue tout du long — nommez la tonalité à laquelle elle appartient.';

  @override
  String get setupSelectDegrees => 'Choisir les degrés';

  @override
  String get setupDegreesToAsk => 'Degrés demandés';

  @override
  String get setupDegreesAll => 'Tous les degrés, extensions comprises.';

  @override
  String get setupDegreesChord => 'Les quatre notes de l\'accord : 1, 3, 5, 7.';

  @override
  String get setupChord => 'Accord';

  @override
  String get setupAll => 'Tous';

  @override
  String get setupQuickChord => 'ACCORD';

  @override
  String get setupQuickAll => 'TOUS';

  @override
  String get setupQuickDiatonic => 'DIATONIQUE';

  @override
  String get setupQuestions => 'Nombre de questions';

  @override
  String get setupQuestionsSub => 'Combien de questions pour cette session ?';

  @override
  String get setupKeys => 'Tonalités';

  @override
  String get setupKeysSub => 'Travaillez une tonalité, ou mélangez les 12.';

  @override
  String get setupShuffleAll => 'Tout mélanger';

  @override
  String get setupOneKey => 'Une tonalité';

  @override
  String get setupDegrees => 'Degrés';

  @override
  String get setupAnswerDelay => 'Délai avant la réponse';

  @override
  String get setupLength => 'Durée';

  @override
  String get setupLengthSub =>
      'Nombre de questions (∞ = jusqu\'à ce que vous arrêtiez).';

  @override
  String setupTierLocked(String tier) {
    return '$tier est verrouillé';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Atteignez d\'abord $need bonnes réponses en $prev. Vous en êtes à $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap RECORD';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct pour cent';
  }

  @override
  String get trainerCorrect => 'JUSTE';

  @override
  String get trainerWrong => 'FAUX';

  @override
  String get trainerCorrectAnswer => 'BONNE RÉPONSE';

  @override
  String get trainerNote => 'NOTE';

  @override
  String get trainerKey => 'TONALITÉ';

  @override
  String get trainerDegree => 'DEGRÉ';

  @override
  String get trainerProgress => 'PROGRESSION';

  @override
  String get trainerStreak => 'SÉRIE';

  @override
  String get trainerPianoKeyboard => 'CLAVIER';

  @override
  String get trainerExitTitle => 'Terminer la session ?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'Un essai par jour et le chrono continue — si vous partez maintenant, $done/$total sera votre score jusqu\'à demain.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'Vous en êtes à $done questions — partir termine la session et garde le score.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'Vous en êtes à $done/$total — la session s\'arrête ici si vous partez.';
  }

  @override
  String get trainerKeepPlaying => 'CONTINUER';

  @override
  String get trainerQuit => 'QUITTER';

  @override
  String get paywallLine1 => 'Chaque tonalité.';

  @override
  String get paywallLine2 => 'Chaque mode.';

  @override
  String get paywallLine3 => 'Pour toujours.';

  @override
  String get paywallRestoring => 'Restauration…';

  @override
  String get paywallTerms => 'Conditions';

  @override
  String get paywallPrivacy => 'Confidentialité';

  @override
  String get animalSnail => 'Escargot';

  @override
  String get animalTurtle => 'Tortue';

  @override
  String get animalPenguin => 'Manchot';

  @override
  String get animalRabbit => 'Lapin';

  @override
  String get animalFox => 'Renard';

  @override
  String get animalHorse => 'Cheval';

  @override
  String get animalFalcon => 'Faucon';

  @override
  String get animalCheetah => 'Guépard';

  @override
  String get homeShuffleHandsFree => 'Mélangées · mains libres';

  @override
  String homeTierDifficulty(String tier) {
    return 'Difficulté $tier';
  }

  @override
  String get trainerGridView => 'GRILLE';

  @override
  String get trainerAccuracy => 'PRÉCISION';

  @override
  String get settingsTitle => 'RÉGLAGES';

  @override
  String get settingsAccountStatus => 'ÉTAT DU COMPTE';

  @override
  String get settingsFreePlan => 'Offre gratuite';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub =>
      'Tous les modes et toutes les tonalités, débloqués.';

  @override
  String get settingsFreeSub => 'Touchez pour tout débloquer.';

  @override
  String get settingsActive => 'ACTIF';

  @override
  String get settingsTraining => 'ENTRAÎNEMENT';

  @override
  String get settingsAdaptive => 'Difficulté adaptative';

  @override
  String get settingsAdaptiveTag => 'ENTRAÎNEMENT INTELLIGENT';

  @override
  String get settingsAdaptiveBody =>
      'Les degrés auxquels vous répondez lentement ou faux reviennent bien plus souvent que ceux que vous maîtrisez — juste mais lent compte encore comme non appris. Le chrono se resserre quand vous êtes affûté et se relâche quand vous commencez à rater.';

  @override
  String get settingsAdaptiveLocked =>
      'Fonction PRO — passez à Pro pour débloquer l\'entraînement intelligent qui s\'adapte à vos faiblesses.';

  @override
  String get settingsSimpleNotes => 'Noms de notes simples';

  @override
  String get settingsSimpleNotesTag => 'ORTHOGRAPHE DES NOTES';

  @override
  String get settingsSimpleNotesBody =>
      'Un seul nom par note partout — pas de barres, pas de doubles noms. Do  Ré♭  Ré  Mi♭  Mi  Fa  Fa♯  Sol  La♭  La  Si♭  Si.';

  @override
  String get settingsKeyboardTonic => 'Clavier depuis la tonique';

  @override
  String get settingsKeyboardTonicTag => 'SAISIE AU PIANO';

  @override
  String get settingsKeyboardTonicBody =>
      'Le piano du jeu commence sur la tonique de votre tonalité au lieu de Do.';

  @override
  String get settingsNotation => 'SYSTÈME DE NOTATION';

  @override
  String get settingsFreeMode => 'MODE LIBRE';

  @override
  String get settingsFreeModeTitle => 'Mode libre';

  @override
  String get settingsFreeModeSub =>
      'Des nombres à votre rythme. Pas de chrono, pas de score.';

  @override
  String get settingsNotifications => 'NOTIFICATIONS';

  @override
  String get settingsReminders => 'Rappels quotidiens';

  @override
  String get settingsRemindersTag => 'QUIZ + SAUVE-SÉRIE';

  @override
  String get settingsRemindersBody =>
      'Un quiz rapide par jour, plus un rappel avant que votre série ne s\'arrête.';

  @override
  String get settingsNews => 'NOUVEAUTÉS';

  @override
  String get settingsWhatsNew => 'Nouveautés';

  @override
  String get settingsStore => 'BOUTIQUE';

  @override
  String get settingsUpgrade => 'PASSER À PRO';

  @override
  String get settingsRestorePurchases => 'RESTAURER LES ACHATS';

  @override
  String get settingsProRestored => 'PRO restauré';

  @override
  String get settingsHomeScreen => 'ÉCRAN D\'ACCUEIL';

  @override
  String get settingsWidgets => 'Widgets';

  @override
  String get settingsWidgetsSub =>
      'Une question par heure, sur votre écran d\'accueil';

  @override
  String get settingsSupport => 'ASSISTANCE';

  @override
  String get settingsRate => 'Noter Improvy';

  @override
  String get settingsRateSub =>
      'Une note, c\'est ainsi que d\'autres musiciens la trouvent';

  @override
  String get settingsFeedback => 'Envoyer un retour';

  @override
  String get settingsFeedbackSub => 'Directement à nous, sans quitter l\'app';

  @override
  String get settingsFeedbackSent => 'Envoyé. Nous les lisons tous.';

  @override
  String get settingsContact => 'Contacter l\'assistance';

  @override
  String settingsWriteTo(String email) {
    return 'Écrivez à $email';
  }

  @override
  String get settingsFollow => 'Suivre le développeur';

  @override
  String settingsInstagram(String handle) {
    return 'Retrouvez-nous sur Instagram : @$handle';
  }

  @override
  String get settingsLegal => 'MENTIONS LÉGALES';

  @override
  String get settingsClearTitle => 'Effacer toutes les données ?';

  @override
  String get settingsClearBody =>
      'Cela supprimera définitivement toute votre progression et vos statistiques.';

  @override
  String get settingsWidgetsTwo => 'DEUX WIDGETS';

  @override
  String get settingsWidgetQuestion => 'Question';

  @override
  String get settingsWidgetQuestionBody =>
      'Un degré de la gamme en attente de réponse, un nouveau chaque heure. Touchez-le pour voir la réponse.';

  @override
  String get settingsWidgetDaily => 'Défi du jour';

  @override
  String get settingsWidgetDailyBody =>
      'La tonalité du jour, votre score une fois joué, et votre série.';

  @override
  String get settingsWidgetHow => 'COMMENT EN AJOUTER UN';

  @override
  String get settingsWidgetIos1 =>
      'Maintenez un espace vide de l\'écran d\'accueil';

  @override
  String get settingsWidgetIos2 => 'Touchez le + en haut';

  @override
  String get settingsWidgetIos3 => 'Cherchez Improvy et choisissez un widget';

  @override
  String get settingsWidgetAndroid2 => 'Touchez Widgets';

  @override
  String get settingsWidgetAndroid3 =>
      'Trouvez Improvy et faites glisser un widget';

  @override
  String statsLevel(int n) {
    return 'NIVEAU $n';
  }

  @override
  String get statsOverall => 'MAÎTRISE\nGLOBALE';

  @override
  String get statsNotes => 'NOTES';

  @override
  String get statsStreak => 'SÉRIE';

  @override
  String get statsNothingYet => 'RIEN À AFFICHER POUR L\'INSTANT';

  @override
  String get statsLast30 => 'STATISTIQUES SUR LES 30 DERNIÈRES PARTIES';

  @override
  String get statsSkillMastery => 'Maîtrise';

  @override
  String get statsLatestGame => 'DERNIÈRE PARTIE';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'IL Y A $n PARTIES',
      one: 'IL Y A 1 PARTIE',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'Pas de données • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Temps de réponse • $when';
  }

  @override
  String get statsResponseTime => 'Temps de réponse';

  @override
  String get statsLatest => 'DERNIÈRE';

  @override
  String get statsSpeedTitle => 'Votre vitesse vit ici';

  @override
  String get statsSpeedBody =>
      'Jouez une session et regardez chaque réponse s\'accélérer.';

  @override
  String get statsDegreeAccuracy => 'Précision par degré';

  @override
  String get statsPlays => 'JOUÉES';

  @override
  String get statsAccuracy => 'PRÉCISION';

  @override
  String get statsGamesPlayed => 'Parties jouées';

  @override
  String get statsHeatmap => 'Carte du clavier';

  @override
  String get statsByNote => 'PERFORMANCE PAR NOTE';

  @override
  String get statsSlow => 'LENT';

  @override
  String get statsFast => 'RAPIDE';

  @override
  String get statsRank => 'RANK';

  @override
  String get statsFirstRunTitle => 'Jouez une session';

  @override
  String get statsFirstRunBody =>
      'Trente questions dans une tonalité et chaque graphique de cette page se remplit — votre vitesse, les degrés que vous ratez, les notes qui vous ralentissent.';

  @override
  String get kaTitle => 'ANALYSE DE LA TONALITÉ';

  @override
  String get kaMastery => 'MAÎTRISE';

  @override
  String get kaAvgResp => 'RÉP. MOY.';

  @override
  String get kaPerAnswer => 'PAR RÉPONSE';

  @override
  String get kaToday => 'AUJOURD\'HUI';

  @override
  String get kaAccuracyOverTime => 'Temps de réponse';

  @override
  String get kaDegreeMastery => 'Maîtrise des degrés chromatiques';

  @override
  String get kaModeProgress => 'Progression par mode';

  @override
  String get kaDegreeToNote => 'DEGRÉ › NOTE';

  @override
  String get kaNoteToDegree => 'NOTE › DEGRÉ';

  @override
  String get kaOfWhat => '…OF WHAT?';

  @override
  String get kaConfusions => 'Confusions fréquentes';

  @override
  String get kaNoConfusions => 'AUCUNE CONFUSION. BRAVO !';

  @override
  String get kaNote => 'NOTE';

  @override
  String get kaHarmonizer => 'Harmonizer';

  @override
  String get kaHarmonizerSub => 'Maîtrise de « …Of What? »';

  @override
  String get dailyTitle => 'DÉFI DU JOUR';

  @override
  String get dailyDone => 'DÉFI RELEVÉ';

  @override
  String get dailyFlawless => 'SANS FAUTE';

  @override
  String get dailyOutOfTime => 'TEMPS ÉCOULÉ';

  @override
  String get dailySharp => 'AFFÛTÉ';

  @override
  String get dailySolid => 'SOLIDE';

  @override
  String get dailyWarmingUp => 'EN CHAUFFE';

  @override
  String get dailyTomorrow => 'DEMAIN, NOUVELLE TONALITÉ';

  @override
  String get dailyCopied => 'Résultat copié — collez-le où vous voulez';

  @override
  String dailyNewIn(String when) {
    return 'Nouveau défi dans $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Prochain défi dans $when';
  }

  @override
  String get dailyBackHome => 'Retour à l\'accueil';

  @override
  String get dailyTheRun => 'LA SÉRIE';

  @override
  String get dailyStreak => 'SÉRIE DE DÉFIS';

  @override
  String get dailyShare => 'Partagez votre résultat';

  @override
  String get pocketTitle => 'POCKET MODE';

  @override
  String get pocketDegrees => 'DEGRÉS';

  @override
  String get pocketDelay => 'DÉLAI';

  @override
  String get pocketSession => 'SESSION';

  @override
  String get pocketListen => 'ÉCOUTEZ';

  @override
  String get pocketYourTurn => 'À VOUS';

  @override
  String get pocketAnswer => 'RÉPONSE';

  @override
  String get pocketReady => 'PRÊT';

  @override
  String get pocketComplete => 'SESSION TERMINÉE';

  @override
  String get pocketPlaying => 'EN COURS';

  @override
  String get pocketPaused => 'EN PAUSE';

  @override
  String get pocketScreenOff => 'Continue écran éteint';

  @override
  String get pocketAudioSession => 'Session audio';

  @override
  String get feedbackTitle => 'Dites-nous';

  @override
  String get feedbackBody =>
      'Ça nous arrive directement. Pas d\'app mail, pas de compte, pas de nom sauf si vous l\'écrivez.';

  @override
  String get feedbackHintBug => 'Que s\'est-il passé, et que faisiez-vous ?';

  @override
  String get feedbackHint => 'Ce que vous voulez nous dire.';

  @override
  String get feedbackEmail =>
      'Votre e-mail — seulement si vous voulez une réponse';

  @override
  String get feedbackSend => 'ENVOYER';

  @override
  String get feedbackKindBug => 'Quelque chose ne va pas';

  @override
  String get feedbackKindIdea => 'Une idée';

  @override
  String get feedbackKindOther => 'Autre chose';

  @override
  String get levelUp => 'Niveau supérieur !';

  @override
  String get levelUpYouAreNow => 'Vous êtes maintenant ';

  @override
  String get awesome => 'Génial !';

  @override
  String whatsNewVersionHere(String v) {
    return 'La version $v\nest là';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSION $v';
  }

  @override
  String get continueLabel => 'CONTINUER';

  @override
  String get fullChangelog => 'Journal complet des modifications';

  @override
  String get quizFromHome => 'DEPUIS VOTRE ÉCRAN D\'ACCUEIL';

  @override
  String get quizTrain => 'Travailler ';

  @override
  String get freeModeTitle => 'MODE LIBRE';

  @override
  String get freeModeTapNext => 'TOUCHEZ N\'IMPORTE OÙ POUR LE SUIVANT';

  @override
  String get freeModeNumbersDone => 'NOMBRES FAITS';

  @override
  String get freeModeSub =>
      'Pas de score, pas de chrono — juste des répétitions.';

  @override
  String get freeModeGoAgain => 'ENCORE';

  @override
  String get remTargetTitle => 'Entraînement ciblé 🎯';

  @override
  String get remDailyTitle => 'Défi du jour 🏆';

  @override
  String remDailyBody(String key) {
    return 'Le défi du jour est en $key majeur — un seul essai, faites-le compter.';
  }

  @override
  String get remQuizTitle => 'Quiz rapide 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return 'Quel est le $degree de $key majeur ? Touchez pour vérifier.';
  }

  @override
  String remLevelBody(String pct) {
    return 'Il vous manque $pct% pour passer au niveau suivant. On comble l\'écart ?';
  }

  @override
  String get remMaxedBody => 'Au maximum — gardez ces réflexes affûtés.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Chaque degré, chaque tonalité, instantanément. 3 minutes ?';

  @override
  String get remEarTitle => 'Entraînement de l\'oreille 🎧';

  @override
  String get remEarBody =>
      'Le rappel rapide bat la théorie lente. Une session rapide ?';

  @override
  String get remFallbackBody => 'L\'heure de s\'entraîner ?';

  @override
  String get remComeback3 =>
      'Les degrés s\'oublient vite quand on s\'arrête. Vos tonalités vous attendent.';

  @override
  String get remComeback7 =>
      'Une semaine sans jouer — votre rappel instantané a besoin de chauffer. On revient ?';

  @override
  String get remStreakTitle => 'Ne cassez pas votre série ! 🔥';

  @override
  String remStreakBody(int n) {
    return 'Votre série de $n jours s\'arrête ce soir — 2 minutes pour la garder en vie.';
  }

  @override
  String get clear => 'Effacer';

  @override
  String get statsSigNone => 'AUCUNE';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n DIÈSES',
      one: '1 DIÈSE',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n BÉMOLS',
      one: '1 BÉMOL',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'Vous confondez encore $a et $b en $key majeur. 10 questions pour régler ça ?';
  }

  @override
  String get freeModeDone => 'FAITS';

  @override
  String get freeModeLeft => 'RESTANTS';

  @override
  String get animalQuote1 => 'Lentement mais sûrement !';

  @override
  String get animalQuote2 => 'Progression régulière !';

  @override
  String get animalQuote3 => 'Ça glisse tout seul !';

  @override
  String get animalQuote4 => 'Rapide comme un lièvre !';

  @override
  String get animalQuote5 => 'Rusé et vif !';

  @override
  String get animalQuote6 => 'Au galop, avec précision !';

  @override
  String get animalQuote7 => 'Toujours plus haut ! Vue perçante !';

  @override
  String get animalQuote8 => 'Inarrêtable ! Vrai Maestro !';

  @override
  String get explainerTapKey => 'TOUCHEZ UNE TONALITÉ';

  @override
  String explainerQuestion(String key, String degree) {
    return 'En $key, quelle note est le $degree ?';
  }

  @override
  String get explainerRight => 'C\'est ça.';

  @override
  String get explainerWrong => 'Presque — réessayez.';

  @override
  String get explainerAgain => 'Une autre';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key au total';
  }

  @override
  String statsTotalGamesChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n PARTIES',
      one: '1 PARTIE',
    );
    return '$_temp0';
  }

  @override
  String homeBestOf(int score, int cap) {
    return '$score/$cap RECORD';
  }

  @override
  String get dailyMajorSuffix => 'majeur';

  @override
  String dailyStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String dailyRule(int questions, int seconds) {
    return '$questions questions · $seconds secondes';
  }

  @override
  String get dailySubjectKeyOf => 'Tonalité de ';

  @override
  String get dailySubjectOn => 'Sur ';

  @override
  String get wQuestion => 'QUESTION';

  @override
  String get wQuestionLong => 'LA QUESTION DU JOUR';

  @override
  String get wReveal => 'Touchez pour voir';

  @override
  String get wDaily => 'DÉFI';

  @override
  String get wDailyLong => 'DÉFI DU JOUR';

  @override
  String get wToday => 'aujourd\'hui';

  @override
  String get wDone => 'Fait';

  @override
  String get wTomorrow => 'Le prochain demain';

  @override
  String get wLevel => 'VOTRE NIVEAU';

  @override
  String get wMastery => 'MAÎTRISE DES TONALITÉS';

  @override
  String get wStreak => 'SÉRIE';

  @override
  String get wDays => 'jours d’affilée';

  @override
  String get wDayStreak => 'jours de série';

  @override
  String get wAtRisk => 'Jouez aujourd’hui pour la garder';

  @override
  String get wNeedsWork => 'À TRAVAILLER';

  @override
  String get wMastered => 'maîtrisée';

  @override
  String get wWeakHint =>
      'Votre tonalité la plus faible. Touchez pour la travailler.';

  @override
  String get wWeakEmpty => 'Jouez d’abord une tonalité';

  @override
  String get wStart => 'COMMENCER';

  @override
  String get wHandsFree => 'MAINS LIBRES';

  @override
  String get wPocketSub => 'Travaillez écran éteint';

  @override
  String get wTheory => 'LE DEGRÉ DU JOUR';

  @override
  String get wOpenApp => 'Ouvrez Improvy pour la remplir.';
}

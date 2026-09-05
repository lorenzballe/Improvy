// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get gotIt => 'Got it';

  @override
  String get notNow => 'Not now';

  @override
  String get retry => 'RETRY';

  @override
  String get home => 'HOME';

  @override
  String get start => 'START';

  @override
  String get startTraining => 'START TRAINING';

  @override
  String get proOnly => 'PRO ONLY';

  @override
  String get free => 'FREE';

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
  String get tierApprentice => 'Apprentice';

  @override
  String get tierVirtuoso => 'Virtuoso';

  @override
  String get tierMaster => 'Master';

  @override
  String get onboardingTag => 'Mental training';

  @override
  String get onboardingHeadline => 'Every note\nis a\nnumber.';

  @override
  String get onboardingPromise =>
      'See the number under any note instantly, in all twelve keys — no counting, no theory book.';

  @override
  String get onboardingStart => 'Start training';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get explainerEyebrow => 'HOW IT WORKS';

  @override
  String explainerStep(int n) {
    return '$n OF 3';
  }

  @override
  String get explainer1Title => 'Every key\nhas a number.';

  @override
  String get explainer1Body =>
      'These are the seven notes of C major. Musicians call them by their number — the degree — because the number says what the note is doing, and it works the same in every key.';

  @override
  String get explainer2Title => 'Change key.\nThe numbers stay.';

  @override
  String get explainer2Body =>
      'Tap a key and watch. The letters move, the numbers do not: the 5 is always the 5. Learn the numbers once and you have all twelve keys.';

  @override
  String get explainer3Title => 'Try one.';

  @override
  String get explainer3Body =>
      'That is the whole game. Fast enough, often enough, and it stops being arithmetic and becomes instinct — two minutes a day is plenty.';

  @override
  String get letsGo => 'Let\'s go';

  @override
  String get summaryTitle => 'SESSION COMPLETE';

  @override
  String get summaryPerfect => 'PERFECT SCORE';

  @override
  String get summaryPassed => 'LEVEL PASSED';

  @override
  String get summaryCompleted => 'COMPLETED';

  @override
  String get summaryNotYet => 'NOT YET — KEEP GOING';

  @override
  String get summaryCorrect => 'CORRECT';

  @override
  String get summaryErrors => 'ERRORS';

  @override
  String get summaryTime => 'TIME';

  @override
  String get summaryAccuracy => 'ACCURACY %';

  @override
  String get summaryModeMastery => 'MODE MASTERY';

  @override
  String get summaryNextDifficulty => 'PLAY NEXT DIFFICULTY';

  @override
  String summaryUpsellTitle(String key) {
    return 'That was the free half of $key';
  }

  @override
  String get summaryUpsellBody =>
      'Chromatic adds the five altered degrees — the rest of the key.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Lifetime licence';

  @override
  String get paywallTagline => 'Every key. Every mode. Forever.';

  @override
  String get paywallEvery => 'Every ';

  @override
  String get paywallForever => 'Forever.';

  @override
  String get paywallWhatYouGet => 'What you get, from musician to musician';

  @override
  String get paywallCta => 'Unlock lifetime access';

  @override
  String paywallPrice(String price) {
    return '$price · one-time payment';
  }

  @override
  String get paywallRestore => 'Restore';

  @override
  String get paywallNoPurchase => 'No previous purchase found';

  @override
  String get featChromatic => 'Chromatic Mode';

  @override
  String get featChromaticMeta => 'all 12 keys';

  @override
  String get featNtn => 'Note to Number';

  @override
  String get featNtnMeta => 'chromatic';

  @override
  String get featOfWhat => '…Of What?';

  @override
  String get featOfWhatMeta => 'all 15 degrees';

  @override
  String get featPocket => 'Pocket Mode';

  @override
  String get featPocketMeta => 'all 12 degrees';

  @override
  String get featCustom => 'Custom Mode';

  @override
  String get featCustomMeta => 'any degree';

  @override
  String get featAdaptive => 'Adaptive difficulty';

  @override
  String get featAdaptiveMeta => 'auto';

  @override
  String get featAnalytics => 'Deep analytics';

  @override
  String get featAnalyticsMeta => 'per key';

  @override
  String get storeNotReadyTitle => 'Store not ready';

  @override
  String get storeNotReadyBody =>
      'No product is available for purchase right now. Please try again in a moment.';

  @override
  String get almostThereTitle => 'Almost there';

  @override
  String get almostThereBody =>
      'Your payment went through but PRO could not be activated automatically. Tap Restore purchases in a moment — you will not be charged twice.';

  @override
  String get billingUnavailableTitle => 'Billing unavailable';

  @override
  String get billingUnavailableBody =>
      'In-app purchases are not available on this device.';

  @override
  String get purchaseFailedTitle => 'Purchase failed';

  @override
  String get purchaseFailedBody =>
      'Something went wrong while contacting the store. Please try again.';

  @override
  String get notifPromptTitle => 'Make it stick';

  @override
  String get notifPromptBody =>
      'One quick quiz a day keeps every note sharp and your streak alive. Off whenever you want.';

  @override
  String get notifPromptYes => 'Yes, remind me';

  @override
  String get homeAllKeys => 'ALL KEYS MASTERY';

  @override
  String get homeSpecialModes => 'SPECIAL MODES';

  @override
  String get homePickUp => 'PICK UP WHERE YOU LEFT OFF';

  @override
  String get homeTotalSessions => 'TOTAL SESSIONS';

  @override
  String get homeAccuracy => 'ACCURACY';

  @override
  String get homeTotalProgress => 'TOTAL PROGRESS';

  @override
  String get homeNextMilestone => 'NEXT MILESTONE';

  @override
  String get homeMaxLevel => 'MAX LEVEL!';

  @override
  String homeLevelShort(int n) {
    return 'LVL $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% to $animal';
  }

  @override
  String get homeNtnDesc => 'Given a note name, identify its numerical degree.';

  @override
  String get homeOfWhatDesc =>
      'A note is a given degree — name the root. Harmonize any melody.';

  @override
  String get homePocketDesc =>
      'Hands-free audio drill: a voice asks, waits, then says the note. Plays with the screen off.';

  @override
  String get homeCustomDesc =>
      'Choose your key, direction, and specific degrees to train on.';

  @override
  String homeLastSession(String when) {
    return 'LAST SESSION • $when';
  }

  @override
  String get homeResume => 'Resume Session';

  @override
  String get homeReadyTitle => 'Ready to start?';

  @override
  String get homeReadyBody => 'Select a key from above';

  @override
  String get homeGamesPlayed => 'GAMES PLAYED';

  @override
  String get homeChooseMode => 'Choose Mode';

  @override
  String get homeChooseModeSub => 'Select how you want to train today';

  @override
  String get homeDiatonicDesc => 'Master the 7 notes of the scale.';

  @override
  String get homeChromaticDesc => 'Challenge yourself with all 12 semitones.';

  @override
  String homeLockedTier(String prev) {
    return 'Keep training in $prev mode to unlock this difficulty.';
  }

  @override
  String get homeYourProgress => 'YOUR PROGRESS';

  @override
  String get homeKeepTraining => 'KEEP TRAINING';

  @override
  String get homeHandsFree => 'Hands-free audio';

  @override
  String get homeJustNow => 'Just now';

  @override
  String homeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String homeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String homeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get homeQuote1 =>
      'Every master was once a beginner. Let\'s visualize those first notes!';

  @override
  String get homeQuote2 =>
      'Halfway to mastery — your instincts are sharpening. Keep pushing!';

  @override
  String get homeQuote3 =>
      'True mastery lives in the details. Trust your instincts and play!';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Key of $key, $pct percent';
  }

  @override
  String get setupTrainingSetup => 'TRAINING SETUP';

  @override
  String get setupHarmonizeSetup => 'HARMONIZE SETUP';

  @override
  String get setupPersonalized =>
      'FREE PRACTICE · DOES NOT COUNT TOWARDS MASTERY';

  @override
  String get setupHandsFree => 'HANDS-FREE · AUDIO';

  @override
  String get setupSelectRootKey => 'Select Root Key';

  @override
  String get setupSelectRootKeySub =>
      'Choose the foundation for your training.';

  @override
  String get setupSelectNote => 'Select Note';

  @override
  String get setupSelectNoteSub =>
      'The melody note held for the whole session.';

  @override
  String get setupIntensity => 'Training Intensity';

  @override
  String get setupIntensityChromatic =>
      'Master all 12 chromatic notes in this key.';

  @override
  String get setupIntensityDiatonic =>
      'Focus on the 7 notes of the major scale.';

  @override
  String get setupDifficulty => 'Difficulty';

  @override
  String get setupDifficultySub =>
      'Higher difficulty means less time to answer.';

  @override
  String get setupMode => 'Mode';

  @override
  String get setupModeNormalSub => 'Name the note for a degree, in this key.';

  @override
  String get setupModeNtnSub => 'Name the degree for a note, in this key.';

  @override
  String get setupModeOfWhatSub =>
      'One note held throughout — name the key it belongs to.';

  @override
  String get setupSelectDegrees => 'Select Degrees';

  @override
  String get setupDegreesToAsk => 'Degrees to Ask';

  @override
  String get setupDegreesAll => 'Every degree, extensions included.';

  @override
  String get setupDegreesChord => 'The four chord tones: 1, 3, 5, 7.';

  @override
  String get setupChord => 'Chord';

  @override
  String get setupAll => 'All';

  @override
  String get setupQuickChord => 'CHORD';

  @override
  String get setupQuickAll => 'ALL';

  @override
  String get setupQuickDiatonic => 'DIATONIC';

  @override
  String get setupQuestions => 'Number of Questions';

  @override
  String get setupQuestionsSub => 'How many questions for this session?';

  @override
  String get setupKeys => 'Keys';

  @override
  String get setupKeysSub => 'Train one key, or shuffle through all 12.';

  @override
  String get setupShuffleAll => 'Shuffle all';

  @override
  String get setupOneKey => 'One key';

  @override
  String get setupDegrees => 'Degrees';

  @override
  String get setupAnswerDelay => 'Answer Delay';

  @override
  String get setupLength => 'Length';

  @override
  String get setupLengthSub => 'Number of questions (∞ = until you stop).';

  @override
  String setupTierLocked(String tier) {
    return '$tier is locked';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Reach $need correct in $prev first. You are at $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap BEST';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct percent';
  }

  @override
  String get trainerCorrect => 'CORRECT';

  @override
  String get trainerWrong => 'WRONG';

  @override
  String get trainerCorrectAnswer => 'CORRECT ANSWER';

  @override
  String get trainerNote => 'NOTE';

  @override
  String get trainerKey => 'KEY';

  @override
  String get trainerDegree => 'DEGREE';

  @override
  String get trainerProgress => 'PROGRESS';

  @override
  String get trainerStreak => 'STREAK';

  @override
  String get trainerPianoKeyboard => 'PIANO KEYBOARD';

  @override
  String get trainerExitTitle => 'End this session?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'One attempt per day, and the clock keeps running — if you leave now, $done/$total is your score until tomorrow.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'You are $done questions in — leaving ends the run and keeps the score.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'You are $done/$total in — the run ends here if you leave.';
  }

  @override
  String get trainerKeepPlaying => 'KEEP PLAYING';

  @override
  String get trainerQuit => 'QUIT';

  @override
  String get paywallLine1 => 'Every key.';

  @override
  String get paywallLine2 => 'Every mode.';

  @override
  String get paywallLine3 => 'Forever.';

  @override
  String get paywallRestoring => 'Restoring…';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get animalSnail => 'Snail';

  @override
  String get animalTurtle => 'Turtle';

  @override
  String get animalPenguin => 'Penguin';

  @override
  String get animalRabbit => 'Rabbit';

  @override
  String get animalFox => 'Fox';

  @override
  String get animalHorse => 'Horse';

  @override
  String get animalFalcon => 'Falcon';

  @override
  String get animalCheetah => 'Cheetah';

  @override
  String get homeShuffleHandsFree => 'Shuffle · hands-free';

  @override
  String homeTierDifficulty(String tier) {
    return '$tier Difficulty';
  }

  @override
  String get trainerGridView => 'GRID VIEW';

  @override
  String get trainerAccuracy => 'ACCURACY';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsAccountStatus => 'ACCOUNT STATUS';

  @override
  String get settingsFreePlan => 'Free Plan';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub => 'Every mode and key, unlocked.';

  @override
  String get settingsFreeSub => 'Tap to unlock every mode and key.';

  @override
  String get settingsActive => 'ACTIVE';

  @override
  String get settingsTraining => 'TRAINING';

  @override
  String get settingsAdaptive => 'Adaptive Difficulty';

  @override
  String get settingsAdaptiveTag => 'SMART TRAINING';

  @override
  String get settingsAdaptiveBody =>
      'Degrees you answer slowly or get wrong come up several times more often than ones you own — right but slow still counts as unlearned. The clock tightens while you are sharp and eases off when you start missing.';

  @override
  String get settingsAdaptiveLocked =>
      'PRO feature — upgrade to unlock smart training that adapts to your weaknesses.';

  @override
  String get settingsSimpleNotes => 'Simple Note Names';

  @override
  String get settingsSimpleNotesTag => 'NOTE SPELLING';

  @override
  String get settingsSimpleNotesBody =>
      'One name per note everywhere — no slashes, no double names. C  D♭  D  E♭  E  F  F♯  G  A♭  A  B♭  B.';

  @override
  String get settingsKeyboardTonic => 'Keyboard from Tonic';

  @override
  String get settingsKeyboardTonicTag => 'PIANO INPUT';

  @override
  String get settingsKeyboardTonicBody =>
      'The in-game piano starts on your key’s tonic instead of C.';

  @override
  String get settingsNotation => 'NOTATION SYSTEM';

  @override
  String get settingsFreeMode => 'FREE MODE';

  @override
  String get settingsFreeModeTitle => 'Free Mode';

  @override
  String get settingsFreeModeSub =>
      'Numbers at your own pace. No timer, no score.';

  @override
  String get settingsNotifications => 'NOTIFICATIONS';

  @override
  String get settingsReminders => 'Daily reminders';

  @override
  String get settingsRemindersTag => 'QUIZ NUDGE + STREAK SAVER';

  @override
  String get settingsRemindersBody =>
      'One quick quiz a day, plus a nudge before your streak breaks.';

  @override
  String get settingsNews => 'NEWS & UPDATES';

  @override
  String get settingsWhatsNew => 'What\'s new';

  @override
  String get settingsStore => 'STORE';

  @override
  String get settingsUpgrade => 'UPGRADE TO PRO';

  @override
  String get settingsRestorePurchases => 'RESTORE PURCHASES';

  @override
  String get settingsProRestored => 'PRO restored';

  @override
  String get settingsHomeScreen => 'HOME SCREEN';

  @override
  String get settingsWidgets => 'Widgets';

  @override
  String get settingsWidgetsSub =>
      'A question an hour, right on your home screen';

  @override
  String get settingsBackup => 'BACKUP';

  @override
  String get settingsExport => 'Export progress';

  @override
  String get settingsExportSub => 'One file with every key, score and setting';

  @override
  String get settingsExportFailed => 'Could not start the export';

  @override
  String get settingsRestoreFile => 'Restore from file';

  @override
  String get settingsRestoreFileSub => 'Replaces what is on this phone';

  @override
  String get settingsRestored => 'Restored. Everything is back.';

  @override
  String get settingsRestoreTitle => 'Restore from a file?';

  @override
  String get settingsRestoreBody =>
      'Everything on this phone — every key, score and setting — is replaced by what is in the file. Your Pro licence is not affected.';

  @override
  String get settingsChooseFile => 'Choose file';

  @override
  String get settingsSupport => 'SUPPORT';

  @override
  String get settingsRate => 'Rate Improvy';

  @override
  String get settingsRateSub => 'A rating is how other musicians find it';

  @override
  String get settingsFeedback => 'Send Feedback';

  @override
  String get settingsFeedbackSub => 'Straight to us, without leaving the app';

  @override
  String get settingsFeedbackSent => 'Sent. We read every one of these.';

  @override
  String get settingsContact => 'Contact Support';

  @override
  String settingsWriteTo(String email) {
    return 'Write to $email';
  }

  @override
  String get settingsFollow => 'Follow the developer';

  @override
  String settingsInstagram(String handle) {
    return 'Find us on Instagram: @$handle';
  }

  @override
  String get settingsLegal => 'LEGAL';

  @override
  String get settingsClearTitle => 'Clear All Data?';

  @override
  String get settingsClearBody =>
      'This will permanently delete all your progress and stats.';

  @override
  String get settingsWidgetsTwo => 'TWO WIDGETS';

  @override
  String get settingsWidgetQuestion => 'Question';

  @override
  String get settingsWidgetQuestionBody =>
      'A scale degree waiting for an answer, a new one every hour. Tap it to reveal the answer.';

  @override
  String get settingsWidgetDaily => 'Daily Challenge';

  @override
  String get settingsWidgetDailyBody =>
      'The key of the day, your score once you have played, and your streak.';

  @override
  String get settingsWidgetHow => 'HOW TO ADD ONE';

  @override
  String get settingsWidgetIos1 =>
      'Touch and hold an empty spot on your home screen';

  @override
  String get settingsWidgetIos2 => 'Tap the + in the top corner';

  @override
  String get settingsWidgetIos3 => 'Search for Improvy and pick a widget';

  @override
  String get settingsWidgetAndroid2 => 'Tap Widgets';

  @override
  String get settingsWidgetAndroid3 => 'Find Improvy and drag a widget out';

  @override
  String statsLevel(int n) {
    return 'LEVEL $n';
  }

  @override
  String get statsOverall => 'OVERALL\nPROFICIENCY';

  @override
  String get statsNotes => 'NOTES';

  @override
  String get statsStreak => 'STREAK';

  @override
  String get statsNothingYet => 'NOTHING TO SHOW YET';

  @override
  String get statsLast30 => 'STATISTICS BASED ON THE LAST 30 GAMES';

  @override
  String get statsSkillMastery => 'Skill Mastery';

  @override
  String get statsLatestGame => 'LATEST GAME';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n GAMES AGO',
      one: '1 GAME AGO',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'No data • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Response Time • $when';
  }

  @override
  String get statsResponseTime => 'Response Time';

  @override
  String get statsLatest => 'LATEST';

  @override
  String get statsSpeedTitle => 'Your speed lives here';

  @override
  String get statsSpeedBody =>
      'Play a session and watch every answer get quicker.';

  @override
  String get statsDegreeAccuracy => 'Degree Accuracy';

  @override
  String get statsPlays => 'PLAYS';

  @override
  String get statsAccuracy => 'ACCURACY';

  @override
  String get statsGamesPlayed => 'Games Played';

  @override
  String get statsHeatmap => 'Keyboard Heatmap';

  @override
  String get statsByNote => 'PERFORMANCE BY NOTE';

  @override
  String get statsSlow => 'SLOW';

  @override
  String get statsFast => 'FAST';

  @override
  String get statsRank => 'RANK';

  @override
  String get statsFirstRunTitle => 'Play one session';

  @override
  String get statsFirstRunBody =>
      'Thirty questions in one key and every chart on this page fills in — your speed, the degrees you miss, the notes that slow you down.';

  @override
  String get kaTitle => 'KEY ANALYSIS';

  @override
  String get kaMastery => 'MASTERY';

  @override
  String get kaAvgResp => 'AVG RESP.';

  @override
  String get kaPerAnswer => 'PER ANSWER';

  @override
  String get kaToday => 'TODAY';

  @override
  String get kaAccuracyOverTime => 'Response Time';

  @override
  String get kaDegreeMastery => 'Chromatic Degree Mastery';

  @override
  String get kaModeProgress => 'Mode Progress';

  @override
  String get kaDegreeToNote => 'DEGREE › NOTE';

  @override
  String get kaNoteToDegree => 'NOTE › DEGREE';

  @override
  String get kaOfWhat => '…OF WHAT?';

  @override
  String get kaConfusions => 'Common Confusions';

  @override
  String get kaNoConfusions => 'NO CONFUSIONS YET. GREAT JOB!';

  @override
  String get kaNote => 'NOTE';

  @override
  String get kaHarmonizer => 'Harmonizer';

  @override
  String get kaHarmonizerSub => '“…Of What?” mastery';

  @override
  String get dailyTitle => 'DAILY CHALLENGE';

  @override
  String get dailyDone => 'DAILY DONE';

  @override
  String get dailyFlawless => 'FLAWLESS';

  @override
  String get dailyOutOfTime => 'OUT OF TIME';

  @override
  String get dailySharp => 'SHARP';

  @override
  String get dailySolid => 'SOLID';

  @override
  String get dailyWarmingUp => 'WARMING UP';

  @override
  String get dailyTomorrow => 'TOMORROW IS A NEW KEY';

  @override
  String get dailyCopied => 'Result copied — paste it anywhere';

  @override
  String dailyNewIn(String when) {
    return 'New challenge in $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Next challenge in $when';
  }

  @override
  String get dailyBackHome => 'Back to Home';

  @override
  String get dailyTheRun => 'THE RUN';

  @override
  String get dailyStreak => 'CHALLENGE STREAK';

  @override
  String get dailyShare => 'Share your result';

  @override
  String get pocketTitle => 'POCKET MODE';

  @override
  String get pocketDegrees => 'DEGREES';

  @override
  String get pocketDelay => 'DELAY';

  @override
  String get pocketSession => 'SESSION';

  @override
  String get pocketListen => 'LISTEN';

  @override
  String get pocketYourTurn => 'YOUR TURN';

  @override
  String get pocketAnswer => 'ANSWER';

  @override
  String get pocketReady => 'READY';

  @override
  String get pocketComplete => 'SESSION COMPLETE';

  @override
  String get pocketPlaying => 'PLAYING';

  @override
  String get pocketPaused => 'PAUSED';

  @override
  String get pocketScreenOff => 'Keeps playing with the screen off';

  @override
  String get pocketAudioSession => 'Audio session';

  @override
  String get feedbackTitle => 'Tell us';

  @override
  String get feedbackBody =>
      'It comes straight to us. No email app, no account, no name attached unless you write one.';

  @override
  String get feedbackHintBug => 'What happened, and what were you doing?';

  @override
  String get feedbackHint => 'Whatever you want to say.';

  @override
  String get feedbackEmail => 'Your email — only if you want an answer';

  @override
  String get feedbackSend => 'SEND';

  @override
  String get feedbackKindBug => 'Something is broken';

  @override
  String get feedbackKindIdea => 'An idea';

  @override
  String get feedbackKindOther => 'Something else';

  @override
  String get levelUp => 'Level Up!';

  @override
  String get levelUpYouAreNow => 'You are now a ';

  @override
  String get awesome => 'Awesome!';

  @override
  String whatsNewVersionHere(String v) {
    return 'Version $v\nis here';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSION $v';
  }

  @override
  String get continueLabel => 'CONTINUE';

  @override
  String get fullChangelog => 'Full changelog';

  @override
  String get quizFromHome => 'FROM YOUR HOME SCREEN';

  @override
  String get quizTrain => 'Train ';

  @override
  String get freeModeTitle => 'FREE MODE';

  @override
  String get freeModeTapNext => 'TAP ANYWHERE FOR THE NEXT';

  @override
  String get freeModeNumbersDone => 'NUMBERS DONE';

  @override
  String get freeModeSub => 'No score, no clock — just the reps.';

  @override
  String get freeModeGoAgain => 'GO AGAIN';

  @override
  String get remTargetTitle => 'Target practice 🎯';

  @override
  String get remDailyTitle => 'Daily Challenge 🏆';

  @override
  String remDailyBody(String key) {
    return 'Today\'s challenge is in $key major — one attempt, make it count.';
  }

  @override
  String get remQuizTitle => 'Quick quiz 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return 'What\'s the $degree of $key major? Tap to check.';
  }

  @override
  String remLevelBody(String pct) {
    return 'You\'re $pct% from levelling up. Close the gap?';
  }

  @override
  String get remMaxedBody => 'Maxed out — keep those reflexes razor-sharp.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Every degree, every key, instantly. Got 3 minutes?';

  @override
  String get remEarTitle => 'Ear training 🎧';

  @override
  String get remEarBody => 'Fast recall beats slow theory. Quick session?';

  @override
  String get remFallbackBody => 'Time to practise?';

  @override
  String get remComeback3 =>
      'Scale degrees fade fast when you stop. Your keys miss you.';

  @override
  String get remComeback7 =>
      'A week away — your instant recall needs a warm-up. Come back?';

  @override
  String get remStreakTitle => 'Don\'t break your streak! 🔥';

  @override
  String remStreakBody(int n) {
    return 'Your $n-day streak ends tonight — 2 minutes to keep it alive.';
  }

  @override
  String get clear => 'Clear';

  @override
  String get statsSigNone => 'NONE';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n SHARPS',
      one: '1 SHARP',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n FLATS',
      one: '1 FLAT',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'You keep mixing up $a and $b in $key major. 10 questions to nail it?';
  }

  @override
  String get freeModeDone => 'DONE';

  @override
  String get freeModeLeft => 'LEFT';

  @override
  String get animalQuote1 => 'Slow and steady wins!';

  @override
  String get animalQuote2 => 'Steady progress!';

  @override
  String get animalQuote3 => 'Sliding smoothly!';

  @override
  String get animalQuote4 => 'Fast as a hare!';

  @override
  String get animalQuote5 => 'Clever and quick!';

  @override
  String get animalQuote6 => 'Galloping with precision!';

  @override
  String get animalQuote7 => 'Soaring high! Sharp vision!';

  @override
  String get animalQuote8 => 'Unstoppable! True Maestro!';

  @override
  String get explainerTapKey => 'TAP A KEY';

  @override
  String explainerQuestion(String key, String degree) {
    return 'In $key, which note is the $degree?';
  }

  @override
  String get explainerRight => 'That\'s it.';

  @override
  String get explainerWrong => 'Not quite — try again.';

  @override
  String get explainerAgain => 'Another one';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key overall';
  }

  @override
  String statsTotalGamesChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n GAMES',
      one: '1 GAME',
    );
    return '$_temp0';
  }

  @override
  String homeBestOf(int score, int cap) {
    return '$score/$cap BEST';
  }

  @override
  String get dailyMajorSuffix => 'major';

  @override
  String dailyStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dailyRule(int questions, int seconds) {
    return '$questions questions · $seconds seconds';
  }

  @override
  String get dailySubjectKeyOf => 'Key of ';

  @override
  String get dailySubjectOn => 'On ';

  @override
  String get wQuestion => 'QUESTION';

  @override
  String get wQuestionLong => 'TODAY\'S QUESTION';

  @override
  String get wReveal => 'Tap to reveal';

  @override
  String get wDaily => 'DAILY';

  @override
  String get wDailyLong => 'DAILY CHALLENGE';

  @override
  String get wToday => 'today';

  @override
  String get wDone => 'Done';

  @override
  String get wTomorrow => 'Next one tomorrow';

  @override
  String get wLevel => 'YOUR LEVEL';

  @override
  String get wMastery => 'KEY MASTERY';

  @override
  String get wStreak => 'STREAK';

  @override
  String get wDays => 'days in a row';

  @override
  String get wDayStreak => 'day streak';

  @override
  String get wAtRisk => 'Play today to keep it';

  @override
  String get wNeedsWork => 'NEEDS WORK';

  @override
  String get wMastered => 'mastered';

  @override
  String get wWeakHint => 'Your weakest key. Tap to train it.';

  @override
  String get wWeakEmpty => 'Play a key first';

  @override
  String get wStart => 'START TRAINING';

  @override
  String get wHandsFree => 'HANDS-FREE';

  @override
  String get wPocketSub => 'Train with the screen off';

  @override
  String get wTheory => 'DEGREE OF THE DAY';

  @override
  String get wOpenApp => 'Open Improvy to fill this in.';

  @override
  String get statsSkillMasterySub =>
      'Per key: degree › note, note › degree, …Of What?';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Improvy'**
  String get appName;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get home;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @startTraining.
  ///
  /// In en, this message translates to:
  /// **'START TRAINING'**
  String get startTraining;

  /// No description provided for @proOnly.
  ///
  /// In en, this message translates to:
  /// **'PRO ONLY'**
  String get proOnly;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @modeDiatonic.
  ///
  /// In en, this message translates to:
  /// **'Diatonic'**
  String get modeDiatonic;

  /// No description provided for @modeChromatic.
  ///
  /// In en, this message translates to:
  /// **'Chromatic'**
  String get modeChromatic;

  /// No description provided for @modeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get modeCustom;

  /// No description provided for @modeNoteToNumber.
  ///
  /// In en, this message translates to:
  /// **'Note to Number'**
  String get modeNoteToNumber;

  /// No description provided for @modeOfWhat.
  ///
  /// In en, this message translates to:
  /// **'…Of What?'**
  String get modeOfWhat;

  /// No description provided for @modePocket.
  ///
  /// In en, this message translates to:
  /// **'Pocket Mode'**
  String get modePocket;

  /// No description provided for @modeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get modeNormal;

  /// No description provided for @tierApprentice.
  ///
  /// In en, this message translates to:
  /// **'Apprentice'**
  String get tierApprentice;

  /// No description provided for @tierVirtuoso.
  ///
  /// In en, this message translates to:
  /// **'Virtuoso'**
  String get tierVirtuoso;

  /// No description provided for @tierMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get tierMaster;

  /// No description provided for @onboardingTag.
  ///
  /// In en, this message translates to:
  /// **'Mental training'**
  String get onboardingTag;

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Every note\nis a\nnumber.'**
  String get onboardingHeadline;

  /// No description provided for @onboardingPromise.
  ///
  /// In en, this message translates to:
  /// **'See the number under any note instantly, in all twelve keys — no counting, no theory book.'**
  String get onboardingPromise;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start training'**
  String get onboardingStart;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @explainerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get explainerEyebrow;

  /// No description provided for @explainerStep.
  ///
  /// In en, this message translates to:
  /// **'{n} OF 3'**
  String explainerStep(int n);

  /// No description provided for @explainer1Title.
  ///
  /// In en, this message translates to:
  /// **'Every key\nhas a number.'**
  String get explainer1Title;

  /// No description provided for @explainer1Body.
  ///
  /// In en, this message translates to:
  /// **'These are the seven notes of C major. Musicians call them by their number — the degree — because the number says what the note is doing, and it works the same in every key.'**
  String get explainer1Body;

  /// No description provided for @explainer2Title.
  ///
  /// In en, this message translates to:
  /// **'Change key.\nThe numbers stay.'**
  String get explainer2Title;

  /// No description provided for @explainer2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap a key and watch. The letters move, the numbers do not: the 5 is always the 5. Learn the numbers once and you have all twelve keys.'**
  String get explainer2Body;

  /// No description provided for @explainer3Title.
  ///
  /// In en, this message translates to:
  /// **'Try one.'**
  String get explainer3Title;

  /// No description provided for @explainer3Body.
  ///
  /// In en, this message translates to:
  /// **'That is the whole game. Fast enough, often enough, and it stops being arithmetic and becomes instinct — two minutes a day is plenty.'**
  String get explainer3Body;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get letsGo;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get summaryTitle;

  /// No description provided for @summaryPerfect.
  ///
  /// In en, this message translates to:
  /// **'PERFECT SCORE'**
  String get summaryPerfect;

  /// No description provided for @summaryPassed.
  ///
  /// In en, this message translates to:
  /// **'LEVEL PASSED'**
  String get summaryPassed;

  /// No description provided for @summaryCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get summaryCompleted;

  /// No description provided for @summaryNotYet.
  ///
  /// In en, this message translates to:
  /// **'NOT YET — KEEP GOING'**
  String get summaryNotYet;

  /// No description provided for @summaryCorrect.
  ///
  /// In en, this message translates to:
  /// **'CORRECT'**
  String get summaryCorrect;

  /// No description provided for @summaryErrors.
  ///
  /// In en, this message translates to:
  /// **'ERRORS'**
  String get summaryErrors;

  /// No description provided for @summaryTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get summaryTime;

  /// No description provided for @summaryAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY %'**
  String get summaryAccuracy;

  /// No description provided for @summaryModeMastery.
  ///
  /// In en, this message translates to:
  /// **'MODE MASTERY'**
  String get summaryModeMastery;

  /// No description provided for @summaryNextDifficulty.
  ///
  /// In en, this message translates to:
  /// **'PLAY NEXT DIFFICULTY'**
  String get summaryNextDifficulty;

  /// No description provided for @summaryUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'That was the free half of {key}'**
  String summaryUpsellTitle(String key);

  /// No description provided for @summaryUpsellBody.
  ///
  /// In en, this message translates to:
  /// **'Chromatic adds the five altered degrees — the rest of the key.'**
  String get summaryUpsellBody;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvy Pro'**
  String get paywallTitle;

  /// No description provided for @paywallLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime licence'**
  String get paywallLifetime;

  /// No description provided for @paywallTagline.
  ///
  /// In en, this message translates to:
  /// **'Every key. Every mode. Forever.'**
  String get paywallTagline;

  /// No description provided for @paywallEvery.
  ///
  /// In en, this message translates to:
  /// **'Every '**
  String get paywallEvery;

  /// No description provided for @paywallForever.
  ///
  /// In en, this message translates to:
  /// **'Forever.'**
  String get paywallForever;

  /// No description provided for @paywallWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What you get, from musician to musician'**
  String get paywallWhatYouGet;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Unlock lifetime access'**
  String get paywallCta;

  /// No description provided for @paywallPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} · one-time payment'**
  String paywallPrice(String price);

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get paywallRestore;

  /// No description provided for @paywallNoPurchase.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found'**
  String get paywallNoPurchase;

  /// No description provided for @featChromatic.
  ///
  /// In en, this message translates to:
  /// **'Chromatic Mode'**
  String get featChromatic;

  /// No description provided for @featChromaticMeta.
  ///
  /// In en, this message translates to:
  /// **'all 12 keys'**
  String get featChromaticMeta;

  /// No description provided for @featNtn.
  ///
  /// In en, this message translates to:
  /// **'Note to Number'**
  String get featNtn;

  /// No description provided for @featNtnMeta.
  ///
  /// In en, this message translates to:
  /// **'chromatic'**
  String get featNtnMeta;

  /// No description provided for @featOfWhat.
  ///
  /// In en, this message translates to:
  /// **'…Of What?'**
  String get featOfWhat;

  /// No description provided for @featOfWhatMeta.
  ///
  /// In en, this message translates to:
  /// **'all 15 degrees'**
  String get featOfWhatMeta;

  /// No description provided for @featPocket.
  ///
  /// In en, this message translates to:
  /// **'Pocket Mode'**
  String get featPocket;

  /// No description provided for @featPocketMeta.
  ///
  /// In en, this message translates to:
  /// **'all 12 degrees'**
  String get featPocketMeta;

  /// No description provided for @featCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Mode'**
  String get featCustom;

  /// No description provided for @featCustomMeta.
  ///
  /// In en, this message translates to:
  /// **'any degree'**
  String get featCustomMeta;

  /// No description provided for @featAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive difficulty'**
  String get featAdaptive;

  /// No description provided for @featAdaptiveMeta.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get featAdaptiveMeta;

  /// No description provided for @featAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Deep analytics'**
  String get featAnalytics;

  /// No description provided for @featAnalyticsMeta.
  ///
  /// In en, this message translates to:
  /// **'per key'**
  String get featAnalyticsMeta;

  /// No description provided for @storeNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Store not ready'**
  String get storeNotReadyTitle;

  /// No description provided for @storeNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'No product is available for purchase right now. Please try again in a moment.'**
  String get storeNotReadyBody;

  /// No description provided for @almostThereTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get almostThereTitle;

  /// No description provided for @almostThereBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment went through but PRO could not be activated automatically. Tap Restore purchases in a moment — you will not be charged twice.'**
  String get almostThereBody;

  /// No description provided for @billingUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing unavailable'**
  String get billingUnavailableTitle;

  /// No description provided for @billingUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases are not available on this device.'**
  String get billingUnavailableBody;

  /// No description provided for @purchaseFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailedTitle;

  /// No description provided for @purchaseFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while contacting the store. Please try again.'**
  String get purchaseFailedBody;

  /// No description provided for @notifPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it stick'**
  String get notifPromptTitle;

  /// No description provided for @notifPromptBody.
  ///
  /// In en, this message translates to:
  /// **'One quick quiz a day keeps every note sharp and your streak alive. Off whenever you want.'**
  String get notifPromptBody;

  /// No description provided for @notifPromptYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, remind me'**
  String get notifPromptYes;

  /// No description provided for @homeAllKeys.
  ///
  /// In en, this message translates to:
  /// **'ALL KEYS MASTERY'**
  String get homeAllKeys;

  /// No description provided for @homeSpecialModes.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL MODES'**
  String get homeSpecialModes;

  /// No description provided for @homePickUp.
  ///
  /// In en, this message translates to:
  /// **'PICK UP WHERE YOU LEFT OFF'**
  String get homePickUp;

  /// No description provided for @homeTotalSessions.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SESSIONS'**
  String get homeTotalSessions;

  /// No description provided for @homeAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get homeAccuracy;

  /// No description provided for @homeTotalProgress.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PROGRESS'**
  String get homeTotalProgress;

  /// No description provided for @homeNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'NEXT MILESTONE'**
  String get homeNextMilestone;

  /// No description provided for @homeMaxLevel.
  ///
  /// In en, this message translates to:
  /// **'MAX LEVEL!'**
  String get homeMaxLevel;

  /// No description provided for @homeLevelShort.
  ///
  /// In en, this message translates to:
  /// **'LVL {n}'**
  String homeLevelShort(int n);

  /// No description provided for @homeToNext.
  ///
  /// In en, this message translates to:
  /// **'{pct}% to {animal}'**
  String homeToNext(String pct, String animal);

  /// No description provided for @homeNtnDesc.
  ///
  /// In en, this message translates to:
  /// **'Given a note name, identify its numerical degree.'**
  String get homeNtnDesc;

  /// No description provided for @homeOfWhatDesc.
  ///
  /// In en, this message translates to:
  /// **'A note is a given degree — name the root. Harmonize any melody.'**
  String get homeOfWhatDesc;

  /// No description provided for @homePocketDesc.
  ///
  /// In en, this message translates to:
  /// **'Hands-free audio drill: a voice asks, waits, then says the note. Plays with the screen off.'**
  String get homePocketDesc;

  /// No description provided for @homeCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your key, direction, and specific degrees to train on.'**
  String get homeCustomDesc;

  /// No description provided for @homeLastSession.
  ///
  /// In en, this message translates to:
  /// **'LAST SESSION • {when}'**
  String homeLastSession(String when);

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Session'**
  String get homeResume;

  /// No description provided for @homeReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to start?'**
  String get homeReadyTitle;

  /// No description provided for @homeReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Select a key from above'**
  String get homeReadyBody;

  /// No description provided for @homeGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'GAMES PLAYED'**
  String get homeGamesPlayed;

  /// No description provided for @homeChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose Mode'**
  String get homeChooseMode;

  /// No description provided for @homeChooseModeSub.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to train today'**
  String get homeChooseModeSub;

  /// No description provided for @homeDiatonicDesc.
  ///
  /// In en, this message translates to:
  /// **'Master the 7 notes of the scale.'**
  String get homeDiatonicDesc;

  /// No description provided for @homeChromaticDesc.
  ///
  /// In en, this message translates to:
  /// **'Challenge yourself with all 12 semitones.'**
  String get homeChromaticDesc;

  /// No description provided for @homeLockedTier.
  ///
  /// In en, this message translates to:
  /// **'Keep training in {prev} mode to unlock this difficulty.'**
  String homeLockedTier(String prev);

  /// No description provided for @homeYourProgress.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROGRESS'**
  String get homeYourProgress;

  /// No description provided for @homeKeepTraining.
  ///
  /// In en, this message translates to:
  /// **'KEEP TRAINING'**
  String get homeKeepTraining;

  /// No description provided for @homeHandsFree.
  ///
  /// In en, this message translates to:
  /// **'Hands-free audio'**
  String get homeHandsFree;

  /// No description provided for @homeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get homeJustNow;

  /// No description provided for @homeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String homeMinutesAgo(int n);

  /// No description provided for @homeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String homeHoursAgo(int n);

  /// No description provided for @homeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String homeDaysAgo(int n);

  /// No description provided for @homeQuote1.
  ///
  /// In en, this message translates to:
  /// **'Every master was once a beginner. Let\'s visualize those first notes!'**
  String get homeQuote1;

  /// No description provided for @homeQuote2.
  ///
  /// In en, this message translates to:
  /// **'Halfway to mastery — your instincts are sharpening. Keep pushing!'**
  String get homeQuote2;

  /// No description provided for @homeQuote3.
  ///
  /// In en, this message translates to:
  /// **'True mastery lives in the details. Trust your instincts and play!'**
  String get homeQuote3;

  /// No description provided for @homeKeyTileLabel.
  ///
  /// In en, this message translates to:
  /// **'Key of {key}, {pct} percent'**
  String homeKeyTileLabel(String key, int pct);

  /// No description provided for @setupTrainingSetup.
  ///
  /// In en, this message translates to:
  /// **'TRAINING SETUP'**
  String get setupTrainingSetup;

  /// No description provided for @setupHarmonizeSetup.
  ///
  /// In en, this message translates to:
  /// **'HARMONIZE SETUP'**
  String get setupHarmonizeSetup;

  /// No description provided for @setupPersonalized.
  ///
  /// In en, this message translates to:
  /// **'FREE PRACTICE · DOES NOT COUNT TOWARDS MASTERY'**
  String get setupPersonalized;

  /// No description provided for @setupHandsFree.
  ///
  /// In en, this message translates to:
  /// **'HANDS-FREE · AUDIO'**
  String get setupHandsFree;

  /// No description provided for @setupSelectRootKey.
  ///
  /// In en, this message translates to:
  /// **'Select Root Key'**
  String get setupSelectRootKey;

  /// No description provided for @setupSelectRootKeySub.
  ///
  /// In en, this message translates to:
  /// **'Choose the foundation for your training.'**
  String get setupSelectRootKeySub;

  /// No description provided for @setupSelectNote.
  ///
  /// In en, this message translates to:
  /// **'Select Note'**
  String get setupSelectNote;

  /// No description provided for @setupSelectNoteSub.
  ///
  /// In en, this message translates to:
  /// **'The melody note held for the whole session.'**
  String get setupSelectNoteSub;

  /// No description provided for @setupIntensity.
  ///
  /// In en, this message translates to:
  /// **'Training Intensity'**
  String get setupIntensity;

  /// No description provided for @setupIntensityChromatic.
  ///
  /// In en, this message translates to:
  /// **'Master all 12 chromatic notes in this key.'**
  String get setupIntensityChromatic;

  /// No description provided for @setupIntensityDiatonic.
  ///
  /// In en, this message translates to:
  /// **'Focus on the 7 notes of the major scale.'**
  String get setupIntensityDiatonic;

  /// No description provided for @setupDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get setupDifficulty;

  /// No description provided for @setupDifficultySub.
  ///
  /// In en, this message translates to:
  /// **'Higher difficulty means less time to answer.'**
  String get setupDifficultySub;

  /// No description provided for @setupMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get setupMode;

  /// No description provided for @setupModeNormalSub.
  ///
  /// In en, this message translates to:
  /// **'Name the note for a degree, in this key.'**
  String get setupModeNormalSub;

  /// No description provided for @setupModeNtnSub.
  ///
  /// In en, this message translates to:
  /// **'Name the degree for a note, in this key.'**
  String get setupModeNtnSub;

  /// No description provided for @setupModeOfWhatSub.
  ///
  /// In en, this message translates to:
  /// **'One note held throughout — name the key it belongs to.'**
  String get setupModeOfWhatSub;

  /// No description provided for @setupSelectDegrees.
  ///
  /// In en, this message translates to:
  /// **'Select Degrees'**
  String get setupSelectDegrees;

  /// No description provided for @setupDegreesToAsk.
  ///
  /// In en, this message translates to:
  /// **'Degrees to Ask'**
  String get setupDegreesToAsk;

  /// No description provided for @setupDegreesAll.
  ///
  /// In en, this message translates to:
  /// **'Every degree, extensions included.'**
  String get setupDegreesAll;

  /// No description provided for @setupDegreesChord.
  ///
  /// In en, this message translates to:
  /// **'The four chord tones: 1, 3, 5, 7.'**
  String get setupDegreesChord;

  /// No description provided for @setupChord.
  ///
  /// In en, this message translates to:
  /// **'Chord'**
  String get setupChord;

  /// No description provided for @setupAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get setupAll;

  /// No description provided for @setupQuickChord.
  ///
  /// In en, this message translates to:
  /// **'CHORD'**
  String get setupQuickChord;

  /// No description provided for @setupQuickAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get setupQuickAll;

  /// No description provided for @setupQuickDiatonic.
  ///
  /// In en, this message translates to:
  /// **'DIATONIC'**
  String get setupQuickDiatonic;

  /// No description provided for @setupQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get setupQuestions;

  /// No description provided for @setupQuestionsSub.
  ///
  /// In en, this message translates to:
  /// **'How many questions for this session?'**
  String get setupQuestionsSub;

  /// No description provided for @setupKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get setupKeys;

  /// No description provided for @setupKeysSub.
  ///
  /// In en, this message translates to:
  /// **'Train one key, or shuffle through all 12.'**
  String get setupKeysSub;

  /// No description provided for @setupShuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all'**
  String get setupShuffleAll;

  /// No description provided for @setupOneKey.
  ///
  /// In en, this message translates to:
  /// **'One key'**
  String get setupOneKey;

  /// No description provided for @setupDegrees.
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get setupDegrees;

  /// No description provided for @setupAnswerDelay.
  ///
  /// In en, this message translates to:
  /// **'Answer Delay'**
  String get setupAnswerDelay;

  /// No description provided for @setupLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get setupLength;

  /// No description provided for @setupLengthSub.
  ///
  /// In en, this message translates to:
  /// **'Number of questions (∞ = until you stop).'**
  String get setupLengthSub;

  /// No description provided for @setupTierLocked.
  ///
  /// In en, this message translates to:
  /// **'{tier} is locked'**
  String setupTierLocked(String tier);

  /// No description provided for @setupTierLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Reach {need} correct in {prev} first. You are at {have}.'**
  String setupTierLockedBody(int need, String prev, int have);

  /// No description provided for @setupBest.
  ///
  /// In en, this message translates to:
  /// **'{best}/{cap} BEST'**
  String setupBest(int best, int cap);

  /// No description provided for @setupKeyCellLabel.
  ///
  /// In en, this message translates to:
  /// **'{key}, {pct} percent'**
  String setupKeyCellLabel(String key, int pct);

  /// No description provided for @trainerCorrect.
  ///
  /// In en, this message translates to:
  /// **'CORRECT'**
  String get trainerCorrect;

  /// No description provided for @trainerWrong.
  ///
  /// In en, this message translates to:
  /// **'WRONG'**
  String get trainerWrong;

  /// No description provided for @trainerCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'CORRECT ANSWER'**
  String get trainerCorrectAnswer;

  /// No description provided for @trainerNote.
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get trainerNote;

  /// No description provided for @trainerKey.
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get trainerKey;

  /// No description provided for @trainerDegree.
  ///
  /// In en, this message translates to:
  /// **'DEGREE'**
  String get trainerDegree;

  /// No description provided for @trainerProgress.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get trainerProgress;

  /// No description provided for @trainerStreak.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get trainerStreak;

  /// No description provided for @trainerPianoKeyboard.
  ///
  /// In en, this message translates to:
  /// **'PIANO KEYBOARD'**
  String get trainerPianoKeyboard;

  /// No description provided for @trainerExitTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get trainerExitTitle;

  /// No description provided for @trainerExitDaily.
  ///
  /// In en, this message translates to:
  /// **'One attempt per day, and the clock keeps running — if you leave now, {done}/{total} is your score until tomorrow.'**
  String trainerExitDaily(int done, int total);

  /// No description provided for @trainerExitEndless.
  ///
  /// In en, this message translates to:
  /// **'You are {done} questions in — leaving ends the run and keeps the score.'**
  String trainerExitEndless(int done);

  /// No description provided for @trainerExitBody.
  ///
  /// In en, this message translates to:
  /// **'You are {done}/{total} in — the run ends here if you leave.'**
  String trainerExitBody(int done, int total);

  /// No description provided for @trainerKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'KEEP PLAYING'**
  String get trainerKeepPlaying;

  /// No description provided for @trainerQuit.
  ///
  /// In en, this message translates to:
  /// **'QUIT'**
  String get trainerQuit;

  /// No description provided for @paywallLine1.
  ///
  /// In en, this message translates to:
  /// **'Every key.'**
  String get paywallLine1;

  /// No description provided for @paywallLine2.
  ///
  /// In en, this message translates to:
  /// **'Every mode.'**
  String get paywallLine2;

  /// No description provided for @paywallLine3.
  ///
  /// In en, this message translates to:
  /// **'Forever.'**
  String get paywallLine3;

  /// No description provided for @paywallRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get paywallRestoring;

  /// No description provided for @paywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get paywallPrivacy;

  /// No description provided for @animalSnail.
  ///
  /// In en, this message translates to:
  /// **'Snail'**
  String get animalSnail;

  /// No description provided for @animalTurtle.
  ///
  /// In en, this message translates to:
  /// **'Turtle'**
  String get animalTurtle;

  /// No description provided for @animalPenguin.
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get animalPenguin;

  /// No description provided for @animalRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get animalRabbit;

  /// No description provided for @animalFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get animalFox;

  /// No description provided for @animalHorse.
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get animalHorse;

  /// No description provided for @animalFalcon.
  ///
  /// In en, this message translates to:
  /// **'Falcon'**
  String get animalFalcon;

  /// No description provided for @animalCheetah.
  ///
  /// In en, this message translates to:
  /// **'Cheetah'**
  String get animalCheetah;

  /// No description provided for @homeShuffleHandsFree.
  ///
  /// In en, this message translates to:
  /// **'Shuffle · hands-free'**
  String get homeShuffleHandsFree;

  /// No description provided for @homeTierDifficulty.
  ///
  /// In en, this message translates to:
  /// **'{tier} Difficulty'**
  String homeTierDifficulty(String tier);

  /// No description provided for @trainerGridView.
  ///
  /// In en, this message translates to:
  /// **'GRID VIEW'**
  String get trainerGridView;

  /// No description provided for @trainerAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get trainerAccuracy;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT STATUS'**
  String get settingsAccountStatus;

  /// No description provided for @settingsFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get settingsFreePlan;

  /// No description provided for @settingsProPlan.
  ///
  /// In en, this message translates to:
  /// **'Improvy Pro'**
  String get settingsProPlan;

  /// No description provided for @settingsProSub.
  ///
  /// In en, this message translates to:
  /// **'Every mode and key, unlocked.'**
  String get settingsProSub;

  /// No description provided for @settingsFreeSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock every mode and key.'**
  String get settingsFreeSub;

  /// No description provided for @settingsActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get settingsActive;

  /// No description provided for @settingsTraining.
  ///
  /// In en, this message translates to:
  /// **'TRAINING'**
  String get settingsTraining;

  /// No description provided for @settingsAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Difficulty'**
  String get settingsAdaptive;

  /// No description provided for @settingsAdaptiveTag.
  ///
  /// In en, this message translates to:
  /// **'SMART TRAINING'**
  String get settingsAdaptiveTag;

  /// No description provided for @settingsAdaptiveBody.
  ///
  /// In en, this message translates to:
  /// **'Degrees you answer slowly or get wrong come up several times more often than ones you own — right but slow still counts as unlearned. The clock tightens while you are sharp and eases off when you start missing.'**
  String get settingsAdaptiveBody;

  /// No description provided for @settingsAdaptiveLocked.
  ///
  /// In en, this message translates to:
  /// **'PRO feature — upgrade to unlock smart training that adapts to your weaknesses.'**
  String get settingsAdaptiveLocked;

  /// No description provided for @settingsSimpleNotes.
  ///
  /// In en, this message translates to:
  /// **'Simple Note Names'**
  String get settingsSimpleNotes;

  /// No description provided for @settingsSimpleNotesTag.
  ///
  /// In en, this message translates to:
  /// **'NOTE SPELLING'**
  String get settingsSimpleNotesTag;

  /// No description provided for @settingsSimpleNotesBody.
  ///
  /// In en, this message translates to:
  /// **'One name per note everywhere — no slashes, no double names. C  D♭  D  E♭  E  F  F♯  G  A♭  A  B♭  B.'**
  String get settingsSimpleNotesBody;

  /// No description provided for @settingsKeyboardTonic.
  ///
  /// In en, this message translates to:
  /// **'Keyboard from Tonic'**
  String get settingsKeyboardTonic;

  /// No description provided for @settingsKeyboardTonicTag.
  ///
  /// In en, this message translates to:
  /// **'PIANO INPUT'**
  String get settingsKeyboardTonicTag;

  /// No description provided for @settingsKeyboardTonicBody.
  ///
  /// In en, this message translates to:
  /// **'The in-game piano starts on your key’s tonic instead of C.'**
  String get settingsKeyboardTonicBody;

  /// No description provided for @settingsNotation.
  ///
  /// In en, this message translates to:
  /// **'NOTATION SYSTEM'**
  String get settingsNotation;

  /// No description provided for @settingsFreeMode.
  ///
  /// In en, this message translates to:
  /// **'FREE MODE'**
  String get settingsFreeMode;

  /// No description provided for @settingsFreeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Mode'**
  String get settingsFreeModeTitle;

  /// No description provided for @settingsFreeModeSub.
  ///
  /// In en, this message translates to:
  /// **'Numbers at your own pace. No timer, no score.'**
  String get settingsFreeModeSub;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsNotifications;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersTag.
  ///
  /// In en, this message translates to:
  /// **'QUIZ NUDGE + STREAK SAVER'**
  String get settingsRemindersTag;

  /// No description provided for @settingsRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'One quick quiz a day, plus a nudge before your streak breaks.'**
  String get settingsRemindersBody;

  /// No description provided for @settingsNews.
  ///
  /// In en, this message translates to:
  /// **'NEWS & UPDATES'**
  String get settingsNews;

  /// No description provided for @settingsWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get settingsWhatsNew;

  /// No description provided for @settingsStore.
  ///
  /// In en, this message translates to:
  /// **'STORE'**
  String get settingsStore;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE TO PRO'**
  String get settingsUpgrade;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'RESTORE PURCHASES'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsProRestored.
  ///
  /// In en, this message translates to:
  /// **'PRO restored'**
  String get settingsProRestored;

  /// No description provided for @settingsHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'HOME SCREEN'**
  String get settingsHomeScreen;

  /// No description provided for @settingsWidgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get settingsWidgets;

  /// No description provided for @settingsWidgetsSub.
  ///
  /// In en, this message translates to:
  /// **'A question an hour, right on your home screen'**
  String get settingsWidgetsSub;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get settingsSupport;

  /// No description provided for @settingsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate Improvy'**
  String get settingsRate;

  /// No description provided for @settingsRateSub.
  ///
  /// In en, this message translates to:
  /// **'A rating is how other musicians find it'**
  String get settingsRateSub;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackSub.
  ///
  /// In en, this message translates to:
  /// **'Straight to us, without leaving the app'**
  String get settingsFeedbackSub;

  /// No description provided for @settingsFeedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. We read every one of these.'**
  String get settingsFeedbackSent;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settingsContact;

  /// No description provided for @settingsWriteTo.
  ///
  /// In en, this message translates to:
  /// **'Write to {email}'**
  String settingsWriteTo(String email);

  /// No description provided for @settingsFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow the developer'**
  String get settingsFollow;

  /// No description provided for @settingsInstagram.
  ///
  /// In en, this message translates to:
  /// **'Find us on Instagram: @{handle}'**
  String settingsInstagram(String handle);

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get settingsLegal;

  /// No description provided for @settingsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get settingsClearTitle;

  /// No description provided for @settingsClearBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your progress and stats.'**
  String get settingsClearBody;

  /// No description provided for @settingsWidgetsTwo.
  ///
  /// In en, this message translates to:
  /// **'TWO WIDGETS'**
  String get settingsWidgetsTwo;

  /// No description provided for @settingsWidgetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get settingsWidgetQuestion;

  /// No description provided for @settingsWidgetQuestionBody.
  ///
  /// In en, this message translates to:
  /// **'A scale degree waiting for an answer, a new one every hour. Tap it to reveal the answer.'**
  String get settingsWidgetQuestionBody;

  /// No description provided for @settingsWidgetDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get settingsWidgetDaily;

  /// No description provided for @settingsWidgetDailyBody.
  ///
  /// In en, this message translates to:
  /// **'The key of the day, your score once you have played, and your streak.'**
  String get settingsWidgetDailyBody;

  /// No description provided for @settingsWidgetHow.
  ///
  /// In en, this message translates to:
  /// **'HOW TO ADD ONE'**
  String get settingsWidgetHow;

  /// No description provided for @settingsWidgetIos1.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on your home screen'**
  String get settingsWidgetIos1;

  /// No description provided for @settingsWidgetIos2.
  ///
  /// In en, this message translates to:
  /// **'Tap the + in the top corner'**
  String get settingsWidgetIos2;

  /// No description provided for @settingsWidgetIos3.
  ///
  /// In en, this message translates to:
  /// **'Search for Improvy and pick a widget'**
  String get settingsWidgetIos3;

  /// No description provided for @settingsWidgetAndroid2.
  ///
  /// In en, this message translates to:
  /// **'Tap Widgets'**
  String get settingsWidgetAndroid2;

  /// No description provided for @settingsWidgetAndroid3.
  ///
  /// In en, this message translates to:
  /// **'Find Improvy and drag a widget out'**
  String get settingsWidgetAndroid3;

  /// No description provided for @statsLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {n}'**
  String statsLevel(int n);

  /// No description provided for @statsOverall.
  ///
  /// In en, this message translates to:
  /// **'OVERALL\nPROFICIENCY'**
  String get statsOverall;

  /// No description provided for @statsNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get statsNotes;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get statsStreak;

  /// No description provided for @statsNothingYet.
  ///
  /// In en, this message translates to:
  /// **'NOTHING TO SHOW YET'**
  String get statsNothingYet;

  /// No description provided for @statsLast30.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS BASED ON THE LAST 30 GAMES'**
  String get statsLast30;

  /// No description provided for @statsSkillMastery.
  ///
  /// In en, this message translates to:
  /// **'Skill Mastery'**
  String get statsSkillMastery;

  /// No description provided for @statsLatestGame.
  ///
  /// In en, this message translates to:
  /// **'LATEST GAME'**
  String get statsLatestGame;

  /// No description provided for @statsGamesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 GAME AGO} other{{n} GAMES AGO}}'**
  String statsGamesAgo(int n);

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data • {when}'**
  String statsNoData(String when);

  /// No description provided for @statsResponseTimeWhen.
  ///
  /// In en, this message translates to:
  /// **'Response Time • {when}'**
  String statsResponseTimeWhen(String when);

  /// No description provided for @statsResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get statsResponseTime;

  /// No description provided for @statsLatest.
  ///
  /// In en, this message translates to:
  /// **'LATEST'**
  String get statsLatest;

  /// No description provided for @statsSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your speed lives here'**
  String get statsSpeedTitle;

  /// No description provided for @statsSpeedBody.
  ///
  /// In en, this message translates to:
  /// **'Play a session and watch every answer get quicker.'**
  String get statsSpeedBody;

  /// No description provided for @statsDegreeAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Degree Accuracy'**
  String get statsDegreeAccuracy;

  /// No description provided for @statsPlays.
  ///
  /// In en, this message translates to:
  /// **'PLAYS'**
  String get statsPlays;

  /// No description provided for @statsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get statsAccuracy;

  /// No description provided for @statsGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get statsGamesPlayed;

  /// No description provided for @statsHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Heatmap'**
  String get statsHeatmap;

  /// No description provided for @statsByNote.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE BY NOTE'**
  String get statsByNote;

  /// No description provided for @statsSlow.
  ///
  /// In en, this message translates to:
  /// **'SLOW'**
  String get statsSlow;

  /// No description provided for @statsFast.
  ///
  /// In en, this message translates to:
  /// **'FAST'**
  String get statsFast;

  /// No description provided for @statsRank.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get statsRank;

  /// No description provided for @statsFirstRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Play one session'**
  String get statsFirstRunTitle;

  /// No description provided for @statsFirstRunBody.
  ///
  /// In en, this message translates to:
  /// **'Thirty questions in one key and every chart on this page fills in — your speed, the degrees you miss, the notes that slow you down.'**
  String get statsFirstRunBody;

  /// No description provided for @kaTitle.
  ///
  /// In en, this message translates to:
  /// **'KEY ANALYSIS'**
  String get kaTitle;

  /// No description provided for @kaMastery.
  ///
  /// In en, this message translates to:
  /// **'MASTERY'**
  String get kaMastery;

  /// No description provided for @kaAvgResp.
  ///
  /// In en, this message translates to:
  /// **'AVG RESP.'**
  String get kaAvgResp;

  /// No description provided for @kaPerAnswer.
  ///
  /// In en, this message translates to:
  /// **'PER ANSWER'**
  String get kaPerAnswer;

  /// No description provided for @kaToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get kaToday;

  /// No description provided for @kaAccuracyOverTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get kaAccuracyOverTime;

  /// No description provided for @kaDegreeMastery.
  ///
  /// In en, this message translates to:
  /// **'Chromatic Degree Mastery'**
  String get kaDegreeMastery;

  /// No description provided for @kaModeProgress.
  ///
  /// In en, this message translates to:
  /// **'Mode Progress'**
  String get kaModeProgress;

  /// No description provided for @kaDegreeToNote.
  ///
  /// In en, this message translates to:
  /// **'DEGREE › NOTE'**
  String get kaDegreeToNote;

  /// No description provided for @kaNoteToDegree.
  ///
  /// In en, this message translates to:
  /// **'NOTE › DEGREE'**
  String get kaNoteToDegree;

  /// No description provided for @kaOfWhat.
  ///
  /// In en, this message translates to:
  /// **'…OF WHAT?'**
  String get kaOfWhat;

  /// No description provided for @kaConfusions.
  ///
  /// In en, this message translates to:
  /// **'Common Confusions'**
  String get kaConfusions;

  /// No description provided for @kaNoConfusions.
  ///
  /// In en, this message translates to:
  /// **'NO CONFUSIONS YET. GREAT JOB!'**
  String get kaNoConfusions;

  /// No description provided for @kaNote.
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get kaNote;

  /// No description provided for @kaHarmonizer.
  ///
  /// In en, this message translates to:
  /// **'Harmonizer'**
  String get kaHarmonizer;

  /// No description provided for @kaHarmonizerSub.
  ///
  /// In en, this message translates to:
  /// **'“…Of What?” mastery'**
  String get kaHarmonizerSub;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get dailyTitle;

  /// No description provided for @dailyDone.
  ///
  /// In en, this message translates to:
  /// **'DAILY DONE'**
  String get dailyDone;

  /// No description provided for @dailyFlawless.
  ///
  /// In en, this message translates to:
  /// **'FLAWLESS'**
  String get dailyFlawless;

  /// No description provided for @dailyOutOfTime.
  ///
  /// In en, this message translates to:
  /// **'OUT OF TIME'**
  String get dailyOutOfTime;

  /// No description provided for @dailySharp.
  ///
  /// In en, this message translates to:
  /// **'SHARP'**
  String get dailySharp;

  /// No description provided for @dailySolid.
  ///
  /// In en, this message translates to:
  /// **'SOLID'**
  String get dailySolid;

  /// No description provided for @dailyWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'WARMING UP'**
  String get dailyWarmingUp;

  /// No description provided for @dailyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW IS A NEW KEY'**
  String get dailyTomorrow;

  /// No description provided for @dailyCopied.
  ///
  /// In en, this message translates to:
  /// **'Result copied — paste it anywhere'**
  String get dailyCopied;

  /// No description provided for @dailyNewIn.
  ///
  /// In en, this message translates to:
  /// **'New challenge in {when}'**
  String dailyNewIn(String when);

  /// No description provided for @dailyNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next challenge in {when}'**
  String dailyNextIn(String when);

  /// No description provided for @dailyBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get dailyBackHome;

  /// No description provided for @dailyTheRun.
  ///
  /// In en, this message translates to:
  /// **'THE RUN'**
  String get dailyTheRun;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGE STREAK'**
  String get dailyStreak;

  /// No description provided for @dailyShare.
  ///
  /// In en, this message translates to:
  /// **'Share your result'**
  String get dailyShare;

  /// No description provided for @pocketTitle.
  ///
  /// In en, this message translates to:
  /// **'POCKET MODE'**
  String get pocketTitle;

  /// No description provided for @pocketDegrees.
  ///
  /// In en, this message translates to:
  /// **'DEGREES'**
  String get pocketDegrees;

  /// No description provided for @pocketDelay.
  ///
  /// In en, this message translates to:
  /// **'DELAY'**
  String get pocketDelay;

  /// No description provided for @pocketSession.
  ///
  /// In en, this message translates to:
  /// **'SESSION'**
  String get pocketSession;

  /// No description provided for @pocketListen.
  ///
  /// In en, this message translates to:
  /// **'LISTEN'**
  String get pocketListen;

  /// No description provided for @pocketYourTurn.
  ///
  /// In en, this message translates to:
  /// **'YOUR TURN'**
  String get pocketYourTurn;

  /// No description provided for @pocketAnswer.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get pocketAnswer;

  /// No description provided for @pocketReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get pocketReady;

  /// No description provided for @pocketComplete.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get pocketComplete;

  /// No description provided for @pocketPlaying.
  ///
  /// In en, this message translates to:
  /// **'PLAYING'**
  String get pocketPlaying;

  /// No description provided for @pocketPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get pocketPaused;

  /// No description provided for @pocketScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Keeps playing with the screen off'**
  String get pocketScreenOff;

  /// No description provided for @pocketAudioSession.
  ///
  /// In en, this message translates to:
  /// **'Audio session'**
  String get pocketAudioSession;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us'**
  String get feedbackTitle;

  /// No description provided for @feedbackBody.
  ///
  /// In en, this message translates to:
  /// **'It comes straight to us. No email app, no account, no name attached unless you write one.'**
  String get feedbackBody;

  /// No description provided for @feedbackHintBug.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what were you doing?'**
  String get feedbackHintBug;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Whatever you want to say.'**
  String get feedbackHint;

  /// No description provided for @feedbackEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email — only if you want an answer'**
  String get feedbackEmail;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get feedbackSend;

  /// No description provided for @feedbackKindBug.
  ///
  /// In en, this message translates to:
  /// **'Something is broken'**
  String get feedbackKindBug;

  /// No description provided for @feedbackKindIdea.
  ///
  /// In en, this message translates to:
  /// **'An idea'**
  String get feedbackKindIdea;

  /// No description provided for @feedbackKindOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get feedbackKindOther;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'Level Up!'**
  String get levelUp;

  /// No description provided for @levelUpYouAreNow.
  ///
  /// In en, this message translates to:
  /// **'You are now a '**
  String get levelUpYouAreNow;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @whatsNewVersionHere.
  ///
  /// In en, this message translates to:
  /// **'Version {v}\nis here'**
  String whatsNewVersionHere(String v);

  /// No description provided for @whatsNewVersion.
  ///
  /// In en, this message translates to:
  /// **'VERSION {v}'**
  String whatsNewVersion(String v);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueLabel;

  /// No description provided for @fullChangelog.
  ///
  /// In en, this message translates to:
  /// **'Full changelog'**
  String get fullChangelog;

  /// No description provided for @quizFromHome.
  ///
  /// In en, this message translates to:
  /// **'FROM YOUR HOME SCREEN'**
  String get quizFromHome;

  /// No description provided for @quizTrain.
  ///
  /// In en, this message translates to:
  /// **'Train '**
  String get quizTrain;

  /// No description provided for @freeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'FREE MODE'**
  String get freeModeTitle;

  /// No description provided for @freeModeTapNext.
  ///
  /// In en, this message translates to:
  /// **'TAP ANYWHERE FOR THE NEXT'**
  String get freeModeTapNext;

  /// No description provided for @freeModeNumbersDone.
  ///
  /// In en, this message translates to:
  /// **'NUMBERS DONE'**
  String get freeModeNumbersDone;

  /// No description provided for @freeModeSub.
  ///
  /// In en, this message translates to:
  /// **'No score, no clock — just the reps.'**
  String get freeModeSub;

  /// No description provided for @freeModeGoAgain.
  ///
  /// In en, this message translates to:
  /// **'GO AGAIN'**
  String get freeModeGoAgain;

  /// No description provided for @remTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Target practice 🎯'**
  String get remTargetTitle;

  /// No description provided for @remDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge 🏆'**
  String get remDailyTitle;

  /// No description provided for @remDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge is in {key} major — one attempt, make it count.'**
  String remDailyBody(String key);

  /// No description provided for @remQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick quiz 🎹'**
  String get remQuizTitle;

  /// No description provided for @remQuizBody.
  ///
  /// In en, this message translates to:
  /// **'What\'s the {degree} of {key} major? Tap to check.'**
  String remQuizBody(String degree, String key);

  /// No description provided for @remLevelBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re {pct}% from levelling up. Close the gap?'**
  String remLevelBody(String pct);

  /// No description provided for @remMaxedBody.
  ///
  /// In en, this message translates to:
  /// **'Maxed out — keep those reflexes razor-sharp.'**
  String get remMaxedBody;

  /// No description provided for @remGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvy 🎹'**
  String get remGenericTitle;

  /// No description provided for @remGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Every degree, every key, instantly. Got 3 minutes?'**
  String get remGenericBody;

  /// No description provided for @remEarTitle.
  ///
  /// In en, this message translates to:
  /// **'Ear training 🎧'**
  String get remEarTitle;

  /// No description provided for @remEarBody.
  ///
  /// In en, this message translates to:
  /// **'Fast recall beats slow theory. Quick session?'**
  String get remEarBody;

  /// No description provided for @remFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Time to practise?'**
  String get remFallbackBody;

  /// No description provided for @remComeback3.
  ///
  /// In en, this message translates to:
  /// **'Scale degrees fade fast when you stop. Your keys miss you.'**
  String get remComeback3;

  /// No description provided for @remComeback7.
  ///
  /// In en, this message translates to:
  /// **'A week away — your instant recall needs a warm-up. Come back?'**
  String get remComeback7;

  /// No description provided for @remStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your streak! 🔥'**
  String get remStreakTitle;

  /// No description provided for @remStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Your {n}-day streak ends tonight — 2 minutes to keep it alive.'**
  String remStreakBody(int n);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @statsSigNone.
  ///
  /// In en, this message translates to:
  /// **'NONE'**
  String get statsSigNone;

  /// No description provided for @statsSigSharp.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 SHARP} other{{n} SHARPS}}'**
  String statsSigSharp(int n);

  /// No description provided for @statsSigFlat.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 FLAT} other{{n} FLATS}}'**
  String statsSigFlat(int n);

  /// No description provided for @remConfusion.
  ///
  /// In en, this message translates to:
  /// **'You keep mixing up {a} and {b} in {key} major. 10 questions to nail it?'**
  String remConfusion(String a, String b, String key);

  /// No description provided for @freeModeDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get freeModeDone;

  /// No description provided for @freeModeLeft.
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get freeModeLeft;

  /// No description provided for @animalQuote1.
  ///
  /// In en, this message translates to:
  /// **'Slow and steady wins!'**
  String get animalQuote1;

  /// No description provided for @animalQuote2.
  ///
  /// In en, this message translates to:
  /// **'Steady progress!'**
  String get animalQuote2;

  /// No description provided for @animalQuote3.
  ///
  /// In en, this message translates to:
  /// **'Sliding smoothly!'**
  String get animalQuote3;

  /// No description provided for @animalQuote4.
  ///
  /// In en, this message translates to:
  /// **'Fast as a hare!'**
  String get animalQuote4;

  /// No description provided for @animalQuote5.
  ///
  /// In en, this message translates to:
  /// **'Clever and quick!'**
  String get animalQuote5;

  /// No description provided for @animalQuote6.
  ///
  /// In en, this message translates to:
  /// **'Galloping with precision!'**
  String get animalQuote6;

  /// No description provided for @animalQuote7.
  ///
  /// In en, this message translates to:
  /// **'Soaring high! Sharp vision!'**
  String get animalQuote7;

  /// No description provided for @animalQuote8.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable! True Maestro!'**
  String get animalQuote8;

  /// No description provided for @explainerTapKey.
  ///
  /// In en, this message translates to:
  /// **'TAP A KEY'**
  String get explainerTapKey;

  /// No description provided for @explainerQuestion.
  ///
  /// In en, this message translates to:
  /// **'In {key}, which note is the {degree}?'**
  String explainerQuestion(String key, String degree);

  /// No description provided for @explainerRight.
  ///
  /// In en, this message translates to:
  /// **'That\'s it.'**
  String get explainerRight;

  /// No description provided for @explainerWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite — try again.'**
  String get explainerWrong;

  /// No description provided for @explainerAgain.
  ///
  /// In en, this message translates to:
  /// **'Another one'**
  String get explainerAgain;

  /// No description provided for @summaryFamilyMastery.
  ///
  /// In en, this message translates to:
  /// **'{family} · {key}'**
  String summaryFamilyMastery(String family, String key);

  /// No description provided for @summaryKeyOverall.
  ///
  /// In en, this message translates to:
  /// **'{key} overall'**
  String summaryKeyOverall(String key);

  /// No description provided for @statsTotalGamesChip.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 GAME} other{{n} GAMES}}'**
  String statsTotalGamesChip(int n);

  /// No description provided for @homeBestOf.
  ///
  /// In en, this message translates to:
  /// **'{score}/{cap} BEST'**
  String homeBestOf(int score, int cap);

  /// No description provided for @dailyMajorSuffix.
  ///
  /// In en, this message translates to:
  /// **'major'**
  String get dailyMajorSuffix;

  /// No description provided for @dailyStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String dailyStreakDays(int n);

  /// No description provided for @dailyRule.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · {seconds} seconds'**
  String dailyRule(int questions, int seconds);

  /// No description provided for @dailySubjectKeyOf.
  ///
  /// In en, this message translates to:
  /// **'Key of '**
  String get dailySubjectKeyOf;

  /// No description provided for @dailySubjectOn.
  ///
  /// In en, this message translates to:
  /// **'On '**
  String get dailySubjectOn;

  /// No description provided for @wQuestion.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get wQuestion;

  /// No description provided for @wQuestionLong.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S QUESTION'**
  String get wQuestionLong;

  /// No description provided for @wReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get wReveal;

  /// No description provided for @wDaily.
  ///
  /// In en, this message translates to:
  /// **'DAILY'**
  String get wDaily;

  /// No description provided for @wDailyLong.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get wDailyLong;

  /// No description provided for @wToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get wToday;

  /// No description provided for @wDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get wDone;

  /// No description provided for @wTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Next one tomorrow'**
  String get wTomorrow;

  /// No description provided for @wLevel.
  ///
  /// In en, this message translates to:
  /// **'YOUR LEVEL'**
  String get wLevel;

  /// No description provided for @wMastery.
  ///
  /// In en, this message translates to:
  /// **'KEY MASTERY'**
  String get wMastery;

  /// No description provided for @wStreak.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get wStreak;

  /// No description provided for @wDays.
  ///
  /// In en, this message translates to:
  /// **'days in a row'**
  String get wDays;

  /// No description provided for @wDayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get wDayStreak;

  /// No description provided for @wAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Play today to keep it'**
  String get wAtRisk;

  /// No description provided for @wNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'NEEDS WORK'**
  String get wNeedsWork;

  /// No description provided for @wMastered.
  ///
  /// In en, this message translates to:
  /// **'mastered'**
  String get wMastered;

  /// No description provided for @wWeakHint.
  ///
  /// In en, this message translates to:
  /// **'Your weakest key. Tap to train it.'**
  String get wWeakHint;

  /// No description provided for @wWeakEmpty.
  ///
  /// In en, this message translates to:
  /// **'Play a key first'**
  String get wWeakEmpty;

  /// No description provided for @wStart.
  ///
  /// In en, this message translates to:
  /// **'START TRAINING'**
  String get wStart;

  /// No description provided for @wHandsFree.
  ///
  /// In en, this message translates to:
  /// **'HANDS-FREE'**
  String get wHandsFree;

  /// No description provided for @wPocketSub.
  ///
  /// In en, this message translates to:
  /// **'Train with the screen off'**
  String get wPocketSub;

  /// No description provided for @wTheory.
  ///
  /// In en, this message translates to:
  /// **'DEGREE OF THE DAY'**
  String get wTheory;

  /// No description provided for @wOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open Improvy to fill this in.'**
  String get wOpenApp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

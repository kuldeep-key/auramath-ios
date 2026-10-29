import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @gotItLetsDraw.
  ///
  /// In en, this message translates to:
  /// **'Got it, let\'s draw'**
  String get gotItLetsDraw;

  /// No description provided for @hearItAgain.
  ///
  /// In en, this message translates to:
  /// **'Hear it again'**
  String get hearItAgain;

  /// No description provided for @todaysCase.
  ///
  /// In en, this message translates to:
  /// **'Here\'s today\'s case. Listen first.'**
  String get todaysCase;

  /// No description provided for @iKnowIt.
  ///
  /// In en, this message translates to:
  /// **'I know it'**
  String get iKnowIt;

  /// No description provided for @helpMe.
  ///
  /// In en, this message translates to:
  /// **'Help me'**
  String get helpMe;

  /// No description provided for @trickyTapMe.
  ///
  /// In en, this message translates to:
  /// **'Tricky one? Tap me!'**
  String get trickyTapMe;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @pieceBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get pieceBar;

  /// No description provided for @pieceGap.
  ///
  /// In en, this message translates to:
  /// **'Gap'**
  String get pieceGap;

  /// No description provided for @pieceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pieceTotal;

  /// No description provided for @taller.
  ///
  /// In en, this message translates to:
  /// **'Taller'**
  String get taller;

  /// No description provided for @shorter.
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get shorter;

  /// No description provided for @takeAway.
  ///
  /// In en, this message translates to:
  /// **'Take away'**
  String get takeAway;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @caseCracked.
  ///
  /// In en, this message translates to:
  /// **'Case cracked!'**
  String get caseCracked;

  /// No description provided for @youSolvedIt.
  ///
  /// In en, this message translates to:
  /// **'You solved the case!'**
  String get youSolvedIt;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New badge!'**
  String get newBadge;

  /// No description provided for @addToSash.
  ///
  /// In en, this message translates to:
  /// **'Add to my sash'**
  String get addToSash;

  /// No description provided for @yourBadge.
  ///
  /// In en, this message translates to:
  /// **'Your badge'**
  String get yourBadge;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @readyForNewCase.
  ///
  /// In en, this message translates to:
  /// **'Ready for a new case?'**
  String get readyForNewCase;

  /// No description provided for @backToProblem.
  ///
  /// In en, this message translates to:
  /// **'Back to the problem'**
  String get backToProblem;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get howCanIHelp;

  /// No description provided for @pickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick one.'**
  String get pickOne;

  /// No description provided for @aHint.
  ///
  /// In en, this message translates to:
  /// **'A hint'**
  String get aHint;

  /// No description provided for @showMeHow.
  ///
  /// In en, this message translates to:
  /// **'Show me how'**
  String get showMeHow;

  /// No description provided for @anEasierOne.
  ///
  /// In en, this message translates to:
  /// **'Something easier'**
  String get anEasierOne;

  /// No description provided for @stillThere.
  ///
  /// In en, this message translates to:
  /// **'Still there?'**
  String get stillThere;

  /// No description provided for @stillThinking.
  ///
  /// In en, this message translates to:
  /// **'I\'m still thinking'**
  String get stillThinking;

  /// No description provided for @askTotal.
  ///
  /// In en, this message translates to:
  /// **'Both together?'**
  String get askTotal;

  /// No description provided for @askB.
  ///
  /// In en, this message translates to:
  /// **'How tall is the {name}?'**
  String askB(String name);

  /// No description provided for @whatAsked.
  ///
  /// In en, this message translates to:
  /// **'What does the question ask?'**
  String get whatAsked;

  /// No description provided for @checkSumAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your sum again.'**
  String get checkSumAgain;

  /// No description provided for @checkOnePart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s check one part.'**
  String get checkOnePart;

  /// No description provided for @partRight.
  ///
  /// In en, this message translates to:
  /// **'{name} is right!'**
  String partRight(String name);

  /// No description provided for @nowCheckAdding.
  ///
  /// In en, this message translates to:
  /// **'Now check your adding.'**
  String get nowCheckAdding;

  /// No description provided for @sideTakeAcrossTen.
  ///
  /// In en, this message translates to:
  /// **'Take away across a ten'**
  String get sideTakeAcrossTen;

  /// No description provided for @sideAddWithCarry.
  ///
  /// In en, this message translates to:
  /// **'Adding with a carry'**
  String get sideAddWithCarry;

  /// No description provided for @takeABreak.
  ///
  /// In en, this message translates to:
  /// **'Take a break?'**
  String get takeABreak;

  /// No description provided for @drawingSaved.
  ///
  /// In en, this message translates to:
  /// **'Your drawing is saved.'**
  String get drawingSaved;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @timeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'That\'s today\'s time!'**
  String get timeUpTitle;

  /// No description provided for @timeUpBody.
  ///
  /// In en, this message translates to:
  /// **'Great detective work. Your case is saved for next time.'**
  String get timeUpBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @finishThisOne.
  ///
  /// In en, this message translates to:
  /// **'Finish this one'**
  String get finishThisOne;

  /// No description provided for @lostInternet.
  ///
  /// In en, this message translates to:
  /// **'Lost the internet. Your work is saved.'**
  String get lostInternet;

  /// No description provided for @kidMyTrail.
  ///
  /// In en, this message translates to:
  /// **'My trail'**
  String get kidMyTrail;

  /// No description provided for @kidMyBadges.
  ///
  /// In en, this message translates to:
  /// **'My badges'**
  String get kidMyBadges;

  /// No description provided for @kidForGrownUps.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups'**
  String get kidForGrownUps;

  /// No description provided for @kidHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get kidHome;

  /// No description provided for @kidWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String kidWelcomeBack(String name);

  /// No description provided for @kidWelcomeBackNoName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get kidWelcomeBackNoName;

  /// No description provided for @kidCaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your case is waiting.'**
  String get kidCaseWaiting;

  /// No description provided for @kidLetsSee.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see'**
  String get kidLetsSee;

  /// No description provided for @kidSoundOff.
  ///
  /// In en, this message translates to:
  /// **'Your sound is off'**
  String get kidSoundOff;

  /// No description provided for @kidSoundOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it up to hear me. Or read along.'**
  String get kidSoundOffBody;

  /// No description provided for @kidSoundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound is on now'**
  String get kidSoundOn;

  /// No description provided for @kidIllRead.
  ///
  /// In en, this message translates to:
  /// **'I\'ll read'**
  String get kidIllRead;

  /// No description provided for @kidVoiceResting.
  ///
  /// In en, this message translates to:
  /// **'My voice is resting'**
  String get kidVoiceResting;

  /// No description provided for @kidVoiceRestingBody.
  ///
  /// In en, this message translates to:
  /// **'Today I\'ll show the words big instead.'**
  String get kidVoiceRestingBody;

  /// No description provided for @kidOkLetsGo.
  ///
  /// In en, this message translates to:
  /// **'OK, let\'s go'**
  String get kidOkLetsGo;

  /// No description provided for @kidNextToEarn.
  ///
  /// In en, this message translates to:
  /// **'Next to earn'**
  String get kidNextToEarn;

  /// No description provided for @kidNoBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'Crack a case to earn your first badge!'**
  String get kidNoBadgesYet;

  /// No description provided for @kidBackToBadges.
  ///
  /// In en, this message translates to:
  /// **'Back to my badges'**
  String get kidBackToBadges;

  /// No description provided for @kidDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get kidDone;

  /// No description provided for @kidYouAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get kidYouAreHere;

  /// No description provided for @kidNextStop.
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get kidNextStop;

  /// No description provided for @kidStopAddBig.
  ///
  /// In en, this message translates to:
  /// **'Adding to 1000'**
  String get kidStopAddBig;

  /// No description provided for @kidStopTakeAwayBig.
  ///
  /// In en, this message translates to:
  /// **'Taking away to 1000'**
  String get kidStopTakeAwayBig;

  /// No description provided for @kidStopTrees.
  ///
  /// In en, this message translates to:
  /// **'Tree cases'**
  String get kidStopTrees;

  /// No description provided for @kidStopTrickyWords.
  ///
  /// In en, this message translates to:
  /// **'Tricky word cases'**
  String get kidStopTrickyWords;

  /// No description provided for @kidStopTotalAndDifference.
  ///
  /// In en, this message translates to:
  /// **'Burger cases'**
  String get kidStopTotalAndDifference;

  /// No description provided for @kidReachedTop.
  ///
  /// In en, this message translates to:
  /// **'You reached the top!'**
  String get kidReachedTop;

  /// No description provided for @kidNewTrailSoon.
  ///
  /// In en, this message translates to:
  /// **'A new trail opens soon. Keep your detective skills sharp!'**
  String get kidNewTrailSoon;

  /// No description provided for @kidQuickCheck.
  ///
  /// In en, this message translates to:
  /// **'A quick check!'**
  String get kidQuickCheck;

  /// No description provided for @kidQuickCheckBody.
  ///
  /// In en, this message translates to:
  /// **'A warm-up game with sums you know. No score.'**
  String get kidQuickCheckBody;

  /// No description provided for @kidLetsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play'**
  String get kidLetsPlay;

  /// No description provided for @kidTrickierOne.
  ///
  /// In en, this message translates to:
  /// **'Ready for a trickier one?'**
  String get kidTrickierOne;

  /// No description provided for @kidTreeWordProblem.
  ///
  /// In en, this message translates to:
  /// **'Tree Word Problem'**
  String get kidTreeWordProblem;

  /// No description provided for @kidWordProblem.
  ///
  /// In en, this message translates to:
  /// **'Word Problem'**
  String get kidWordProblem;

  /// No description provided for @kidSameTreesWatchWords.
  ///
  /// In en, this message translates to:
  /// **'Same trees. Watch the words!'**
  String get kidSameTreesWatchWords;

  /// No description provided for @kidLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get kidLetsGo;

  /// No description provided for @kidDoneForToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get kidDoneForToday;

  /// No description provided for @kidOnARoll.
  ///
  /// In en, this message translates to:
  /// **'On a roll!'**
  String get kidOnARoll;

  /// No description provided for @kidCaseAfterCase.
  ///
  /// In en, this message translates to:
  /// **'Case after case. Detective work!'**
  String get kidCaseAfterCase;

  /// No description provided for @kidTryNewSkill.
  ///
  /// In en, this message translates to:
  /// **'Try a new skill!'**
  String get kidTryNewSkill;

  /// No description provided for @kidNewStopOpened.
  ///
  /// In en, this message translates to:
  /// **'A new stop opened on your trail: {stop}.'**
  String kidNewStopOpened(String stop);

  /// No description provided for @kidSeeMyTrail.
  ///
  /// In en, this message translates to:
  /// **'See my trail'**
  String get kidSeeMyTrail;

  /// No description provided for @kidMySash.
  ///
  /// In en, this message translates to:
  /// **'My sash'**
  String get kidMySash;

  /// No description provided for @kidInYourSash.
  ///
  /// In en, this message translates to:
  /// **'It\'s in your sash. Your grown-up sees it too.'**
  String get kidInYourSash;

  /// No description provided for @kidNextCase.
  ///
  /// In en, this message translates to:
  /// **'Next case'**
  String get kidNextCase;

  /// No description provided for @kidTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get kidTryAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

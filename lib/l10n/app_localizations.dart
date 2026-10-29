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

  /// No description provided for @setupYourChild.
  ///
  /// In en, this message translates to:
  /// **'your child'**
  String get setupYourChild;

  /// No description provided for @setupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// No description provided for @setupTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get setupTryAgain;

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalised maths.\nTargeted growth.'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Bar-model word problems for ages 5 to 10, read aloud and drawn by your child.'**
  String get setupWelcomeBody;

  /// No description provided for @setupGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get setupGetStarted;

  /// No description provided for @setupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get setupHaveAccount;

  /// No description provided for @setupNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your child\'s first name'**
  String get setupNameTitle;

  /// No description provided for @setupNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the first name. No surname.'**
  String get setupNameSubtitle;

  /// No description provided for @setupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get setupNameLabel;

  /// No description provided for @setupAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'How old is {name}?'**
  String setupAgeTitle(String name);

  /// No description provided for @setupYearTitle.
  ///
  /// In en, this message translates to:
  /// **'Which school year is {name} in?'**
  String setupYearTitle(String name);

  /// No description provided for @setupYearUsual.
  ///
  /// In en, this message translates to:
  /// **'Usual for age {age}'**
  String setupYearUsual(int age);

  /// No description provided for @setupKindergarten.
  ///
  /// In en, this message translates to:
  /// **'Kindergarten'**
  String get setupKindergarten;

  /// No description provided for @setupYearN.
  ///
  /// In en, this message translates to:
  /// **'Year {n}'**
  String setupYearN(int n);

  /// No description provided for @setupStartTitle.
  ///
  /// In en, this message translates to:
  /// **'What can {name} already do?'**
  String setupStartTitle(String name);

  /// No description provided for @setupStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick everything that feels easy. In school order.'**
  String get setupStartSubtitle;

  /// No description provided for @setupCanCount100.
  ///
  /// In en, this message translates to:
  /// **'Counting to 100'**
  String get setupCanCount100;

  /// No description provided for @setupCanAdd100.
  ///
  /// In en, this message translates to:
  /// **'Adding to 100'**
  String get setupCanAdd100;

  /// No description provided for @setupCanSub100.
  ///
  /// In en, this message translates to:
  /// **'Subtracting to 100'**
  String get setupCanSub100;

  /// No description provided for @setupCanAdd1000.
  ///
  /// In en, this message translates to:
  /// **'Adding to 1000'**
  String get setupCanAdd1000;

  /// No description provided for @setupCanSub1000.
  ///
  /// In en, this message translates to:
  /// **'Subtracting to 1000'**
  String get setupCanSub1000;

  /// No description provided for @setupCanWordProblems.
  ///
  /// In en, this message translates to:
  /// **'Word problems with bars'**
  String get setupCanWordProblems;

  /// No description provided for @setupNotSure.
  ///
  /// In en, this message translates to:
  /// **'I\'m not sure'**
  String get setupNotSure;

  /// No description provided for @setupNotSureDetail.
  ///
  /// In en, this message translates to:
  /// **'Help me figure it out'**
  String get setupNotSureDetail;

  /// No description provided for @setupNotSureTitle.
  ///
  /// In en, this message translates to:
  /// **'No problem'**
  String get setupNotSureTitle;

  /// No description provided for @setupNotSureBody.
  ///
  /// In en, this message translates to:
  /// **'{name} starts at a typical {year} level. The first sums find the real one, and we\'ll email you what we found.'**
  String setupNotSureBody(String name, String year);

  /// No description provided for @setupNotSureBodyNoYear.
  ///
  /// In en, this message translates to:
  /// **'{name} starts at a level typical for their age. The first sums find the real one, and we\'ll email you what we found.'**
  String setupNotSureBodyNoYear(String name);

  /// No description provided for @setupQuickSums.
  ///
  /// In en, this message translates to:
  /// **'Four quick sums first'**
  String get setupQuickSums;

  /// No description provided for @setupQuickSumsDetail.
  ///
  /// In en, this message translates to:
  /// **'Before any word problem.'**
  String get setupQuickSumsDetail;

  /// No description provided for @setupEmailAfter.
  ///
  /// In en, this message translates to:
  /// **'An email after the first session'**
  String get setupEmailAfter;

  /// No description provided for @setupEmailAfterDetail.
  ///
  /// In en, this message translates to:
  /// **'Telling you where {name} is.'**
  String setupEmailAfterDetail(String name);

  /// No description provided for @setupGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What would help most?'**
  String get setupGoalTitle;

  /// No description provided for @setupGoalConfidence.
  ///
  /// In en, this message translates to:
  /// **'Build confidence'**
  String get setupGoalConfidence;

  /// No description provided for @setupGoalConfidenceDetail.
  ///
  /// In en, this message translates to:
  /// **'Calm, positive practice'**
  String get setupGoalConfidenceDetail;

  /// No description provided for @setupGoalCatchUp.
  ///
  /// In en, this message translates to:
  /// **'Catch up'**
  String get setupGoalCatchUp;

  /// No description provided for @setupGoalCatchUpDetail.
  ///
  /// In en, this message translates to:
  /// **'Fill gaps from school'**
  String get setupGoalCatchUpDetail;

  /// No description provided for @setupGoalAhead.
  ///
  /// In en, this message translates to:
  /// **'Get ahead'**
  String get setupGoalAhead;

  /// No description provided for @setupGoalAheadDetail.
  ///
  /// In en, this message translates to:
  /// **'Stretch with harder cases'**
  String get setupGoalAheadDetail;

  /// No description provided for @setupGoalWordProblems.
  ///
  /// In en, this message translates to:
  /// **'Word problems'**
  String get setupGoalWordProblems;

  /// No description provided for @setupGoalWordProblemsDetail.
  ///
  /// In en, this message translates to:
  /// **'Reading and drawing them'**
  String get setupGoalWordProblemsDetail;

  /// No description provided for @setupDataTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s details stay safe'**
  String setupDataTitle(String name);

  /// No description provided for @setupDataStored.
  ///
  /// In en, this message translates to:
  /// **'Stored in Australia'**
  String get setupDataStored;

  /// No description provided for @setupDataStoredDetail.
  ///
  /// In en, this message translates to:
  /// **'On servers in Australia.'**
  String get setupDataStoredDetail;

  /// No description provided for @setupDataNoAi.
  ///
  /// In en, this message translates to:
  /// **'Nothing personal goes to the AI'**
  String get setupDataNoAi;

  /// No description provided for @setupDataNoAiDetail.
  ///
  /// In en, this message translates to:
  /// **'The tutor never sees a name or a birthday.'**
  String get setupDataNoAiDetail;

  /// No description provided for @setupDataFirstName.
  ///
  /// In en, this message translates to:
  /// **'Only a first name'**
  String get setupDataFirstName;

  /// No description provided for @setupDataFirstNameDetail.
  ///
  /// In en, this message translates to:
  /// **'Your child never types personal details.'**
  String get setupDataFirstNameDetail;

  /// No description provided for @setupDataDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete it any time'**
  String get setupDataDelete;

  /// No description provided for @setupDataDeleteDetail.
  ///
  /// In en, this message translates to:
  /// **'From Settings, in one step.'**
  String get setupDataDeleteDetail;

  /// No description provided for @setupAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get setupAgree;

  /// No description provided for @setupSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {name}\'s place'**
  String setupSaveTitle(String name);

  /// No description provided for @setupSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One family account, so progress follows your child to any phone.'**
  String get setupSaveSubtitle;

  /// No description provided for @setupSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving {name}\'s place…'**
  String setupSaving(String name);

  /// No description provided for @setupContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get setupContinueApple;

  /// No description provided for @setupContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get setupContinueGoogle;

  /// No description provided for @setupUseEmail.
  ///
  /// In en, this message translates to:
  /// **'Use my email'**
  String get setupUseEmail;

  /// No description provided for @setupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get setupEmailLabel;

  /// No description provided for @setupEmailMeLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a link'**
  String get setupEmailMeLink;

  /// No description provided for @setupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type the email address to send the link to.'**
  String get setupEmailInvalid;

  /// No description provided for @setupAppleOff.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in isn\'t switched on for this server yet.'**
  String get setupAppleOff;

  /// No description provided for @setupEmailOff.
  ///
  /// In en, this message translates to:
  /// **'This server can\'t send email yet.'**
  String get setupEmailOff;

  /// No description provided for @setupSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get setupSignInTitle;

  /// No description provided for @setupSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your family account.'**
  String get setupSignInSubtitle;

  /// No description provided for @setupCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get setupCheckTitle;

  /// No description provided for @setupCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the link we sent to sign in on this phone.'**
  String get setupCheckBody;

  /// No description provided for @setupTappedLink.
  ///
  /// In en, this message translates to:
  /// **'I tapped the link'**
  String get setupTappedLink;

  /// No description provided for @setupLinkNotYet.
  ///
  /// In en, this message translates to:
  /// **'The link hasn\'t opened on this phone yet. Open the email on this phone and tap the link.'**
  String get setupLinkNotYet;

  /// No description provided for @setupDevLink.
  ///
  /// In en, this message translates to:
  /// **'Open the link (dev only)'**
  String get setupDevLink;

  /// No description provided for @setupVerifying.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get setupVerifying;

  /// No description provided for @setupLinkMissing.
  ///
  /// In en, this message translates to:
  /// **'This link has no sign-in code in it. Ask for a new one.'**
  String get setupLinkMissing;

  /// No description provided for @setupBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get setupBackToSignIn;

  /// No description provided for @setupReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get setupReadyTitle;

  /// No description provided for @setupReadyBody.
  ///
  /// In en, this message translates to:
  /// **'{name} starts with a short warm-up, then a story case.'**
  String setupReadyBody(String name);

  /// No description provided for @setupHandOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over to {name}'**
  String setupHandOver(String name);

  /// No description provided for @setupOwnPhone.
  ///
  /// In en, this message translates to:
  /// **'{name} has their own phone'**
  String setupOwnPhone(String name);

  /// No description provided for @setupLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the grown-up area'**
  String get setupLockTitle;

  /// No description provided for @setupLockBody.
  ///
  /// In en, this message translates to:
  /// **'So only you can change settings or see the book.'**
  String get setupLockBody;

  /// No description provided for @setupUseFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID'**
  String get setupUseFaceId;

  /// No description provided for @setupUsePasscode.
  ///
  /// In en, this message translates to:
  /// **'Use a passcode'**
  String get setupUsePasscode;

  /// No description provided for @setupFaceIdFailed.
  ///
  /// In en, this message translates to:
  /// **'Face ID didn\'t work. You can use a passcode instead.'**
  String get setupFaceIdFailed;

  /// No description provided for @setupFaceIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Face ID isn\'t set up on this phone. Use a passcode instead.'**
  String get setupFaceIdMissing;

  /// No description provided for @setupPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a passcode'**
  String get setupPassTitle;

  /// No description provided for @setupPassBody.
  ///
  /// In en, this message translates to:
  /// **'{n} digits, so only grown-ups can open the grown-up area.'**
  String setupPassBody(int n);

  /// No description provided for @setupPassAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get setupPassAgainTitle;

  /// No description provided for @setupPassAgainBody.
  ///
  /// In en, this message translates to:
  /// **'The same {n} digits, to be sure.'**
  String setupPassAgainBody(int n);

  /// No description provided for @setupPassMismatch.
  ///
  /// In en, this message translates to:
  /// **'Those didn\'t match. Choose a passcode again.'**
  String get setupPassMismatch;

  /// No description provided for @setupPassShort.
  ///
  /// In en, this message translates to:
  /// **'The passcode is {n} digits.'**
  String setupPassShort(int n);

  /// No description provided for @setupPassAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'Your family has a passcode'**
  String get setupPassAlreadySet;

  /// No description provided for @setupPassAlreadySetBody.
  ///
  /// In en, this message translates to:
  /// **'It was set on another phone. Use it to open the grown-up area here too.'**
  String get setupPassAlreadySetBody;

  /// No description provided for @setupJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {name}\'s phone'**
  String setupJoinTitle(String name);

  /// No description provided for @setupJoinBody.
  ///
  /// In en, this message translates to:
  /// **'On {name}\'s phone, open Auramath, tap I\'m a kid and type this code.'**
  String setupJoinBody(String name);

  /// No description provided for @setupWorksOnce.
  ///
  /// In en, this message translates to:
  /// **'Works once, for {time}'**
  String setupWorksOnce(String time);

  /// No description provided for @setupCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has run out. Show a new code.'**
  String get setupCodeExpired;

  /// No description provided for @setupProgressFollows.
  ///
  /// In en, this message translates to:
  /// **'Progress follows {name}'**
  String setupProgressFollows(String name);

  /// No description provided for @setupProgressFollowsDetail.
  ///
  /// In en, this message translates to:
  /// **'Lessons carry on from any phone in the family.'**
  String get setupProgressFollowsDetail;

  /// No description provided for @setupNewCode.
  ///
  /// In en, this message translates to:
  /// **'Show a new code'**
  String get setupNewCode;
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

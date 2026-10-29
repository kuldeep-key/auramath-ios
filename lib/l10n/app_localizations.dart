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

  /// No description provided for @takeABreak.
  ///
  /// In en, this message translates to:
  /// **'Take a break?'**
  String get takeABreak;

  /// No description provided for @exampleFacts.
  ///
  /// In en, this message translates to:
  /// **'Building A is {a} m. B is {d} m {relation}.'**
  String exampleFacts(int a, int d, String relation);

  /// No description provided for @exampleA.
  ///
  /// In en, this message translates to:
  /// **'Building A is {a} metres tall.'**
  String exampleA(int a);

  /// No description provided for @exampleB.
  ///
  /// In en, this message translates to:
  /// **'Building B is {d} metres {relation}.'**
  String exampleB(int d, String relation);

  /// No description provided for @exampleTake.
  ///
  /// In en, this message translates to:
  /// **'{a} take away {d} is {b}.'**
  String exampleTake(int a, int d, int b);

  /// No description provided for @exampleAdd.
  ///
  /// In en, this message translates to:
  /// **'{a} add {d} is {b}.'**
  String exampleAdd(int a, int d, int b);

  /// No description provided for @exampleTogether.
  ///
  /// In en, this message translates to:
  /// **'Together: {a} + {b} = {total} metres.'**
  String exampleTogether(int a, int b, int total);

  /// No description provided for @exampleShorter.
  ///
  /// In en, this message translates to:
  /// **'shorter'**
  String get exampleShorter;

  /// No description provided for @exampleTaller.
  ///
  /// In en, this message translates to:
  /// **'taller'**
  String get exampleTaller;

  /// No description provided for @exampleAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get exampleAgain;

  /// No description provided for @exampleNowYouTry.
  ///
  /// In en, this message translates to:
  /// **'Now you try'**
  String get exampleNowYouTry;

  /// No description provided for @lessonHundreds.
  ///
  /// In en, this message translates to:
  /// **'Hundreds'**
  String get lessonHundreds;

  /// No description provided for @lessonTens.
  ///
  /// In en, this message translates to:
  /// **'Tens'**
  String get lessonTens;

  /// No description provided for @lessonOnes.
  ///
  /// In en, this message translates to:
  /// **'Ones'**
  String get lessonOnes;

  /// No description provided for @lessonNotEnoughOnes.
  ///
  /// In en, this message translates to:
  /// **'Take {take} ones from {have}? Not enough!'**
  String lessonNotEnoughOnes(int take, int have);

  /// No description provided for @lessonNotEnoughTens.
  ///
  /// In en, this message translates to:
  /// **'Take {take} tens from {have}? Not enough!'**
  String lessonNotEnoughTens(int take, int have);

  /// No description provided for @lessonTapATen.
  ///
  /// In en, this message translates to:
  /// **'Tap a ten to break it.'**
  String get lessonTapATen;

  /// No description provided for @lessonTapAHundred.
  ///
  /// In en, this message translates to:
  /// **'Tap a hundred to break it.'**
  String get lessonTapAHundred;

  /// No description provided for @lessonTakeOnes.
  ///
  /// In en, this message translates to:
  /// **'Take away {n} ones.'**
  String lessonTakeOnes(int n);

  /// No description provided for @lessonTakeTens.
  ///
  /// In en, this message translates to:
  /// **'Take away {n} tens.'**
  String lessonTakeTens(int n);

  /// No description provided for @lessonTakeHundreds.
  ///
  /// In en, this message translates to:
  /// **'Take away {n} hundreds.'**
  String lessonTakeHundreds(int n);

  /// No description provided for @lessonAddOnes.
  ///
  /// In en, this message translates to:
  /// **'Add {n} ones.'**
  String lessonAddOnes(int n);

  /// No description provided for @lessonAddTens.
  ///
  /// In en, this message translates to:
  /// **'Add {n} tens.'**
  String lessonAddTens(int n);

  /// No description provided for @lessonAddHundreds.
  ///
  /// In en, this message translates to:
  /// **'Add {n} hundreds.'**
  String lessonAddHundreds(int n);

  /// No description provided for @lessonMakeATen.
  ///
  /// In en, this message translates to:
  /// **'{n} ones! Tap the ones to make a ten.'**
  String lessonMakeATen(int n);

  /// No description provided for @lessonMakeAHundred.
  ///
  /// In en, this message translates to:
  /// **'{n} tens! Tap the tens to make a hundred.'**
  String lessonMakeAHundred(int n);

  /// No description provided for @lessonDoIt.
  ///
  /// In en, this message translates to:
  /// **'Do it'**
  String get lessonDoIt;

  /// No description provided for @lessonSideDone.
  ///
  /// In en, this message translates to:
  /// **'{sum} = {answer}. You did it!'**
  String lessonSideDone(String sum, int answer);

  /// No description provided for @lessonLostInternetBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll carry on from here when it\'s back.'**
  String get lessonLostInternetBody;

  /// No description provided for @lessonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get lessonTryAgain;

  /// No description provided for @lessonNeedInternet.
  ///
  /// In en, this message translates to:
  /// **'We need the internet to start'**
  String get lessonNeedInternet;

  /// No description provided for @lessonNeedInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Check the Wi-Fi, then try again.'**
  String get lessonNeedInternetBody;

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

  /// No description provided for @pairBrand.
  ///
  /// In en, this message translates to:
  /// **'Auramath'**
  String get pairBrand;

  /// No description provided for @pairWhosUsing.
  ///
  /// In en, this message translates to:
  /// **'Hi! Who\'s using Auramath?'**
  String get pairWhosUsing;

  /// No description provided for @pairImAKid.
  ///
  /// In en, this message translates to:
  /// **'I\'m a kid'**
  String get pairImAKid;

  /// No description provided for @pairImAGrownUp.
  ///
  /// In en, this message translates to:
  /// **'I\'m a grown-up'**
  String get pairImAGrownUp;

  /// No description provided for @pairHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get pairHaveAccount;

  /// No description provided for @pairTypeCode.
  ///
  /// In en, this message translates to:
  /// **'Type your code'**
  String get pairTypeCode;

  /// No description provided for @pairCodeWhere.
  ///
  /// In en, this message translates to:
  /// **'Your grown-up has it on their phone.'**
  String get pairCodeWhere;

  /// No description provided for @pairAskForNewCode.
  ///
  /// In en, this message translates to:
  /// **'Ask your grown-up to make a new code on their phone.'**
  String get pairAskForNewCode;

  /// No description provided for @pairChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your code'**
  String get pairChecking;

  /// No description provided for @pairOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the internet. Check the Wi-Fi, then try again.'**
  String get pairOffline;

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work: {message}'**
  String pairFailed(String message);

  /// No description provided for @pairTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get pairTryAgain;

  /// No description provided for @pairPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Child\'s phone'**
  String get pairPhoneLabel;

  /// No description provided for @pairCodeWrong.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work'**
  String get pairCodeWrong;

  /// No description provided for @pairCodeWrongBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your grown-up for a new one.'**
  String get pairCodeWrongBody;

  /// No description provided for @pairTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many tries'**
  String get pairTooMany;

  /// No description provided for @pairTooManyBody.
  ///
  /// In en, this message translates to:
  /// **'Wait a few minutes, then ask your grown-up for a new code.'**
  String get pairTooManyBody;

  /// No description provided for @pairNewCode.
  ///
  /// In en, this message translates to:
  /// **'Grown-up: new code'**
  String get pairNewCode;

  /// No description provided for @pairWhichChild.
  ///
  /// In en, this message translates to:
  /// **'Which child is this phone for?'**
  String get pairWhichChild;

  /// No description provided for @pairNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No children here yet. Ask your grown-up to add you on their phone.'**
  String get pairNoChildren;

  /// No description provided for @pairIsThisYou.
  ///
  /// In en, this message translates to:
  /// **'Is this you?'**
  String get pairIsThisYou;

  /// No description provided for @pairYesMe.
  ///
  /// In en, this message translates to:
  /// **'Yes, that\'s me!'**
  String get pairYesMe;

  /// No description provided for @pairNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get pairNo;

  /// No description provided for @pairYoureIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re in, {name}!'**
  String pairYoureIn(String name);

  /// No description provided for @pairPhoneYours.
  ///
  /// In en, this message translates to:
  /// **'This phone is yours for lessons now.'**
  String get pairPhoneYours;

  /// No description provided for @pairLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get pairLetsGo;

  /// No description provided for @pairRemoved.
  ///
  /// In en, this message translates to:
  /// **'This phone was removed'**
  String get pairRemoved;

  /// No description provided for @pairRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress is safe. Ask your grown-up for a new code.'**
  String get pairRemovedBody;

  /// No description provided for @pairWhosLearning.
  ///
  /// In en, this message translates to:
  /// **'Who\'s learning today?'**
  String get pairWhosLearning;

  /// No description provided for @pairGrownUps.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups'**
  String get pairGrownUps;

  /// No description provided for @pairNoKidsYet.
  ///
  /// In en, this message translates to:
  /// **'No children yet. Add one to start learning.'**
  String get pairNoKidsYet;

  /// No description provided for @pairAddChild.
  ///
  /// In en, this message translates to:
  /// **'Add a child'**
  String get pairAddChild;

  /// No description provided for @pairCarryOn.
  ///
  /// In en, this message translates to:
  /// **'Carry on here?'**
  String get pairCarryOn;

  /// No description provided for @pairStartedOn.
  ///
  /// In en, this message translates to:
  /// **'You started this case on {device}. It moved with you.'**
  String pairStartedOn(String device);

  /// No description provided for @pairStartedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'You started this case on another phone. It moved with you.'**
  String get pairStartedElsewhere;

  /// No description provided for @pairCarryOnHere.
  ///
  /// In en, this message translates to:
  /// **'Carry on here'**
  String get pairCarryOnHere;

  /// No description provided for @guYourChild.
  ///
  /// In en, this message translates to:
  /// **'your child'**
  String get guYourChild;

  /// No description provided for @guTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get guTryAgain;

  /// No description provided for @guLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get guLoading;

  /// No description provided for @guCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get guCancel;

  /// No description provided for @guDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guDone;

  /// No description provided for @guOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get guOn;

  /// No description provided for @guOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get guOff;

  /// No description provided for @guPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups only'**
  String get guPassTitle;

  /// No description provided for @guPassEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter your passcode.'**
  String get guPassEnter;

  /// No description provided for @guPassForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot passcode?'**
  String get guPassForgot;

  /// No description provided for @guPassWrong.
  ///
  /// In en, this message translates to:
  /// **'That\'s not the passcode. Try again.'**
  String get guPassWrong;

  /// No description provided for @guPassLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Try again after {time}.'**
  String guPassLocked(String time);

  /// No description provided for @guPassLockedSoon.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes and try again.'**
  String get guPassLockedSoon;

  /// No description provided for @guPassChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a passcode'**
  String get guPassChooseTitle;

  /// No description provided for @guPassNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new passcode'**
  String get guPassNewTitle;

  /// No description provided for @guPassChooseBody.
  ///
  /// In en, this message translates to:
  /// **'{n} digits, so only grown-ups can open this area.'**
  String guPassChooseBody(int n);

  /// No description provided for @guPassConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get guPassConfirmTitle;

  /// No description provided for @guPassConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'To be sure it\'s right.'**
  String get guPassConfirmBody;

  /// No description provided for @guPassMismatch.
  ///
  /// In en, this message translates to:
  /// **'Those didn\'t match. Choose a passcode again.'**
  String get guPassMismatch;

  /// No description provided for @guPassShort.
  ///
  /// In en, this message translates to:
  /// **'Type all {n} digits.'**
  String guPassShort(int n);

  /// No description provided for @guPassResetBlocked.
  ///
  /// In en, this message translates to:
  /// **'The server still asks for the old passcode before it sets a new one, so this can\'t finish yet.'**
  String get guPassResetBlocked;

  /// No description provided for @guFaceIdReason.
  ///
  /// In en, this message translates to:
  /// **'Open the grown-up area'**
  String get guFaceIdReason;

  /// No description provided for @guUseFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID'**
  String get guUseFaceId;

  /// No description provided for @guForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your passcode?'**
  String get guForgotTitle;

  /// No description provided for @guForgotBody.
  ///
  /// In en, this message translates to:
  /// **'We will email a sign-in link to {email}.'**
  String guForgotBody(String email);

  /// No description provided for @guForgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send the link'**
  String get guForgotSend;

  /// No description provided for @guForgotSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get guForgotSentTitle;

  /// No description provided for @guForgotSentBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a sign-in link to {email}. Open it on this phone, then come back to choose a new passcode.'**
  String guForgotSentBody(String email);

  /// No description provided for @guForgotResend.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get guForgotResend;

  /// No description provided for @guForgotNoEmail.
  ///
  /// In en, this message translates to:
  /// **'This account has no email address to send a link to.'**
  String get guForgotNoEmail;

  /// No description provided for @guHomeHi.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get guHomeHi;

  /// No description provided for @guHomeWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions this week} =1{1 session this week} other{{count} sessions this week}}'**
  String guHomeWeek(int count);

  /// No description provided for @guProgressError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load progress'**
  String get guProgressError;

  /// No description provided for @guHomeProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'{month} progress'**
  String guHomeProgressTitle(String month);

  /// No description provided for @guHomeProgressBody.
  ///
  /// In en, this message translates to:
  /// **'{name} this month'**
  String guHomeProgressBody(String name);

  /// No description provided for @guHomeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get guHomeFamily;

  /// No description provided for @guHomePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get guHomePlan;

  /// No description provided for @guHomeBackTo.
  ///
  /// In en, this message translates to:
  /// **'Back to {name}'**
  String guHomeBackTo(String name);

  /// No description provided for @guHomeNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No children yet'**
  String get guHomeNoChildren;

  /// No description provided for @guHomeNoChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Add a child to start their first lesson.'**
  String get guHomeNoChildrenBody;

  /// No description provided for @guAddChild.
  ///
  /// In en, this message translates to:
  /// **'Add a child'**
  String get guAddChild;

  /// No description provided for @guSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get guSettingsTitle;

  /// No description provided for @guSetTime.
  ///
  /// In en, this message translates to:
  /// **'Time each day'**
  String get guSetTime;

  /// No description provided for @guSetMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String guSetMinutes(int n);

  /// No description provided for @guSetReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get guSetReadAloud;

  /// No description provided for @guSetPad.
  ///
  /// In en, this message translates to:
  /// **'Number pad'**
  String get guSetPad;

  /// No description provided for @guSetPadPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s own'**
  String get guSetPadPhone;

  /// No description provided for @guSetPadApp.
  ///
  /// In en, this message translates to:
  /// **'The app\'s own'**
  String get guSetPadApp;

  /// No description provided for @guSetBigPad.
  ///
  /// In en, this message translates to:
  /// **'Bigger number pad (accessibility)'**
  String get guSetBigPad;

  /// No description provided for @guSetChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Changes the setting'**
  String get guSetChangeHint;

  /// No description provided for @guFamilyAndPhones.
  ///
  /// In en, this message translates to:
  /// **'Family and phones'**
  String get guFamilyAndPhones;

  /// No description provided for @guChildPlan.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s plan'**
  String guChildPlan(String name);

  /// No description provided for @guNotifyLink.
  ///
  /// In en, this message translates to:
  /// **'Email after each session'**
  String get guNotifyLink;

  /// No description provided for @guRightsLink.
  ///
  /// In en, this message translates to:
  /// **'Your data and rights'**
  String get guRightsLink;

  /// No description provided for @guSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get guSignOut;

  /// No description provided for @guFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family and phones'**
  String get guFamilyTitle;

  /// No description provided for @guGrownUps.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups'**
  String get guGrownUps;

  /// No description provided for @guChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get guChildren;

  /// No description provided for @guPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get guPhones;

  /// No description provided for @guYou.
  ///
  /// In en, this message translates to:
  /// **'{email} (you)'**
  String guYou(String email);

  /// No description provided for @guOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get guOwner;

  /// No description provided for @guGrownUp.
  ///
  /// In en, this message translates to:
  /// **'Grown-up'**
  String get guGrownUp;

  /// No description provided for @guInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get guInvited;

  /// No description provided for @guRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get guRemove;

  /// No description provided for @guRemovePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String guRemovePhoneLabel(String label);

  /// No description provided for @guNoPhones.
  ///
  /// In en, this message translates to:
  /// **'No phones joined yet'**
  String get guNoPhones;

  /// No description provided for @guNoChildrenRow.
  ///
  /// In en, this message translates to:
  /// **'No children yet'**
  String get guNoChildrenRow;

  /// No description provided for @guInviteGrownUp.
  ///
  /// In en, this message translates to:
  /// **'Invite a grown-up'**
  String get guInviteGrownUp;

  /// No description provided for @guAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add a child\'s phone'**
  String get guAddPhone;

  /// No description provided for @guInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a grown-up'**
  String get guInviteTitle;

  /// No description provided for @guInviteBody.
  ///
  /// In en, this message translates to:
  /// **'They can see the book and change settings.'**
  String get guInviteBody;

  /// No description provided for @guInviteEmail.
  ///
  /// In en, this message translates to:
  /// **'Their email'**
  String get guInviteEmail;

  /// No description provided for @guInviteSend.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get guInviteSend;

  /// No description provided for @guInviteBadEmail.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address.'**
  String get guInviteBadEmail;

  /// No description provided for @guInviteSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite sent'**
  String get guInviteSentTitle;

  /// No description provided for @guInviteSentBody.
  ///
  /// In en, this message translates to:
  /// **'We emailed a link to {email}.'**
  String guInviteSentBody(String email);

  /// No description provided for @guCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Here is a code'**
  String get guCodeTitle;

  /// No description provided for @guCodeNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Here is a new code'**
  String get guCodeNewTitle;

  /// No description provided for @guCodeNewBody.
  ///
  /// In en, this message translates to:
  /// **'The old one stopped working.'**
  String get guCodeNewBody;

  /// No description provided for @guCodeLeft.
  ///
  /// In en, this message translates to:
  /// **'Works once. {time} left.'**
  String guCodeLeft(String time);

  /// No description provided for @guCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has stopped working.'**
  String get guCodeExpired;

  /// No description provided for @guCodeAgain.
  ///
  /// In en, this message translates to:
  /// **'Get a new code'**
  String get guCodeAgain;

  /// No description provided for @guCodeTypeOn.
  ///
  /// In en, this message translates to:
  /// **'Type it on {name}\'s phone'**
  String guCodeTypeOn(String name);

  /// No description provided for @guCodeTypeOnChild.
  ///
  /// In en, this message translates to:
  /// **'Type it on your child\'s phone'**
  String get guCodeTypeOnChild;

  /// No description provided for @guRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}?'**
  String guRemoveTitle(String label);

  /// No description provided for @guRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'It signs out straight away. Progress stays safe in the family account.'**
  String get guRemoveBody;

  /// No description provided for @guRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove phone'**
  String get guRemoveButton;

  /// No description provided for @guRemoveGone.
  ///
  /// In en, this message translates to:
  /// **'That phone isn\'t in your family any more.'**
  String get guRemoveGone;

  /// No description provided for @guRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone removed'**
  String get guRemovedTitle;

  /// No description provided for @guRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'That phone is signed out. Join a new phone with a code any time.'**
  String get guRemovedBody;

  /// No description provided for @guAddChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a child'**
  String get guAddChildTitle;

  /// No description provided for @guAddChildBody.
  ///
  /// In en, this message translates to:
  /// **'You agree for them, as their grown-up. Only a first name.'**
  String get guAddChildBody;

  /// No description provided for @guAddChildName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get guAddChildName;

  /// No description provided for @guAddChildNameNeeded.
  ///
  /// In en, this message translates to:
  /// **'Type a first name.'**
  String get guAddChildNameNeeded;

  /// No description provided for @guAddChildYear.
  ///
  /// In en, this message translates to:
  /// **'School year (optional)'**
  String get guAddChildYear;

  /// No description provided for @guAddChildYearHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Year 2'**
  String get guAddChildYearHint;

  /// No description provided for @guAddChildAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree, continue'**
  String get guAddChildAgree;

  /// No description provided for @guRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data and rights'**
  String get guRightsTitle;

  /// No description provided for @guStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'What we keep'**
  String get guStoredTitle;

  /// No description provided for @guStored1.
  ///
  /// In en, this message translates to:
  /// **'Your email, and other grown-ups\' emails'**
  String get guStored1;

  /// No description provided for @guStored2.
  ///
  /// In en, this message translates to:
  /// **'Each child\'s first name, and their age, school year and goal if you gave them'**
  String get guStored2;

  /// No description provided for @guStored3.
  ///
  /// In en, this message translates to:
  /// **'Every step of every lesson'**
  String get guStored3;

  /// No description provided for @guStored4.
  ///
  /// In en, this message translates to:
  /// **'The names of joined phones'**
  String get guStored4;

  /// No description provided for @guDownload.
  ///
  /// In en, this message translates to:
  /// **'Download everything'**
  String get guDownload;

  /// No description provided for @guDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'A file with all of your family\'s data'**
  String get guDownloadBody;

  /// No description provided for @guExportPending.
  ///
  /// In en, this message translates to:
  /// **'Getting it ready…'**
  String get guExportPending;

  /// No description provided for @guExportReady.
  ///
  /// In en, this message translates to:
  /// **'Ready. Tap to save it on this phone.'**
  String get guExportReady;

  /// No description provided for @guExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone as {file}'**
  String guExportSaved(String file);

  /// No description provided for @guExportFailed.
  ///
  /// In en, this message translates to:
  /// **'The export failed. Tap to try again.'**
  String get guExportFailed;

  /// No description provided for @guExportExpired.
  ///
  /// In en, this message translates to:
  /// **'That export has expired. Tap to start another.'**
  String get guExportExpired;

  /// No description provided for @guDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete the family account'**
  String get guDeleteAccount;

  /// No description provided for @guDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Everything, for every child, straight away'**
  String get guDeleteAccountBody;

  /// No description provided for @guDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your family account?'**
  String get guDeleteTitle;

  /// No description provided for @guDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes everything we keep: every child\'s lessons and progress, the other grown-ups\' access and every joined phone. It happens straight away and can\'t be undone. Download everything first if you want a copy.'**
  String get guDeleteBody;

  /// No description provided for @guDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get guDeleteButton;

  /// No description provided for @guNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'A note after each session?'**
  String get guNotifyTitle;

  /// No description provided for @guNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you what {name} did and what\'s next. Nothing else.'**
  String guNotifyBody(String name);

  /// No description provided for @guNotifyCard.
  ///
  /// In en, this message translates to:
  /// **'An email after each session'**
  String get guNotifyCard;

  /// No description provided for @guNotifyCardBody.
  ///
  /// In en, this message translates to:
  /// **'One short note, after the session ends.'**
  String get guNotifyCardBody;

  /// No description provided for @guNotifyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes please'**
  String get guNotifyYes;

  /// No description provided for @guNotifyNo.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get guNotifyNo;

  /// No description provided for @guSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out on this phone?'**
  String get guSignOutTitle;

  /// No description provided for @guSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Progress stays safe in your family account.'**
  String get guSignOutBody;

  /// No description provided for @guBookTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s book'**
  String guBookTitle(String name);

  /// No description provided for @guTabWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get guTabWeek;

  /// No description provided for @guTabSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get guTabSkills;

  /// No description provided for @guTabBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get guTabBadges;

  /// No description provided for @guSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'{day} · {n} min'**
  String guSessionTitle(String day, int n);

  /// No description provided for @guSessionUnfinished.
  ///
  /// In en, this message translates to:
  /// **'{day} · not finished'**
  String guSessionUnfinished(String day);

  /// No description provided for @guNoNote.
  ///
  /// In en, this message translates to:
  /// **'No note for this session.'**
  String get guNoNote;

  /// No description provided for @guNoteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the note.'**
  String get guNoteError;

  /// No description provided for @guNothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get guNothingSaved;

  /// No description provided for @guNothingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s sessions this week show here.'**
  String guNothingThisWeek(String name);

  /// No description provided for @guSkillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Each skill\'s progress will show here. It isn\'t ready yet.'**
  String get guSkillsEmpty;

  /// No description provided for @guBadgesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Badges show on {name}\'s own screens.'**
  String guBadgesEmpty(String name);

  /// No description provided for @guMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month view'**
  String get guMonthView;

  /// No description provided for @guMonthViewBody.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get guMonthViewBody;

  /// No description provided for @guSimpleReport.
  ///
  /// In en, this message translates to:
  /// **'See the simple report'**
  String get guSimpleReport;

  /// No description provided for @guWhatsNext.
  ///
  /// In en, this message translates to:
  /// **'What\'s next in the plan'**
  String get guWhatsNext;

  /// No description provided for @guPlanBody.
  ///
  /// In en, this message translates to:
  /// **'What comes next, from {name}\'s latest lessons.'**
  String guPlanBody(String name);

  /// No description provided for @guPlanNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guPlanNext;

  /// No description provided for @guPlanCheck.
  ///
  /// In en, this message translates to:
  /// **'A quick check'**
  String get guPlanCheck;

  /// No description provided for @guPlanCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get guPlanCheckNow;

  /// No description provided for @guPlanCheckOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String guPlanCheckOn(String date);

  /// No description provided for @guPlanAway.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day since the last lesson} other{{days} days since the last lesson}}'**
  String guPlanAway(int days);

  /// No description provided for @guPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get guPlanEmpty;

  /// No description provided for @guPlanEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The plan fills in after {name}\'s first lesson.'**
  String guPlanEmptyBody(String name);

  /// No description provided for @guReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple report'**
  String get guReportTitle;

  /// No description provided for @guReportBody.
  ///
  /// In en, this message translates to:
  /// **'The short version for a quick look.'**
  String get guReportBody;

  /// No description provided for @guReportSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions this week'**
  String get guReportSessions;

  /// No description provided for @guReportTime.
  ///
  /// In en, this message translates to:
  /// **'Time this week'**
  String get guReportTime;

  /// No description provided for @guReportNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guReportNext;

  /// No description provided for @guReportNextNone.
  ///
  /// In en, this message translates to:
  /// **'After the first lesson'**
  String get guReportNextNone;

  /// No description provided for @guMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} in {month}'**
  String guMonthTitle(String name, String month);

  /// No description provided for @guMonthBody.
  ///
  /// In en, this message translates to:
  /// **'From 1 {month} to today.'**
  String guMonthBody(String month);

  /// No description provided for @guMonthSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions this month'**
  String get guMonthSessions;

  /// No description provided for @guMonthTime.
  ///
  /// In en, this message translates to:
  /// **'Time this month'**
  String get guMonthTime;

  /// No description provided for @guMonthChartLater.
  ///
  /// In en, this message translates to:
  /// **'A chart of {name}\'s skill steps will show here once the server reports them.'**
  String guMonthChartLater(String name);

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

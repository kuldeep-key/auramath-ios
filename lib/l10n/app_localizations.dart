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

  /// No description provided for @tooHardTitle.
  ///
  /// In en, this message translates to:
  /// **'This one\'s tricky. Want a hand?'**
  String get tooHardTitle;

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

  /// No description provided for @sideTypeIt.
  ///
  /// In en, this message translates to:
  /// **'So what is {sum}? Type it in.'**
  String sideTypeIt(String sum);

  /// No description provided for @sidePractice.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try one like it: {sum}'**
  String sidePractice(String sum);

  /// No description provided for @sidePracticeDone.
  ///
  /// In en, this message translates to:
  /// **'Nice practice! Now back to the case.'**
  String get sidePracticeDone;

  /// No description provided for @sideKindEnd.
  ///
  /// In en, this message translates to:
  /// **'These are tricky. We\'ll practise them again soon. Back to the case!'**
  String get sideKindEnd;

  /// No description provided for @sideAnswerIs.
  ///
  /// In en, this message translates to:
  /// **'{sum} = {answer}. Now back to the case.'**
  String sideAnswerIs(String sum, int answer);

  /// No description provided for @lessonWarmUpStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s warm up with a few sums. No rush!'**
  String get lessonWarmUpStart;

  /// No description provided for @lessonWarmUpNext.
  ///
  /// In en, this message translates to:
  /// **'Here\'s another sum.'**
  String get lessonWarmUpNext;

  /// Read aloud in place of the ? in a warm-up sum: '56 - 19 = what'
  ///
  /// In en, this message translates to:
  /// **'what'**
  String get lessonWarmUpBlank;

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

  /// No description provided for @lessonNoChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up'**
  String get lessonNoChildTitle;

  /// No description provided for @lessonNoChildBody.
  ///
  /// In en, this message translates to:
  /// **'A grown-up needs to add you before your first case.'**
  String get lessonNoChildBody;

  /// No description provided for @lessonPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up'**
  String get lessonPausedTitle;

  /// No description provided for @lessonPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons are paused for now. A grown-up can turn them back on.'**
  String get lessonPausedBody;

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

  /// No description provided for @leaveThisOne.
  ///
  /// In en, this message translates to:
  /// **'Try a different case'**
  String get leaveThisOne;

  /// No description provided for @leftWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'A case is waiting'**
  String get leftWaitingTitle;

  /// No description provided for @leftWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Last time you left the {item} case. Want to try it again?'**
  String leftWaitingBody(String item);

  /// No description provided for @leftTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try it again'**
  String get leftTryAgain;

  /// No description provided for @leftSomethingNew.
  ///
  /// In en, this message translates to:
  /// **'Something new'**
  String get leftSomethingNew;

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

  /// No description provided for @keptTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved for next time'**
  String get keptTitle;

  /// No description provided for @keptBody.
  ///
  /// In en, this message translates to:
  /// **'We were away a while, so this case is kept for next time.'**
  String get keptBody;

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
  /// **'It has been more than 10 minutes since you signed in. Sign in again, then choose a new passcode.'**
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

  /// No description provided for @guHomeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get guHomeFamily;

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

  /// No description provided for @guHomePaused.
  ///
  /// In en, this message translates to:
  /// **'Lessons are paused'**
  String get guHomePaused;

  /// No description provided for @guHomePausedBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons can\'t start until a grown-up agrees again to how we keep their learning. You can do that in Your data and rights.'**
  String get guHomePausedBody;

  /// No description provided for @guHomePausedLink.
  ///
  /// In en, this message translates to:
  /// **'Your data and rights'**
  String get guHomePausedLink;

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

  /// No description provided for @guInvitedEmail.
  ///
  /// In en, this message translates to:
  /// **'{email} (invited)'**
  String guInvitedEmail(String email);

  /// No description provided for @guCancelInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get guCancelInviteLink;

  /// No description provided for @guCancelInviteLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the invite to {email}'**
  String guCancelInviteLabel(String email);

  /// No description provided for @guRemoveGrownUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove {email}'**
  String guRemoveGrownUpLabel(String email);

  /// No description provided for @guSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get guSignedIn;

  /// No description provided for @guNoBrowsers.
  ///
  /// In en, this message translates to:
  /// **'Not signed in anywhere else'**
  String get guNoBrowsers;

  /// No description provided for @guThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get guThisPhone;

  /// No description provided for @guBrowserUnnamed.
  ///
  /// In en, this message translates to:
  /// **'A browser'**
  String get guBrowserUnnamed;

  /// No description provided for @guSignOutBrowserLink.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get guSignOutBrowserLink;

  /// No description provided for @guSignOutBrowserLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out {label}'**
  String guSignOutBrowserLabel(String label);

  /// No description provided for @guOpenChildHint.
  ///
  /// In en, this message translates to:
  /// **'Shows where they are'**
  String get guOpenChildHint;

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

  /// No description provided for @guRemoveGrownUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {email}?'**
  String guRemoveGrownUpTitle(String email);

  /// No description provided for @guRemoveGrownUpBody.
  ///
  /// In en, this message translates to:
  /// **'They\'re signed out straight away and can\'t open the family account any more. You can invite them again later.'**
  String get guRemoveGrownUpBody;

  /// No description provided for @guRemoveGrownUpButton.
  ///
  /// In en, this message translates to:
  /// **'Remove them'**
  String get guRemoveGrownUpButton;

  /// No description provided for @guRemoveGrownUpGone.
  ///
  /// In en, this message translates to:
  /// **'That grown-up isn\'t in your family any more.'**
  String get guRemoveGrownUpGone;

  /// No description provided for @guCancelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the invite to {email}?'**
  String guCancelInviteTitle(String email);

  /// No description provided for @guCancelInviteBody.
  ///
  /// In en, this message translates to:
  /// **'The link we emailed them stops working. You can send a new invite any time.'**
  String get guCancelInviteBody;

  /// No description provided for @guCancelInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel the invite'**
  String get guCancelInviteButton;

  /// No description provided for @guKeepInvite.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get guKeepInvite;

  /// No description provided for @guCancelInviteGone.
  ///
  /// In en, this message translates to:
  /// **'That invite isn\'t waiting any more.'**
  String get guCancelInviteGone;

  /// No description provided for @guSignOutBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out {label}?'**
  String guSignOutBrowserTitle(String label);

  /// No description provided for @guSignOutBrowserBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s signed out straight away. Anyone using it would need to sign in again.'**
  String get guSignOutBrowserBody;

  /// No description provided for @guSignOutBrowserButton.
  ///
  /// In en, this message translates to:
  /// **'Sign it out'**
  String get guSignOutBrowserButton;

  /// No description provided for @guBrowserGone.
  ///
  /// In en, this message translates to:
  /// **'That browser is already signed out.'**
  String get guBrowserGone;

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

  /// No description provided for @guAddChildYearUnknown.
  ///
  /// In en, this message translates to:
  /// **'Type Kindergarten or a year from 1 to 5.'**
  String get guAddChildYearUnknown;

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

  /// No description provided for @guConsentLink.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your consent'**
  String get guConsentLink;

  /// No description provided for @guConsentLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons stop until you agree again'**
  String get guConsentLinkBody;

  /// No description provided for @guConsentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'You\'ve withdrawn your consent'**
  String get guConsentWithdrawn;

  /// No description provided for @guConsentWithdrawnBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons are paused and no child can be added. What we keep stays until you delete it.'**
  String get guConsentWithdrawnBody;

  /// No description provided for @guConsentAgainLink.
  ///
  /// In en, this message translates to:
  /// **'Agree again'**
  String get guConsentAgainLink;

  /// No description provided for @guConsentAgainLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons can start again straight away'**
  String get guConsentAgainLinkBody;

  /// No description provided for @guConsentError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your consent'**
  String get guConsentError;

  /// No description provided for @guWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your consent?'**
  String get guWithdrawTitle;

  /// No description provided for @guWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Lessons stop straight away on every phone, and no child can be added. Nothing is deleted: what we keep stays until you delete it here. You can agree again any time.'**
  String get guWithdrawBody;

  /// No description provided for @guWithdrawButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get guWithdrawButton;

  /// No description provided for @guAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Agree again?'**
  String get guAgainTitle;

  /// No description provided for @guAgainBody.
  ///
  /// In en, this message translates to:
  /// **'You agree, as their grown-up, that we keep each child\'s first name and every step of their lessons, so lessons can carry on. You can withdraw again or delete everything any time.'**
  String get guAgainBody;

  /// No description provided for @guAgainButton.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get guAgainButton;

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

  /// No description provided for @guLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Where {name} is'**
  String guLearningTitle(String name);

  /// No description provided for @guLearningBody.
  ///
  /// In en, this message translates to:
  /// **'What {name} is working on, and how their level has changed.'**
  String guLearningBody(String name);

  /// No description provided for @guLearningEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get guLearningEmpty;

  /// No description provided for @guLearningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This fills in after {name}\'s first lesson.'**
  String guLearningEmptyBody(String name);

  /// No description provided for @guLearningComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparing amounts'**
  String get guLearningComparison;

  /// No description provided for @guLearningOther.
  ///
  /// In en, this message translates to:
  /// **'Their lessons'**
  String get guLearningOther;

  /// No description provided for @guLearningLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String guLearningLevel(String level);

  /// No description provided for @guLearningNow.
  ///
  /// In en, this message translates to:
  /// **'Working at this level now'**
  String get guLearningNow;

  /// No description provided for @guLearningHistory.
  ///
  /// In en, this message translates to:
  /// **'How it changed'**
  String get guLearningHistory;

  /// No description provided for @guLearningNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Still at the level they started on.'**
  String get guLearningNoChanges;

  /// No description provided for @guLearningMovedUp.
  ///
  /// In en, this message translates to:
  /// **'Moved up to level {level}'**
  String guLearningMovedUp(String level);

  /// No description provided for @guLearningWentBack.
  ///
  /// In en, this message translates to:
  /// **'Went back a level to build confidence'**
  String get guLearningWentBack;

  /// No description provided for @guLearningChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed to level {level}'**
  String guLearningChanged(String level);

  /// No description provided for @guLearningEdit.
  ///
  /// In en, this message translates to:
  /// **'Change {name}\'s details'**
  String guLearningEdit(String name);

  /// No description provided for @guLearningEditBody.
  ///
  /// In en, this message translates to:
  /// **'Name, age and school year'**
  String get guLearningEditBody;

  /// No description provided for @guEditTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s details'**
  String guEditTitle(String name);

  /// No description provided for @guEditBody.
  ///
  /// In en, this message translates to:
  /// **'Change what you told us. Lessons follow from the next one.'**
  String get guEditBody;

  /// No description provided for @guEditName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get guEditName;

  /// No description provided for @guEditNameNeeded.
  ///
  /// In en, this message translates to:
  /// **'Type a first name.'**
  String get guEditNameNeeded;

  /// No description provided for @guEditNameLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it to 40 letters or fewer.'**
  String get guEditNameLong;

  /// No description provided for @guEditAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get guEditAge;

  /// No description provided for @guEditYear.
  ///
  /// In en, this message translates to:
  /// **'School year'**
  String get guEditYear;

  /// No description provided for @guEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get guEditSave;

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
  /// **'Bar-model word problems for ages 6 to 10, read aloud and drawn by your child.'**
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

  /// No description provided for @setupAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Auramath is for ages 6 to 10 for now.'**
  String get setupAgeRange;

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

  /// No description provided for @setupGoalSchool.
  ///
  /// In en, this message translates to:
  /// **'Do well in the school curriculum'**
  String get setupGoalSchool;

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

  /// No description provided for @setupCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Or type the 6-digit code from the email'**
  String get setupCodeLabel;

  /// No description provided for @setupCodeUse.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the code'**
  String get setupCodeUse;

  /// No description provided for @setupCodeSix.
  ///
  /// In en, this message translates to:
  /// **'The code is 6 numbers.'**
  String get setupCodeSix;

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

  /// No description provided for @setupReadyNoHelp.
  ///
  /// In en, this message translates to:
  /// **'Please let {name} try on their own. Getting stuck is part of it, and the help is built in.'**
  String setupReadyNoHelp(String name);

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

  /// DRAFT, for Julia and design (no Figma frame): the case partner's small thinking cue when the tutor's decision takes over a second (NFR-05). Never a spinner; the child can carry on.
  ///
  /// In en, this message translates to:
  /// **'Hmm, let me think.'**
  String get lessonThinking;

  /// DRAFT, for Julia and design (no Figma frame), AI-09: the tutor offers to read the question again after quick wrong answers. The question is read aloud as it opens.
  ///
  /// In en, this message translates to:
  /// **'Let\'s read it again'**
  String get lessonReadAgainTitle;

  /// DRAFT, for Julia (AI-09): closes the read-again prompt.
  ///
  /// In en, this message translates to:
  /// **'Back to my drawing'**
  String get lessonReadAgainBack;

  /// DRAFT, for Julia and design (no Figma frame), AI-10: the first help on a case that looks new links to one the child solved.
  ///
  /// In en, this message translates to:
  /// **'You\'ve solved one like this'**
  String get lessonSeenBeforeTitle;

  /// DRAFT, for Julia (AI-10): above a peek at the earlier case.
  ///
  /// In en, this message translates to:
  /// **'Remember this case? You cracked it. This one works the same way.'**
  String get lessonSeenBeforeLinked;

  /// DRAFT, for Julia (AI-10): when the decision names no earlier case, or this phone doesn't have it.
  ///
  /// In en, this message translates to:
  /// **'You\'ve cracked a case like this before. How did you draw it?'**
  String get lessonSeenBeforeNoCase;

  /// DRAFT, for Julia (AI-10): closes the seen-before prompt.
  ///
  /// In en, this message translates to:
  /// **'Back to my case'**
  String get lessonSeenBeforeBack;

  /// DRAFT, for Julia and design (no Figma frame), AI-08: above three faces after a solved case, ages 7 and up. Optional; Next works without a face.
  ///
  /// In en, this message translates to:
  /// **'How was this case?'**
  String get lessonRateAsk;

  /// DRAFT (AI-08): the happy face.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get lessonRateEasy;

  /// DRAFT (AI-08): the middle face.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get lessonRateOk;

  /// DRAFT (AI-08): the thinking face.
  ///
  /// In en, this message translates to:
  /// **'Tricky'**
  String get lessonRateTricky;

  /// DRAFT, for Julia (AI-08): the kind line about checking work after 'Easy'. Shown back only as a teaching moment.
  ///
  /// In en, this message translates to:
  /// **'Easy ones are worth a check too. A quick look at your sum keeps them easy.'**
  String get lessonRateSaidEasy;

  /// DRAFT, for Julia (AI-08): after 'OK'.
  ///
  /// In en, this message translates to:
  /// **'Thanks for telling me. Checking each step helps every time.'**
  String get lessonRateSaidOk;

  /// DRAFT, for Julia (AI-08): after 'Tricky'.
  ///
  /// In en, this message translates to:
  /// **'Tricky cases take care. Checking each bar helped you crack it.'**
  String get lessonRateSaidTricky;

  /// DRAFT, for Julia and design (no Figma frame), AI-07: the first-meeting scene, once per child before their first lesson, with the grown-up there.
  ///
  /// In en, this message translates to:
  /// **'Meet your case partner'**
  String get kidMeetTitle;

  /// DRAFT, for Julia (AI-07): a note for the grown-up at the top of the first-meeting scene.
  ///
  /// In en, this message translates to:
  /// **'Grown-up: please stay for this part.'**
  String get kidMeetGrownUp;

  /// DRAFT, for Julia (AI-07): line 1 of the case partner's disclosure. A line the content bundle serves (policy line.intro.*) replaces these.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your case partner. I help you crack maths cases.'**
  String get kidMeetLine1;

  /// DRAFT, for Julia (AI-07): line 2, the disclosure itself.
  ///
  /// In en, this message translates to:
  /// **'I\'m a computer helper, an AI. I\'m not a person.'**
  String get kidMeetLine2;

  /// DRAFT, for Julia (AI-07): line 3.
  ///
  /// In en, this message translates to:
  /// **'Julia\'s team wrote my rules. I can make mistakes, so if something looks odd, tell your grown-up.'**
  String get kidMeetLine3;

  /// DRAFT, for Julia (AI-07): line 4.
  ///
  /// In en, this message translates to:
  /// **'Your grown-up can see your work.'**
  String get kidMeetLine4;

  /// DRAFT (AI-07): ends the first-meeting scene and opens the first lesson.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start'**
  String get kidMeetStart;

  /// DRAFT, for Julia and design (Figma 37.2 not built yet), TUT-09: a Help me choice on the sum steps; the number sentence shows each number's name under it, beside the bars.
  ///
  /// In en, this message translates to:
  /// **'Show the sum in words'**
  String get lessonEasierSum;

  /// DRAFT (TUT-09): the word under the difference in the easier number sentence.
  ///
  /// In en, this message translates to:
  /// **'gap'**
  String get lessonSentenceGap;

  /// DRAFT (TUT-09): the word under the ? in the easier sentence for the total.
  ///
  /// In en, this message translates to:
  /// **'both'**
  String get lessonSentenceBoth;
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

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

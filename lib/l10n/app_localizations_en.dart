// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gotItLetsDraw => 'Got it, let\'s draw';

  @override
  String get hearItAgain => 'Hear it again';

  @override
  String get todaysCase => 'Here\'s today\'s case. Listen first.';

  @override
  String get iKnowIt => 'I know it';

  @override
  String get helpMe => 'Help me';

  @override
  String get trickyTapMe => 'Tricky one? Tap me!';

  @override
  String get check => 'Check';

  @override
  String get pieceBar => 'Bar';

  @override
  String get pieceGap => 'Gap';

  @override
  String get pieceTotal => 'Total';

  @override
  String get taller => 'Taller';

  @override
  String get shorter => 'Shorter';

  @override
  String get takeAway => 'Take away';

  @override
  String get add => 'Add';

  @override
  String get caseCracked => 'Case cracked!';

  @override
  String get youSolvedIt => 'You solved the case!';

  @override
  String get newBadge => 'New badge!';

  @override
  String get addToSash => 'Add to my sash';

  @override
  String get yourBadge => 'Your badge';

  @override
  String get next => 'Next';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get readyForNewCase => 'Ready for a new case?';

  @override
  String get backToProblem => 'Back to the problem';

  @override
  String get howCanIHelp => 'How can I help?';

  @override
  String get pickOne => 'Pick one.';

  @override
  String get aHint => 'A hint';

  @override
  String get showMeHow => 'Show me how';

  @override
  String get anEasierOne => 'Something easier';

  @override
  String get stillThere => 'Still there?';

  @override
  String get stillThinking => 'I\'m still thinking';

  @override
  String get askTotal => 'Both together?';

  @override
  String askB(String name) {
    return 'How tall is the $name?';
  }

  @override
  String get whatAsked => 'What does the question ask?';

  @override
  String get checkSumAgain => 'Check your sum again.';

  @override
  String get checkOnePart => 'Let\'s check one part.';

  @override
  String partRight(String name) {
    return '$name is right!';
  }

  @override
  String get nowCheckAdding => 'Now check your adding.';

  @override
  String get sideTakeAcrossTen => 'Take away across a ten';

  @override
  String get sideAddWithCarry => 'Adding with a carry';

  @override
  String get takeABreak => 'Take a break?';

  @override
  String get drawingSaved => 'Your drawing is saved.';

  @override
  String get goHome => 'Go home';

  @override
  String get timeUpTitle => 'That\'s today\'s time!';

  @override
  String get timeUpBody =>
      'Great detective work. Your case is saved for next time.';

  @override
  String get ok => 'OK';

  @override
  String get finishThisOne => 'Finish this one';

  @override
  String get lostInternet => 'Lost the internet. Your work is saved.';

  @override
  String get pairBrand => 'Auramath';

  @override
  String get pairWhosUsing => 'Hi! Who\'s using Auramath?';

  @override
  String get pairImAKid => 'I\'m a kid';

  @override
  String get pairImAGrownUp => 'I\'m a grown-up';

  @override
  String get pairHaveAccount => 'I already have an account';

  @override
  String get pairTypeCode => 'Type your code';

  @override
  String get pairCodeWhere => 'Your grown-up has it on their phone.';

  @override
  String get pairAskForNewCode =>
      'Ask your grown-up to make a new code on their phone.';

  @override
  String get pairChecking => 'Checking your code';

  @override
  String get pairOffline =>
      'Can\'t reach the internet. Check the Wi-Fi, then try again.';

  @override
  String pairFailed(String message) {
    return 'That didn\'t work: $message';
  }

  @override
  String get pairTryAgain => 'Try again';

  @override
  String get pairPhoneLabel => 'Child\'s phone';

  @override
  String get pairCodeWrong => 'That code didn\'t work';

  @override
  String get pairCodeWrongBody => 'Ask your grown-up for a new one.';

  @override
  String get pairTooMany => 'Too many tries';

  @override
  String get pairTooManyBody =>
      'Wait a few minutes, then ask your grown-up for a new code.';

  @override
  String get pairNewCode => 'Grown-up: new code';

  @override
  String get pairWhichChild => 'Which child is this phone for?';

  @override
  String get pairNoChildren =>
      'No children here yet. Ask your grown-up to add you on their phone.';

  @override
  String get pairIsThisYou => 'Is this you?';

  @override
  String get pairYesMe => 'Yes, that\'s me!';

  @override
  String get pairNo => 'No';

  @override
  String pairYoureIn(String name) {
    return 'You\'re in, $name!';
  }

  @override
  String get pairPhoneYours => 'This phone is yours for lessons now.';

  @override
  String get pairLetsGo => 'Let\'s go';

  @override
  String get pairRemoved => 'This phone was removed';

  @override
  String get pairRemovedBody =>
      'Your progress is safe. Ask your grown-up for a new code.';

  @override
  String get pairWhosLearning => 'Who\'s learning today?';

  @override
  String get pairGrownUps => 'Grown-ups';

  @override
  String get pairNoKidsYet => 'No children yet. Add one to start learning.';

  @override
  String get pairAddChild => 'Add a child';

  @override
  String get pairCarryOn => 'Carry on here?';

  @override
  String pairStartedOn(String device) {
    return 'You started this case on $device. It moved with you.';
  }

  @override
  String get pairStartedElsewhere =>
      'You started this case on another phone. It moved with you.';

  @override
  String get pairCarryOnHere => 'Carry on here';
}

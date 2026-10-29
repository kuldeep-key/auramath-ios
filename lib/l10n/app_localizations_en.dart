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
  String get setupYourChild => 'your child';

  @override
  String get setupContinue => 'Continue';

  @override
  String get setupTryAgain => 'Try again';

  @override
  String get setupWelcomeTitle => 'Personalised maths.\nTargeted growth.';

  @override
  String get setupWelcomeBody =>
      'Bar-model word problems for ages 5 to 10, read aloud and drawn by your child.';

  @override
  String get setupGetStarted => 'Get started';

  @override
  String get setupHaveAccount => 'I already have an account';

  @override
  String get setupNameTitle => 'Your child\'s first name';

  @override
  String get setupNameSubtitle => 'Only the first name. No surname.';

  @override
  String get setupNameLabel => 'First name';

  @override
  String setupAgeTitle(String name) {
    return 'How old is $name?';
  }

  @override
  String setupYearTitle(String name) {
    return 'Which school year is $name in?';
  }

  @override
  String setupYearUsual(int age) {
    return 'Usual for age $age';
  }

  @override
  String get setupKindergarten => 'Kindergarten';

  @override
  String setupYearN(int n) {
    return 'Year $n';
  }

  @override
  String setupStartTitle(String name) {
    return 'What can $name already do?';
  }

  @override
  String get setupStartSubtitle =>
      'Pick everything that feels easy. In school order.';

  @override
  String get setupCanCount100 => 'Counting to 100';

  @override
  String get setupCanAdd100 => 'Adding to 100';

  @override
  String get setupCanSub100 => 'Subtracting to 100';

  @override
  String get setupCanAdd1000 => 'Adding to 1000';

  @override
  String get setupCanSub1000 => 'Subtracting to 1000';

  @override
  String get setupCanWordProblems => 'Word problems with bars';

  @override
  String get setupNotSure => 'I\'m not sure';

  @override
  String get setupNotSureDetail => 'Help me figure it out';

  @override
  String get setupNotSureTitle => 'No problem';

  @override
  String setupNotSureBody(String name, String year) {
    return '$name starts at a typical $year level. The first sums find the real one, and we\'ll email you what we found.';
  }

  @override
  String setupNotSureBodyNoYear(String name) {
    return '$name starts at a level typical for their age. The first sums find the real one, and we\'ll email you what we found.';
  }

  @override
  String get setupQuickSums => 'Four quick sums first';

  @override
  String get setupQuickSumsDetail => 'Before any word problem.';

  @override
  String get setupEmailAfter => 'An email after the first session';

  @override
  String setupEmailAfterDetail(String name) {
    return 'Telling you where $name is.';
  }

  @override
  String get setupGoalTitle => 'What would help most?';

  @override
  String get setupGoalConfidence => 'Build confidence';

  @override
  String get setupGoalConfidenceDetail => 'Calm, positive practice';

  @override
  String get setupGoalCatchUp => 'Catch up';

  @override
  String get setupGoalCatchUpDetail => 'Fill gaps from school';

  @override
  String get setupGoalAhead => 'Get ahead';

  @override
  String get setupGoalAheadDetail => 'Stretch with harder cases';

  @override
  String get setupGoalWordProblems => 'Word problems';

  @override
  String get setupGoalWordProblemsDetail => 'Reading and drawing them';

  @override
  String setupDataTitle(String name) {
    return '$name\'s details stay safe';
  }

  @override
  String get setupDataStored => 'Stored in Australia';

  @override
  String get setupDataStoredDetail => 'On servers in Australia.';

  @override
  String get setupDataNoAi => 'Nothing personal goes to the AI';

  @override
  String get setupDataNoAiDetail =>
      'The tutor never sees a name or a birthday.';

  @override
  String get setupDataFirstName => 'Only a first name';

  @override
  String get setupDataFirstNameDetail =>
      'Your child never types personal details.';

  @override
  String get setupDataDelete => 'Delete it any time';

  @override
  String get setupDataDeleteDetail => 'From Settings, in one step.';

  @override
  String get setupAgree => 'I agree';

  @override
  String setupSaveTitle(String name) {
    return 'Save $name\'s place';
  }

  @override
  String get setupSaveSubtitle =>
      'One family account, so progress follows your child to any phone.';

  @override
  String setupSaving(String name) {
    return 'Saving $name\'s place…';
  }

  @override
  String get setupContinueApple => 'Continue with Apple';

  @override
  String get setupContinueGoogle => 'Continue with Google';

  @override
  String get setupUseEmail => 'Use my email';

  @override
  String get setupEmailLabel => 'Email address';

  @override
  String get setupEmailMeLink => 'Email me a link';

  @override
  String get setupEmailInvalid => 'Type the email address to send the link to.';

  @override
  String get setupAppleOff =>
      'Apple sign-in isn\'t switched on for this server yet.';

  @override
  String get setupEmailOff => 'This server can\'t send email yet.';

  @override
  String get setupSignInTitle => 'Welcome back';

  @override
  String get setupSignInSubtitle => 'Sign in to your family account.';

  @override
  String get setupCheckTitle => 'Check your email';

  @override
  String get setupCheckBody => 'Tap the link we sent to sign in on this phone.';

  @override
  String get setupTappedLink => 'I tapped the link';

  @override
  String get setupLinkNotYet =>
      'The link hasn\'t opened on this phone yet. Open the email on this phone and tap the link.';

  @override
  String get setupDevLink => 'Open the link (dev only)';

  @override
  String get setupVerifying => 'Signing you in…';

  @override
  String get setupLinkMissing =>
      'This link has no sign-in code in it. Ask for a new one.';

  @override
  String get setupBackToSignIn => 'Back to sign in';

  @override
  String get setupReadyTitle => 'All set!';

  @override
  String setupReadyBody(String name) {
    return '$name starts with a short warm-up, then a story case.';
  }

  @override
  String setupHandOver(String name) {
    return 'Hand over to $name';
  }

  @override
  String setupOwnPhone(String name) {
    return '$name has their own phone';
  }

  @override
  String get setupLockTitle => 'Lock the grown-up area';

  @override
  String get setupLockBody =>
      'So only you can change settings or see the book.';

  @override
  String get setupUseFaceId => 'Use Face ID';

  @override
  String get setupUsePasscode => 'Use a passcode';

  @override
  String get setupFaceIdFailed =>
      'Face ID didn\'t work. You can use a passcode instead.';

  @override
  String get setupFaceIdMissing =>
      'Face ID isn\'t set up on this phone. Use a passcode instead.';

  @override
  String get setupPassTitle => 'Choose a passcode';

  @override
  String setupPassBody(int n) {
    return '$n digits, so only grown-ups can open the grown-up area.';
  }

  @override
  String get setupPassAgainTitle => 'Type it again';

  @override
  String setupPassAgainBody(int n) {
    return 'The same $n digits, to be sure.';
  }

  @override
  String get setupPassMismatch =>
      'Those didn\'t match. Choose a passcode again.';

  @override
  String setupPassShort(int n) {
    return 'The passcode is $n digits.';
  }

  @override
  String get setupPassAlreadySet => 'Your family has a passcode';

  @override
  String get setupPassAlreadySetBody =>
      'It was set on another phone. Use it to open the grown-up area here too.';

  @override
  String setupJoinTitle(String name) {
    return 'Join $name\'s phone';
  }

  @override
  String setupJoinBody(String name) {
    return 'On $name\'s phone, open Auramath, tap I\'m a kid and type this code.';
  }

  @override
  String setupWorksOnce(String time) {
    return 'Works once, for $time';
  }

  @override
  String get setupCodeExpired => 'This code has run out. Show a new code.';

  @override
  String setupProgressFollows(String name) {
    return 'Progress follows $name';
  }

  @override
  String get setupProgressFollowsDetail =>
      'Lessons carry on from any phone in the family.';

  @override
  String get setupNewCode => 'Show a new code';
}

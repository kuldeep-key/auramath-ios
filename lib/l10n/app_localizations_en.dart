// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gotItLetsDraw => 'Let\'s draw it';

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
  String get tooHardTitle => 'This one\'s tricky. Want a hand?';

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
  String get takeABreak => 'Take a break?';

  @override
  String exampleFacts(int a, int d, String relation) {
    return 'Building A is $a m. B is $d m $relation.';
  }

  @override
  String exampleA(int a) {
    return 'Building A is $a metres tall.';
  }

  @override
  String exampleB(int d, String relation) {
    return 'Building B is $d metres $relation.';
  }

  @override
  String exampleTake(int a, int d, int b) {
    return '$a take away $d is $b.';
  }

  @override
  String exampleAdd(int a, int d, int b) {
    return '$a add $d is $b.';
  }

  @override
  String exampleTogether(int a, int b, int total) {
    return 'Together: $a + $b = $total metres.';
  }

  @override
  String get exampleShorter => 'shorter';

  @override
  String get exampleTaller => 'taller';

  @override
  String get exampleAgain => 'Again';

  @override
  String get exampleNowYouTry => 'Now you try';

  @override
  String get lessonHundreds => 'Hundreds';

  @override
  String get lessonTens => 'Tens';

  @override
  String get lessonOnes => 'Ones';

  @override
  String lessonNotEnoughOnes(int take, int have) {
    return 'Take $take ones from $have? Not enough!';
  }

  @override
  String lessonNotEnoughTens(int take, int have) {
    return 'Take $take tens from $have? Not enough!';
  }

  @override
  String get lessonTapATen => 'Tap a ten to break it.';

  @override
  String get lessonTapAHundred => 'Tap a hundred to break it.';

  @override
  String lessonTakeOnes(int n) {
    return 'Take away $n ones.';
  }

  @override
  String lessonTakeTens(int n) {
    return 'Take away $n tens.';
  }

  @override
  String lessonTakeHundreds(int n) {
    return 'Take away $n hundreds.';
  }

  @override
  String lessonAddOnes(int n) {
    return 'Add $n ones.';
  }

  @override
  String lessonAddTens(int n) {
    return 'Add $n tens.';
  }

  @override
  String lessonAddHundreds(int n) {
    return 'Add $n hundreds.';
  }

  @override
  String lessonMakeATen(int n) {
    return '$n ones! Tap the ones to make a ten.';
  }

  @override
  String lessonMakeAHundred(int n) {
    return '$n tens! Tap the tens to make a hundred.';
  }

  @override
  String get lessonDoIt => 'Do it';

  @override
  String lessonSideDone(String sum, int answer) {
    return '$sum = $answer. You did it!';
  }

  @override
  String sideTypeIt(String sum) {
    return 'So what is $sum? Type it in.';
  }

  @override
  String sidePractice(String sum) {
    return 'Let\'s try one like it: $sum';
  }

  @override
  String get sidePracticeDone => 'Nice practice! Now back to the case.';

  @override
  String get sideKindEnd =>
      'These are tricky. We\'ll practise them again soon. Back to the case!';

  @override
  String sideAnswerIs(String sum, int answer) {
    return '$sum = $answer. Now back to the case.';
  }

  @override
  String get lessonWarmUpStart => 'Let\'s warm up with a few sums. No rush!';

  @override
  String get lessonWarmUpNext => 'Here\'s another sum.';

  @override
  String get lessonWarmUpBlank => 'what';

  @override
  String get lessonLostInternetBody =>
      'We\'ll carry on from here when it\'s back.';

  @override
  String get lessonTryAgain => 'Try again';

  @override
  String get lessonNeedInternet => 'We need the internet to start';

  @override
  String get lessonNeedInternetBody => 'Check the Wi-Fi, then try again.';

  @override
  String get lessonNoChildTitle => 'Ask your family';

  @override
  String get lessonNoChildBody =>
      'Someone in your family needs to add you before your first case.';

  @override
  String get lessonPausedTitle => 'Ask your family';

  @override
  String get lessonPausedBody =>
      'Lessons are paused for now. Someone in your family can turn them back on.';

  @override
  String get drawingSaved => 'Your drawing is saved.';

  @override
  String get goHome => 'Go home';

  @override
  String get leaveThisOne => 'Try a different case';

  @override
  String get leftWaitingTitle => 'A case is waiting';

  @override
  String leftWaitingBody(String item) {
    return 'Last time you left the $item case. Want to try it again?';
  }

  @override
  String get leftTryAgain => 'Try it again';

  @override
  String get leftSomethingNew => 'Something new';

  @override
  String get timeUpTitle => 'That\'s today\'s time!';

  @override
  String get timeUpBody =>
      'Great detective work. Your case is saved for next time.';

  @override
  String get keptTitle => 'Saved for next time';

  @override
  String get keptBody =>
      'We were away a while, so this case is kept for next time.';

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
  String get pairImAGrownUp => 'I\'m a parent or carer';

  @override
  String get pairHaveAccount => 'I already have an account';

  @override
  String get pairTypeCode => 'Type your code';

  @override
  String get pairCodeWhere => 'Your family has it on their phone.';

  @override
  String get pairAskForNewCode =>
      'Ask your family to make a new code on their phone.';

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
  String get pairCodeWrongBody => 'Ask your family for a new one.';

  @override
  String get pairCodeDidntWork => 'That code didn\'t work.';

  @override
  String get pairTooMany => 'Let\'s get a new code';

  @override
  String get pairTooManyBody =>
      'That code has stopped working. Wait a few minutes, then ask your family for a new one.';

  @override
  String get pairNewCode => 'Family: new code';

  @override
  String get pairWhichChild => 'Which child is this phone for?';

  @override
  String get pairNoChildren =>
      'No children here yet. Ask your family to add you on their phone.';

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
      'Your family took this phone off. Your cases are safe. Ask for a new code to join again.';

  @override
  String get pairWhosLearning => 'Who\'s learning today?';

  @override
  String get pairGrownUps => 'Family area';

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

  @override
  String get guYourChild => 'your child';

  @override
  String get guTryAgain => 'Try again';

  @override
  String get guLoading => 'Loading';

  @override
  String get guCancel => 'Cancel';

  @override
  String get guDone => 'Done';

  @override
  String get guOn => 'On';

  @override
  String get guOff => 'Off';

  @override
  String get guPassTitle => 'Family area';

  @override
  String get guPassEnter => 'Enter your passcode.';

  @override
  String get guPassForgot => 'Forgot passcode?';

  @override
  String get guPassWrong => 'That is not it. Try again.';

  @override
  String guPassLocked(String time) {
    return 'Too many tries. Wait until $time, or sign in again.';
  }

  @override
  String get guPassLockedSoon =>
      'Too many tries. Wait a little, or sign in again.';

  @override
  String get guPassChooseTitle => 'Lock the Family area';

  @override
  String get guPassNewTitle => 'Set a new passcode';

  @override
  String guPassChooseBody(int n) {
    return '$n digits only you know.';
  }

  @override
  String get guPassConfirmTitle => 'Lock the Family area';

  @override
  String get guPassConfirmBody => 'Type it once more to be sure.';

  @override
  String get guPassMismatch => 'Those did not match. Start again.';

  @override
  String guPassShort(int n) {
    return 'Type all $n digits.';
  }

  @override
  String get guPassResetBlocked =>
      'It has been more than 10 minutes since you signed in. Sign in again, then choose a new passcode.';

  @override
  String get guFaceIdReason => 'Open the Family area';

  @override
  String get guUseFaceId => 'Use Face ID';

  @override
  String get guFaceFail => 'Face ID did not work. Use your passcode instead.';

  @override
  String get guForgotTitle => 'Forgot your passcode?';

  @override
  String guForgotBody(String email) {
    return 'Sign in again and set a new one. We will email a link to $email.';
  }

  @override
  String get guForgotSend => 'Email me a sign-in link';

  @override
  String get guForgotSentTitle => 'Check your email';

  @override
  String guForgotSentBody(String email) {
    return 'We sent a sign-in link to $email. Open it on this phone, then come back to choose a new passcode.';
  }

  @override
  String get guForgotResend => 'Send it again';

  @override
  String get guForgotNoEmail =>
      'This account has no email address to send a link to.';

  @override
  String get guForgotOr =>
      'Or sign in again here with Apple or Google, then choose a new passcode.';

  @override
  String get guHomeHi => 'Family area';

  @override
  String get guHomeChildren => 'Children';

  @override
  String get guHomeThisFamily => 'This family';

  @override
  String get guHomeAddChildDetail => 'Their own details and consent';

  @override
  String get guHomeSettingsDetail => 'Time per day, read-aloud, emails';

  @override
  String get guHomePhones => 'Phones and family';

  @override
  String get guHomePhonesDetail => 'Join, remove, invite';

  @override
  String get guHomeRightsDetail => 'Download or delete everything';

  @override
  String get guHomeSignOut => 'Sign out of this phone';

  @override
  String get guHomeNotesDetail => 'What each session\'s email said';

  @override
  String guHomeAbout(int age, String year) {
    return '$age, $year';
  }

  @override
  String guHomeAge(int age) {
    return '$age';
  }

  @override
  String guHomeWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions this week',
      one: '1 session this week',
      zero: 'No sessions this week',
    );
    return '$_temp0';
  }

  @override
  String get guProgressError => 'Couldn\'t load progress';

  @override
  String get guHomeFamily => 'Family';

  @override
  String guHomeBackTo(String name) {
    return 'Back to $name';
  }

  @override
  String get guHomeNoChildren => 'No children yet';

  @override
  String get guHomeNoChildrenBody => 'Add a child to start their first lesson.';

  @override
  String get guHomePaused => 'Lessons are paused';

  @override
  String get guHomePausedBody =>
      'Lessons can\'t start until a parent or carer agrees again to how we keep their learning. You can do that in Your data and rights.';

  @override
  String get guHomePausedLink => 'Your data and rights';

  @override
  String get guAddChild => 'Add a child';

  @override
  String get guSettingsTitle => 'Settings';

  @override
  String get guSetTime => 'Time each day';

  @override
  String guSetMinutes(int n) {
    return '$n min';
  }

  @override
  String get guSetReadAloud => 'Read aloud';

  @override
  String get guSetReadAloudDetail =>
      'The teacher\'s voice. Off until you turn it on';

  @override
  String get guSetTimeSheetBody =>
      'The app ends the session kindly at this point.';

  @override
  String guSetMinutesLong(int n) {
    return '$n minutes';
  }

  @override
  String get guSaved => 'Saved';

  @override
  String get guSetBigPad => 'Bigger number pad';

  @override
  String get guSetBigPadDetail => 'Accessibility: the lesson\'s keys grow';

  @override
  String get guSetChangeHint => 'Changes the setting';

  @override
  String get guFamilyAndPhones => 'Family and phones';

  @override
  String guChildPlan(String name) {
    return '$name\'s plan';
  }

  @override
  String get guEmailRow => 'Report email';

  @override
  String get guEmailUnknown => 'Not set';

  @override
  String get guEmailUnsubscribeNote =>
      'Every email also has a link to stop them.';

  @override
  String get guEmailHowOften => 'How often';

  @override
  String get guEmailHowOftenTitle => 'How often should we email?';

  @override
  String get guEmailEach => 'After each session';

  @override
  String get guEmailEachDetail => 'One short note when a session ends';

  @override
  String get guEmailWeekly => 'Once a week';

  @override
  String get guEmailWeeklyDetail => 'One note on Monday about the week before';

  @override
  String get guEmailOff => 'Off';

  @override
  String get guEmailOffDetail => 'No emails about lessons';

  @override
  String get guRightsLink => 'Your data and rights';

  @override
  String get guSignOut => 'Sign out';

  @override
  String get guFamilyTitle => 'Phones and family';

  @override
  String get guGrownUps => 'Family members';

  @override
  String get guChildren => 'Children';

  @override
  String get guPhones => 'Phones';

  @override
  String guYou(String email) {
    return '$email (you)';
  }

  @override
  String get guOwner => 'Owner';

  @override
  String get guGrownUp => 'Family member';

  @override
  String get guInvited => 'Invited';

  @override
  String get guRemove => 'Remove';

  @override
  String guRemovePhoneLabel(String label) {
    return 'Remove $label';
  }

  @override
  String get guNoPhones => 'No phones joined yet';

  @override
  String get guNoChildrenRow => 'No children yet';

  @override
  String guInvitedEmail(String email) {
    return '$email (invited)';
  }

  @override
  String get guCancelInviteLink => 'Cancel';

  @override
  String guCancelInviteLabel(String email) {
    return 'Cancel the invite to $email';
  }

  @override
  String guRemoveGrownUpLabel(String email) {
    return 'Remove $email';
  }

  @override
  String get guSignedIn => 'Signed in';

  @override
  String get guNoBrowsers => 'Not signed in anywhere else';

  @override
  String get guThisPhone => 'This phone';

  @override
  String get guBrowserUnnamed => 'A browser';

  @override
  String get guSignOutBrowserLink => 'Sign out';

  @override
  String guSignOutBrowserLabel(String label) {
    return 'Sign out $label';
  }

  @override
  String get guOpenChildHint => 'Shows where they are';

  @override
  String get guInviteGrownUp => 'Invite a family member';

  @override
  String get guAddPhone => 'Join a child\'s phone';

  @override
  String get guInviteTitle => 'Invite a family member';

  @override
  String get guInviteBody =>
      'They can see the notes and change settings. They set their own passcode.';

  @override
  String get guInviteEmail => 'Their email';

  @override
  String get guInviteSend => 'Send invite';

  @override
  String get guInviteBadEmail => 'That doesn\'t look like an email address.';

  @override
  String get guInviteSentTitle => 'Invite sent';

  @override
  String guInviteSentBody(String email) {
    return '$email has an email with a link. It works for 7 days. You will see them here once they join.';
  }

  @override
  String get guInviteSentDone => 'Done';

  @override
  String get guCodeTitle => 'Here is a code';

  @override
  String get guCodeNewTitle => 'Here is a new code';

  @override
  String get guCodeNewBody => 'The old one stopped working.';

  @override
  String guCodeLeft(String time) {
    return 'Works once, for $time. Five tries.';
  }

  @override
  String get guCodeExpired =>
      'That code has expired. Codes last 10 minutes. Show a new one when you are both ready.';

  @override
  String get guCodeAgain => 'Show a new code';

  @override
  String guCodeTypeOn(String name) {
    return 'Type it on $name\'s phone';
  }

  @override
  String get guCodeTypeOnChild => 'Type it on your child\'s phone';

  @override
  String guRemoveTitle(String label) {
    return 'Remove $label?';
  }

  @override
  String get guRemoveBody =>
      'It signs out straight away and keeps nothing. Progress stays safe in the family account.';

  @override
  String get guRemoveButton => 'Remove phone';

  @override
  String get guRemoveGone => 'That phone isn\'t in your family any more.';

  @override
  String get guRemovedTitle => 'Phone removed';

  @override
  String get guRemovedBody =>
      'That phone is signed out. On it, your child sees \"This phone was removed\". Join a new phone with a code any time.';

  @override
  String guRemoveGrownUpTitle(String email) {
    return 'Remove $email?';
  }

  @override
  String get guRemoveGrownUpBody =>
      'They\'re signed out straight away and can\'t open the family account any more. You can invite them again later.';

  @override
  String get guRemoveGrownUpButton => 'Remove them';

  @override
  String get guRemoveGrownUpGone => 'They aren\'t in your family any more.';

  @override
  String guCancelInviteTitle(String email) {
    return 'Cancel the invite to $email?';
  }

  @override
  String get guCancelInviteBody =>
      'The link we emailed them stops working. You can send a new invite any time.';

  @override
  String get guCancelInviteButton => 'Cancel the invite';

  @override
  String get guKeepInvite => 'Keep it';

  @override
  String get guCancelInviteGone => 'That invite isn\'t waiting any more.';

  @override
  String guSignOutBrowserTitle(String label) {
    return 'Sign out $label?';
  }

  @override
  String get guSignOutBrowserBody =>
      'It\'s signed out straight away. Anyone using it would need to sign in again.';

  @override
  String get guSignOutBrowserButton => 'Sign it out';

  @override
  String get guBrowserGone => 'That browser is already signed out.';

  @override
  String get guAddChildTitle => 'Add a child';

  @override
  String get guAddChildBody =>
      'You agree for them, as their parent or guardian. Only a first name.';

  @override
  String get guAddChildName => 'First name';

  @override
  String get guAddChildNameNeeded => 'Type a first name.';

  @override
  String get guAddChildYear => 'School year (optional)';

  @override
  String get guAddChildYearHint => 'For example, Year 2';

  @override
  String get guAddChildYearUnknown =>
      'Type Kindergarten or a year from 1 to 5.';

  @override
  String get guAddChildAgree => 'Continue';

  @override
  String get guAddChildConsent =>
      'I am this child\'s parent or guardian. I agree to the same terms for them.';

  @override
  String get guRightsTitle => 'Your data and rights';

  @override
  String get guRightsBody =>
      'Everything we hold is stored in Australia and belongs to your family.';

  @override
  String get guStoredTitle => 'What we keep';

  @override
  String get guStored1 => 'Your email, and other family members\' emails';

  @override
  String get guStored2 =>
      'Each child\'s first name, and their age, school year and goal if you gave them';

  @override
  String get guStored3 => 'Every step of every lesson';

  @override
  String get guStored4 => 'The names of joined phones';

  @override
  String get guDownload => 'Download everything';

  @override
  String get guDownloadBody =>
      'A file with every child\'s data, ready within a day';

  @override
  String get guExportPending => 'Getting it ready…';

  @override
  String get guExportReady => 'Ready. Tap to save it on this phone.';

  @override
  String guExportSaved(String file) {
    return 'Saved on this phone as $file';
  }

  @override
  String get guExportFailed => 'The export failed. Tap to try again.';

  @override
  String get guExportExpired =>
      'That export has expired. Tap to start another.';

  @override
  String get guDeleteAccount => 'Delete the family account';

  @override
  String get guDeleteAccountBody => 'Everyone, everything, straight away';

  @override
  String get guDeleteTitle => 'Delete the family account?';

  @override
  String get guDeleteBody => 'This cannot be undone.';

  @override
  String get guDeleteChildren => 'Every child';

  @override
  String get guDeleteChildrenBody => 'Their details, cases and badges';

  @override
  String get guDeleteSessions => 'Every session and tap';

  @override
  String get guDeleteSessionsBody => 'The whole learning record';

  @override
  String get guDeleteNotes => 'Every note and email';

  @override
  String get guDeleteNotesBody => 'We keep nothing to send';

  @override
  String get guDeletePhones => 'Every phone and family member';

  @override
  String get guDeletePhonesBody => 'All signed out, now';

  @override
  String get guDeleteNow =>
      'It happens straight away, not in 30 days. If you want a copy first, download everything before you delete.';

  @override
  String get guDeleteDownloadFirst => 'Download everything first';

  @override
  String get guDeleteButton => 'Delete everything';

  @override
  String get guDeleteConfirmTitle => 'Type DELETE to confirm';

  @override
  String get guDeleteConfirmBody =>
      'One last check that it is you, and that you mean it.';

  @override
  String get guDeleteConfirmLabel => 'Type DELETE';

  @override
  String get guDeleteConfirmWord => 'DELETE';

  @override
  String get guDeleteConfirmButton => 'Delete the family account';

  @override
  String get guDeleteKeep => 'Keep my account';

  @override
  String get guDeletedTitle => 'Deleted';

  @override
  String get guDeletedBody =>
      'Your family account is gone and every phone is signed out. Thank you for trying Auramath.';

  @override
  String get guClose => 'Close';

  @override
  String get guConsentLink => 'Withdraw your consent';

  @override
  String get guConsentLinkBody => 'Lessons stop until you agree again';

  @override
  String get guConsentWithdrawn => 'You\'ve withdrawn your consent';

  @override
  String get guConsentWithdrawnBody =>
      'Lessons are paused and no child can be added. What we keep stays until you delete it.';

  @override
  String get guConsentAgainLink => 'Agree again';

  @override
  String get guConsentAgainLinkBody => 'Lessons can start again straight away';

  @override
  String get guConsentError => 'Couldn\'t check your consent';

  @override
  String get guWithdrawTitle => 'Withdraw your consent?';

  @override
  String get guWithdrawBody =>
      'Lessons stop straight away on every phone, and no child can be added. Nothing is deleted: what we keep stays until you delete it here. You can agree again any time.';

  @override
  String get guWithdrawButton => 'Withdraw consent';

  @override
  String get guAgainTitle => 'Agree again?';

  @override
  String get guAgainBody =>
      'You agree, as their parent or carer, that we keep each child\'s first name and every step of their lessons, so lessons can carry on. You can withdraw again or delete everything any time.';

  @override
  String get guAgainButton => 'I agree';

  @override
  String get guNotifyTitle => 'An email after each session';

  @override
  String get guNotifyBody =>
      'A short note: what was practised, how much help was needed, something to try tonight.';

  @override
  String get guNotifyCard => 'Sent to your email';

  @override
  String guNotifyCardBody(String name) {
    return 'Within a few minutes of $name finishing.';
  }

  @override
  String get guNotifyYes => 'Continue';

  @override
  String get guNotifyNo => 'Not now';

  @override
  String get guNotifyCheck => 'Email me after each session';

  @override
  String get guSignOutTitle => 'Sign out of this phone?';

  @override
  String get guSignOutBody =>
      'Nothing about your children stays on this phone. Sign in again any time with Apple, Google or an email link.';

  @override
  String get guSignedOut => 'Signed out';

  @override
  String guBookTitle(String name) {
    return '$name\'s book';
  }

  @override
  String get guTabWeek => 'This week';

  @override
  String get guTabSkills => 'Skills';

  @override
  String get guTabBadges => 'Badges';

  @override
  String guSessionTitle(String day, int n) {
    return '$day · $n min';
  }

  @override
  String guSessionUnfinished(String day) {
    return '$day · not finished';
  }

  @override
  String get guNoNote => 'No note for this session.';

  @override
  String get guNotesLink => 'Recent notes';

  @override
  String guNotesTitle(String name) {
    return '$name\'s notes';
  }

  @override
  String get guNotesBody =>
      'What each session email said. Nothing is scored or graded.';

  @override
  String get guNotesEmpty => 'No notes yet';

  @override
  String guNotesEmptyBody(String name) {
    return 'The first one arrives a few minutes after $name\'s first session.';
  }

  @override
  String guNotesNone(String name) {
    return 'No notes yet. One comes after each of $name\'s sessions.';
  }

  @override
  String get guNoteError => 'Couldn\'t load the note.';

  @override
  String get guNothingSaved => 'Nothing saved yet';

  @override
  String guNothingThisWeek(String name) {
    return '$name\'s sessions this week show here.';
  }

  @override
  String get guSkillsEmpty =>
      'Each skill\'s progress will show here. It isn\'t ready yet.';

  @override
  String guBadgesEmpty(String name) {
    return 'Badges show on $name\'s own screens.';
  }

  @override
  String get guMonthView => 'Month view';

  @override
  String get guMonthViewBody => 'This month';

  @override
  String get guSimpleReport => 'See the simple report';

  @override
  String get guWhatsNext => 'What\'s next in the plan';

  @override
  String guPlanBody(String name) {
    return 'What comes next, from $name\'s latest lessons.';
  }

  @override
  String get guPlanNext => 'Next';

  @override
  String get guPlanCheck => 'A quick check';

  @override
  String get guPlanCheckNow => 'Due now';

  @override
  String guPlanCheckOn(String date) {
    return 'Due $date';
  }

  @override
  String guPlanAway(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days since the last lesson',
      one: '1 day since the last lesson',
    );
    return '$_temp0';
  }

  @override
  String get guPlanEmpty => 'Nothing planned yet';

  @override
  String guPlanEmptyBody(String name) {
    return 'The plan fills in after $name\'s first lesson.';
  }

  @override
  String guLearningTitle(String name) {
    return 'Where $name is';
  }

  @override
  String guLearningBody(String name) {
    return 'What $name is working on, and how their level has changed.';
  }

  @override
  String get guLearningEmpty => 'Nothing yet';

  @override
  String guLearningEmptyBody(String name) {
    return 'This fills in after $name\'s first lesson.';
  }

  @override
  String get guLearningComparison => 'Comparing amounts';

  @override
  String get guLearningOther => 'Their lessons';

  @override
  String guLearningLevel(String level) {
    return 'Level $level';
  }

  @override
  String get guLearningNow => 'Working at this level now';

  @override
  String get guLearningHistory => 'How it changed';

  @override
  String get guLearningNoChanges => 'Still at the level they started on.';

  @override
  String guLearningMovedUp(String level) {
    return 'Moved up to level $level';
  }

  @override
  String get guLearningWentBack => 'Went back a level to build confidence';

  @override
  String guLearningChanged(String level) {
    return 'Changed to level $level';
  }

  @override
  String guLearningEdit(String name) {
    return 'Change $name\'s details';
  }

  @override
  String get guLearningEditBody => 'Name, age and school year';

  @override
  String guChildDoing(String name) {
    return 'How $name is doing';
  }

  @override
  String get guChildWorkingOn => 'Working on';

  @override
  String get guChildNow => 'Now';

  @override
  String guChildJourney(String name) {
    return '$name\'s journey';
  }

  @override
  String get guChildDetails => 'Details';

  @override
  String get guChildFirstName => 'First name';

  @override
  String get guChildAge => 'Age';

  @override
  String get guChildYear => 'School year';

  @override
  String get guChildNotSet => 'Not set';

  @override
  String guChildPicture(String name) {
    return 'Change $name\'s picture';
  }

  @override
  String get guLearningMovedUpPlain => 'Moved up a level';

  @override
  String get guLearningChangedPlain => 'Moved to a new level';

  @override
  String guEditTitle(String name) {
    return '$name\'s details';
  }

  @override
  String get guEditBody =>
      'Change what you told us. Lessons follow from the next one.';

  @override
  String get guEditName => 'First name';

  @override
  String get guEditNameNeeded => 'Type a first name.';

  @override
  String get guEditNameLong => 'Keep it to 40 letters or fewer.';

  @override
  String get guEditAge => 'Age';

  @override
  String get guEditYear => 'School year';

  @override
  String get guEditAvatar => 'Detective';

  @override
  String guEditAvatarHint(String name) {
    return 'Let $name pick one.';
  }

  @override
  String get guEditSave => 'Save';

  @override
  String get guReportTitle => 'Simple report';

  @override
  String get guReportBody => 'The short version for a quick look.';

  @override
  String get guReportSessions => 'Sessions this week';

  @override
  String get guReportTime => 'Time this week';

  @override
  String get guReportNext => 'Next';

  @override
  String get guReportNextNone => 'After the first lesson';

  @override
  String guMonthTitle(String name, String month) {
    return '$name in $month';
  }

  @override
  String guMonthBody(String month) {
    return 'From 1 $month to today.';
  }

  @override
  String get guMonthSessions => 'Sessions this month';

  @override
  String get guMonthTime => 'Time this month';

  @override
  String guMonthChartLater(String name) {
    return 'A chart of $name\'s skill steps will show here once the server reports them.';
  }

  @override
  String get kidMyTrail => 'My trail';

  @override
  String get kidMyBadges => 'My badges';

  @override
  String get kidForGrownUps => 'Family area';

  @override
  String get kidHome => 'Home';

  @override
  String kidWelcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get kidWelcomeBackNoName => 'Welcome back!';

  @override
  String get kidCaseWaiting => 'Your case is waiting.';

  @override
  String get kidLetsSee => 'Let\'s see';

  @override
  String get kidSoundOff => 'Your sound is off';

  @override
  String get kidSoundOffBody => 'Turn it up to hear me. Or read along.';

  @override
  String get kidSoundOn => 'Sound is on now';

  @override
  String get kidIllRead => 'I\'ll read';

  @override
  String get kidVoiceResting => 'My voice is resting';

  @override
  String get kidVoiceRestingBody => 'Today I\'ll show the words big instead.';

  @override
  String get kidOkLetsGo => 'OK, let\'s go';

  @override
  String get kidNextToEarn => 'Next to earn';

  @override
  String get kidSessionBadgeEarned => 'Your badge for this session';

  @override
  String get kidStreakMoment =>
      'Back on the case again! Detectives keep at it.';

  @override
  String get kidSessionBadgeFinished => 'Case cracked';

  @override
  String get kidSessionBadgeTimeUp => 'Detective at work';

  @override
  String get kidSessionBadgeLeft => 'Tried a tricky case';

  @override
  String get kidSessionBadgePaused => 'Good start on a case';

  @override
  String get kidNoBadgesYet => 'Crack a case to earn your first badge!';

  @override
  String get kidBackToBadges => 'Back to my badges';

  @override
  String get kidDone => 'Done';

  @override
  String get kidYouAreHere => 'You are here';

  @override
  String get kidNextStop => 'Next stop';

  @override
  String get kidStopAddBig => 'Adding to 1000';

  @override
  String get kidStopTakeAwayBig => 'Taking away to 1000';

  @override
  String get kidStopTrees => 'Tree cases';

  @override
  String get kidStopTrickyWords => 'Tricky word cases';

  @override
  String get kidStopTotalAndDifference => 'Burger cases';

  @override
  String get kidReachedTop => 'You reached the top!';

  @override
  String get kidNewTrailSoon =>
      'A new trail opens soon. Keep your detective skills sharp!';

  @override
  String get kidQuickCheck => 'A quick check!';

  @override
  String get kidQuickCheckBody =>
      'A warm-up game with sums you know. No score.';

  @override
  String get kidLetsPlay => 'Let\'s play';

  @override
  String get kidTrickierOne => 'Ready for a trickier one?';

  @override
  String get kidTreeWordProblem => 'Tree Word Problem';

  @override
  String get kidWordProblem => 'Word Problem';

  @override
  String get kidSameTreesWatchWords => 'Same trees. Watch the words!';

  @override
  String get kidLetsGo => 'Let\'s go';

  @override
  String get kidDoneForToday => 'Done for today';

  @override
  String get kidOnARoll => 'On a roll!';

  @override
  String get kidCaseAfterCase => 'Case after case. Detective work!';

  @override
  String get kidTryNewSkill => 'Try a new skill';

  @override
  String kidNewStopOpened(String stop) {
    return 'A new stop opened on your trail: $stop.';
  }

  @override
  String get kidSeeMyTrail => 'See my trail';

  @override
  String get kidMySash => 'My sash';

  @override
  String get kidInYourSash => 'It\'s in your sash. Your family sees it too.';

  @override
  String get kidNextCase => 'Next case';

  @override
  String get kidTryAgain => 'Try again';

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
      'Bar-model word problems for ages 6 to 10, read aloud and drawn by your child. Made with Julia Fong\'s method.';

  @override
  String get setupGetStarted => 'Get started';

  @override
  String get setupHaveAccount => 'I already have an account';

  @override
  String get setupNameTitle => 'Your child\'s first name';

  @override
  String get setupNameSubtitle => 'Only the first name. No surname.';

  @override
  String get setupNameNote =>
      'We use it to say hello. It never goes to the AI.';

  @override
  String get setupNameLabel => 'First name';

  @override
  String get setupAgeRange => 'Auramath is for ages 6 to 10 for now.';

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
    return 'What is $name confident in?';
  }

  @override
  String get setupStartSubtitle =>
      'Select all likely areas your child is confident in. In school order.';

  @override
  String get setupCanCount100 => 'Counting to 100';

  @override
  String get setupCanAdd100 => 'Adding to 100';

  @override
  String get setupCanSub100 => 'Taking away to 100';

  @override
  String get setupCanAdd1000 => 'Adding to 1000';

  @override
  String get setupCanSub1000 => 'Taking away to 1000';

  @override
  String get setupCanWordProblems => 'Word problems with bars';

  @override
  String get setupNotSure => 'I\'m not sure';

  @override
  String get setupNotSureDetail => 'Help me figure it out';

  @override
  String setupNotSureFromAge(String name) {
    return 'We\'ll start from $name\'s age and find out';
  }

  @override
  String get setupNotSureTitle => 'No problem';

  @override
  String setupNotSureBody(String name, int age) {
    return '$name starts where most $age-year-olds do. A few quick sums find the real starting point. We email you what we found after the first session.';
  }

  @override
  String setupNotSureBodyNoYear(String name) {
    return '$name starts where most children their age do. A few quick sums find the real starting point. We email you what we found after the first session.';
  }

  @override
  String get setupQuickSums => 'Four quick sums first';

  @override
  String get setupQuickSumsDetail => 'Before any word problem.';

  @override
  String get setupEmailAfter => 'An email after the first session';

  @override
  String setupEmailAfterDetail(String name) {
    return 'Telling you where $name is, in plain words.';
  }

  @override
  String get setupGoalTitle => 'What would help most?';

  @override
  String get setupGoalSubtitle => 'Pick the one that fits best.';

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
  String get setupGoalSchool => 'Do well in the school curriculum';

  @override
  String get setupGoalSchoolDetail => 'Keep pace with the NSW syllabus';

  @override
  String get setupGoalNotSure => 'Not sure yet';

  @override
  String get setupGoalNotSureDetail => 'That is fine too';

  @override
  String setupDataTitle(String name) {
    return 'What we hold about $name';
  }

  @override
  String get setupDataSubtitle => 'And who sees it.';

  @override
  String get setupDataStored => 'Stored in Australia';

  @override
  String get setupDataStoredDetail => 'On servers in Australia.';

  @override
  String get setupDataTaps => 'Every tap in a lesson';

  @override
  String get setupDataTapsDetail =>
      'So the tutor can see how the sum went. Never typed words.';

  @override
  String get setupDataNoAi => 'Nothing personal goes to the AI';

  @override
  String get setupDataNoAiDetail =>
      'The tutor never sees a name or a birthday.';

  @override
  String get setupDataFirstName => 'First name, age, school year';

  @override
  String get setupDataFirstNameDetail =>
      'And what was practised. No gender, no birthday.';

  @override
  String get setupDataHelpers => 'Who helps us';

  @override
  String get setupDataHelpersDetail =>
      'Google Cloud in Sydney runs Auramath, its AI model (Gemini) and its voice. An email service sends your sign-in emails and notes. They work only for us, and none of them gets a name.';

  @override
  String get setupDataJulia => 'Julia sees how families are doing';

  @override
  String get setupDataJuliaDetail =>
      'During the home week, Julia, our teacher, gets a weekly summary of her families\' lessons.';

  @override
  String get setupDataDelete => 'Download or delete it any time';

  @override
  String get setupDataDeleteDetail =>
      'From the Family area, in one step, for the whole family.';

  @override
  String get setupDataWho => 'Who else sees anything';

  @override
  String get setupDataAi => 'The AI that runs the lesson';

  @override
  String get setupDataAiDetail =>
      'Gemini, on Google Cloud in Sydney. It sees the problem and the taps, never a name, age or anything about your family.';

  @override
  String get setupDataVoice => 'The voice that reads aloud';

  @override
  String get setupDataVoiceDetail =>
      'Google Cloud\'s voice, in Sydney. It gets the words on screen, nothing about your child.';

  @override
  String get setupDataEmail => 'The email service';

  @override
  String get setupDataEmailDetail =>
      'Sends your sign-in emails and notes to your address only.';

  @override
  String get setupDataJuliaName => 'Julia Fong';

  @override
  String get setupDataJuliaWeekly =>
      'Gets a weekly summary of her families\' progress, by first name only.';

  @override
  String setupDataConsent(String name) {
    return 'I am $name\'s parent or guardian. I agree to this for $name.';
  }

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
  String get setupContinueApple => 'Sign in with Apple';

  @override
  String get setupContinueGoogle => 'Sign in with Google';

  @override
  String get setupUseEmail => 'Use my email';

  @override
  String get setupEmailLabel => 'Your email';

  @override
  String get setupEmailMeLink => 'Email me a sign-in link';

  @override
  String get setupOr => 'or';

  @override
  String get setupTerms =>
      'By continuing you agree to the terms and privacy notice.';

  @override
  String get setupEmailInvalid => 'Type the email address to send the link to.';

  @override
  String get setupAppleOff =>
      'Apple sign-in isn\'t switched on for this server yet.';

  @override
  String get setupEmailOff => 'This server can\'t send email yet.';

  @override
  String get setupSignInTitle => 'Sign in or create your family account';

  @override
  String get setupSignInSubtitle =>
      'One family account. Your child never signs in.';

  @override
  String get setupCheckTitle => 'Check your email';

  @override
  String get setupCheckBody =>
      'Tap the link we sent to your email. It works once, for 15 minutes.';

  @override
  String setupCheckBodyTo(String email) {
    return 'Tap the link we sent to $email. It works once, for 15 minutes.';
  }

  @override
  String get setupSendAgain => 'Send it again';

  @override
  String get setupSentAgain => 'Sent again. Check your spam folder too.';

  @override
  String get setupWrongEmail => 'Not your email?';

  @override
  String get setupTappedLink => 'I tapped the link';

  @override
  String get setupLinkNotYet =>
      'The link hasn\'t opened on this phone yet. Open the email on this phone and tap the link.';

  @override
  String get setupDevLink => 'Open the link (dev only)';

  @override
  String get setupCodeLabel => 'Or type the 6-digit code from the email';

  @override
  String get setupCodeUse => 'Sign in with the code';

  @override
  String get setupCodeSix => 'The code is 6 numbers.';

  @override
  String get setupVerifying => 'Signing you in…';

  @override
  String get setupSignedIn => 'Signed in';

  @override
  String get setupLinkMissing =>
      'This link has no sign-in code in it. Ask for a new one.';

  @override
  String get setupBackToSignIn => 'Back to sign in';

  @override
  String setupReadyTitle(String name) {
    return '$name\'s work is ready.';
  }

  @override
  String setupReadyBody(String name) {
    return '$name\'s turn: let them have a go at today\'s tutor-set work. We will send you an update of their progress from today.';
  }

  @override
  String get setupReadyNoHelp => 'Please don\'t help with the sums';

  @override
  String setupReadyNoHelpDetail(String name) {
    return 'The tutor needs to see what $name can do alone. Sit nearby if you like.';
  }

  @override
  String get setupReadyMeet => 'Meet the tutor together';

  @override
  String setupReadyMeetDetail(String name) {
    return 'It will tell $name it is a computer helper, an AI, with you there.';
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
  String get setupLockTitle => 'Lock the Family area';

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
  String get setupPassTitle => 'Lock the Family area';

  @override
  String setupPassBody(String digits, String name) {
    return '$digits only you know. $name never sees this part.';
  }

  @override
  String setupPassDigits(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n digits',
      one: 'One digit',
    );
    return '$_temp0';
  }

  @override
  String get setupPassFour => 'Four digits';

  @override
  String get setupPassAgainTitle => 'Lock the Family area';

  @override
  String get setupPassAgainBody => 'Type it once more to be sure.';

  @override
  String get setupPassMismatch => 'Those did not match. Start again.';

  @override
  String get setupPassSet => 'Passcode set';

  @override
  String setupPassShort(int n) {
    return 'The passcode is $n digits.';
  }

  @override
  String get setupPassAlreadySet => 'Your family has a passcode';

  @override
  String get setupPassAlreadySetBody =>
      'It was set on another phone. Use it to open the Family area here too.';

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
    return 'Works once, for $time. Five tries.';
  }

  @override
  String get setupCodeExpired =>
      'That code has expired. Codes last 10 minutes. Show a new one when you are both ready.';

  @override
  String setupProgressFollows(String name) {
    return 'Progress follows $name';
  }

  @override
  String get setupProgressFollowsDetail =>
      'Lessons carry on from any phone in the family.';

  @override
  String get setupJoinDone => 'Done';

  @override
  String get setupNewCode => 'Show a new code';

  @override
  String get lessonThinking => 'Hmm, let me think.';

  @override
  String get lessonReadAgainTitle => 'Let\'s read it again';

  @override
  String get lessonReadAgainBack => 'Back to my drawing';

  @override
  String get lessonSeenBeforeTitle => 'You\'ve solved one like this';

  @override
  String get lessonSeenBeforeLinked =>
      'Remember this case? You cracked it. This one works the same way.';

  @override
  String get lessonSeenBeforeNoCase =>
      'You\'ve cracked a case like this before. How did you draw it?';

  @override
  String get lessonSeenBeforeBack => 'Back to my case';

  @override
  String get lessonRateAsk => 'How was that one?';

  @override
  String get lessonRateAnyAnswer => 'Any answer is fine.';

  @override
  String get lessonRateSkip => 'Skip';

  @override
  String get lessonDrawStoryOut => 'Can you draw the story out?';

  @override
  String get lessonDrawTogether => 'Let\'s do it together.';

  @override
  String get lessonLetsDraw => 'Let\'s draw';

  @override
  String get lessonFamilySees => 'Your family will see this too.';

  @override
  String get lessonRateEasy => 'Easy';

  @override
  String get lessonRateOk => 'OK';

  @override
  String get lessonRateTricky => 'Tricky';

  @override
  String get lessonRateSaidEasy =>
      'Easy ones are worth a check too. A quick look at your sum keeps them easy.';

  @override
  String get lessonRateSaidOk =>
      'Thanks for telling me. Checking each step helps every time.';

  @override
  String get lessonRateSaidTricky =>
      'Tricky cases take care. Checking each bar helped you crack it.';

  @override
  String get kidMeetTitle => 'Meet your tutor';

  @override
  String get kidMeetGrownUp => 'Parent or carer: please stay for this part.';

  @override
  String get kidMeetLine1 =>
      'Hi! I\'m your tutor. I help you crack maths cases.';

  @override
  String get kidMeetLine2 =>
      'I\'m a computer helper, an AI. I\'m not a person.';

  @override
  String get kidMeetLine3 =>
      'Julia\'s team wrote my rules. I can make mistakes, so if something looks odd, tell your family.';

  @override
  String get kidMeetLine4 => 'Your family can see your work.';

  @override
  String get kidMeetStart => 'Let\'s start';

  @override
  String get lessonEasierSum => 'Show the sum in words';

  @override
  String get lessonSentenceGap => 'gap';

  @override
  String get lessonSentenceBoth => 'both';

  @override
  String get exampleNewOne => 'Now try a new one';

  @override
  String get lessonLeaveForNow => 'Leave it for now';

  @override
  String lessonItIs(String name) {
    return 'The $name';
  }

  @override
  String lessonItHighlighted(String name) {
    return '\'It\' and the $name are in the same colour.';
  }

  @override
  String get lessonDetourPaused =>
      'Your case is waiting. Your drawing is kept.';

  @override
  String get kidReadToMe => 'Read it to me';

  @override
  String get lessonEverydayPicture => 'A parent and a child, side by side.';

  @override
  String get lessonGrownUp => 'Parent';

  @override
  String get lessonYou => 'You';

  @override
  String get lessonBarSenseLine => 'A longer bar shows a bigger number.';

  @override
  String lessonBarSenseAsk(int n) {
    return 'Which bar shows $n?';
  }

  @override
  String lessonStarsAsk(int a, int b) {
    return 'Let\'s compare $a stars and $b stars. Which row has more?';
  }

  @override
  String get lessonStarsRight =>
      'Yes! More stars make a longer row. Back to the bars.';

  @override
  String get lessonBarSenseRight =>
      'Yes! The longer bar shows the bigger number.';

  @override
  String lessonBarLabel(int n) {
    return 'Bar $n';
  }

  @override
  String lessonStarRow(int n) {
    return 'Row $n';
  }

  @override
  String get lessonTakeBack => 'Take it back';

  @override
  String get lessonSee => 'See';

  @override
  String get lessonSeeQuestion => 'See the question';

  @override
  String get lessonQuestionBack => 'Back to my work';

  @override
  String get lessonUndo => 'Undo';

  @override
  String get kidQuickLine => 'Quick sums! Type the answer.';

  @override
  String get kidQuickOneMore => 'Check it and have one more go.';

  @override
  String get kidQuickRegroup =>
      'Look at the ones first. Do you need to regroup?';

  @override
  String get kidQuickSideDone =>
      'That\'s regrouping! Now have one more go at your sum.';

  @override
  String get kidQuickSideBack => 'Back to my sums';

  @override
  String get kidPickAvatar => 'Pick your detective';

  @override
  String get kidPickAvatarSave => 'That\'s me!';

  @override
  String get kidPickAvatarFailed =>
      'That didn\'t save. Check the internet and tap again.';

  @override
  String get guDrawingLabel => 'The child\'s drawing from this lesson';

  @override
  String get kidPickAvatarAskGrownUp =>
      'Ask your family to set your detective for you.';

  @override
  String get kidQuickDone => 'Warmed up!';

  @override
  String get kidQuickOnToday => 'On to today.';

  @override
  String get kidQuickGo => 'Go!';

  @override
  String get kidQuickTier1 => 'Charged up!';

  @override
  String get kidQuickTier2 => 'On fire!';

  @override
  String get kidQuickTier3 => 'Super charged!';

  @override
  String get kidQuickStory => 'On to a case';

  @override
  String get kidQuickHome => 'Back home';

  @override
  String get kidTodayTitle => 'Which one first?';

  @override
  String get kidTodayStory => 'A story problem';

  @override
  String get kidTodayQuick => 'Quick sums';

  @override
  String get kidWelcomeChooseToday => 'Choose today\'s work';

  @override
  String kidWordWhat(String word) {
    return 'What does $word mean?';
  }

  @override
  String get kidWordTaller =>
      'Taller means it reaches higher. The taller one gets the longer bar.';

  @override
  String get kidWordShorter =>
      'Shorter means it does not reach as high. The shorter one gets the shorter bar.';

  @override
  String get kidWordMore =>
      'More means it weighs more. The heavier one gets the longer bar.';

  @override
  String get kidWordLess =>
      'Less means it weighs less. The lighter one gets the shorter bar.';

  @override
  String get kidWordGotIt => 'Got it';

  @override
  String lessonNameHowTall(String a) {
    return 'How tall is the $a?';
  }

  @override
  String lessonNameHowHeavy(String a) {
    return 'How heavy is the $a?';
  }

  @override
  String get lessonSentenceBox => 'Empty box';

  @override
  String get lessonSentenceAdd => 'Add. Tap to take away.';

  @override
  String get lessonSentenceTake => 'Take away. Tap to add.';

  @override
  String get lessonSentenceCheck => 'Check my sentence';

  @override
  String lessonSentenceTitle(String b) {
    return 'Make a number sentence for the $b.';
  }

  @override
  String get lessonHeavier => 'Heavier';

  @override
  String get lessonLighter => 'Lighter';

  @override
  String get lessonMore => 'more';

  @override
  String get lessonLess => 'less';

  @override
  String get kidSurpriseMe => 'Surprise me';

  @override
  String kidLookName(int n) {
    return 'Look $n';
  }

  @override
  String get kidTutorPlaceholderName => 'Your tutor';

  @override
  String kidTutorName(int n) {
    return 'Tutor $n';
  }

  @override
  String kidVoiceName(int n) {
    return 'Voice $n';
  }

  @override
  String get kidHearHello => 'Hear hello';

  @override
  String get kidChooseThis => 'Choose this one';

  @override
  String get kidThisIsMe => 'This is me!';

  @override
  String get kidThisIsMyTutor => 'This is my teacher!';

  @override
  String get kidMyLookNote => 'Change how you look';

  @override
  String get kidMyTutorNote => 'Pick who teaches you';

  @override
  String get kidMyVoiceNote => 'How your teacher sounds';

  @override
  String get kidMyWorldNote => 'Where your cases happen';

  @override
  String get kidTapYourPicture => 'Tap your picture.';

  @override
  String get kidErrTitle => 'That didn\'t work';

  @override
  String get kidErrLine => 'Let\'s have another go.';

  @override
  String get kidErrRetry => 'Have another go';

  @override
  String get kidReadyForACase => 'Ready for a case?';

  @override
  String get kidGoHome => 'Go home';

  @override
  String get pairReadyToPlay => 'Hi! Ready to play?';

  @override
  String get pairPlay => 'Play';

  @override
  String get pairParentsAndCarers => 'Parents and carers';

  @override
  String get pairSetUpSignIn => 'Already set up? Sign in';

  @override
  String get pairFamilyArea => 'Family area';

  @override
  String get kidComingSoon => 'Coming soon';

  @override
  String get kidMe => 'Me';

  @override
  String get kidMyLook => 'My look';

  @override
  String get kidMyTutor => 'My tutor';

  @override
  String get kidMyVoice => 'My tutor\'s voice';

  @override
  String get kidMyWorld => 'My world';

  @override
  String get kidWorldNextTime => 'Your new world starts next time.';

  @override
  String get kidSaveFailed =>
      'That didn\'t save. Check the internet and tap again.';

  @override
  String get kidBadgeCabinet => 'My badges';

  @override
  String get kidCabinetEmpty => 'Your badges will live here.';

  @override
  String get kidTodaysBadge => 'Today\'s badge';

  @override
  String get kidNewMedal => 'A new medal!';

  @override
  String get kidTrailGoesOn => 'Your trail goes on. Time to try a new skill!';

  @override
  String get kidNewBadge => 'A new badge!';

  @override
  String get kidHabitBarBuilder => 'You draw the bars yourself.';

  @override
  String get kidHabitCarefulReader => 'You read the question with care.';

  @override
  String get kidHabitLearnItDoIt => 'You learn a step, then do it on your own.';

  @override
  String get kidHabitDoubleChecker => 'You check your work and fix it.';

  @override
  String get kidLandTrophy => 'A land trophy!';

  @override
  String get kidEveryStop => 'Every stop, all yours.';

  @override
  String get kidIntoYourBadges => 'Into your badges!';

  @override
  String get kidCameBack => 'You came back!';

  @override
  String get kidKeepComingBack =>
      'Detectives who keep coming back get really good.';

  @override
  String kidMedalFor(String stop) {
    return 'Your medal for $stop.';
  }

  @override
  String get kidFirstCaseLine => 'Your first case, cracked.';

  @override
  String kidWalkedAll(String land) {
    return 'You walked all of $land.';
  }

  @override
  String get kidNotNow => 'Not now';

  @override
  String get kidBackHome => 'Back home';

  @override
  String get kidTrailExplored => 'Explored';

  @override
  String get kidTrailEarned => 'Earned';

  @override
  String get kidTrailMist => 'Still in the mist';

  @override
  String get kidPolishMe => 'Polish me';

  @override
  String get kidSidePath => 'Side path';

  @override
  String get kidSidePathBack => 'Back to your case';

  @override
  String get kidTrailLookBack => 'Look back';

  @override
  String kidTrailOf(String name) {
    return '$name\'s trail';
  }

  @override
  String get timeUpCallItADay => 'Call it a day';

  @override
  String get timeUpBodyFinish =>
      'Good detective work. Finish this one, or call it a day?';

  @override
  String get lostInternetTitle => 'Lost the internet';

  @override
  String get lostInternetBody =>
      'Your drawing is safe. We\'ll carry on when it\'s back.';

  @override
  String get kidCheckAgain => 'Check again';

  @override
  String get lessonNeedInternetAsk =>
      'Ask your family to check the Wi-Fi. Then tap Check again.';

  @override
  String get guSetNoLimit => 'No limit';

  @override
  String get guSetThisPhone => 'This phone';

  @override
  String get guSetOffline =>
      'Not saved. Check the internet, then change it again.';

  @override
  String get guSetNotSaved => 'That didn\'t save. Please change it again.';

  @override
  String get guSetReadAloudOff =>
      'Read aloud isn\'t on in AuraMath yet, so it stays off for now.';

  @override
  String get guSetCantRead =>
      'These settings can\'t be read right now. Check the internet and come back.';

  @override
  String get reportProblemRow => 'Report a problem';

  @override
  String get reportProblemRowDetail => 'A lesson, a note or the app';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportIntro => 'A person on the Auramath team reads every report.';

  @override
  String get reportAbout => 'What is it about?';

  @override
  String reportCaseStory(String a, String b) {
    return '$a and $b';
  }

  @override
  String get reportCaseLabel => 'A story problem';

  @override
  String reportCaseWhen(String child, String when) {
    return '$child, $when';
  }

  @override
  String get reportNoCases =>
      'No lessons to pick from yet. Something else is always there.';

  @override
  String get reportSomethingElse => 'Something else';

  @override
  String get reportSomethingElseDetail => 'The app, a note or an email';

  @override
  String get reportWhatHappened => 'What happened?';

  @override
  String get reportNoteLabel => 'Your note (you can leave it out)';

  @override
  String get reportNoteHint => 'A sentence or two is plenty.';

  @override
  String get reportNoNames => 'Please don\'t include names.';

  @override
  String get reportSend => 'Send';

  @override
  String get reportOffline =>
      'Not sent. Check the internet, then send it again. Your note is still here.';

  @override
  String get reportTooMany =>
      'That\'s a lot of reports in one hour. Please send this one a little later. Your note is still here.';

  @override
  String get reportGone =>
      'That lesson can\'t be found any more. Pick another, or Something else.';

  @override
  String get reportNotSent =>
      'That couldn\'t be sent. Please check the note, then send it again.';

  @override
  String get reportThanksTitle => 'Thank you';

  @override
  String get reportThanksBody =>
      'We have your report. A person at Key will look at it.';

  @override
  String get reportSentTitle => 'Sent';

  @override
  String get reportSentBody =>
      'It goes into the team\'s weekly review of what the tutor wrote and said.';

  @override
  String get reportBackToFamily => 'Back to the Family area';

  @override
  String get kidMyCasebook => 'My casebook';

  @override
  String get kidCasebookToday => 'Today';

  @override
  String get kidCasebookLastTime => 'Last time';

  @override
  String kidCasebookDayBadge(String day, String badge) {
    return '$day · badge: $badge';
  }

  @override
  String get kidCasebookEmpty => 'Your solved cases will live here.';

  @override
  String get kidCaseDrawing => 'Your drawing';

  @override
  String get kidCaseInYourHead => 'You solved this one in your head.';

  @override
  String kidCaseSticker(String object) {
    return '$object sticker';
  }

  @override
  String get kidBack => 'Back';

  @override
  String get guOffline =>
      'Can\'t connect right now. Please check the internet.';

  @override
  String get guSomethingWrong =>
      'That didn\'t work just now. Please give it a moment, then have another go.';

  @override
  String get kidThePeak => 'The peak';

  @override
  String get kidTheTop => 'The top';

  @override
  String get kidReachedPeak => 'You reached the peak!';

  @override
  String kidNewLandOpens(String name) {
    return 'A new land opens: $name.';
  }

  @override
  String kidClimbedEveryLand(String path) {
    return 'You climbed every land in $path!';
  }
}

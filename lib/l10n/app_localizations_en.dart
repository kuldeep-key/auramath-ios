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
  String get guPassTitle => 'Grown-ups only';

  @override
  String get guPassEnter => 'Enter your passcode.';

  @override
  String get guPassForgot => 'Forgot passcode?';

  @override
  String get guPassWrong => 'That\'s not the passcode. Try again.';

  @override
  String guPassLocked(String time) {
    return 'Too many tries. Try again after $time.';
  }

  @override
  String get guPassLockedSoon =>
      'Too many tries. Wait a few minutes and try again.';

  @override
  String get guPassChooseTitle => 'Choose a passcode';

  @override
  String get guPassNewTitle => 'Choose a new passcode';

  @override
  String guPassChooseBody(int n) {
    return '$n digits, so only grown-ups can open this area.';
  }

  @override
  String get guPassConfirmTitle => 'Type it again';

  @override
  String get guPassConfirmBody => 'To be sure it\'s right.';

  @override
  String get guPassMismatch => 'Those didn\'t match. Choose a passcode again.';

  @override
  String guPassShort(int n) {
    return 'Type all $n digits.';
  }

  @override
  String get guPassResetBlocked =>
      'The server still asks for the old passcode before it sets a new one, so this can\'t finish yet.';

  @override
  String get guFaceIdReason => 'Open the grown-up area';

  @override
  String get guUseFaceId => 'Use Face ID';

  @override
  String get guForgotTitle => 'Forgot your passcode?';

  @override
  String guForgotBody(String email) {
    return 'We will email a sign-in link to $email.';
  }

  @override
  String get guForgotSend => 'Send the link';

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
  String get guHomeHi => 'Hi there';

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
  String guHomeProgressTitle(String month) {
    return '$month progress';
  }

  @override
  String guHomeProgressBody(String name) {
    return '$name this month';
  }

  @override
  String get guHomeFamily => 'Family';

  @override
  String get guHomePlan => 'Plan';

  @override
  String guHomeBackTo(String name) {
    return 'Back to $name';
  }

  @override
  String get guHomeNoChildren => 'No children yet';

  @override
  String get guHomeNoChildrenBody => 'Add a child to start their first lesson.';

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
  String get guSetPad => 'Number pad';

  @override
  String get guSetPadPhone => 'Phone\'s own';

  @override
  String get guSetPadApp => 'The app\'s own';

  @override
  String get guSetBigPad => 'Bigger number pad (accessibility)';

  @override
  String get guSetChangeHint => 'Changes the setting';

  @override
  String get guFamilyAndPhones => 'Family and phones';

  @override
  String guChildPlan(String name) {
    return '$name\'s plan';
  }

  @override
  String get guNotifyLink => 'Email after each session';

  @override
  String get guRightsLink => 'Your data and rights';

  @override
  String get guSignOut => 'Sign out';

  @override
  String get guFamilyTitle => 'Family and phones';

  @override
  String get guGrownUps => 'Grown-ups';

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
  String get guGrownUp => 'Grown-up';

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
  String get guInviteGrownUp => 'Invite a grown-up';

  @override
  String get guAddPhone => 'Add a child\'s phone';

  @override
  String get guInviteTitle => 'Invite a grown-up';

  @override
  String get guInviteBody => 'They can see the book and change settings.';

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
    return 'We emailed a link to $email.';
  }

  @override
  String get guCodeTitle => 'Here is a code';

  @override
  String get guCodeNewTitle => 'Here is a new code';

  @override
  String get guCodeNewBody => 'The old one stopped working.';

  @override
  String guCodeLeft(String time) {
    return 'Works once. $time left.';
  }

  @override
  String get guCodeExpired => 'This code has stopped working.';

  @override
  String get guCodeAgain => 'Get a new code';

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
      'It signs out straight away. Progress stays safe in the family account.';

  @override
  String get guRemoveButton => 'Remove phone';

  @override
  String get guRemoveGone => 'That phone isn\'t in your family any more.';

  @override
  String get guRemovedTitle => 'Phone removed';

  @override
  String get guRemovedBody =>
      'That phone is signed out. Join a new phone with a code any time.';

  @override
  String get guAddChildTitle => 'Add a child';

  @override
  String get guAddChildBody =>
      'You agree for them, as their grown-up. Only a first name.';

  @override
  String get guAddChildName => 'First name';

  @override
  String get guAddChildNameNeeded => 'Type a first name.';

  @override
  String get guAddChildYear => 'School year (optional)';

  @override
  String get guAddChildYearHint => 'For example, Year 2';

  @override
  String get guAddChildAgree => 'I agree, continue';

  @override
  String get guRightsTitle => 'Your data and rights';

  @override
  String get guStoredTitle => 'What we keep';

  @override
  String get guStored1 => 'Your email, and other grown-ups\' emails';

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
  String get guDownloadBody => 'A file with all of your family\'s data';

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
  String get guDeleteAccountBody =>
      'Everything, for every child, straight away';

  @override
  String get guDeleteTitle => 'Delete your family account?';

  @override
  String get guDeleteBody =>
      'This deletes everything we keep: every child\'s lessons and progress, the other grown-ups\' access and every joined phone. It happens straight away and can\'t be undone. Download everything first if you want a copy.';

  @override
  String get guDeleteButton => 'Delete everything';

  @override
  String get guNotifyTitle => 'A note after each session?';

  @override
  String guNotifyBody(String name) {
    return 'We\'ll email you what $name did and what\'s next. Nothing else.';
  }

  @override
  String get guNotifyCard => 'An email after each session';

  @override
  String get guNotifyCardBody => 'One short note, after the session ends.';

  @override
  String get guNotifyYes => 'Yes please';

  @override
  String get guNotifyNo => 'Not now';

  @override
  String get guSignOutTitle => 'Sign out on this phone?';

  @override
  String get guSignOutBody => 'Progress stays safe in your family account.';

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
}

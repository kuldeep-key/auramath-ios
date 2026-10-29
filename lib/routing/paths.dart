/// Every screen's address. Screens navigate only through these, so a
/// renamed route breaks the build, not the app. Figma node ids in comments.
abstract final class Paths {
  // ------------------------------------------------ a phone with no account
  /// Open · Who's here? (644:107): the first screen on a fresh phone.
  static const open = '/open';

  /// Welcome (643:2).
  static const welcome = '/welcome';

  // -------------------------------- setup, before the grown-up signs in
  static const setupName = '/setup/name'; // 643:24
  static const setupAge = '/setup/age'; // 643:40
  static const setupYear = '/setup/year'; // 643:66
  static const setupStart = '/setup/start'; // 643:102
  static const setupNotSure = '/setup/not-sure'; // 643:145
  static const setupGoal = '/setup/goal'; // 643:169
  static const setupData = '/setup/data'; // 643:203
  static const setupSave = '/setup/save'; // SavePlace 643:235
  static const setupCheckEmail = '/setup/check-email'; // CheckEmail 653:144

  // ------------------------------------ setup, once signed in (parent)
  static const setupReady = '/setup/ready'; // 644:2
  static const setupLock = '/setup/lock'; // 644:20
  static const setupJoinCode = '/setup/join-code'; // JoinCode 644:75

  // ------------------------------------------------------------ sign-in
  static const signIn = '/sign-in'; // SignIn 653:2
  static const signInCheckEmail = '/sign-in/check-email'; // 653:144

  /// The emailed link lands here: `/auth/verify?m=<token>`.
  static const verify = '/auth/verify';

  // -------------------------------------------- the child's own phone
  static const pair = '/pair'; // GetCode 644:147
  static const pairWrong = '/pair/wrong'; // CodeWrong 653:55
  static const pairWhichChild = '/pair/which-child'; // WhichChild 653:115
  static const pairIsThisYou = '/pair/is-this-you'; // IsThisYou 644:205
  static const pairJoined = '/pair/joined'; // PhoneJoined 644:240
  /// On the child's phone after a grown-up removed it. Not designed in
  /// Figma; built from Removed 653:172's look.
  static const removed = '/removed';

  // ------------------------------------------------------- the child
  /// A1 · Who's learning? (644:38): the shared phone's picker.
  static const kids = '/kids';
  static const home = '/home'; // Home 649:2
  static const welcomeBack = '/welcome-back'; // 651:133
  static const carryOn = '/carry-on'; // OtherPhone 653:24
  static const sound = '/sound'; // 650:149
  static const noVoice = '/no-voice'; // 659:39
  static const badges = '/badges'; // B1 650:233
  static const trail = '/trail'; // K2 651:68
  static const trailTop = '/trail/top'; // TrailTop 659:2
  static const check = '/check'; // A quick check 651:165

  /// After a solved case: X1 (650:166), Streak (650:202), Up (651:35),
  /// Y4 (648:83). `?next=<problemId>` is the case the engine chose.
  static const afterCase = '/after-case';

  /// Keep going: the lesson route opens the unfinished case (this phone's
  /// or the server's) or the next one the engine chose.
  static const lessonNext = '/lesson';

  /// "Carry on here" on OtherPhone: resume the case from the other phone
  /// without asking again.
  static const lessonCarryOnHere = '/lesson?here=1';
  static String lesson(String problemId) => '/lesson/$problemId';
  static String badge(String id) => '/badges/$id'; // B2 651:2
  static String afterCaseNext(String next) => '$afterCase?next=$next';

  // ----------------------------- the grown-up area (passcode-locked)
  /// GPass (652:173). `?to=<path>` is where to go once unlocked.
  static const grownUpsPass = '/grown-ups/pass';
  static const forgotPasscode = '/grown-ups/forgot'; // ForgotPass 653:132
  static const grownUps = '/grown-ups'; // PHome 658:84
  static const settings = '/grown-ups/settings'; // 652:75
  static const family = '/grown-ups/family'; // 652:213
  static const invite = '/grown-ups/family/invite'; // 652:251
  static const newCode = '/grown-ups/family/new-code'; // NewCode 653:89
  static const addChild = '/grown-ups/add-child'; // 667:87
  static const rights = '/grown-ups/rights'; // 667:66

  /// Delete the family account: its own confirmation (not in Figma).
  static const deleteAccount = '/grown-ups/rights/delete';
  static const notify = '/grown-ups/notify'; // 659:52
  static const signOut = '/grown-ups/sign-out'; // 659:105

  /// Phone removed (653:172): the grown-up's confirmation after removing.
  static const phoneRemoved = '/grown-ups/family/phone-removed';
  static String removePhone(String deviceId) =>
      '/grown-ups/family/phones/$deviceId/remove'; // 653:159
  static String book(String childId) => '/grown-ups/children/$childId/book';
  static String plan(String childId) => '/grown-ups/children/$childId/plan';
  static String report(String childId) =>
      '/grown-ups/children/$childId/report'; // R0 667:44
  static String month(String childId) =>
      '/grown-ups/children/$childId/month'; // Monthly 658:121

  /// Screens a phone with no account may show.
  static bool isPublic(String loc) =>
      loc == open ||
      loc == welcome ||
      _under(loc, '/setup') && !_signedInSetup.contains(loc) ||
      _under(loc, signIn) ||
      loc == verify ||
      _under(loc, pair) ||
      loc == removed;

  static const _signedInSetup = {setupReady, setupLock, setupJoinCode};

  static bool isGrownUp(String loc) =>
      _under(loc, grownUps) && loc != grownUpsPass && loc != forgotPasscode;

  static bool isSignedInSetup(String loc) => _signedInSetup.contains(loc);

  static bool _under(String loc, String root) =>
      loc == root || loc.startsWith('$root/');
}

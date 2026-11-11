import 'package:go_router/go_router.dart';

import '../../../data/repositories/grown_up_repository.dart';
import '../../../data/repositories/setup_repository.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/add_child_screen.dart';
import 'views/book_screen.dart';
import 'views/consent_screens.dart';
import 'views/edit_child_screen.dart';
import 'views/family_remove_screens.dart';
import 'views/family_screen.dart';
import 'views/forgot_passcode_screen.dart';
import 'views/grown_up_home_screen.dart';
import 'views/invite_screen.dart';
import 'views/learning_screen.dart';
import 'views/leave_screens.dart';
import 'views/month_screen.dart';
import 'views/new_code_screen.dart';
import 'views/notify_screen.dart';
import 'views/passcode_screen.dart';
import 'views/plan_screen.dart';
import 'views/remove_phone_screen.dart';
import 'views/report_screen.dart';
import 'views/rights_screen.dart';
import 'views/settings_screen.dart';

/// The grown-up area behind the passcode (Figma 7 and 8, PHome, Rights,
/// AddChild, Notify, SignOut), and the screens with no Figma frame yet:
/// consent, removing grown-ups, invites and browsers, the child's learning
/// and their details.
List<RouteBase> grownUpRoutes(Deps deps) {
  final repo = GrownUpRepository(deps.client, deps.store);
  final family = deps.family;
  String child(GoRouterState s) => s.pathParameters['childId']!;
  return [
    GoRoute(
      path: Paths.grownUpsPass,
      builder: (_, s) => PasscodeScreen(
        account: deps.account,
        family: family,
        repo: repo,
        deviceLock: deps.deviceLock,
        to: s.uri.queryParameters['to'],
      ),
    ),
    GoRoute(
      path: Paths.forgotPasscode,
      builder: (_, _) =>
          ForgotPasscodeScreen(account: deps.account, repo: repo),
    ),
    GoRoute(
      path: Paths.grownUps,
      builder: (_, _) =>
          GrownUpHomeScreen(account: deps.account, family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.settings,
      builder: (_, _) => SettingsScreen(family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.family,
      builder: (_, _) => FamilyScreen(family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.invite,
      builder: (_, _) => InviteScreen(repo: repo),
    ),
    GoRoute(
      path: Paths.newCode,
      builder: (_, _) => NewCodeScreen(family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.phoneRemoved,
      builder: (_, _) => const PhoneRemovedScreen(),
    ),
    GoRoute(
      path: Paths.addChild,
      builder: (_, _) => AddChildScreen(family: family),
    ),
    GoRoute(
      path: Paths.rights,
      builder: (_, _) => RightsScreen(
        repo: repo,
        family: family,
        deletePath: Paths.deleteAccount,
      ),
    ),
    GoRoute(
      path: Paths.withdrawConsent,
      builder: (_, _) => WithdrawConsentScreen(family: family),
    ),
    GoRoute(
      path: Paths.agreeAgain,
      builder: (_, _) => AgreeAgainScreen(family: family),
    ),
    GoRoute(
      path: Paths.deleteAccount,
      builder: (_, _) => DeleteAccountScreen(
        account: deps.account,
        repo: repo,
        sessions: deps.sessions,
      ),
    ),
    GoRoute(
      path: Paths.notify,
      builder: (_, _) => NotifyScreen(family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.signOut,
      builder: (_, _) => SignOutScreen(
        account: deps.account,
        repo: repo,
        sessions: deps.sessions,
      ),
    ),
    GoRoute(
      path: '/grown-ups/family/phones/:deviceId/remove',
      builder: (_, s) => RemovePhoneScreen(
        deviceId: s.pathParameters['deviceId']!,
        repo: repo,
      ),
    ),
    GoRoute(
      path: '/grown-ups/family/grown-ups/:memberId/remove',
      builder: (_, s) => RemoveGrownUpScreen(
        memberId: s.pathParameters['memberId']!,
        repo: repo,
      ),
    ),
    GoRoute(
      path: '/grown-ups/family/invites/:inviteId/cancel',
      builder: (_, s) => CancelInviteScreen(
        inviteId: s.pathParameters['inviteId']!,
        repo: repo,
      ),
    ),
    GoRoute(
      path: '/grown-ups/family/browsers/:browserId/remove',
      builder: (_, s) => RemoveBrowserScreen(
        browserId: s.pathParameters['browserId']!,
        repo: repo,
      ),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/learning',
      builder: (_, s) =>
          LearningScreen(childId: child(s), family: family, repo: repo),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/edit',
      builder: (_, s) => EditChildScreen(
        childId: child(s),
        family: family,
        setup: SetupRepository(deps.client),
      ),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/book',
      builder: (_, s) =>
          BookScreen(childId: child(s), family: family, repo: repo),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/plan',
      builder: (_, s) =>
          PlanScreen(childId: child(s), family: family, repo: repo),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/report',
      builder: (_, s) =>
          ReportScreen(childId: child(s), family: family, repo: repo),
    ),
    GoRoute(
      path: '/grown-ups/children/:childId/month',
      builder: (_, s) =>
          MonthScreen(childId: child(s), family: family, repo: repo),
    ),
  ];
}

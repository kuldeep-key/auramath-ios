import 'package:go_router/go_router.dart';

import '../../../data/repositories/grown_up_repository.dart';
import '../../../data/services/key_store.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/add_child_screen.dart';
import 'views/book_screen.dart';
import 'views/family_screen.dart';
import 'views/forgot_passcode_screen.dart';
import 'views/grown_up_home_screen.dart';
import 'views/invite_screen.dart';
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

/// Delete the family account: not in Figma, so not yet in [Paths].
// ponytail: local path until Paths gains `deleteAccount` (lead's file).
const deleteAccountPath = '${Paths.rights}/delete';

/// The grown-up area behind the passcode (Figma 7 and 8, PHome, Rights,
/// AddChild, Notify, SignOut). [store] holds this phone's lesson settings
/// and the forgot-passcode marker.
List<RouteBase> grownUpRoutes(Deps deps, {KeyStore? store}) {
  final repo = GrownUpRepository(deps.client, store ?? SecureKeyStore());
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
      builder: (_, _) =>
          RightsScreen(repo: repo, deletePath: deleteAccountPath),
    ),
    GoRoute(
      path: deleteAccountPath,
      builder: (_, _) => DeleteAccountScreen(account: deps.account, repo: repo),
    ),
    GoRoute(
      path: Paths.notify,
      builder: (_, _) => NotifyScreen(family: family, repo: repo),
    ),
    GoRoute(
      path: Paths.signOut,
      builder: (_, _) => SignOutScreen(account: deps.account),
    ),
    GoRoute(
      path: '/grown-ups/family/phones/:deviceId/remove',
      builder: (_, s) => RemovePhoneScreen(
        deviceId: s.pathParameters['deviceId']!,
        repo: repo,
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

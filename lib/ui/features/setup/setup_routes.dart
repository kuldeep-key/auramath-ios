import 'package:go_router/go_router.dart';

import '../../../data/repositories/setup_repository.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'setup_paths.dart';
import 'views/age_screen.dart';
import 'views/check_email_screen.dart';
import 'views/data_screen.dart';
import 'views/goal_screen.dart';
import 'views/join_code_screen.dart';
import 'views/lock_screen.dart';
import 'views/name_screen.dart';
import 'views/not_sure_screen.dart';
import 'views/passcode_screen.dart';
import 'views/ready_screen.dart';
import 'views/save_place_screen.dart';
import 'views/sign_in_screen.dart';
import 'views/start_screen.dart';
import 'views/verify_screen.dart';
import 'views/welcome_screen.dart';
import 'views/year_screen.dart';

/// Parent setup and sign-in (Figma 1 · Getting started, SignIn, CheckEmail).
List<RouteBase> setupRoutes(Deps deps) {
  final draft = deps.account.draft;
  String child(GoRouterState s) => s.uri.queryParameters['child'] ?? '';
  String name(GoRouterState s) => s.uri.queryParameters['name'] ?? '';
  GoRoute checkEmail(String path, {required bool fromSetup}) => GoRoute(
    path: path,
    builder: (_, s) => CheckEmailScreen(
      deps: deps,
      fromSetup: fromSetup,
      devToken: s.uri.queryParameters['dev'],
      token: s.uri.queryParameters['m'],
    ),
  );

  return [
    GoRoute(path: Paths.welcome, builder: (_, _) => const WelcomeScreen()),
    GoRoute(
      path: Paths.setupName,
      builder: (_, _) => NameScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupAge,
      builder: (_, _) => AgeScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupYear,
      builder: (_, _) => YearScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupStart,
      builder: (_, _) => StartScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupNotSure,
      builder: (_, _) => NotSureScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupGoal,
      builder: (_, _) => GoalScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupData,
      builder: (_, _) => DataScreen(draft: draft),
    ),
    GoRoute(
      path: Paths.setupSave,
      builder: (_, _) => SavePlaceScreen(deps: deps),
    ),
    checkEmail(Paths.setupCheckEmail, fromSetup: true),
    GoRoute(
      path: Paths.setupReady,
      builder: (_, s) => ReadyScreen(childId: child(s), name: name(s)),
    ),
    GoRoute(
      path: Paths.setupLock,
      builder: (_, s) =>
          LockScreen(deps: deps, childId: child(s), name: name(s)),
    ),
    GoRoute(
      path: SetupPaths.passcode,
      builder: (_, s) =>
          PasscodeScreen(deps: deps, childId: child(s), name: name(s)),
    ),
    GoRoute(
      path: Paths.setupJoinCode,
      builder: (_, s) =>
          JoinCodeScreen(repo: SetupRepository(deps.client), name: name(s)),
    ),
    GoRoute(
      path: Paths.signIn,
      builder: (_, _) => SignInScreen(deps: deps),
    ),
    checkEmail(Paths.signInCheckEmail, fromSetup: false),
    GoRoute(
      path: Paths.verify,
      builder: (_, s) =>
          VerifyScreen(deps: deps, token: s.uri.queryParameters['m']),
    ),
  ];
}

import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import '../../../ui/core/parts/placeholder_screen.dart';

/// Parent setup and sign-in (Figma 1 · Getting started, SignIn, CheckEmail).
List<RouteBase> setupRoutes(Deps deps) => [
  GoRoute(
    path: Paths.welcome,
    builder: (_, _) => const PlaceholderScreen('welcome'),
  ),
  GoRoute(
    path: Paths.setupName,
    builder: (_, _) => const PlaceholderScreen('setupName'),
  ),
  GoRoute(
    path: Paths.setupAge,
    builder: (_, _) => const PlaceholderScreen('setupAge'),
  ),
  GoRoute(
    path: Paths.setupYear,
    builder: (_, _) => const PlaceholderScreen('setupYear'),
  ),
  GoRoute(
    path: Paths.setupStart,
    builder: (_, _) => const PlaceholderScreen('setupStart'),
  ),
  GoRoute(
    path: Paths.setupNotSure,
    builder: (_, _) => const PlaceholderScreen('setupNotSure'),
  ),
  GoRoute(
    path: Paths.setupGoal,
    builder: (_, _) => const PlaceholderScreen('setupGoal'),
  ),
  GoRoute(
    path: Paths.setupData,
    builder: (_, _) => const PlaceholderScreen('setupData'),
  ),
  GoRoute(
    path: Paths.setupSave,
    builder: (_, _) => const PlaceholderScreen('setupSave'),
  ),
  GoRoute(
    path: Paths.setupCheckEmail,
    builder: (_, _) => const PlaceholderScreen('setupCheckEmail'),
  ),
  GoRoute(
    path: Paths.setupReady,
    builder: (_, _) => const PlaceholderScreen('setupReady'),
  ),
  GoRoute(
    path: Paths.setupLock,
    builder: (_, _) => const PlaceholderScreen('setupLock'),
  ),
  GoRoute(
    path: Paths.setupJoinCode,
    builder: (_, _) => const PlaceholderScreen('setupJoinCode'),
  ),
  GoRoute(
    path: Paths.signIn,
    builder: (_, _) => const PlaceholderScreen('signIn'),
  ),
  GoRoute(
    path: Paths.signInCheckEmail,
    builder: (_, _) => const PlaceholderScreen('signInCheckEmail'),
  ),
  GoRoute(
    path: Paths.verify,
    builder: (_, _) => const PlaceholderScreen('verify'),
  ),
];

import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import '../../../ui/core/parts/placeholder_screen.dart';
import 'views/home_screen.dart';

/// The child's screens around the lesson (Home, Welcome back, badges, trail, after a case, sound and voice).
List<RouteBase> childRoutes(Deps deps) => [
  GoRoute(
    path: Paths.home,
    builder: (context, _) =>
        HomeScreen(onKeepGoing: () => context.go(Paths.lessonNext)),
  ),
  GoRoute(
    path: Paths.welcomeBack,
    builder: (_, _) => const PlaceholderScreen('welcomeBack'),
  ),
  GoRoute(
    path: Paths.sound,
    builder: (_, _) => const PlaceholderScreen('sound'),
  ),
  GoRoute(
    path: Paths.noVoice,
    builder: (_, _) => const PlaceholderScreen('noVoice'),
  ),
  GoRoute(
    path: Paths.badges,
    builder: (_, _) => const PlaceholderScreen('badges'),
  ),
  GoRoute(
    path: '/badges/:badgeId',
    builder: (_, _) => const PlaceholderScreen('badge'),
  ),
  GoRoute(
    path: Paths.trail,
    builder: (_, _) => const PlaceholderScreen('trail'),
  ),
  GoRoute(
    path: Paths.trailTop,
    builder: (_, _) => const PlaceholderScreen('trailTop'),
  ),
  GoRoute(
    path: Paths.check,
    builder: (_, _) => const PlaceholderScreen('check'),
  ),
  GoRoute(
    path: Paths.afterCase,
    builder: (_, _) => const PlaceholderScreen('afterCase'),
  ),
];

import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import '../../../ui/core/parts/placeholder_screen.dart';

/// The grown-up area behind the passcode (Figma 7 and 8, PHome, Rights, AddChild, Notify, SignOut).
List<RouteBase> grownUpRoutes(Deps deps) => [
  GoRoute(
    path: Paths.grownUpsPass,
    builder: (_, _) => const PlaceholderScreen('grownUpsPass'),
  ),
  GoRoute(
    path: Paths.forgotPasscode,
    builder: (_, _) => const PlaceholderScreen('forgotPasscode'),
  ),
  GoRoute(
    path: Paths.grownUps,
    builder: (_, _) => const PlaceholderScreen('grownUps'),
  ),
  GoRoute(
    path: Paths.settings,
    builder: (_, _) => const PlaceholderScreen('settings'),
  ),
  GoRoute(
    path: Paths.family,
    builder: (_, _) => const PlaceholderScreen('family'),
  ),
  GoRoute(
    path: Paths.invite,
    builder: (_, _) => const PlaceholderScreen('invite'),
  ),
  GoRoute(
    path: Paths.newCode,
    builder: (_, _) => const PlaceholderScreen('newCode'),
  ),
  GoRoute(
    path: Paths.addChild,
    builder: (_, _) => const PlaceholderScreen('addChild'),
  ),
  GoRoute(
    path: Paths.rights,
    builder: (_, _) => const PlaceholderScreen('rights'),
  ),
  GoRoute(
    path: Paths.notify,
    builder: (_, _) => const PlaceholderScreen('notify'),
  ),
  GoRoute(
    path: Paths.signOut,
    builder: (_, _) => const PlaceholderScreen('signOut'),
  ),
  GoRoute(
    path: '/grown-ups/family/phones/:deviceId/remove',
    builder: (_, _) => const PlaceholderScreen('removePhone'),
  ),
  GoRoute(
    path: '/grown-ups/children/:childId/book',
    builder: (_, _) => const PlaceholderScreen('book'),
  ),
  GoRoute(
    path: '/grown-ups/children/:childId/plan',
    builder: (_, _) => const PlaceholderScreen('plan'),
  ),
  GoRoute(
    path: '/grown-ups/children/:childId/report',
    builder: (_, _) => const PlaceholderScreen('report'),
  ),
  GoRoute(
    path: '/grown-ups/children/:childId/month',
    builder: (_, _) => const PlaceholderScreen('month'),
  ),
];

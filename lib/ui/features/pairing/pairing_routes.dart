import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import '../../../ui/core/parts/placeholder_screen.dart';

/// The child's phone and the shared-phone picker (Open, GetCode, CodeWrong, WhichChild, IsThisYou, PhoneJoined, Removed, A1, OtherPhone).
List<RouteBase> pairingRoutes(Deps deps) => [
  GoRoute(path: Paths.open, builder: (_, _) => const PlaceholderScreen('open')),
  GoRoute(path: Paths.pair, builder: (_, _) => const PlaceholderScreen('pair')),
  GoRoute(
    path: Paths.pairWrong,
    builder: (_, _) => const PlaceholderScreen('pairWrong'),
  ),
  GoRoute(
    path: Paths.pairWhichChild,
    builder: (_, _) => const PlaceholderScreen('pairWhichChild'),
  ),
  GoRoute(
    path: Paths.pairIsThisYou,
    builder: (_, _) => const PlaceholderScreen('pairIsThisYou'),
  ),
  GoRoute(
    path: Paths.pairJoined,
    builder: (_, _) => const PlaceholderScreen('pairJoined'),
  ),
  GoRoute(
    path: Paths.removed,
    builder: (_, _) => const PlaceholderScreen('removed'),
  ),
  GoRoute(path: Paths.kids, builder: (_, _) => const PlaceholderScreen('kids')),
  GoRoute(
    path: Paths.carryOn,
    builder: (_, _) => const PlaceholderScreen('carryOn'),
  ),
];

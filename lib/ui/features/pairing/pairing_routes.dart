import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/carry_on_screen.dart';
import 'views/code_wrong_screen.dart';
import 'views/get_code_screen.dart';
import 'views/is_this_you_screen.dart';
import 'views/kids_screen.dart';
import 'views/open_screen.dart';
import 'views/phone_joined_screen.dart';
import 'views/removed_screen.dart';
import 'views/which_child_screen.dart';

/// The child's phone and the shared-phone picker (Open, GetCode, CodeWrong, WhichChild, IsThisYou, PhoneJoined, Removed, A1, OtherPhone).
List<RouteBase> pairingRoutes(Deps deps) => [
  GoRoute(path: Paths.open, builder: (_, _) => const OpenScreen()),
  GoRoute(
    path: Paths.pair,
    builder: (_, _) =>
        GetCodeScreen(account: deps.account, family: deps.family),
  ),
  GoRoute(
    path: Paths.pairWrong,
    builder: (_, s) =>
        CodeWrongScreen(tooMany: s.uri.queryParameters['tooMany'] == '1'),
  ),
  GoRoute(
    path: Paths.pairWhichChild,
    builder: (_, _) => WhichChildScreen(family: deps.family),
  ),
  GoRoute(
    path: Paths.pairIsThisYou,
    // `?id=<childId>&name=<name>`; without them, ask which child
    redirect: (_, s) => s.uri.queryParameters['id'] == null
        ? Paths.pairWhichChild
        : null,
    builder: (_, s) => IsThisYouScreen(
      account: deps.account,
      childId: s.uri.queryParameters['id']!,
      name: s.uri.queryParameters['name'] ?? '',
    ),
  ),
  GoRoute(
    path: Paths.pairJoined,
    builder: (_, s) =>
        PhoneJoinedScreen(name: s.uri.queryParameters['name'] ?? ''),
  ),
  GoRoute(
    path: Paths.removed,
    builder: (_, _) => RemovedScreen(account: deps.account),
  ),
  GoRoute(
    path: Paths.kids,
    builder: (_, _) => KidsScreen(account: deps.account, family: deps.family),
  ),
  GoRoute(
    path: Paths.carryOn,
    builder: (_, s) => CarryOnScreen(device: s.uri.queryParameters['device']),
  ),
];

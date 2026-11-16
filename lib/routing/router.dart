import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/voice.dart';
import '../deps.dart';
import '../ui/features/child_home/child_routes.dart';
import '../ui/features/grown_ups/grown_up_routes.dart';
import '../ui/features/pairing/pairing_routes.dart';
import '../ui/features/quick_sums/quick_sums_routes.dart';
import '../ui/features/setup/setup_routes.dart';
import 'lesson_route.dart';
import 'redirect.dart';

/// The app's one navigator.
///
/// - Switching area (setup → child, child → grown-ups) uses `go`, which
///   replaces the stack, so finished flows never pile up underneath.
/// - Steps inside an area use `push`, so ← and Android's back pop them.
/// - [redirectFor] guards every route; it reruns when the account changes.
GoRouter buildRouter(Deps deps, {String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? '/',
  // a new screen hushes the last one's line (the prototype's go(): hush())
  observers: [HushOnLeave(deps.voice)],
  refreshListenable: deps.account,
  redirect: (context, state) => redirectFor(
    uri: state.uri,
    role: deps.account.role,
    removed: deps.account.removed,
    grownUpsUnlocked: deps.account.grownUpsUnlocked,
    childId: deps.account.childId,
    // "I agree" given on Data and the child not saved yet: setup is signing in
    settingUp: deps.account.draft.agreed,
  ),
  errorBuilder: (context, state) => _NotFound(state.uri.toString()),
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, _) => null,
      builder: (_, _) => const SizedBox(),
    ),
    ...setupRoutes(deps),
    ...pairingRoutes(deps),
    ...childRoutes(deps),
    ...grownUpRoutes(deps),
    ...lessonRoutes(deps),
    ...quickSumsRoutes(deps),
  ],
);

/// A link the app doesn't know (an old email, a typo): say so, and offer
/// the way home rather than a blank screen.
class _NotFound extends StatelessWidget {
  const _NotFound(this.location);

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "That page doesn't exist: $location",
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Go home'),
          ),
        ],
      ),
    ),
  );
}

/// Stops the voice whenever the screen changes, as the prototype's `go()`
/// calls `hush()` first: a line never carries on over the next screen,
/// which then says its own.
class HushOnLeave extends NavigatorObserver {
  HushOnLeave(this.voice);

  final Voice voice;

  void _hush(Route<dynamic>? route) {
    // a dialog or sheet over the screen leaves its line playing
    if (route is PageRoute) unawaited(voice.stop());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _hush(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _hush(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _hush(newRoute);
}

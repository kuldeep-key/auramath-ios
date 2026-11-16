import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/material.dart';

import 'motion.dart';

/// How a screen arrives, as the prototype's router (`go()` and its `TR`
/// table: 420 ms, [AuraCurves.screen]). A plain route arrives as `push`
/// ([AuraPushTransitionsBuilder]); these are the others.
enum Arrive {
  /// In from the right as the screen below slides 28 % left and dims to
  /// 0.6 (the prototype's `push`; popping it is its `back`).
  push,

  /// From the bottom; the screen below dims a little.
  rise,

  /// Cross-fades with the screen below.
  fade,

  /// In from 1.12× as the screen below shrinks to 0.92× and fades.
  zoom,
}

/// A go_router page that arrives as [arrive] says. Use it from a route's
/// `pageBuilder`: `MotionPage(key: state.pageKey, arrive: …, child: …)`.
class MotionPage<T> extends Page<T> {
  const MotionPage({super.key, required this.arrive, required this.child});

  final Arrive arrive;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _MotionRoute<T>(this);
}

class _MotionRoute<T> extends PageRoute<T> {
  _MotionRoute(MotionPage<T> page) : super(settings: page);

  MotionPage<T> get _page => settings as MotionPage<T>;

  @override
  Duration get transitionDuration => AuraDurations.screen;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (calmMotion(context)) return child;
    final t = screenCurve(animation);
    return switch (_page.arrive) {
      Arrive.push => _pushIn(t, child),
      Arrive.rise => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      ),
      Arrive.fade => FadeTransition(opacity: t, child: child),
      Arrive.zoom => FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: 1.12, end: 1.0).animate(t),
          child: child,
        ),
      ),
    };
  }

  /// The screen below leaves to match.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) {
        if (child == null || calmMotion(context)) return child;
        final t = screenCurve(secondaryAnimation);
        return switch (_page.arrive) {
          Arrive.push => _pushBelow(t, child),
          Arrive.rise => FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.7).animate(t),
            child: child,
          ),
          Arrive.fade => FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(t),
            child: child,
          ),
          Arrive.zoom => FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(t),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.92).animate(t),
              child: child,
            ),
          ),
        };
      };
}

/// [animation] on the prototype's screen curve, played forwards in time
/// both ways: a screen leaving eases out as one arriving does, as each
/// Web Animation in `go()` does.
Animation<double> screenCurve(Animation<double> animation) => CurvedAnimation(
  parent: animation,
  curve: AuraCurves.screen,
  reverseCurve: AuraCurves.screen.flipped,
);

/// The prototype's `push`, arriving: in from 100 % to the right.
Widget _pushIn(Animation<double> t, Widget child) => SlideTransition(
  position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(t),
  child: child,
);

/// The prototype's `push`, the screen below: 28 % to the left, dimming
/// to 0.6 (and back again on `back`).
Widget _pushBelow(Animation<double> t, Widget child) => SlideTransition(
  position: Tween(begin: Offset.zero, end: const Offset(-0.28, 0)).animate(t),
  child: FadeTransition(
    opacity: Tween(begin: 1.0, end: 0.6).animate(t),
    child: child,
  ),
);

/// The prototype's `push` and `back` for every plain route: 420 ms on
/// [AuraCurves.screen], the screen below sliding 28 % and dimming to 0.6.
/// It keeps the iOS swipe back: the drag follows the finger, linearly.
class AuraPushTransitionsBuilder extends PageTransitionsBuilder {
  const AuraPushTransitionsBuilder();

  @override
  Duration get transitionDuration => AuraDurations.screen;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) {
        if (child == null || calmMotion(context)) return child;
        return _pushBelow(screenCurve(secondaryAnimation), child);
      };

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // the platform's swipe back, with its own slide held still: the
    // gesture drives this route's animation, drawn below as ours
    final swipe = CupertinoRouteTransitionMixin.buildPageTransitions<T>(
      route,
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      child,
    );
    if (calmMotion(context)) return swipe;
    final t = route.popGestureInProgress ? animation : screenCurve(animation);
    // below another plain route, which shares this transition, the
    // secondary animation is ours to draw; below any other route it is
    // held still and that route's [delegatedTransition] draws it
    final below = route.popGestureInProgress
        ? secondaryAnimation
        : screenCurve(secondaryAnimation);
    return _pushBelow(below, _pushIn(t, swipe));
  }
}

/// Every platform slides screens in from the side, as the prototype's push
/// (Android too), keeping the swipe back.
const auraPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: AuraPushTransitionsBuilder(),
    TargetPlatform.android: AuraPushTransitionsBuilder(),
    TargetPlatform.macOS: AuraPushTransitionsBuilder(),
  },
);

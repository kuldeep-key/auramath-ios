import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'motion.dart';

/// How a screen arrives, as the prototype's router (420 ms). `push` is the
/// platform's own slide, which keeps iOS's swipe back; these are the others.
enum Arrive {
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
  Duration get transitionDuration => const Duration(milliseconds: 420);

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
    final t = CurvedAnimation(parent: animation, curve: AuraCurves.screen);
    return switch (_page.arrive) {
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
        final t = CurvedAnimation(
          parent: secondaryAnimation,
          curve: AuraCurves.screen,
        );
        return switch (_page.arrive) {
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

/// Every platform slides screens in from the side, as the prototype's push
/// (Android too), keeping the swipe back.
const auraPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  },
);

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The prototype's `sheet()` on the grown-up side: a white card that rises
/// from below over a navy scrim (a picker, a "Withdraw consent?" check).
///
/// - open: the card from 110 % below, 420 ms, `cubic-bezier(.2,1.1,.3,1)`
///   (`sheetUp`); the scrim fades in over 250 ms (`fade`);
/// - close: the card back down, 250 ms ease-in (`sheetDown`), the scrim
///   out with it (`fadeOut`);
/// - a tap on the scrim closes it, unless [modal].
///
/// Calm motion: it appears and goes without moving.
Future<T?> showAuraSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool modal = false,
}) => Navigator.of(
  context,
).push<T>(AuraSheetRoute<T>(builder: builder, modal: modal));

class AuraSheetRoute<T> extends PopupRoute<T> {
  AuraSheetRoute({required this.builder, this.modal = false});

  final WidgetBuilder builder;
  final bool modal;

  static const openDuration = Duration(milliseconds: 420);
  static const closeDuration = Duration(milliseconds: 250);

  /// The scrim: navy at 35 %.
  static const scrim = Color(0x590F2A73);

  @override
  Duration get transitionDuration => openDuration;

  @override
  Duration get reverseTransitionDuration => closeDuration;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  /// How far below its place the card is, as a share of its height.
  static double dropAt(double t, {required bool closing}) => closing
      ? 1.1 * Curves.easeIn.transform(1 - t)
      : 1.1 * (1 - AuraCurves.sheet.transform(t));

  /// The scrim's strength (0..1) at route value [t].
  static double scrimAt(double t, {required bool closing}) {
    if (closing) return Curves.ease.flipped.transform(t);
    final open = openDuration.inMilliseconds;
    return Curves.ease.transform((t * open / 250).clamp(0.0, 1.0));
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final calm = calmMotion(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, sheet) {
        final closing = animation.status == AnimationStatus.reverse;
        final t = animation.value;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: modal ? null : () => Navigator.of(context).maybePop(),
                child: ColoredBox(
                  color: scrim.withValues(
                    alpha:
                        scrim.a *
                        (calm
                            ? (closing ? 0.0 : 1.0)
                            : scrimAt(t, closing: closing)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14 + MediaQuery.paddingOf(context).bottom,
              child: FractionalTranslation(
                translation: Offset(0, calm ? 0 : dropAt(t, closing: closing)),
                child: sheet,
              ),
            ),
          ],
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 536,
            maxHeight: MediaQuery.sizeOf(context).height - 60,
          ),
          child: _Card(child: builder(context)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Container(
      key: const Key('auraSheet'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x730F2A73),
            offset: Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // the grab handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DCE8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  );
}

/// A sheet's title and line (`.sheet h3`, `.sheet p`): Black 26 and Bold
/// 20, centred.
class SheetHeading extends StatelessWidget {
  const SheetHeading({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AuraText.sheetTitle,
        ),
      ),
      if (body != null) ...[
        const SizedBox(height: 12),
        Text(body!, textAlign: TextAlign.center, style: AuraText.sheetLine),
      ],
      const SizedBox(height: 12),
    ],
  );
}

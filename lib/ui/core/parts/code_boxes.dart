import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// A short code shown one digit per box: the pairing code a grown-up reads
/// out (JoinCode, NewCode), the digits a child types (GetCode), the
/// passcode dots (GPass). The prototype's `.codebox`: white boxes 46 × 60
/// with a 2 pt line edge and a 3 pt lip; the box to type in next is blue
/// on blue tint. Boxes shrink to fit narrow phones.
///
/// A new [shake] number shakes the row (a wrong code): the prototype's
/// `.codebox.shake`, 400 ms, 8 pt left then right.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.length,
    required this.value,
    this.obscure = false,
    this.light = false,
    this.lit = false,
    this.cursor = true,
    this.shake = 0,
  });

  final int length;
  final String value;

  /// Dots instead of digits (a passcode).
  final bool obscure;

  /// On the blue play background: navy edges and lip, navy digits.
  final bool light;

  /// Every box blue (NewCode's fresh code, `span.f` on each).
  final bool lit;

  /// The next box to type in is blue; off for a code that is only shown.
  final bool cursor;

  /// Shakes the row each time it changes.
  final int shake;

  static const boxWidth = 46.0;
  static const boxHeight = 60.0;

  // No LayoutBuilder: pages ask their body for its intrinsic height
  // (AuraPage), which a LayoutBuilder can't answer.
  @override
  Widget build(BuildContext context) => Semantics(
    label: obscure
        ? '${value.length} of $length digits'
        : value.split('').join(' '),
    excludeSemantics: true,
    child: Shake(
      trigger: shake,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: boxWidth),
                child: AspectRatio(
                  aspectRatio: boxWidth / boxHeight,
                  child: _box(i),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _box(int i) {
    final on = lit || (cursor && i == value.length);
    final edge = light ? AuraColors.navy : AuraColors.line;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? AuraColors.blueTint : AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.small),
        // on the play background navy wins over the blue (`.scr.play`)
        border: Border.all(
          color: on && !light ? AuraColors.blue : edge,
          width: 2,
        ),
        boxShadow: [BoxShadow(color: edge, offset: Offset(0, light ? 4 : 3))],
      ),
      child: i < value.length
          ? FittedBox(
              child: Text(
                obscure ? '●' : value[i],
                style: AuraText.codeDigit.copyWith(
                  color: light ? AuraColors.navy : AuraColors.ink,
                ),
              ),
            )
          : null,
    );
  }
}

/// The prototype's `shake` (400 ms, ease): 8 pt left at a quarter, 8 pt
/// right at three quarters, home at the end. Plays each time [trigger]
/// changes; still under calm motion.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  static const duration = Duration(milliseconds: 400);

  static const _frames = [(0.0, 0.0), (0.25, -8.0), (0.75, 8.0), (1.0, 0.0)];

  /// Where the row is at [t] (0..1). As in CSS, `ease` runs within each
  /// pair of keyframes, not across the whole.
  static double offsetAt(double t) {
    for (var i = 1; i < _frames.length; i++) {
      final (t1, v1) = _frames[i];
      if (t <= t1) {
        final (t0, v0) = _frames[i - 1];
        return v0 + (v1 - v0) * Curves.ease.transform((t - t0) / (t1 - t0));
      }
    }
    return 0;
  }

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Shake.duration);

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !calmMotion(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(_c.isAnimating ? Shake.offsetAt(_c.value) : 0, 0),
      child: child,
    ),
  );
}

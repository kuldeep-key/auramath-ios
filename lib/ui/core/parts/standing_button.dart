import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// How a standing button asks to be noticed. Never a popup.
enum Attention { none, pulse, shake }

/// "I know it" and "Help me", always on the lesson board.
/// Figma: Prototype parts › Standing button.
class StandingButton extends StatefulWidget {
  const StandingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor = AuraColors.blue,
    this.attention = Attention.none,
    this.nudge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color iconColor;
  final Attention attention;

  /// Shown above the button for 4.2 s when it shakes.
  final String? nudge;

  @override
  State<StandingButton> createState() => _StandingButtonState();
}

class _StandingButtonState extends State<StandingButton>
    with SingleTickerProviderStateMixin {
  // the prototype's shake: 0.6 s, twice
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  Timer? _nudgeTimer;
  bool _showNudge = false;

  /// Each pulse plays the halo three times (1.2 s each).
  int _pulses = 0;

  @override
  void initState() {
    super.initState();
    _react();
  }

  @override
  void didUpdateWidget(StandingButton old) {
    super.didUpdateWidget(old);
    if (old.attention != widget.attention) _react();
  }

  void _react() {
    if (widget.attention == Attention.none) return;
    if (widget.attention == Attention.pulse) {
      _pulses++;
      return;
    }
    _anim.forward(from: 0);
    if (widget.attention == Attention.shake && widget.nudge != null) {
      _showNudge = true;
      _nudgeTimer?.cancel();
      _nudgeTimer = Timer(const Duration(milliseconds: 4200), () {
        if (mounted) setState(() => _showNudge = false);
      });
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          AuraHaptics.tap();
          widget.onPressed();
        },
        child: PressScale(
          child: Loop(
            key: ValueKey(_pulses),
            period: const Duration(milliseconds: 1200),
            times: _pulses == 0 ? 0 : 3,
            builder: (context, t, child) {
              // the prototype's helpPulse: a blue halo and edge at halfway
              final k = _pulses == 0 ? 0.0 : halfway(t);
              return Container(
                constraints: const BoxConstraints(minHeight: 72),
                decoration: BoxDecoration(
                  color: AuraColors.white,
                  borderRadius: BorderRadius.circular(AuraRadii.panel),
                  border: Border.all(
                    color: Color.lerp(AuraColors.line, AuraColors.blue, k)!,
                    width: 2,
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: AuraColors.line,
                      offset: Offset(0, 4),
                    ),
                    if (k > 0)
                      BoxShadow(
                        color: AuraColors.blue.withValues(alpha: 0.25 * k),
                        spreadRadius: 8 * k,
                      ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 24),
                Text(widget.label, style: AuraText.standing),
              ],
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            if (!_anim.isAnimating || calmMotion(context)) return child!;
            // the prototype's shake keyframes, twice
            final t = Curves.easeInOut.transform((_anim.value * 2) % 1);
            const x = [(0.0, 0.0), (0.2, -8.0), (0.4, 8.0), (0.6, -5.0)];
            const turn = [(0.0, 0.0), (0.2, -2.0), (0.4, 2.0), (0.6, 0.0)];
            return Transform.translate(
              offset: Offset(keyframes(t, [...x, (0.8, 5.0), (1.0, 0.0)]), 0),
              child: Transform.rotate(
                angle: keyframes(t, [...turn, (1.0, 0.0)]) * math.pi / 180,
                child: child,
              ),
            );
          },
          child: button,
        ),
        if (_showNudge)
          Positioned(
            left: 0,
            right: 0,
            top: -44,
            child: Center(
              // the prototype's tipIn: up from 6 px below, from 0.96
              child: Entrance(
                duration: const Duration(milliseconds: 300),
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, -6 * (1 - t)),
                    child: Transform.scale(
                      scale: 0.96 + 0.04 * t,
                      child: child,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.nudge!,
                    style: AuraText.body.copyWith(color: AuraColors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

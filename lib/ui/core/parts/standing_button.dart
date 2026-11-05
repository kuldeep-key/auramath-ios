import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  Timer? _nudgeTimer;
  bool _showNudge = false;

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
        onTap: widget.onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.line, width: 2),
            boxShadow: const [
              BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 24),
              Text(widget.label, style: AuraText.standing),
            ],
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
            final t = _anim.value;
            return switch (widget.attention) {
              Attention.shake => Transform.translate(
                offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
                child: child,
              ),
              Attention.pulse => Transform.scale(
                scale: 1 + math.sin(t * math.pi) * 0.06,
                child: child,
              ),
              Attention.none => child!,
            };
          },
          child: button,
        ),
        if (_showNudge)
          Positioned(
            left: 0,
            right: 0,
            top: -44,
            child: Center(
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
      ],
    );
  }
}

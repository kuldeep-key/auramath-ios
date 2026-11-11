import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'speech_bubble.dart';

/// Speak button, the coach's line, and home. Figma: Prototype parts ›
/// Lesson header.
class LessonHeader extends StatelessWidget {
  const LessonHeader({
    super.key,
    required this.line,
    required this.onSpeak,
    required this.onHome,
    this.big = false,
    this.speaking,
  });

  final String line;
  final VoidCallback onSpeak;
  final VoidCallback onHome;

  /// Big words while the voice is resting.
  final bool big;

  /// While true, the speak button glows (the prototype's speakPulse).
  final ValueListenable<bool>? speaking;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ValueListenableBuilder(
        valueListenable: speaking ?? const _Quiet(),
        builder: (context, on, button) => on
            ? Loop(
                period: const Duration(seconds: 1),
                builder: (context, t, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.blue.withValues(
                          alpha: 0.25 * halfway(t),
                        ),
                        spreadRadius: 6 * halfway(t),
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: button,
              )
            : button!,
        child: _SquareButton(
          icon: Icons.volume_up_rounded,
          fill: AuraColors.blue,
          fg: AuraColors.white,
          label: 'Say it again',
          onTap: onSpeak,
        ),
      ),
      const SizedBox(width: 8),
      // a long line in large text (NFR-04) scrolls in the bubble rather
      // than pushing the board off the screen
      Expanded(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: big ? 200 : 128),
          child: SingleChildScrollView(
            child: SpeechBubble(text: line, big: big),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _SquareButton(
        icon: Icons.home_rounded,
        fill: AuraColors.white,
        fg: AuraColors.navy,
        label: 'Home',
        onTap: onHome,
      ),
    ],
  );
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.fill,
    required this.fg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color fill;
  final Color fg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: () {
        AuraHaptics.tap();
        onTap();
      },
      child: PressScale(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuraColors.navy, width: 3),
            boxShadow: const [
              BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: fg),
        ),
      ),
    ),
  );
}

/// No voice to follow: never speaking.
class _Quiet implements ValueListenable<bool> {
  const _Quiet();

  @override
  bool get value => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

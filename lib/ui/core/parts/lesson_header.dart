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
    this.onSeeQuestion,
    this.seeQuestionLabel = 'See the question',
    this.sidePath,
  });

  /// JRN-04: during a detour (TUT-08), the case paused, a short side path
  /// to the skill, and the way back to the same step; its words for screen
  /// readers. Null: not on a detour. Nothing is added to the trail.
  final ({String label, String back})? sidePath;

  final String line;
  final VoidCallback onSpeak;
  final VoidCallback onHome;

  /// Big words while the voice is resting.
  final bool big;

  /// While true, the speak button glows (the prototype's speakPulse).
  final ValueListenable<bool>? speaking;

  /// "See the question" on a working screen without the question strip
  /// (show me how, a side lesson): LES-02. Null: no button.
  final VoidCallback? onSeeQuestion;
  final String seeQuestionLabel;

  @override
  Widget build(BuildContext context) => switch (sidePath) {
    null => _row(context),
    final p => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        _row(context),
        SidePath(label: p.label, back: p.back),
      ],
    ),
  };

  Widget _row(BuildContext context) => Row(
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
      if (onSeeQuestion case final see?) ...[
        const SizedBox(width: 8),
        _SquareButton(
          key: const Key('seeQuestion'),
          icon: Icons.visibility_rounded,
          fill: AuraColors.blue,
          fg: AuraColors.white,
          label: seeQuestionLabel,
          onTap: see,
        ),
      ],
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

/// JRN-04 (journey.yaml `side_path`): a small out-and-back path in the
/// lesson header: the case, paused, a short dotted path out to the skill
/// (where the child is now), and the arrow back to the same step. DRAFT
/// for Apoorv: placeholder shapes, no numbers.
class SidePath extends StatelessWidget {
  const SidePath({super.key, required this.label, required this.back});

  final String label;
  final String back;

  @override
  Widget build(BuildContext context) {
    Widget dot(IconData icon, Color fill, Color fg) => Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: AuraColors.navy, width: 2),
      ),
      child: Icon(icon, size: 12, color: fg),
    );
    Widget dots() => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuraColors.navy,
              ),
            ),
        ],
      ),
    );
    return Semantics(
      key: const Key('sidePath'),
      label: '$label. $back',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: AuraColors.yellowTint,
          borderRadius: BorderRadius.circular(AuraRadii.small),
        ),
        child: Row(
          children: [
            // the case, paused
            dot(Icons.pause_rounded, AuraColors.white, AuraColors.navy),
            dots(),
            // the skill: the child is here
            dot(Icons.place_rounded, AuraColors.yellow, AuraColors.navy),
            dots(),
            // and back to the same step
            dot(Icons.undo_rounded, AuraColors.white, AuraColors.blueInk),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    super.key,
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

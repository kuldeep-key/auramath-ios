import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'speak_button.dart';
import 'speech_bubble.dart';

/// The tutor's speak button, the coach's line, and home: the prototype's
/// `lhead`. Figma: Prototype parts › Lesson header.
///
/// The tutor is the lesson's sound switch: a tap mutes it, and a tap while
/// muted turns the sound back on and reads the line.
class LessonHeader extends StatelessWidget {
  const LessonHeader({
    super.key,
    required this.line,
    required this.onSpeak,
    required this.muted,
    required this.onSound,
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

  /// Nothing is read aloud: the button shows the muted speaker.
  final bool muted;

  /// The sound turned on (true) or muted (false).
  final ValueChanged<bool> onSound;
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

  /// The tutor, the line and the buttons (24 Nov): every button as wide
  /// as the tutor and as tall as the line beside it, so the row reads as
  /// one: the line sets the height, never less than a button's.
  Widget _row(BuildContext context) {
    const side = TutorSpeakButton.size, gap = 8.0;
    final see = onSeeQuestion;
    final right = see == null ? side : 2 * side + gap;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // a long line in large text (NFR-04) scrolls in the bubble rather
        // than pushing the board off the screen
        Padding(
          padding: EdgeInsets.only(left: side + gap, right: right + gap),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: big ? 200 : 128),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: side),
                child: SpeechBubble(text: line, big: big),
              ),
            ),
          ),
        ),
        // the child's tutor: it talks while the line plays (TTR-03, TTR-05),
        // and is the lesson's mute (a tap mutes; muted, a tap reads again)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: side,
          child: TutorSpeakButton(
            speaking: speaking,
            muted: muted,
            fill: true,
            label: muted ? 'Sound on' : 'Mute',
            onTap: muted
                ? () {
                    onSound(true);
                    onSpeak();
                  }
                : () => onSound(false),
          ),
        ),
        if (see != null)
          Positioned(
            right: side + gap,
            top: 0,
            bottom: 0,
            width: side,
            child: _SquareButton(
              key: const Key('seeQuestion'),
              icon: Icons.visibility_rounded,
              fill: AuraColors.blue,
              fg: AuraColors.white,
              label: seeQuestionLabel,
              onTap: see,
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: side,
          child: _SquareButton(
            icon: Icons.home_rounded,
            fill: AuraColors.white,
            fg: AuraColors.navy,
            label: 'Home',
            onTap: onHome,
          ),
        ),
      ],
    );
  }
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
        // as big as the header makes it: the tutor's width, the line's
        // height
        child: Container(
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

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The case partner's voice for the child's screens outside the lesson
/// board (NFR-06): whatever reads a line aloud. The app puts one above its
/// routes; without one no speaker shows.
class ReadAloud extends InheritedWidget {
  const ReadAloud({super.key, required this.say, required super.child});

  final void Function(String text) say;

  static ReadAloud? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReadAloud>();

  @override
  bool updateShouldNotify(ReadAloud old) => old.say != say;
}

/// The speaker on a child's screen (NFR-06): reads [text] aloud, 56 pt
/// (NFR-02). Shows nothing when there's no [ReadAloud] or nothing to say.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final voice = ReadAloud.maybeOf(context);
    if (voice == null || text.trim().isEmpty) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.kidReadToMe,
      child: GestureDetector(
        key: const Key('speak'),
        onTap: () {
          AuraHaptics.tap();
          voice.say(text);
        },
        child: PressScale(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AuraColors.blue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AuraColors.navy, width: 3),
              boxShadow: const [
                BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.volume_up_rounded, color: AuraColors.white),
          ),
        ),
      ),
    );
  }
}

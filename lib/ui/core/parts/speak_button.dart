import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../data/services/sound_effects.dart';
import '../../../l10n/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'journey_art.dart';

/// The case partner's voice for the child's screens outside the lesson
/// board (NFR-06): whatever reads a line aloud, and whether a line is
/// playing now ([speaking], for the speakers' pulse). The app puts one
/// above its routes; without one no speaker shows.
class ReadAloud extends InheritedWidget {
  const ReadAloud({
    super.key,
    required this.say,
    this.speaking,
    required super.child,
  });

  final void Function(String text) say;
  final ValueListenable<bool>? speaking;

  static ReadAloud? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReadAloud>();

  @override
  bool updateShouldNotify(ReadAloud old) =>
      old.say != say || old.speaking != speaking;
}

/// The prototype's `.speak` fill: a blue that lightens to the top.
const speakGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF5B8CFF), AuraColors.blue],
);

/// The speaker on a child's screen (NFR-06): reads [text] aloud, 56 pt
/// (NFR-02). As the prototype's `.speak`: a blue square lightening to the
/// top, navy edge and lip, and while a line plays a blue ring pulses
/// round it once a second (`speakPulse`). Shows nothing when there's no
/// [ReadAloud] or nothing to say.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final voice = ReadAloud.maybeOf(context);
    if (voice == null || text.trim().isEmpty) return const SizedBox.shrink();
    final button = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: speakGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.navy, width: 3),
        boxShadow: const [
          BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.volume_up_rounded, color: AuraColors.white),
    );
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
          child: SpeakingPulse(
            speaking: voice.speaking,
            radius: 16,
            child: button,
          ),
        ),
      ),
    );
  }
}

/// [child] with the prototype's `speakPulse` while [speaking] is true.
class SpeakingPulse extends StatelessWidget {
  const SpeakingPulse({
    super.key,
    required this.speaking,
    required this.child,
    this.radius = 16,
  });

  final ValueListenable<bool>? speaking;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => speaking == null
      ? child
      : VoiceWatch(
          voice: speaking!,
          builder: (context, on) =>
              PulseRing.speak(radius: radius, on: on, child: child),
        );
}

/// Rebuilds with [voice]'s value, as [ValueListenableBuilder] does, but
/// takes a change that comes mid-build (a screen that speaks as it builds)
/// on the next frame instead of failing.
class VoiceWatch extends StatefulWidget {
  const VoiceWatch({super.key, required this.voice, required this.builder});

  final ValueListenable<bool> voice;
  final Widget Function(BuildContext context, bool on) builder;

  @override
  State<VoiceWatch> createState() => _VoiceWatchState();
}

class _VoiceWatchState extends State<VoiceWatch> {
  late bool _on = widget.voice.value;

  void _changed() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _changed());
      return;
    }
    if (_on != widget.voice.value) setState(() => _on = widget.voice.value);
  }

  @override
  void initState() {
    super.initState();
    widget.voice.addListener(_changed);
  }

  @override
  void didUpdateWidget(VoiceWatch old) {
    super.didUpdateWidget(old);
    if (old.voice != widget.voice) {
      old.voice.removeListener(_changed);
      widget.voice.addListener(_changed);
      _on = widget.voice.value;
    }
  }

  @override
  void dispose() {
    widget.voice.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _on);
}

/// The lesson header's speaker as the prototype's `.speak.tutorbtn`: the
/// child's tutor's head ([TutorScope]) on a white 60 pt square with a
/// navy edge and lip. While a line plays the tutor talks and the square
/// pulses (`speakPulse`); with the sound off a small navy speaker-off
/// badge sits on its corner (`.tmute`). Tapping hears the line again; in
/// a lesson header that passes [muted], it is the lesson's sound switch
/// instead: a tap mutes, and a tap while muted turns the sound back on and
/// reads the line.
class TutorSpeakButton extends StatelessWidget {
  const TutorSpeakButton({
    super.key,
    required this.onTap,
    this.speaking,
    this.label = 'Say it again',
    this.muted,
  });

  final VoidCallback onTap;
  final ValueListenable<bool>? speaking;
  final String label;

  /// The lesson's own mute: the badge shows while it is on, as it does
  /// while the app's sound is off ([AuraSound.soundOn]).
  final bool? muted;

  static const size = 60.0;

  @override
  Widget build(BuildContext context) {
    final tutor = TutorScope.of(context);
    Widget face(bool talking) => Container(
      width: size,
      height: size,
      // border 3, then the prototype's padding 3 2 1
      padding: const EdgeInsets.fromLTRB(2, 3, 2, 1),
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AuraColors.navy, width: 3),
        boxShadow: const [
          BoxShadow(color: AuraColors.navy, offset: Offset(0, 4)),
        ],
      ),
      child: FittedBox(
        child: TutorFigure(
          tutorId: tutor.tutorId,
          kind: tutor.kind,
          world: tutor.world,
          size: 48,
          headOnly: true,
          state: talking ? TutorState.talking : TutorState.idle,
        ),
      ),
    );
    final mute = VoiceWatch(
      voice: AuraSound.soundOn,
      builder: (context, on) => on && muted != true
          ? const SizedBox.shrink()
          : Container(
              key: const Key('tutorMute'),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AuraColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: AuraColors.white, width: 2),
              ),
              child: const Icon(
                Icons.volume_off_rounded,
                size: 15,
                color: AuraColors.white,
              ),
            ),
    );
    final talking = speaking ?? const _Quiet();
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const Key('tutorSpeak'),
        onTap: () {
          AuraHaptics.tap();
          onTap();
        },
        child: PressScale(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder(
                valueListenable: talking,
                builder: (context, on, _) =>
                    PulseRing.speak(radius: 18, on: on, child: face(on)),
              ),
              Positioned(right: -6, bottom: -6, child: mute),
            ],
          ),
        ),
      ),
    );
  }
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

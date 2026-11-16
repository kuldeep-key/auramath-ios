import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/journey_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/parts/speech_bubble.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';

/// One choice on a picker: its id, what a screen reader calls it, and its
/// picture. Never labelled or sorted by gender (looks.yaml rules).
typedef Choice = ({String id, String label, Widget art});

/// A picker the journey uses for looks, tutors, voices and worlds
/// (ACC-12, TTR-01, TTR-06, REW-22): the choices as large tiles, "Surprise
/// me" where the spec offers it (it picks one at random; the child sees
/// it and can pick again), then "Choose this one", which [onChoose]s it.
/// [onHear] plays a choice's hello (tutors and voices). [disabled] tiles
/// are greyed with no name ("Coming soon" worlds). DRAFT for Apoorv: no
/// Figma frame for the tutor and voice pickers yet; LookPick's eight.
class JourneyPicker extends StatefulWidget {
  const JourneyPicker({
    super.key,
    required this.prompt,
    required this.choices,
    required this.onChoose,
    this.current,
    this.surprise = false,
    this.onHear,
    this.disabled = 0,
    this.disabledLabel,
    this.firstRun = false,
    this.tile = 96,
    this.random,
    this.failedText,
  });

  /// What to say when a save fails; by default "That didn't save".
  final String? Function(Exception)? failedText;

  /// The tutor's line above the choices (`line.pick.*`).
  final String prompt;
  final List<Choice> choices;
  final String? current;
  final bool surprise;
  final ValueChanged<String>? onHear;

  /// Saves the pick; throws when it can't be (offline, refused).
  final Future<void> Function(String id) onChoose;
  final int disabled;
  final String? disabledLabel;

  /// In first run there is no way home: the step is answered first.
  final bool firstRun;
  final double tile;
  final Random? random;

  @override
  State<JourneyPicker> createState() => _JourneyPickerState();
}

class _JourneyPickerState extends State<JourneyPicker> {
  late String? _picked = widget.current;
  bool _saving = false;
  bool _failed = false;
  String? _why;
  late final _random = widget.random ?? Random();

  void _pick(String id) {
    setState(() {
      _picked = id;
      _failed = false;
    });
    widget.onHear?.call(id);
  }

  Future<void> _choose() async {
    final id = _picked;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await widget.onChoose(id);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _why = widget.failedText?.call(e);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      say: widget.prompt,
      top: widget.firstRun
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Ribbon(text: widget.prompt),
            )
          : PlayHeader(title: widget.prompt),
      body: SingleChildScrollView(
        child: Column(
          spacing: 16,
          children: [
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final c in widget.choices)
                  Semantics(
                    button: true,
                    selected: c.id == _picked,
                    label: c.label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: Key('choice-${c.id}'),
                      onTap: () => _pick(c.id),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AuraRadii.panel),
                          border: Border.all(
                            color: c.id == _picked
                                ? AuraColors.yellow
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: SizedBox.square(
                          dimension: widget.tile,
                          child: c.art,
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < widget.disabled; i++)
                  Semantics(
                    label: widget.disabledLabel,
                    excludeSemantics: true,
                    child: Opacity(
                      opacity: 0.45,
                      child: Container(
                        width: widget.tile + 18,
                        height: widget.tile + 18,
                        decoration: BoxDecoration(
                          color: AuraColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AuraRadii.panel),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.disabledLabel ?? '',
                          textAlign: TextAlign.center,
                          style: AuraText.badgeNext,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_failed)
              Text(
                _why ?? l.kidSaveFailed,
                textAlign: TextAlign.center,
                style: AuraText.play,
              ),
          ],
        ),
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (widget.surprise)
            AuraButton(
              key: const Key('surprise'),
              label: l.kidSurpriseMe,
              icon: Icons.casino_rounded,
              color: AuraButtonColor.white,
              onPressed: () => _pick(
                widget.choices[_random.nextInt(widget.choices.length)].id,
              ),
            ),
          if (widget.onHear != null && _picked != null)
            AuraButton(
              label: l.kidHearHello,
              icon: Icons.volume_up_rounded,
              color: AuraButtonColor.white,
              onPressed: () => widget.onHear!(_picked!),
            ),
          AuraButton(
            key: const Key('choose'),
            label: l.kidChooseThis,
            onPressed: _picked == null || _saving ? null : _choose,
          ),
        ],
      ),
    );
  }
}

/// The eight looks (looks.yaml), in the file's order, named "Look 1" to
/// "Look 8" for screen readers until Key names them.
List<Choice> lookChoices(
  AppLocalizations l,
  JourneyConfig config,
  String world,
) => [
  for (final (i, look) in config.looks.indexed)
    (
      id: look.id,
      label: l.kidLookName(i + 1),
      art: LookPortrait(lookId: look.id, world: world, size: 96),
    ),
];

/// The enabled tutors (tutors.yaml), by name once Key names them.
List<Choice> tutorChoices(
  AppLocalizations l,
  JourneyConfig config,
  String world,
) => [
  for (final (i, t) in config.pickable.indexed)
    (
      id: t.id,
      label: t.name ?? l.kidTutorName(i + 1),
      art: TutorFigure(tutorId: t.id, kind: t.kind, world: world, size: 110),
    ),
];

/// The voice set (tutors.yaml `voices.enabled`).
List<Choice> voiceChoices(AppLocalizations l, JourneyConfig config) => [
  for (final (i, v) in config.voices.indexed)
    (
      id: v,
      label: l.kidVoiceName(i + 1),
      art: Container(
        decoration: BoxDecoration(
          color: AuraColors.white,
          borderRadius: BorderRadius.circular(AuraRadii.panel),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.record_voice_over_rounded,
              size: 44,
              color: AuraColors.blueInk,
            ),
            Text(l.kidVoiceName(i + 1), style: AuraText.small),
          ],
        ),
      ),
    ),
];

/// The worlds a child can choose (rules.yaml `worlds.enabled`), by name.
List<Choice> worldChoices(JourneyConfig config) => [
  for (final w in config.enabledWorlds)
    (
      id: w,
      label: config.wordsOf(w).name,
      art: ArtOr(
        artKey: 'art.picker.$w',
        size: 96,
        placeholder: Container(
          decoration: BoxDecoration(
            color: AuraColors.navy,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
          ),
          alignment: Alignment.center,
          child: Text(
            config.wordsOf(w).name,
            textAlign: TextAlign.center,
            style: AuraText.badgeNext,
          ),
        ),
      ),
    ),
];

/// The Me screen (JRN-02): the child's own choices, no passcode (PRV-06).
/// My look, My tutor and its voice, and My world only while the worlds
/// switch is on and two or more worlds are enabled. DRAFT: no Figma frame.
class MeScreen extends StatelessWidget {
  const MeScreen({
    super.key,
    required this.name,
    required this.lookId,
    required this.tutorId,
    required this.tutorKind,
    required this.world,
    required this.showWorld,
  });

  final String? name;
  final String lookId;
  final String tutorId;
  final String tutorKind;
  final String world;
  final bool showWorld;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget row(String label, Widget art, String path, Key key) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: key,
        onTap: () => context.push(path),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.navy, width: 3),
          ),
          child: Row(
            spacing: 14,
            children: [
              art,
              Expanded(child: Text(label, style: AuraText.option)),
              const Icon(Icons.chevron_right_rounded, color: AuraColors.navy),
            ],
          ),
        ),
      ),
    );
    return AuraPage(
      play: true,
      say: l.kidMe,
      top: PlayHeader(title: name ?? l.kidMe),
      body: SingleChildScrollView(
        child: Column(
          spacing: 14,
          children: [
            LookPortrait(lookId: lookId, world: world, size: 120),
            row(
              l.kidMyLook,
              LookPortrait(lookId: lookId, world: world, size: 56),
              Paths.avatar,
              const Key('myLook'),
            ),
            row(
              l.kidMyTutor,
              TutorFigure(
                tutorId: tutorId,
                kind: tutorKind,
                world: world,
                size: 56,
              ),
              Paths.pickTutor,
              const Key('myTutor'),
            ),
            row(
              l.kidMyVoice,
              const Icon(
                Icons.record_voice_over_rounded,
                size: 48,
                color: AuraColors.blueInk,
              ),
              Paths.pickVoice,
              const Key('myVoice'),
            ),
            if (showWorld)
              row(
                l.kidMyWorld,
                const Icon(
                  Icons.public_rounded,
                  size: 48,
                  color: AuraColors.blueInk,
                ),
                Paths.pickWorld,
                const Key('myWorld'),
              ),
          ],
        ),
      ),
    );
  }
}

/// The tutor's line in its speech bubble, under the tutor (Home's
/// greeting, Meet). Tapping the tutor hears it again (TTR-03).
class TutorSays extends StatelessWidget {
  const TutorSays({
    super.key,
    required this.tutorId,
    required this.tutorKind,
    required this.world,
    required this.line,
    required this.size,
    this.state = TutorState.idle,
    this.onTap,
  });

  final String tutorId;
  final String tutorKind;
  final String world;
  final String line;
  final double size;
  final TutorState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      Semantics(
        button: onTap != null,
        label: line,
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('tutor'),
          onTap: onTap,
          child: TutorFigure(
            tutorId: tutorId,
            kind: tutorKind,
            world: world,
            size: size,
            state: state,
          ),
        ),
      ),
      SpeechBubble(text: line),
    ],
  );
}

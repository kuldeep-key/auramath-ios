import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/journey_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/motion/motion.dart';
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
/// (ACC-12, TTR-01, TTR-06, REW-22), drawn as the prototype's LookPick and
/// TutorPick (16 Nov): the choices as big white tiles two to a row, the
/// one picked tinted yellow with a yellow ring and grown a little (200 ms);
/// [chooseLabel] ("This is me!") saves it, and "Surprise me" below is a
/// link that picks one at random (the child sees it and can pick again).
/// Tapping a choice plays its hello ([onHear], tutors and voices). Tiles
/// pop in 400 ms apart by 50 ms. [disabled] tiles are the dashed, unnamed
/// "Coming soon" worlds.
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
    this.aspect = 1,
    this.chooseLabel,
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

  /// A tile's width over its height: square looks, tall tutors.
  final double aspect;

  /// The save button's words; by default "Choose this one".
  final String? chooseLabel;
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
    final tiles = <Widget>[
      for (final (i, c) in widget.choices.indexed)
        Pop(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: i * 50),
          child: Semantics(
            button: true,
            selected: c.id == _picked,
            label: c.label,
            excludeSemantics: true,
            child: GestureDetector(
              key: Key('choice-${c.id}'),
              onTap: () => _pick(c.id),
              child: PickTile(
                picked: c.id == _picked,
                aspect: widget.aspect,
                child: c.art,
              ),
            ),
          ),
        ),
      for (var i = 0; i < widget.disabled; i++)
        Pop(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: (widget.choices.length + i) * 70),
          child: Semantics(
            label: widget.disabledLabel,
            excludeSemantics: true,
            child: _SoonTile(
              aspect: widget.aspect,
              label: widget.disabledLabel ?? '',
            ),
          ),
        ),
    ];
    return AuraPage(
      play: true,
      say: widget.prompt,
      top: widget.firstRun
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Ribbon(text: widget.prompt),
            )
          : PlayHeader(title: widget.prompt),
      body: SingleChildScrollView(
        // room for the picked tile's ring and lip
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
        child: Column(
          spacing: 14,
          children: [
            for (var i = 0; i < tiles.length; i += 2)
              Row(
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tiles[i]),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox(),
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
        spacing: 6,
        children: [
          AuraButton(
            key: const Key('choose'),
            label: widget.chooseLabel ?? l.kidChooseThis,
            onPressed: _picked == null || _saving ? null : _choose,
          ),
          if (widget.surprise)
            Center(
              child: TextButton.icon(
                key: const Key('surprise'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(56, 56),
                  foregroundColor: AuraColors.linkOnBlue,
                ),
                icon: const Icon(Icons.casino_rounded, size: 20),
                label: Text(
                  l.kidSurpriseMe,
                  style: AuraText.link.copyWith(color: AuraColors.linkOnBlue),
                ),
                onPressed: () => _pick(
                  widget.choices[_random.nextInt(widget.choices.length)].id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One choice on a picker: the prototype's `.lookgrid button` and
/// `.tpick`. White, a navy edge and 6 pt lip, radius 24; picked, it turns
/// yellow-tinted with a 5 pt yellow ring and grows to 1.04 (200 ms).
class PickTile extends StatelessWidget {
  const PickTile({
    super.key,
    required this.picked,
    required this.child,
    this.aspect = 1,
  });

  final bool picked;
  final double aspect;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: picked ? 1.04 : 1,
    duration: const Duration(milliseconds: 200),
    child: AspectRatio(
      aspectRatio: aspect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: picked ? AuraColors.yellowTint : AuraColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AuraColors.navy, width: 3),
          boxShadow: [
            if (picked)
              const BoxShadow(color: AuraColors.yellow, spreadRadius: 5),
            const BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
          ],
        ),
        child: FittedBox(child: child),
      ),
    ),
  );
}

/// A world that isn't open yet (`.tile.wsoon`): see-through white, a
/// light edge, a lock and "Coming soon", no name.
class _SoonTile extends StatelessWidget {
  const _SoonTile({required this.aspect, required this.label});

  final double aspect;
  final String label;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspect,
    child: Container(
      decoration: BoxDecoration(
        color: AuraColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AuraColors.white.withValues(alpha: 0.6),
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const Icon(Icons.lock_rounded, size: 40, color: AuraColors.white),
          Text(label, textAlign: TextAlign.center, style: AuraText.badgeNext),
        ],
      ),
    ),
  );
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
      art: LookPortrait(
        lookId: look.id,
        world: world,
        size: 130,
        framed: false,
      ),
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
/// switch is on and two or more worlds are enabled. Drawn as the
/// prototype's Me (16 Nov): Home and the title "Me" at the top, the child's
/// look large with their name, then a white row for each choice with what
/// it does underneath.
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
    Widget icon(IconData i) => Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.blueTint,
      ),
      child: Icon(i, color: AuraColors.navy),
    );
    Widget row(String label, String note, Widget art, String path, Key key) =>
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: key,
            onTap: () => context.push(path),
            child: MeRow(label: label, note: note, art: art),
          ),
        );
    return AuraPage(
      play: true,
      say: l.kidMe,
      top: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Row(
          children: [
            PlayIconButton(
              icon: Icons.home_rounded,
              tooltip: l.kidHome,
              onPressed: () => context.go(Paths.home),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l.kidMe,
                  textAlign: TextAlign.center,
                  style: AuraText.playTitle.copyWith(
                    fontSize: 26,
                    color: AuraColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          spacing: 14,
          children: [
            const SizedBox(height: 2),
            LookPortrait(lookId: lookId, world: world, size: 120),
            if (name != null)
              Text(
                name!,
                textAlign: TextAlign.center,
                style: AuraText.kidName.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 4),
            row(
              l.kidMyLook,
              l.kidMyLookNote,
              LookPortrait(lookId: lookId, world: world, size: 56),
              Paths.avatar,
              const Key('myLook'),
            ),
            row(
              l.kidMyTutor,
              l.kidMyTutorNote,
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                  color: AuraColors.blueTint,
                  child: TutorFigure(
                    tutorId: tutorId,
                    kind: tutorKind,
                    world: world,
                    size: 56,
                  ),
                ),
              ),
              Paths.pickTutor,
              const Key('myTutor'),
            ),
            row(
              l.kidMyVoice,
              l.kidMyVoiceNote,
              icon(Icons.record_voice_over_rounded),
              Paths.pickVoice,
              const Key('myVoice'),
            ),
            if (showWorld)
              row(
                l.kidMyWorld,
                l.kidMyWorldNote,
                icon(Icons.public_rounded),
                Paths.pickWorld,
                const Key('myWorld'),
              ),
          ],
        ),
      ),
    );
  }
}

/// A row on Me (the prototype's `.merow`): white, a navy edge and 5 pt
/// lip, radius 20, at least 76 pt tall; the picture, the choice in bold
/// with what it does under it, and a chevron.
class MeRow extends StatelessWidget {
  const MeRow({
    super.key,
    required this.label,
    required this.note,
    required this.art,
  });

  final String label;
  final String note;
  final Widget art;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 76),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AuraColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AuraColors.navy, width: 3),
      boxShadow: const [
        BoxShadow(color: AuraColors.navy, offset: Offset(0, 5)),
      ],
    ),
    child: Row(
      spacing: 14,
      children: [
        art,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AuraText.option.copyWith(
                  fontSize: 21,
                  color: AuraColors.navy,
                ),
              ),
              Text(
                note,
                style: AuraText.small.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AuraColors.meNote,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AuraColors.navy),
      ],
    ),
  );
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

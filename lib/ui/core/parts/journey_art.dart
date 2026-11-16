import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The art Apoorv delivers (D-59), by the spec's art keys
/// (`art.look.look_03.detective`, `art.tutor.robot.detective`,
/// `art.path.detective.mist`, ...): a file at `assets/art/<key>.png` is used
/// as soon as it is in the build, with no code change. Until then each
/// place draws its placeholder.
abstract final class ArtAssets {
  static Set<String> _have = const {};

  /// Reads which art files this build holds (once, at start).
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      _have = manifest.listAssets().toSet();
    } on Object {
      _have = const {};
    }
  }

  /// Whether the build holds the asset at [path].
  static bool has(String path) => _have.contains(path);

  /// The file for [key], if the build has it.
  static String? pathOf(String? key) {
    if (key == null) return null;
    final path = 'assets/art/$key.png';
    return _have.contains(path) ? path : null;
  }
}

/// [artKey]'s picture when the build has it, else [placeholder]. Hidden
/// from screen readers: the words beside it carry the meaning.
class ArtOr extends StatelessWidget {
  const ArtOr({
    super.key,
    required this.artKey,
    required this.size,
    required this.placeholder,
  });

  final String? artKey;
  final double size;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final path = ArtAssets.pathOf(artKey);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: path == null
            ? placeholder
            : Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// The placeholder for look [index] (0 to 7): a disc in one of the theme's
/// colours with a detective's tool on it. No face, hair or clothes, so
/// nothing implies a gender (looks.yaml rules); never red (NFR-03).
const lookPlaceholders = <({Color color, IconData icon})>[
  (color: AuraColors.blue, icon: Icons.search_rounded),
  (color: AuraColors.yellowLip, icon: Icons.fingerprint_rounded),
  (color: AuraColors.green, icon: Icons.key_rounded),
  (color: AuraColors.navy, icon: Icons.explore_rounded),
  (color: AuraColors.badgeGold, icon: Icons.lightbulb_rounded),
  (color: AuraColors.blueInk, icon: Icons.edit_note_rounded),
  (color: AuraColors.badgeBlueEdge, icon: Icons.star_rounded),
  (color: AuraColors.yellowInk, icon: Icons.extension_rounded),
];

/// The child's look ([lookId], `look_01` to `look_08`) in [world]'s
/// costume (looks.yaml `costume.<world>`): Apoorv's art once delivered,
/// else its placeholder disc.
class LookPortrait extends StatelessWidget {
  const LookPortrait({
    super.key,
    required this.lookId,
    required this.size,
    this.world = 'detective',
    this.framed = true,
  });

  final String lookId;
  final String world;
  final double size;

  /// The navy ring around the portrait (off on the look picker's tiles).
  final bool framed;

  static int indexOf(String lookId) {
    final n = int.tryParse(lookId.replaceFirst('look_', '')) ?? 1;
    return (n - 1).clamp(0, lookPlaceholders.length - 1);
  }

  /// The prototype's portrait for [lookId] in [world]
  /// (`assets/proto/look_01_detective.jpg` ...), drawn until Apoorv's art.
  static String? protoOf(String lookId, String world) =>
      ArtAssets.has('assets/proto/${lookId}_$world.jpg')
      ? 'assets/proto/${lookId}_$world.jpg'
      : null;

  @override
  Widget build(BuildContext context) {
    final p = lookPlaceholders[indexOf(lookId)];
    final proto = protoOf(lookId, world);
    // the prototype's `.avatar`: a round portrait on the yellow disc, a
    // navy ring (4 pt; 3 pt when small); [framed] false is the LookPick
    // tile's bare circle
    if (ArtAssets.pathOf('art.look.$lookId.$world') == null && proto != null) {
      return ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuraColors.yellow,
            border: framed
                ? Border.all(color: AuraColors.navy, width: size < 60 ? 3 : 4)
                : null,
          ),
          child: ClipOval(
            child: Image.asset(
              proto,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
      );
    }
    return ArtOr(
      artKey: 'art.look.$lookId.$world',
      size: size,
      placeholder: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.color,
          border: Border.all(color: AuraColors.navy, width: size < 60 ? 3 : 4),
        ),
        child: Icon(p.icon, size: size * 0.55, color: AuraColors.white),
      ),
    );
  }
}

/// The tutor's five animation states (tutors.yaml `animation`, TTR-04).
enum TutorState { idle, talking, thinking, cheering, encourage }

/// The tutor ([tutorId], its [kind] from tutors.yaml) in [world]'s costume
/// and its [state]. A placeholder until Apoorv's art: a rounded card, a
/// mortarboard for a teacher, a robot for the robot. Moves only while it
/// talks, thinks or cheers; still while the child works (idle), and a
/// still picture for every state with reduced motion. Never flashes,
/// never red.
class TutorFigure extends StatefulWidget {
  const TutorFigure({
    super.key,
    required this.tutorId,
    required this.size,
    this.kind = 'grown_up_teacher',
    this.world = 'detective',
    this.state = TutorState.idle,
  });

  final String tutorId;
  final String kind;
  final String world;
  final double size;
  final TutorState state;

  @override
  State<TutorFigure> createState() => _TutorFigureState();
}

class _TutorFigureState extends State<TutorFigure>
    with SingleTickerProviderStateMixin {
  late final _beat = AnimationController(
    vsync: this,
    // one gentle beat a second at most: far under three flashes a second
    duration: const Duration(milliseconds: 900),
  );

  bool get _moves => widget.state != TutorState.idle;
  TutorState? _ran;

  /// A few gentle beats when the state changes to one that moves, then
  /// still: a placeholder never loops (and a screen can settle).
  Future<void> _run(bool still) async {
    if (!_moves || still) {
      _beat
        ..stop()
        ..value = 0;
      _ran = null;
      return;
    }
    if (_ran == widget.state) return;
    _ran = widget.state;
    try {
      for (var i = 0; i < 2 && mounted && _ran == widget.state; i++) {
        await _beat.forward(from: 0).orCancel;
        await _beat.reverse().orCancel;
      }
    } on TickerCanceled {
      // disposed or stopped
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run(calmMotion(context));
  }

  @override
  void didUpdateWidget(TutorFigure old) {
    super.didUpdateWidget(old);
    _run(calmMotion(context));
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  static Color colorOf(String tutorId) => switch (tutorId) {
    'teacher_1' => AuraColors.blueInk,
    'teacher_2' => AuraColors.green,
    'robot' => AuraColors.navy,
    _ => AuraColors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final icon = widget.kind == 'robot'
        ? Icons.smart_toy_rounded
        : Icons.school_rounded;
    final badge = switch (widget.state) {
      TutorState.talking => Icons.graphic_eq_rounded,
      TutorState.thinking => Icons.more_horiz_rounded,
      TutorState.cheering => Icons.celebration_rounded,
      TutorState.encourage => Icons.thumb_up_rounded,
      TutorState.idle => null,
    };
    final placeholder = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colorOf(widget.tutorId),
              borderRadius: BorderRadius.circular(size * 0.28),
              border: Border.all(
                color: AuraColors.white,
                width: size < 80 ? 3 : 5,
              ),
            ),
            child: Icon(icon, size: size * 0.6, color: AuraColors.white),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -size * 0.06,
            top: -size * 0.06,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuraColors.yellow,
              ),
              child: Icon(badge, size: size * 0.24, color: AuraColors.navy),
            ),
          ),
      ],
    );
    return AnimatedBuilder(
      animation: _beat,
      builder: (_, child) =>
          Transform.scale(scale: 1 + _beat.value * 0.04, child: child),
      child: ArtOr(
        // one picture per state once drawn: art.tutor.<id>.<world>.<state>
        artKey:
            'art.tutor.${widget.tutorId}.${widget.world}'
            '${widget.state == TutorState.idle ? '' : '.${widget.state.name}'}',
        size: size,
        placeholder: placeholder,
      ),
    );
  }
}
